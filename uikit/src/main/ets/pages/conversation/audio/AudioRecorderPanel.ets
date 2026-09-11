/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { curves, window } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import displaySync from '@ohos.graphics.displaySync'
import vibrator from '@ohos.vibrator'
import fs from '@ohos.file.fs'
import AsrManager from '../../../asr/AsrManager'
import { checkAndRequestPermission, checkPermissions } from '../../../helper/permissionHelper'
import { playRawSound } from '../../../helper/soundEffectHelper'
import PcmAudioRecorder from './PcmAudioRecorder'
import { encodePcmToAmr } from './PcmAmrEncoder'
import { VoiceInputDelegate, VoiceInputState } from './VoiceInputDialog'
import {
    BUBBLE_TAIL_HEIGHT,
    BubbleFrame,
    BubbleTransform,
    colorHex,
    colorLuminance,
    drawBubble,
    Easings,
    Tween,
    VoiceInputBackgroundPainter,
    VoiceRecordBottomPainter,
    VoiceWavePainter,
    ZONE_CANCEL,
    ZONE_TEXT
} from './VoiceInputPainters'

const TAG = 'AudioRecorderPanel'

/**
 * 用户取消时 onRecordFail 的 reason
 */
export const REASON_USER_CANCELED = 'user canceled'

const STAGE_IDLE = 0
// 按住录音中
const STAGE_RECORDING = 1
// 在「转文字」上松手后，编辑识别出的文字
const STAGE_EDITING = 2
// 浮层正在退出
const STAGE_DISMISSING = 3

// 气泡形态：松开发送、取消、转文字、编辑文字、没有识别到文字、说话时间太短
const BUBBLE_SEND = 0
const BUBBLE_CANCEL = 1
const BUBBLE_TEXT = 2
const BUBBLE_EDIT = 3
const BUBBLE_NO_TEXT = 4
const BUBBLE_TOO_SHORT = 5

const BUBBLE_COLOR_RED = 0xFFFA5151
const WHITE = 0xFFFFFFFF

const MAX_DURATION_MS = 60 * 1000
const MIN_DURATION_MS = 1000
// 录音剩余多少时间时开始倒计时
const COUNT_DOWN_MS = 10 * 1000

// 气泡内边距，底部包含尖角的高度
const BUBBLE_PADDING_HORIZONTAL = 20
const BUBBLE_PADDING_TOP = 18
const BUBBLE_PADDING_BOTTOM = 26
const TEXT_SIZE = 22
const TEXT_MIN_HEIGHT = 30
const TEXT_MAX_LINES = 6
const HINT_SIZE = 18
// 提示前面的感叹号图标和间距
const HINT_ICON_WIDTH = 28
// 编辑文字时底部按钮升起的距离
const EDIT_ACTION_OFFSET = 28

const SHAKE_KEYFRAMES: number[] = [0, -10, 10, -7, 7, -3, 3, 0]
const SHAKE_DELAY_MS = 100
const SHAKE_DURATION_MS = 420
const EDIT_ACTIONS_CURVE = curves.cubicBezierCurve(0.25, 0.46, 0.45, 0.94)

export interface AudioRecorderPanelListener {
    // 录音完成，audioFile 是 AMR 文件，duration 单位是秒
    onRecordSuccess: (audioFile: string, duration: number) => void
    // 录音失败，用户主动取消时 reason 是 REASON_USER_CANCELED
    onRecordFail: (reason: string) => void
    // 语音转成文字后，用户确认发送文字
    onSendText: (text: string) => void
}

interface WindowRect {
    left: number
    top: number
    width: number
    height: number
}

/**
 * 按住说话，交互参考微信：
 * - 按住按钮开始录音，松开发送语音
 * - 手指滑到左上方的「取消」后松开，不发送
 * - 开启转文字时，手指滑到右上方的「转文字」，边说边显示识别出的文字；松开后可以编辑文字再发送，也可以发送原语音
 *
 * 录音采集 16kHz PCM，发送语音时再编码成 AMR；转文字识别的是从开始录音算起的全部音频。
 * 浮层是一个全屏的 CustomDialog（VoiceInputDialog），界面状态放在 VoiceInputState 里。
 */
export default class AudioRecorderPanel {
    readonly delegate: VoiceInputDelegate = new VoiceInputDelegate()
    private context: common.Context
    private uiContext: UIContext
    private state: VoiceInputState
    // 会话输入栏的 id，操作区只覆盖会话界面，双栏时不会延伸到左边
    private stageComponentId: string
    private dialogController?: CustomDialogController
    private listener?: AudioRecorderPanelListener
    private speechToTextEnabled: boolean = false
    // 气泡使用 app 主色调，气泡上的文字和声波根据主色调的深浅用白色或深色
    private bubbleColor: number = 0xFF3B62E0
    private bubbleContentColor: number = WHITE

    private stage: number = STAGE_IDLE
    // 每次录音加 1，用来丢弃上一次录音延迟到达的回调
    private recordSession: number = 0
    // 手指是否还按着，申请权限是异步的，回来时可能已经松手了
    private pressed: boolean = false
    // 手指和按钮在窗口中的位置
    private touchX: number = 0
    private touchY: number = 0
    private buttonTop: number = 0
    private recorder?: PcmAudioRecorder
    private pcmChunks: ArrayBuffer[] = []
    private pcmBytes: number = 0
    private recordedPcm?: ArrayBuffer
    private startTime: number = 0
    private recordDuration: number = 0
    private tickTimer: number = -1
    private dismissTimer: number = -1

    private asrManager?: AsrManager
    private asrStarted: boolean = false
    private asrFinished: boolean = false
    private asrFailed: boolean = false

