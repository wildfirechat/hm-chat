/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import Config from '@wfc/client/src/main/ets/config'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import SoundMessageContent from '@wfc/client/src/main/ets/wfc/messages/soundMessageContent'
import { showToast } from '../common/utils/Toast'
import AsrAuth from './AsrAuth'
import AsrManager from './AsrManager'
import AsrRecognizeClient from './AsrRecognizeClient'

const TAG = 'SpeechToTextManager'

/**
 * 一条语音消息的转文字结果
 */
export class SpeechToTextResult {
    // 到目前为止识别出的文本
    text: string = ''
    // 是否正在识别
    recognizing: boolean = true
}

/**
 * 转文字结果有变化：开始识别、识别出新的文本、识别结束或取消
 * @param messageUid 语音消息的 messageUid
 */
export type SpeechToTextListener = (messageUid: string) => void

/**
 * 语音消息转文字
 *
 * 长按语音消息选择「转文字」后，请求 Config.ASR_SERVER_URL 识别，识别出的文本逐段显示在语音消息下面。
 * 结果按 messageUid 保存在内存里，消息列表项被回收重建后也能恢复；和 Android 一样不持久化。
 */
class SpeechToTextManager {
    private results: Map<string, SpeechToTextResult> = new Map()
    private clients: Map<string, AsrRecognizeClient> = new Map()
    private listeners: SpeechToTextListener[] = []

    /**
     * 语音消息是否可以转文字：配置了转文字服务，并且语音文件已经上传
     */
    canRecognize(message: Message): boolean {
        let content = message.messageContent as SoundMessageContent
        return !!Config.getAsrServerUrl() && !!content.remotePath
    }

    /**
     * 转文字结果，没有转过或者已经取消时返回 undefined
     */
    getResult(message: Message): SpeechToTextResult | undefined {
        return this.results.get(message.messageUid.toString())
    }

    /**
     * 开始转文字，已经转过或者正在转时忽略
     */
    recognize(message: Message) {
        let key = message.messageUid.toString()
        let address = Config.getAsrServerUrl()
        let content = message.messageContent as SoundMessageContent
        if (!address || !content.remotePath || this.results.has(key)) {
            return
        }
        let serverAddress: string = address
        let audioUrl: string = content.remotePath
        let result = new SpeechToTextResult()
        this.results.set(key, result)
        this.notify(key)

        // asr-api 需要在 header 中带上认证码
        AsrAuth.getAuthCode((authCode: string) => {
            // 获取认证码期间，可能已经取消
            if (this.results.get(key) !== result) {
                return
            }
            let client = new AsrRecognizeClient({
                onText: (text: string) => {
                    result.text = AsrManager.join(result.text, text)
                    this.notify(key)
                },
                onComplete: () => {
                    this.clients.delete(key)
                    result.text = result.text.trim()
                    result.recognizing = false
                    if (result.text.length === 0) {
                        this.results.delete(key)
                        showToast('未识别到文字')
                    }
                    this.notify(key)
                },
                onError: (error: string) => {
                    console.error(TAG, 'speech to text failed', error)
                    this.clients.delete(key)
                    this.onFailed(key)
                }
            })
            this.clients.set(key, client)
            client.recognize(serverAddress, audioUrl, authCode)
        }, (errorCode: number) => {
            console.error(TAG, 'getAuthCode failed', errorCode)
            if (this.results.get(key) === result) {
                this.onFailed(key)
            }
        })
    }

    /**
     * 取消转文字，隐藏已识别出的文本
     */
    cancel(message: Message) {
        let key = message.messageUid.toString()
        let client = this.clients.get(key)
        if (client) {
            client.cancel()
            this.clients.delete(key)
        }
        if (this.results.delete(key)) {
            this.notify(key)
        }
    }

    addListener(listener: SpeechToTextListener) {
        this.listeners.push(listener)
    }

    removeListener(listener: SpeechToTextListener) {
        let index = this.listeners.indexOf(listener)
        if (index >= 0) {
            this.listeners.splice(index, 1)
        }
    }

    private onFailed(key: string) {
        // 和 Android 一样，失败时不保留已识别出的部分文本
        this.results.delete(key)
        showToast('转文字失败')
        this.notify(key)
    }

    private notify(key: string) {
        // 回调里可能会移除监听
        for (let listener of this.listeners.slice()) {
            listener(key)
        }
    }
}

export const speechToTextManager = new SpeechToTextManager()
