/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import { audio } from '@kit.AudioKit'
import { BusinessError } from '@kit.BasicServicesKit'

const TAG = 'PcmAudioRecorder'

export interface PcmAudioDataCallback {
    /**
     * 音频数据，16kHz、16-bit、单声道 PCM，每次 {@link PcmAudioRecorder.CHUNK_BYTES} 字节（30ms）。
     * 每次回调都是新的 ArrayBuffer，可以直接保存
     */
    onAudioData: (pcm: ArrayBuffer) => void
    /**
     * 录音出错，之后不再回调
     */
    onError: (message: string) => void
}

/**
 * PCM 录音，用于实时语音识别和按住说话，采集 16kHz、16-bit、单声道 PCM（与 wf-voice 要求一致）
 */
export default class PcmAudioRecorder {
    static readonly SAMPLE_RATE = 16000
    static readonly BYTES_PER_SECOND = 16000 * 2
    // 每次回调的字节数，对应 30ms 音频
    static readonly CHUNK_BYTES = 960

    private capturer?: audio.AudioCapturer
    private callback?: PcmAudioDataCallback
    private stopped: boolean = false
    private chunk: Uint8Array = new Uint8Array(PcmAudioRecorder.CHUNK_BYTES)
    private chunkLength: number = 0
    private readDataCallback?: (buffer: ArrayBuffer) => void
    private interruptCallback?: (event: audio.InterruptEvent) => void

    /**
     * 开始录音，调用前需要已获得麦克风权限
     * @returns 是否成功开始录音；失败时会先回调 onError，启动过程中调用了 stop 时返回 false 且不回调
     */
    async start(callback: PcmAudioDataCallback): Promise<boolean> {
        this.callback = callback
        let streamInfo: audio.AudioStreamInfo = {
            samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
            channels: audio.AudioChannel.CHANNEL_1,
            sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
            encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        }
        let capturerInfo: audio.AudioCapturerInfo = {
            source: audio.SourceType.SOURCE_TYPE_MIC,
            capturerFlags: 0
        }
        try {
            let capturer = await audio.createAudioCapturer({ streamInfo: streamInfo, capturerInfo: capturerInfo })
            // 创建是异步的，期间可能已经停止了
            if (this.stopped) {
                await capturer.release()
                return false
            }
            this.capturer = capturer
            this.readDataCallback = (buffer: ArrayBuffer): void => {
                this.onReadData(buffer)
            }
            capturer.on('readData', this.readDataCallback)
            this.interruptCallback = (event: audio.InterruptEvent): void => {
                // 例如来电抢走了麦克风
                if (event.forceType === audio.InterruptForceType.INTERRUPT_FORCE
                    && (event.hintType === audio.InterruptHint.INTERRUPT_HINT_PAUSE
                        || event.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP)) {
                    this.fail('录音被中断')
                }
            }
            capturer.on('audioInterrupt', this.interruptCallback)
            await capturer.start()
            if (this.stopped) {
                this.releaseCapturer()
                return false
            }
            console.log(TAG, 'recording started')
            return true
        } catch (e) {
            let err = e as BusinessError
            console.error(TAG, `start failed, code ${err.code}, message ${err.message}`)
            if (this.stopped) {
                this.releaseCapturer()
                return false
            }
            this.fail('启动录音失败: ' + err.message)
            return false
        }
    }

    /**
     * 停止录音，之后不再回调
     */
    stop() {
        if (this.stopped) {
            return
        }
        this.stopped = true
        this.callback = undefined
        this.releaseCapturer()
    }

    private fail(message: string) {
        let callback = this.callback
        this.stop()
        callback?.onError(message)
    }

    private onReadData(buffer: ArrayBuffer) {
        let data = new Uint8Array(buffer)
        let offset = 0
        while (!this.stopped && offset < data.length) {
            let n = Math.min(PcmAudioRecorder.CHUNK_BYTES - this.chunkLength, data.length - offset)
            this.chunk.set(data.subarray(offset, offset + n), this.chunkLength)
            this.chunkLength += n
            offset += n
            if (this.chunkLength === PcmAudioRecorder.CHUNK_BYTES) {
                this.chunkLength = 0
                // readData 回调的 buffer 和 chunk 都会被复用，拷贝一份再回调
                this.callback?.onAudioData(this.chunk.buffer.slice(0))
            }
        }
    }

    private releaseCapturer() {
        if (!this.capturer) {
            return
        }
        const capturer: audio.AudioCapturer = this.capturer
        this.capturer = undefined
        try {
            if (this.readDataCallback) {
                capturer.off('readData', this.readDataCallback)
            }
            if (this.interruptCallback) {
                capturer.off('audioInterrupt')
            }
        } catch (e) {
            console.error(TAG, 'off callback failed', e)
        }
        this.readDataCallback = undefined
        this.interruptCallback = undefined
        capturer.stop()
            .catch((e: BusinessError) => {
                console.error(TAG, `stop capturer failed, code ${e.code}`)
            })
            .finally(() => {
                capturer.release().catch((err: BusinessError) => {
                    console.error(TAG, `release capturer failed, code ${err.code}`)
                })
            })
        console.log(TAG, 'recording stopped')
    }
}