    // 浮层
    private dialogShowing: boolean = false
    private canvas?: CanvasRenderingContext2D
    private frameSync?: displaySync.DisplaySync
    private canvasDirty: boolean = false
    // 浮层在窗口中的位置和尺寸
    private popupX: number = 0
    private popupY: number = 0
    private popupWidth: number = 0
    private popupHeight: number = 0
    // 浮层完成布局、各部分的位置已经计算好
    private layoutReady: boolean = false
    private stageLeft: number = 0
    private stageWidth: number = 0
    private bubbleBottomMargin: number = 0
    private editActionsBottomMargin: number = 0
    private textLineHeight: number = 0
    // 编辑文字时软键盘把气泡和按钮顶起的高度
    private keyboardShift: number = 0
    private keyboardWindow?: window.Window
    private avoidAreaCallback?: (options: window.AvoidAreaOptions) => void
    private background: VoiceInputBackgroundPainter = new VoiceInputBackgroundPainter()
    private bottomView: VoiceRecordBottomPainter = new VoiceRecordBottomPainter()
    private wave: VoiceWavePainter = new VoiceWavePainter()
    private bubbleState: number = BUBBLE_SEND
    private bubbleFrame: BubbleFrame = new BubbleFrame()
    private bubbleFrom: BubbleFrame = new BubbleFrame()
    private bubbleTo: BubbleFrame = new BubbleFrame()
    private bubbleProgress: Tween = new Tween(1)
    private bubbleTransform: BubbleTransform = new BubbleTransform()
    // 说话时间太短时气泡左右晃动的开始时间，0 表示没有晃动
    private shakeStartTime: number = 0
    private countDownShown: boolean = false

    constructor(context: common.Context, uiContext: UIContext, state: VoiceInputState, stageComponentId: string) {
        this.context = context
        this.uiContext = uiContext
        this.state = state
        this.stageComponentId = stageComponentId
        let uuid = util.generateRandomUUID(false)
        this.delegate.rootId = 'voiceInputRoot-' + uuid
        this.delegate.textInputId = 'voiceInputText-' + uuid
        this.delegate.onCanvasReady = (ctx: CanvasRenderingContext2D) => {
            this.canvas = ctx
            this.canvasDirty = true
        }
        this.delegate.onLayout = (width: number, height: number) => {
            this.onPopupLaidOut(width, height)
        }
        this.delegate.onTextChange = (value: string) => {
            this.onEditTextChange(value)
        }
        this.delegate.onEditCancel = () => {
            this.onEditCancelClick()
        }
        this.delegate.onSendVoice = () => {
            this.onSendVoiceClick()
        }
        this.delegate.onSendText = () => {
            this.onSendTextClick()
        }
        try {
            this.bubbleColor = context.resourceManager.getColorSync($r('app.color.wf_primary')) >>> 0
        } catch (e) {
            console.error(TAG, 'get primary color failed', e)
        }
        this.bubbleContentColor = colorLuminance(this.bubbleColor) > 0.3 ? 0xFF191919 : WHITE
    }

    /**
     * @param dialogController VoiceInputDialog 的 controller，浮层由 AudioRecorderPanel 打开和关闭
     */
    attach(dialogController: CustomDialogController, listener: AudioRecorderPanelListener) {
        this.dialogController = dialogController
        this.listener = listener
    }

    release() {
        this.dismissNow()
        this.listener = undefined
        this.dialogController = undefined
    }

    /**
     * 是否可以滑动到「转文字」。需要配置实时语音识别服务 Config.ASR_STREAM_SERVER_URL，转文字的结果通过 onSendText 回调
     */
    setSpeechToTextEnabled(enabled: boolean) {
        this.speechToTextEnabled = enabled
    }

    isShowingRecorder(): boolean {
        return this.dialogShowing
    }

    /**
     * 按住说话按钮的触摸事件
     */
    onTouch(event: TouchEvent) {
        event.stopPropagation()
        if (event.touches.length > 0) {
            let touch = event.touches[0]
            this.touchX = touch.windowX
            this.touchY = touch.windowY
            if (event.type === TouchType.Down) {
                this.buttonTop = touch.windowY - touch.y
            }
        }
        if (event.type === TouchType.Down) {
            this.pressed = true
            this.onPressDown()
        } else if (event.type === TouchType.Move) {
            if (this.stage === STAGE_RECORDING) {
                this.updateZone()
            }
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.pressed = false
            if (this.stage === STAGE_RECORDING) {
                this.stopRecord(this.bottomView.getZone())
            }
        }
    }

    /**
     * 浮层即将被返回键关闭：编辑文字时等同于取消，录音中忽略
     */
    onDialogWillDismiss() {
        if (this.stage === STAGE_EDITING) {
            this.onEditCancelClick()
        }
    }

    // region 录音

    private async onPressDown() {
        if (this.stage === STAGE_DISMISSING) {
            // 上一次录音的浮层还在退出，直接关闭
            this.dismissNow()
        }
        if (this.stage !== STAGE_IDLE) {
            return
        }
        let denied = await checkPermissions(this.context, ['ohos.permission.MICROPHONE'])
        if (denied.length > 0) {
            this.pressed = false
            checkAndRequestPermission(this.context, 'ohos.permission.MICROPHONE')
            return
        }
        if (!this.pressed || this.stage !== STAGE_IDLE) {
            return
        }
        this.startRecord()
    }

    private startRecord() {
        let session = ++this.recordSession
        let recorder = new PcmAudioRecorder()
        this.recorder = recorder
        this.pcmChunks = []
        this.pcmBytes = 0
        this.recordedPcm = undefined
        this.startTime = Date.now()
        this.stage = STAGE_RECORDING
        this.asrStarted = false
        this.asrFinished = false
        this.asrFailed = false
        this.showPopup()
        this.startTick()
        this.vibrate(40)
        // 启动失败时会回调 onError，由 handleRecorderError 结束录音
        recorder.start({
            onAudioData: (pcm: ArrayBuffer) => {
                this.handleAudioData(session, pcm)
            },
            onError: (message: string) => {
                this.handleRecorderError(session, message)
            }
        })
    }

