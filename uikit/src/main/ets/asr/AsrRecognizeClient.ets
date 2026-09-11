/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'
import AsrAuth from './AsrAuth'

const TAG = 'AsrRecognizeClient'

const CONNECT_TIMEOUT_MS = 15 * 1000
// asr-api 要先下载语音文件再识别，开启大模型纠错时还要等全部识别完才开始返回，超时时间长一些
const READ_TIMEOUT_MS = 2 * 60 * 1000
// 收到响应码之后等待 dataEnd 的最长时间。两者都是异步回调，先后顺序没有保证
const WAIT_DATA_END_MS = 1000

const SSE_DATA_PREFIX = 'data:'

export interface AsrRecognizeCallback {
    // 收到一段识别文本
    onText: (text: string) => void
    // 识别完成，之后不再回调
    onComplete: () => void
    // 请求失败，之后不再回调
    onError: (error: string) => void
}

interface RecognizeRequest {
    url: string
    noReuse: boolean
    noLlm: boolean
}

/**
 * 语音消息转文字客户端
 *
 * 请求 asr-api 的 /api/recognize，协议详见 asr-api 项目的 README.md：
 * 1. POST JSON {"url": 语音文件地址, "noReuse": true, "noLlm": false}，HTTP header authCode 中带上认证码
 * 2. asr-api 下载语音文件并识别，以 SSE 的形式逐段返回识别文本，每段文本是一个 data 事件
 *
 * 每次识别使用一个新实例，调用 cancel 之后不再回调。
 */
export default class AsrRecognizeClient {
    private httpRequest?: http.HttpRequest
    private callback?: AsrRecognizeCallback
    private decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
    // 已收到、还没有凑成完整事件的数据
    private buffer: string = ''
    private responseCode: number = -1
    private dataEnded: boolean = false
    private waitDataEndTimer: number = -1

    constructor(callback: AsrRecognizeCallback) {
        this.callback = callback
    }

    /**
     * 开始识别
     * @param address  asr-api 的 /api/recognize 地址
     * @param audioUrl 语音文件地址
     * @param authCode 从 IM 服务获取的认证码
     */
    recognize(address: string, audioUrl: string, authCode: string) {
        let request = http.createHttp()
        this.httpRequest = request
        request.on('dataReceive', (data: ArrayBuffer) => {
            if (this.httpRequest !== request) {
                return
            }
            // 流式解码，一个多字节字符被拆到两段数据里时也能正确解码
            this.buffer += this.decoder.decodeToString(new Uint8Array(data), { stream: true })
            this.handleEvents()
        })
        request.on('dataEnd', () => {
            if (this.httpRequest !== request) {
                return
            }
            this.dataEnded = true
            this.tryComplete()
        })

        let header: Record<string, string> = {
            'Content-Type': 'application/json',
            // 和 Android 一样用 */*：asr-api 的接口声明的是 produces application/json，只接受 text/event-stream 会匹配不上
            'Accept': '*/*'
        }
        header[AsrAuth.HEADER_AUTH_CODE] = authCode
        let body: RecognizeRequest = { url: audioUrl, noReuse: true, noLlm: false }
        console.log(TAG, 'recognize', audioUrl)
        request.requestInStream(address, {
            method: http.RequestMethod.POST,
            header: header,
            extraData: JSON.stringify(body),
            usingCache: false,
            connectTimeout: CONNECT_TIMEOUT_MS,
            readTimeout: READ_TIMEOUT_MS
        }).then((code: number) => {
            if (this.httpRequest !== request) {
                return
            }
            if (code < 200 || code >= 300) {
                console.error(TAG, 'response code', code)
                this.fail('HTTP ' + code)
                return
            }
            this.responseCode = code
            this.tryComplete()
        }).catch((err: BusinessError) => {
            console.error(TAG, `request failed, code=${err?.code}, message=${err?.message}`)
            if (this.httpRequest === request) {
                this.fail('请求失败: ' + (err?.message ?? ''))
            }
        })
    }

    /**
     * 取消识别，之后不再回调
     */
    cancel() {
        this.release()
    }

    /**
     * 响应码和 dataEnd 都收到之后结束识别；只收到响应码时，等一会儿 dataEnd
     */
    private tryComplete() {
        if (this.responseCode === -1) {
            return
        }
        if (this.dataEnded) {
            this.complete()
        } else if (this.waitDataEndTimer === -1) {
            this.waitDataEndTimer = setTimeout(() => {
                this.waitDataEndTimer = -1
                this.complete()
            }, WAIT_DATA_END_MS)
        }
    }

    /**
     * 处理已收到的完整事件，事件之间以空行分隔
     */
    private handleEvents() {
        let data = this.buffer.split('\r\n').join('\n')
        let end = data.indexOf('\n\n')
        while (end >= 0) {
            this.handleEvent(data.substring(0, end))
            data = data.substring(end + 2)
            end = data.indexOf('\n\n')
        }
        this.buffer = data
    }

    private handleEvent(event: string) {
        let lines: string[] = []
        for (let line of event.split('\n')) {
            if (line.startsWith(SSE_DATA_PREFIX)) {
                let value = line.substring(SSE_DATA_PREFIX.length)
                // 按 SSE 规范，冒号后的第一个空格不属于数据
                lines.push(value.startsWith(' ') ? value.substring(1) : value)
            }
        }
        let text = lines.join('\n')
        if (text.length > 0) {
            this.callback?.onText(text)
        }
    }

    private complete() {
        let cb = this.callback
        if (!cb) {
            return
        }
        this.buffer += this.decoder.decodeToString(new Uint8Array(0))
        this.handleEvents()
        // 最后一个事件后面可能没有空行
        if (this.buffer.trim().length > 0) {
            this.handleEvent(this.buffer.split('\r\n').join('\n'))
        }
        this.release()
        cb.onComplete()
    }

    private fail(error: string) {
        let cb = this.callback
        this.release()
        cb?.onError(error)
    }

    private release() {
        this.callback = undefined
        if (this.waitDataEndTimer !== -1) {
            clearTimeout(this.waitDataEndTimer)
            this.waitDataEndTimer = -1
        }
        this.buffer = ''
        let request = this.httpRequest
        this.httpRequest = undefined
        if (request) {
            request.off('dataReceive')
            request.off('dataEnd')
            request.destroy()
        }
    }
}
