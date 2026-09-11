/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import { webSocket } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import AsrAuth from './AsrAuth'

const TAG = 'AsrWebSocketClient'

const MESSAGE_EOS = 'eos'
const MESSAGE_PARTIAL = 'partial'
const MESSAGE_EOS_ACK = '[EOS]'
const MESSAGE_PARTIAL_PREFIX = '[PARTIAL]'
const MESSAGE_PONG = 'pong'
const MESSAGE_TRIAL_PREFIX = '[TRIAL]'

// 发送 eos 前补发约 500ms 静音，让不支持 eos 的旧版本 wf-voice 也能通过 VAD 断句，识别出最后一句。
// 静音和录音一样按 30ms（960 字节）一条消息发送，单条消息过大时 asr-api 或 wf-voice 会断开连接
const SILENCE_FRAME_BYTES = 960
const SILENCE_PADDING_FRAMES = 17

export interface AsrWebSocketCallback {
    // 连接成功，可以开始发送音频
    onConnected: () => void
    // 正在说的这句的中间结果，之后会被新的中间结果或这句的最终结果替换
    onPartialResult: (text: string) => void
    // 识别出一句的最终结果
    onResult: (text: string) => void
    // eos 之前的识别结果已全部返回
    onEos: () => void
    // 连接失败或连接被断开
    onError: (error: string) => void
}

/**
 * 实时语音识别 WebSocket 客户端
 *
 * 连接 asr-api 的 /api/stream，由 asr-api 鉴权后转发给 wf-voice；内网测试时也可以直连 wf-voice。
 * 协议详见 wf-voice 项目的 docs/server-api.md：
 * 1. 连接后发送的第一条文本消息是 clientId；需要边说边出字时，接着发送 partial
 * 2. 二进制消息发送 16kHz、16-bit、单声道 PCM
 * 3. 服务端每识别完一句，推送一条文本消息：[段开始毫秒时间戳+时长秒] 识别文本
 * 4. 发送过 partial 时，说话过程中还会推送正在说的这句的中间结果：[PARTIAL] 识别文本
 * 5. 说话结束时发送 eos，服务端推送完剩余识别结果后回复 [EOS]
 *
 * 每次识别使用一个新实例，调用 disconnect 之后不再回调。
 */
export default class AsrWebSocketClient {
    private ws?: webSocket.WebSocket
    private callback?: AsrWebSocketCallback
    // 等待发送的消息。WebSocket 的 send 在后台线程池中执行，连续调用时消息的发送顺序和调用顺序可能不一致，
    // 音频帧乱序后基本无法识别（例如连接成功后一次补发的录音），所以上一条消息发送完成后再发送下一条
    private sendQueue: Array<string | ArrayBuffer> = []
    private sending: boolean = false

    constructor(callback: AsrWebSocketCallback) {
        this.callback = callback
    }

    /**
     * 连接语音识别服务
     * @param address       WebSocket 地址，asr-api 或 wf-voice
     * @param clientId      客户端 ID，wf-voice 要求每个连接唯一
     * @param partialResult 是否边说边出字
     * @param authCode      连接 asr-api 时需要的认证码，直连 wf-voice 时传 null
     */
    connect(address: string, clientId: string, partialResult: boolean, authCode: string | null) {
        console.log(TAG, 'connecting', address)
        let ws = webSocket.createWebSocket()
        this.ws = ws
        ws.on('open', (err: BusinessError, value: Object) => {
            if (this.ws !== ws) {
                return
            }
            this.send(ws, clientId)
            if (partialResult) {
                this.send(ws, MESSAGE_PARTIAL)
            }
            this.callback?.onConnected()
        })
        ws.on('message', (err: BusinessError, data: string | ArrayBuffer) => {
            if (this.ws !== ws || typeof data !== 'string') {
                return
            }
            this.handleMessage(data as string)
        })
        ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
            console.log(TAG, `closed, code=${value?.code}, reason=${value?.reason}`)
            if (this.ws === ws) {
                this.callback?.onError('连接已断开')
            }
        })
        ws.on('error', (err: BusinessError) => {
            console.error(TAG, `error, code=${err?.code}, message=${err?.message}`)
            if (this.ws === ws) {
                this.callback?.onError('连接失败: ' + (err?.message ?? ''))
            }
        })

        let header: Record<string, string> = {}
        if (authCode) {
            header[AsrAuth.HEADER_AUTH_CODE] = authCode
        }
        let options: webSocket.WebSocketRequestOptions = { header: header }
        ws.connect(address, options).catch((err: BusinessError) => {
            console.error(TAG, `connect failed, code=${err?.code}, message=${err?.message}`)
            if (this.ws === ws) {
                this.callback?.onError('连接失败: ' + (err?.message ?? ''))
            }
        })
    }

    /**
     * 发送音频数据
     * @param pcm 16kHz、16-bit、单声道 PCM
     */
    sendAudioData(pcm: ArrayBuffer) {
        let ws = this.ws
        if (ws) {
            this.send(ws, pcm)
        }
    }

    /**
     * 通知服务端说话结束，服务端返回剩余识别结果后回调 onEos
     */
    sendEos() {
        let ws = this.ws
        if (!ws) {
            return
        }
        for (let i = 0; i < SILENCE_PADDING_FRAMES; i++) {
            this.send(ws, new ArrayBuffer(SILENCE_FRAME_BYTES))
        }
        this.send(ws, MESSAGE_EOS)
    }

    /**
     * 断开连接，之后不再回调
     */
    disconnect() {
        this.callback = undefined
        this.sendQueue = []
        let ws = this.ws
        this.ws = undefined
        if (!ws) {
            return
        }
        ws.off('open')
        ws.off('message')
        ws.off('close')
        ws.off('error')
        ws.close({ code: 1000, reason: '' }).catch((err: BusinessError) => {
            console.warn(TAG, 'close failed', err?.code)
        })
    }

    private send(ws: webSocket.WebSocket, data: string | ArrayBuffer) {
        this.sendQueue.push(data)
        this.sendNext(ws)
    }

    private sendNext(ws: webSocket.WebSocket) {
        if (this.sending || this.ws !== ws || this.sendQueue.length === 0) {
            return
        }
        const data: string | ArrayBuffer = this.sendQueue.shift() as string | ArrayBuffer
        this.sending = true
        ws.send(data)
            .catch((err: BusinessError) => {
                console.warn(TAG, 'send failed', err?.code)
            })
            .finally(() => {
                this.sending = false
                this.sendNext(ws)
            })
    }

    private handleMessage(message: string) {
        if (message === MESSAGE_EOS_ACK) {
            this.callback?.onEos()
        } else if (message.startsWith(MESSAGE_PARTIAL_PREFIX)) {
            let text = message.substring(MESSAGE_PARTIAL_PREFIX.length).trim()
            if (text.length > 0) {
                this.callback?.onPartialResult(text)
            }
        } else if (message.startsWith(MESSAGE_TRIAL_PREFIX)) {
            // 体验版每个连接只识别前 30 秒音频
            console.warn(TAG, message)
        } else if (message !== MESSAGE_PONG) {
            let text = AsrWebSocketClient.parseResultText(message)
            if (text.length > 0) {
                this.callback?.onResult(text)
            }
        }
    }

    /**
     * 去掉识别结果的时间前缀，例如 "[1740992313000+2.35] 你好，世界，" 返回 "你好，世界，"
     */
    private static parseResultText(message: string): string {
        if (message.startsWith('[')) {
            let end = message.indexOf(']')
            if (end > 0) {
                message = message.substring(end + 1)
            }
        }
        return message.trim()
    }
}