    private handleAudioData(session: number, pcm: ArrayBuffer) {
        if (session !== this.recordSession || this.stage !== STAGE_RECORDING) {
            return
        }
        this.pcmChunks.push(pcm)
        this.pcmBytes += pcm.byteLength
        this.wave.setLevel(AudioRecorderPanel.computeLevel(pcm))
        this.asrManager?.feedAudioData(pcm)
    }

    private handleRecorderError(session: number, message: string) {
        if (session !== this.recordSession || this.stage !== STAGE_RECORDING) {
            return
        }
        console.error(TAG, '录音失败: ' + message)
        if (this.pcmBytes > 0) {
            // 例如来电抢走了麦克风，按手指当前的位置结束录音，保留已经录到的声音
            this.stopRecord(this.bottomView.getZone())
        } else {
            this.listener?.onRecordFail(message)
            this.dismissPopup()
        }
    }

    private startTick() {
        this.stopTick()
        this.tickTimer = setInterval(() => {
            this.onTick()
        }, 100)
    }

    private stopTick() {
        if (this.tickTimer !== -1) {
            clearInterval(this.tickTimer)
            this.tickTimer = -1
        }
    }

    private onTick() {
        if (this.stage !== STAGE_RECORDING) {
            this.stopTick()
            return
        }
        let elapsed = Date.now() - this.startTime
        if (elapsed >= MAX_DURATION_MS) {
            this.stopRecord(this.bottomView.getZone())
            return
        }
        if (elapsed > MAX_DURATION_MS - COUNT_DOWN_MS) {
            this.showCountDown(Math.ceil((MAX_DURATION_MS - elapsed) / 1000))
        }
    }

    /**
     * 结束录音
     *
     * @param zone 松手时手指所在的目标
     */
    private stopRecord(zone: number) {
        if (this.stage !== STAGE_RECORDING) {
            return
        }
        this.stopTick()
        this.recordDuration = Date.now() - this.startTime
        this.stage = zone === ZONE_TEXT ? STAGE_EDITING : STAGE_DISMISSING
        if (this.recorder) {
            this.recorder.stop()
            this.recorder = undefined
        }
        this.recordedPcm = this.concatPcm()
        this.pcmChunks = []
        if (zone === ZONE_TEXT) {
            this.enterEditing()
            return
        }
        this.cancelSpeechToText()
        if (zone === ZONE_CANCEL) {
            this.listener?.onRecordFail(REASON_USER_CANCELED)
            this.dismissPopup()
        } else if (this.recordDuration < MIN_DURATION_MS) {
            this.showTooShortTip()
        } else {
            this.sendVoice()
            this.dismissPopup()
        }
    }

    private concatPcm(): ArrayBuffer {
        let result = new Uint8Array(this.pcmBytes)
        let offset = 0
        for (let chunk of this.pcmChunks) {
            result.set(new Uint8Array(chunk), offset)
            offset += chunk.byteLength
        }
        return result.buffer as ArrayBuffer
    }

    /**
     * 把录到的音频编码成 AMR 后回调 onRecordSuccess
     */
    private sendVoice() {
        if (!this.recordedPcm || this.recordedPcm.byteLength === 0 || !this.listener) {
            this.recordedPcm = undefined
            return
        }
        const pcm: ArrayBuffer = this.recordedPcm
        const listener: AudioRecorderPanelListener = this.listener
        this.recordedPcm = undefined
        playRawSound(this.context, 'audido_msg_send_success.mp3')
        let duration = Math.max(1, Math.round(pcm.byteLength / PcmAudioRecorder.BYTES_PER_SECOND))
        let audioFile = this.genAudioFile()
        encodePcmToAmr(pcm, audioFile).then((success: boolean) => {
            if (success) {
                listener.onRecordSuccess(audioFile, duration)
            } else {
                listener.onRecordFail('录音失败')
            }
        })
    }

    private genAudioFile(): string {
        // 上传的文件需要在 cacheDir 下
        let dir = this.context.getApplicationContext().cacheDir + '/audio'
        try {
            fs.mkdirSync(dir)
        } catch (e) {
            // 目录已经存在
        }
        return `${dir}/${Date.now()}.amr`
    }

    /**
     * 停止录音和识别，丢弃录到的音频
     */
    private releaseRecording() {
        this.stage = STAGE_IDLE
        this.recordSession++
        this.stopTick()
        this.clearDismissTimer()
        if (this.recorder) {
            this.recorder.stop()
            this.recorder = undefined
        }
        this.cancelSpeechToText()
        this.pcmChunks = []
        this.pcmBytes = 0
        this.recordedPcm = undefined
    }

    private vibrate(duration: number) {
        try {
            let effect: vibrator.VibrateTime = { type: 'time', duration: duration }
            let attribute: vibrator.VibrateAttribute = { id: 0, usage: 'touch' }
            vibrator.startVibration(effect, attribute).catch((err: BusinessError) => {
                console.warn(TAG, 'vibrate failed', err.code)
            })
        } catch (e) {
            console.warn(TAG, 'vibrate failed', e)
        }
    }

    /**
     * 计算一段 PCM 的音量，0~1
     */
    private static computeLevel(pcm: ArrayBuffer): number {
        let samples = new Int16Array(pcm, 0, Math.floor(pcm.byteLength / 2))
        if (samples.length === 0) {
            return 0
        }
        let sum = 0
        for (let i = 0; i < samples.length; i++) {
            sum += samples[i] * samples[i]
        }
        let db = 20 * Math.log10(Math.max(Math.sqrt(sum / samples.length), 1) / 32768)
        // -50dB 以下视为安静，-15dB 以上视为最大音量
        return Math.max(0, Math.min(1, (db + 50) / 35))
    }

    // endregion

    // region 转文字

    private startSpeechToText() {
        if (this.asrStarted) {
            return
        }
        this.asrStarted = true
        const manager: AsrManager = new AsrManager()
        this.asrManager = manager
        manager.startRecognitionWithAudioFeed({
            onPartialResult: (text: string) => {
                if (this.asrManager === manager) {
                    this.onSpeechText(text, false)
                }
            },
            onFinalResult: (text: string) => {
                if (this.asrManager === manager) {
                    this.onSpeechText(text, true)
                }
            },
            onError: (message: string) => {
                if (this.asrManager === manager) {
                    this.onSpeechError(message)
                }
            },
            onHotwordDetected: (hotword: string, text: string) => {
                if (this.asrManager === manager) {
                    this.onSpeechText(text, true)
                }
            }
        })
        // 转文字从开始录音时算起，先补上已经录到的音频
        if (this.asrManager === manager) {
            for (let chunk of this.pcmChunks) {
                manager.feedAudioData(chunk)
            }
        }
    }

    private onSpeechText(text: string, isFinal: boolean) {
        if (isFinal) {
            this.asrFinished = true
            this.asrManager = undefined
        }
        this.setBubbleText(text)
        if (isFinal && this.stage === STAGE_EDITING) {
            this.onRecognitionDoneInEditing()
        }
    }

    private onSpeechError(message: string) {
        console.warn(TAG, '转文字失败: ' + message)
        // 已经识别出的文字保留，仍然可以编辑后发送
        this.asrFailed = this.state.text.length === 0
        this.asrFinished = true
        this.asrManager = undefined
        this.updateTextHint()
        if (this.stage === STAGE_EDITING) {
            this.onRecognitionDoneInEditing()
        }
    }

    private cancelSpeechToText() {
        let manager = this.asrManager
        if (manager) {
            this.asrManager = undefined
            manager.cancelRecognition()
        }
    }

    // endregion

    // region 浮层

    private showPopup() {
        this.resetPopup()
        this.layoutReady = false
        if (!this.dialogShowing) {
            this.dialogShowing = true
            // 浮层完成布局、拿到尺寸后再计算各部分的位置，在这之前 Canvas 上什么都不画
            this.dialogController?.open()
        }
        this.startFrameLoop()
    }

    private resetPopup() {
        this.background.progress.set(0)
        this.background.panelTop.set(0)
        this.bottomView.reset()
        this.bottomView.setSpeechToTextEnabled(this.speechToTextEnabled)
        this.wave.reset()
        this.bubbleTransform.reset()
        this.bubbleProgress.set(1)
        this.bubbleState = BUBBLE_SEND
        this.shakeStartTime = 0
        this.keyboardShift = 0
        this.countDownShown = false
        let s = this.state
        s.text = ''
        s.textPlaceholder = ''
        s.textEditable = false
        s.textColor = colorHex(this.bubbleContentColor)
        s.textPlaceholderColor = colorHex(((this.bubbleContentColor & 0x00FFFFFF) | 0x99000000) >>> 0)
        s.textAlpha = 0
        s.hintText = ''
        s.hintAlpha = 0
        s.bubbleAlpha = 0
        s.countDownText = ''
        s.countDownAlpha = 0
        s.editActionsVisible = false
        s.editActionsAlpha = 1
        s.cancelAlpha = 0
        s.cancelTranslateY = EDIT_ACTION_OFFSET
        s.sendVoiceAlpha = 0
        s.sendVoiceTranslateY = EDIT_ACTION_OFFSET
        s.sendTextAlpha = 0
        s.sendTextTranslateY = EDIT_ACTION_OFFSET
        s.sendVoiceEnabled = false
        s.sendTextEnabled = false
    }

    private onPopupLaidOut(width: number, height: number) {
        if (this.stage === STAGE_IDLE || !this.dialogShowing || this.layoutReady || width <= 0 || height <= 0) {
            return
        }
        this.popupWidth = width
        this.popupHeight = height
        let popupRect = this.getWindowRect(this.delegate.rootId)
        this.popupX = popupRect ? popupRect.left : 0
        this.popupY = popupRect ? popupRect.top : 0
        let stageRect = this.getWindowRect(this.stageComponentId)
        this.stageLeft = stageRect ? Math.max(0, stageRect.left - this.popupX) : 0
        this.stageWidth = stageRect ? Math.min(width - this.stageLeft, stageRect.width) : width
        if (this.stageWidth <= 0) {
            this.stageLeft = 0
            this.stageWidth = width
        }
        // 底部弧形区域要盖住按住说话的按钮，手指按下时就在「松开 发送」区域内
        let buttonTop = this.buttonTop - this.popupY
        let arcTop = Math.min(height - 110, buttonTop - 16)
        this.bottomView.setStage(this.stageLeft, this.stageLeft + this.stageWidth, arcTop)
        // 录音时深灰背景从弧形按钮处开始，编辑文字时再升到气泡下方
        this.background.setStage(this.stageLeft, this.stageLeft + this.stageWidth)
        this.background.panelTop.set(this.bottomView.getPillTop() + 18)
        // 气泡的尖角固定在按钮上方，内容变多时向上长高
        this.bubbleBottomMargin = height - Math.max(160, this.bottomView.getPillTop() - 141)
        this.editActionsBottomMargin = Math.max(16, height - arcTop - 20)

        let s = this.state
        s.countDownLeft = this.stageLeft
        s.countDownWidth = this.stageWidth
        s.countDownBottom = this.bubbleBottomMargin - 44
        s.editActionsLeft = this.stageLeft
        s.editActionsWidth = this.stageWidth
        s.editActionsBottom = this.editActionsBottomMargin

        this.layoutReady = true
        let frame = new BubbleFrame()
        this.computeBubbleFrame(this.bubbleState, frame)
        this.bubbleFrame = frame
        this.bubbleFrom = frame.copy()
        this.bubbleTo = frame.copy()
        this.bubbleProgress.set(1)
        this.playEnterAnimation()
        this.canvasDirty = true
        this.syncComponents()
    }

    private getWindowRect(id: string): WindowRect | undefined {
        try {
            let info = this.uiContext.getComponentUtils().getRectangleById(id)
            let rect: WindowRect = {
                left: this.uiContext.px2vp(info.windowOffset.x),
                top: this.uiContext.px2vp(info.windowOffset.y),
                width: this.uiContext.px2vp(info.size.width),
                height: this.uiContext.px2vp(info.size.height)
            }
            return rect
        } catch (e) {
            console.error(TAG, 'getRectangleById failed', id, e)
            return undefined
        }
    }

    private playEnterAnimation() {
        this.background.progress.animate(1, 200, Easings.linear)
        this.bottomView.show()
        let t = this.bubbleTransform
        t.alpha.set(0)
        t.scale.set(0.6)
        t.translateY.set(24)
        let overshoot = Easings.overshoot(1.2)
        t.alpha.animate(1, 340, overshoot, 40)
        t.scale.animate(1, 340, overshoot, 40)
        t.translateY.animate(0, 340, overshoot, 40)
    }

    private startFrameLoop() {
        if (this.frameSync) {
            return
        }
        let sync = displaySync.create()
        let range: ExpectedFrameRateRange = { min: 0, max: 120, expected: 60 }
        sync.setExpectedFrameRateRange(range)
        sync.on('frame', (info: displaySync.IntervalInfo) => {
            this.onFrame()
        })
        sync.start()
        this.frameSync = sync
    }

    private stopFrameLoop() {
        let sync = this.frameSync
        if (!sync) {
            return
        }
        this.frameSync = undefined
        sync.stop()
        sync.off('frame')
    }

    private onFrame() {
        let now = Date.now()
        let running = this.background.update(now)
        if (!this.frameSync) {
            // 退出动画结束后已经关闭了浮层
            return
        }
        running = this.bottomView.update(now) || running
        running = this.bubbleTransform.update(now) || running
        if (this.bubbleProgress.update(now)) {
            this.bubbleFrame.set(this.bubbleFrom, this.bubbleTo, this.bubbleProgress.value)
            running = true
        }
        if (this.shakeStartTime > 0) {
            running = this.updateShake(now) || running
        }
        let waveVisible = this.bubbleTransform.alpha.value > 0 && this.bubbleFrame.waveAlpha > 0.01
        if (running || waveVisible || this.canvasDirty) {
            this.canvasDirty = false
            this.draw(now)
            this.syncComponents()
        }
    }

    private updateShake(now: number): boolean {
        let elapsed = now - this.shakeStartTime - SHAKE_DELAY_MS
        if (elapsed < 0) {
            return true
        }
        let fraction = Math.min(1, elapsed / SHAKE_DURATION_MS)
        let position = Easings.accelerateDecelerate(fraction) * (SHAKE_KEYFRAMES.length - 1)
        let index = Math.min(SHAKE_KEYFRAMES.length - 2, Math.floor(position))
        this.bubbleTransform.translateX.value =
            SHAKE_KEYFRAMES[index] + (SHAKE_KEYFRAMES[index + 1] - SHAKE_KEYFRAMES[index]) * (position - index)
        if (fraction >= 1) {
            this.shakeStartTime = 0
            this.bubbleTransform.translateX.value = 0
        }
        return true
    }

    private draw(now: number) {
        let ctx = this.canvas
        if (!ctx || !this.layoutReady) {
            return
        }
        ctx.clearRect(0, 0, this.popupWidth, this.popupHeight)
        this.background.draw(ctx, this.popupWidth, this.popupHeight)
        this.bottomView.draw(ctx, this.popupHeight)
        drawBubble(ctx, this.bubbleFrame, this.bubbleBottom(), this.bubbleTransform, this.wave, now)
    }

    /**
     * 气泡底部（尖角尖端）的 y 坐标
     */
    private bubbleBottom(): number {
        return this.popupHeight - this.bubbleBottomMargin - this.keyboardShift
    }

    /**
     * 气泡里的文字和提示是组件，位置、透明度跟着 Canvas 上的气泡变化
     */
    private syncComponents() {
        if (!this.layoutReady) {
            return
        }
        let f = this.bubbleFrame
        let bottom = this.bubbleBottom()
        let top = bottom - f.height
        let s = this.state
        s.bubbleAlpha = Math.max(0, Math.min(1, this.bubbleTransform.alpha.value))
        s.bubbleScale = this.bubbleTransform.scale.value
        s.bubblePivotX = f.left + f.width / 2
        s.bubblePivotY = bottom
        s.bubbleTranslateX = this.bubbleTransform.translateX.value
        s.bubbleTranslateY = this.bubbleTransform.translateY.value
        s.textLeft = f.left + BUBBLE_PADDING_HORIZONTAL
        s.textTop = top + BUBBLE_PADDING_TOP
        s.textWidth = Math.max(0, f.width - 2 * BUBBLE_PADDING_HORIZONTAL)
        s.textHeight = Math.max(0, f.height - BUBBLE_PADDING_TOP - BUBBLE_PADDING_BOTTOM - f.textBottomMargin)
        s.textAlpha = f.textAlpha
        s.hintLeft = s.textLeft
        s.hintTop = s.textTop
        s.hintWidth = s.textWidth
        s.hintHeight = Math.max(0, f.height - BUBBLE_PADDING_TOP - BUBBLE_PADDING_BOTTOM)
        s.hintAlpha = f.hintAlpha
        // 提示淡入时轻微上浮
        s.hintTranslateY = (1 - f.hintAlpha) * 6
    }

    private updateZone() {
        if (!this.layoutReady) {
            return
        }
        let zone = this.bottomView.zoneAt(this.touchX - this.popupX, this.touchY - this.popupY)
        if (zone === this.bottomView.getZone()) {
            return
        }
        this.bottomView.setZone(zone)
        this.vibrate(10)
        if (zone === ZONE_CANCEL) {
            this.animateBubbleTo(BUBBLE_CANCEL)
        } else if (zone === ZONE_TEXT) {
            this.startSpeechToText()
            this.animateBubbleTo(BUBBLE_TEXT)
        } else {
            this.animateBubbleTo(BUBBLE_SEND)
        }
    }

    /**
     * 气泡从当前的位置、大小、颜色平滑过渡到目标形态；内容变化时用同一个形态再调用一次，气泡会平滑地改变高度
     */
    private animateBubbleTo(state: number) {
        let changed = this.bubbleState !== state
        this.bubbleState = state
        if (!this.layoutReady) {
            return
        }
        this.bubbleFrom = this.bubbleFrame.copy()
        let to = new BubbleFrame()
        this.computeBubbleFrame(state, to)
        this.bubbleTo = to
        this.bubbleProgress.set(0)
        this.bubbleProgress.animate(1, changed ? 320 : 180, Easings.fastOutSlowIn)
    }

    private computeBubbleFrame(state: number, frame: BubbleFrame) {
        let maxWidth = this.stageWidth - 32
        let sendWidth = Math.min(maxWidth, Math.max(160, this.stageWidth * 0.475))
        let tailTargetX = 0
        frame.waveColor = this.bubbleContentColor
        frame.textAlpha = 0
        frame.hintAlpha = 0
        frame.textBottomMargin = 20
        if (state === BUBBLE_CANCEL) {
            // 缩成红色的小方块，移到「取消」上方
            frame.width = 78
            frame.height = 78 + BUBBLE_TAIL_HEIGHT
            tailTargetX = this.bottomView.getCancelCenterX()
            frame.left = Math.max(this.stageLeft + 16, tailTargetX - frame.width / 2)
            frame.color = BUBBLE_COLOR_RED
            frame.waveColor = WHITE
            frame.waveWidth = 34
            frame.waveHeight = 16
            frame.waveCenterX = frame.width / 2
            frame.waveCenterY = (frame.height - BUBBLE_TAIL_HEIGHT) / 2
            frame.waveAlpha = 1
        } else if (state === BUBBLE_TEXT || state === BUBBLE_EDIT || state === BUBBLE_NO_TEXT) {
            // 展开成整行宽度显示文字，声波缩小到右下角，识别完成后消失；没有识别到文字时变成红色的提示
            let noText = state === BUBBLE_NO_TEXT
            let showWave = state === BUBBLE_TEXT || (state === BUBBLE_EDIT && !this.asrFinished)
            frame.left = this.stageLeft + 16
            frame.width = maxWidth
            frame.textBottomMargin = showWave ? 20 : 0
            frame.height = this.measureBubbleHeight(frame.width, frame.textBottomMargin)
            frame.color = noText ? BUBBLE_COLOR_RED : this.bubbleColor
            frame.waveColor = noText ? WHITE : this.bubbleContentColor
            frame.waveWidth = 34
            frame.waveHeight = 16
            frame.waveCenterX = frame.width - 20 - frame.waveWidth / 2
            frame.waveCenterY = frame.height - BUBBLE_TAIL_HEIGHT - 18
            frame.waveAlpha = showWave ? 1 : 0
            frame.textAlpha = noText ? 0 : 1
            frame.hintAlpha = noText ? 1 : 0
            // 和微信一样，整行宽度的气泡尖角固定在同一个位置，转文字、编辑、没有识别到文字之间切换时不动
            tailTargetX = this.stageLeft + this.stageWidth * 0.755
        } else if (state === BUBBLE_TOO_SHORT) {
            // 保持松开发送时的样子，声波换成提示，提示放不下时加宽
            frame.width = Math.min(maxWidth, Math.max(sendWidth, this.measureHintWidth(maxWidth)))
            frame.height = 78 + BUBBLE_TAIL_HEIGHT
            frame.left = this.stageLeft + (this.stageWidth - frame.width) / 2
            frame.color = this.bubbleColor
            frame.waveWidth = sendWidth * 0.46
            frame.waveHeight = 20
            frame.waveCenterX = frame.width / 2
            frame.waveCenterY = (frame.height - BUBBLE_TAIL_HEIGHT) / 2
            frame.waveAlpha = 0
            frame.hintAlpha = 1
            tailTargetX = frame.left + frame.width / 2
        } else {
            frame.width = sendWidth
            frame.height = 78 + BUBBLE_TAIL_HEIGHT
            frame.left = this.stageLeft + (this.stageWidth - frame.width) / 2
            frame.color = this.bubbleColor
            frame.waveWidth = frame.width * 0.46
            frame.waveHeight = 20
            frame.waveCenterX = frame.width / 2
            frame.waveCenterY = (frame.height - BUBBLE_TAIL_HEIGHT) / 2
            frame.waveAlpha = 1
            tailTargetX = frame.left + frame.width / 2
        }
        frame.tailX = tailTargetX - frame.left
    }

    /**
     * 气泡按指定宽度显示当前文字时的高度，文字最多显示 TEXT_MAX_LINES 行，超出后滚动
     */
    private measureBubbleHeight(width: number, textBottomMargin: number): number {
        let contentWidth = Math.max(1, width - 2 * BUBBLE_PADDING_HORIZONTAL)
        let text = this.state.text.length > 0 ? this.state.text : this.state.textPlaceholder
        let textHeight = TEXT_MIN_HEIGHT
        if (text.length > 0) {
            try {
                let measure = this.uiContext.getMeasureUtils()
                if (this.textLineHeight <= 0) {
                    let line = measure.measureTextSize({ textContent: ' ', fontSize: TEXT_SIZE })
                    this.textLineHeight = this.uiContext.px2vp(line.height as number)
                }
                let size = measure.measureTextSize({ textContent: text, fontSize: TEXT_SIZE, constraintWidth: contentWidth })
                textHeight = Math.max(TEXT_MIN_HEIGHT,
                    Math.min(this.textLineHeight * TEXT_MAX_LINES, this.uiContext.px2vp(size.height as number)))
            } catch (e) {
                console.error(TAG, 'measure text failed', e)
            }
        }
        return BUBBLE_PADDING_TOP + textHeight + textBottomMargin + BUBBLE_PADDING_BOTTOM
    }

    /**
     * 气泡完整显示提示所需的宽度
     */
    private measureHintWidth(maxWidth: number): number {
        try {
            let size = this.uiContext.getMeasureUtils().measureTextSize({
                textContent: this.state.hintText,
                fontSize: HINT_SIZE
            })
            return this.uiContext.px2vp(size.width as number) + HINT_ICON_WIDTH + 2 * BUBBLE_PADDING_HORIZONTAL + 2
        } catch (e) {
            return maxWidth
        }
    }

    private setBubbleText(text: string) {
        if (this.state.text !== text) {
            this.state.text = text
            if (this.bubbleState === BUBBLE_TEXT || this.bubbleState === BUBBLE_EDIT) {
                this.animateBubbleTo(this.bubbleState)
                this.scrollTextToEnd()
            }
        }
        this.updateTextHint()
    }

    /**
     * 文字超过最大行数时，滚动到最新识别出的文字
     */
    private scrollTextToEnd() {
        setTimeout(() => {
            try {
                this.delegate.textScroller.scrollEdge(Edge.Bottom)
            } catch (e) {
                // 编辑文字时没有绑定 Scroller
            }
        }, 200)
    }

    private updateTextHint() {
        // 按住转文字时出错，在气泡里提示；松手后没有文字时换成红色的提示气泡
        this.state.textPlaceholder = this.asrFailed && this.stage === STAGE_RECORDING ? '转文字失败' : ''
    }

    private showTooShortTip() {
        this.showHint('说话时间太短', this.bubbleContentColor)
        this.animateBubbleTo(BUBBLE_TOO_SHORT)
        this.shakeStartTime = Date.now()
        this.clearDismissTimer()
        this.dismissTimer = setTimeout(() => {
            this.dismissTimer = -1
            this.dismissPopup()
        }, 1000)
    }

    /**
     * 设置气泡里的提示，图标和文字同色
     */
    private showHint(text: string, color: number) {
        this.state.hintText = text
        this.state.hintColor = colorHex(color)
    }

    private showCountDown(seconds: number) {
        this.state.countDownText = `${seconds} 秒后将停止录音`
        if (!this.countDownShown) {
            this.countDownShown = true
            this.uiContext.animateTo({ duration: 200 }, () => {
                this.state.countDownAlpha = 1
            })
        }
    }

    /**
     * 在「转文字」上松手：底部按钮落下，换成取消、发送原语音、发送；识别结果全部返回后可以编辑文字
     */
    private enterEditing() {
        this.uiContext.animateTo({ duration: 150 }, () => {
            this.state.countDownAlpha = 0
        })
        this.bottomView.hide()
        this.background.panelTop.animate(this.getEditPanelTop(), 360, Easings.fastOutSlowIn)
        this.listenKeyboard()
        this.updateTextHint()
        this.updateEditActions()
        this.showEditActions()
        let manager = this.asrManager
        if (manager) {
            // 录音已经停止，声波换成等待动画，剩余识别结果返回后回调 onFinalResult
            this.wave.setLoading(true)
            this.animateBubbleTo(BUBBLE_EDIT)
            manager.stopRecognition()
        } else {
            // 识别已经结束，或者出错了
            this.asrFinished = true
            this.onRecognitionDoneInEditing()
        }
    }

    private onRecognitionDoneInEditing() {
        this.wave.setLoading(false)
        this.updateTextHint()
        this.updateEditActions()
        if (this.state.text.length === 0) {
            // 没有识别到文字：红色提示，只能取消或者发送原语音
            this.showHint(this.asrFailed ? '转文字失败' : '未识别到文字', WHITE)
            this.animateBubbleTo(BUBBLE_NO_TEXT)
            return
        }
        this.state.textEditable = true
        this.animateBubbleTo(BUBBLE_EDIT)
        setTimeout(() => {
            if (this.stage !== STAGE_EDITING) {
                return
            }
            try {
                // 输入框设置了 enableKeyboardOnFocus(false)，这里获焦不会弹出键盘
                this.uiContext.getFocusController().requestFocus(this.delegate.textInputId)
                this.delegate.textController.caretPosition(this.state.text.length)
            } catch (e) {
                console.warn(TAG, 'focus text failed', e)
            }
        }, 100)
    }

    private isVoiceAvailable(): boolean {
        return this.recordedPcm !== undefined && this.recordedPcm.byteLength > 0 && this.recordDuration >= MIN_DURATION_MS
    }

    private updateEditActions() {
        this.state.sendTextEnabled = this.asrFinished && this.state.text.trim().length > 0
        this.state.sendVoiceEnabled = this.isVoiceAvailable()
    }

    private showEditActions() {
        let s = this.state
        s.editActionsAlpha = 1
        s.editActionsVisible = true
        // 等弧形按钮大部分落下后再升起，两组按钮不在同一时间重叠
        this.uiContext.animateTo({ duration: 300, delay: 140, curve: EDIT_ACTIONS_CURVE }, () => {
            s.cancelAlpha = 1
            s.cancelTranslateY = 0
        })
        this.uiContext.animateTo({ duration: 300, delay: 180, curve: EDIT_ACTIONS_CURVE }, () => {
            s.sendVoiceAlpha = 1
            s.sendVoiceTranslateY = 0
        })
        this.uiContext.animateTo({ duration: 300, delay: 220, curve: EDIT_ACTIONS_CURVE }, () => {
            s.sendTextAlpha = 1
            s.sendTextTranslateY = 0
        })
    }

    private onEditTextChange(value: string) {
        this.state.text = value
        if (this.stage === STAGE_EDITING && this.asrFinished && this.bubbleState === BUBBLE_EDIT) {
            this.updateEditActions()
            this.animateBubbleTo(BUBBLE_EDIT)
        }
    }

    private onEditCancelClick() {
        if (this.stage !== STAGE_EDITING) {
            return
        }
        this.cancelSpeechToText()
        this.listener?.onRecordFail(REASON_USER_CANCELED)
        this.dismissPopup()
    }

    private onSendVoiceClick() {
        if (this.stage !== STAGE_EDITING || !this.isVoiceAvailable()) {
            return
        }
        this.cancelSpeechToText()
        this.sendVoice()
        this.dismissPopup()
    }

    private onSendTextClick() {
        if (this.stage !== STAGE_EDITING) {
            return
        }
        let text = this.state.text.trim()
        if (text.length === 0) {
            return
        }
        this.listener?.onSendText(text)
        this.dismissPopup()
    }

    /**
     * 播放退出动画后关闭浮层
     */
    private dismissPopup() {
        this.clearDismissTimer()
        if (!this.dialogShowing) {
            this.releaseRecording()
            return
        }
        this.stage = STAGE_DISMISSING
        this.hideKeyboard()
        this.stopListenKeyboard()
        this.bubbleProgress.cancel()
        this.shakeStartTime = 0
        this.bottomView.hide()
        let t = this.bubbleTransform
        let accelerate = Easings.accelerate(1)
        t.alpha.animate(0, 180, accelerate)
        t.scale.animate(0.85, 180, accelerate)
        t.translateY.animate(0, 180, accelerate)
        this.uiContext.animateTo({ duration: 150 }, () => {
            this.state.countDownAlpha = 0
            this.state.editActionsAlpha = 0
        })
        this.background.progress.animate(0, 240, Easings.linear, 0, () => {
            this.dismissNow()
        })
        this.startFrameLoop()
    }

    /**
     * 立即关闭浮层，停止录音和识别，不回调
     */
    private dismissNow() {
        this.clearDismissTimer()
        // 先置为空闲，关闭浮层时不再当作用户取消
        this.releaseRecording()
        this.layoutReady = false
        this.stopListenKeyboard()
        this.stopFrameLoop()
        if (this.dialogShowing) {
            this.hideKeyboard()
            this.dialogShowing = false
            this.dialogController?.close()
        }
        this.canvas = undefined
    }

    private clearDismissTimer() {
        if (this.dismissTimer !== -1) {
            clearTimeout(this.dismissTimer)
            this.dismissTimer = -1
        }
    }

    private hideKeyboard() {
        try {
            this.delegate.textController.stopEditing()
        } catch (e) {
            // 没有在编辑
        }
    }

    /**
     * 编辑文字时深灰背景完全不透明处，在气泡下边缘稍上方
     */
    private getEditPanelTop(): number {
        return this.popupHeight - this.keyboardShift - this.bubbleBottomMargin - BUBBLE_TAIL_HEIGHT - 5
    }

    /**
     * 编辑文字时弹出软键盘，把气泡和按钮顶到软键盘上方
     */
    private listenKeyboard() {
        if (this.keyboardWindow) {
            return
        }
        window.getLastWindow(this.context).then((win: window.Window) => {
            if (this.stage !== STAGE_EDITING || this.keyboardWindow) {
                return
            }
            this.keyboardWindow = win
            this.avoidAreaCallback = (options: window.AvoidAreaOptions) => {
                if (options.type === window.AvoidAreaType.TYPE_KEYBOARD) {
                    this.onKeyboardHeightChanged(this.uiContext.px2vp(options.area.bottomRect.height))
                }
            }
            win.on('avoidAreaChange', this.avoidAreaCallback)
        }).catch((err: BusinessError) => {
            console.error(TAG, 'getLastWindow failed', err.code)
        })
    }

    private stopListenKeyboard() {
        let win = this.keyboardWindow
        let callback = this.avoidAreaCallback
        this.keyboardWindow = undefined
        this.avoidAreaCallback = undefined
        if (win && callback) {
            try {
                win.off('avoidAreaChange', callback)
            } catch (e) {
                console.warn(TAG, 'off avoidAreaChange failed', e)
            }
        }
    }

    private onKeyboardHeightChanged(imeHeight: number) {
        let shift = this.stage === STAGE_EDITING && imeHeight > 0
            ? Math.max(0, imeHeight - this.editActionsBottomMargin + 12) : 0
        if (Math.abs(shift - this.keyboardShift) < 0.5) {
            return
        }
        this.keyboardShift = shift
        this.state.editActionsBottom = this.editActionsBottomMargin + shift
        if (this.layoutReady) {
            // 深灰背景跟着气泡移动
            this.background.panelTop.set(this.getEditPanelTop())
            this.canvasDirty = true
            this.syncComponents()
        }
    }

    // endregion
}
