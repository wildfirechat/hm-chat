/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

// 按住说话的全屏浮层。背景、底部操作区、气泡和声波由 AudioRecorderPanel 画在 Canvas 上，
// 这里只放需要交互或排版的文字和按钮，位置和尺寸都由 AudioRecorderPanel 根据按钮位置计算

/**
 * 浮层上会变化的界面状态，由 AudioRecorderPanel 修改
 */
@Observed
export class VoiceInputState {
    // 气泡里识别出的文字，坐标相对于浮层
    text: string = ''
    textPlaceholder: string = ''
    textEditable: boolean = false
    textColor: string = '#FFFFFFFF'
    textPlaceholderColor: string = '#99FFFFFF'
    textLeft: number = 0
    textTop: number = 0
    textWidth: number = 0
    textHeight: number = 0
    textAlpha: number = 0

    // 气泡里的提示：说话时间太短、没有识别到文字
    hintText: string = ''
    hintColor: string = '#FFFFFFFF'
    hintLeft: number = 0
    hintTop: number = 0
    hintWidth: number = 0
    hintHeight: number = 0
    hintAlpha: number = 0
    hintTranslateY: number = 0

    // 气泡整体的变换，文字和提示跟着 Canvas 上的气泡一起缩放、平移
    bubbleAlpha: number = 0
    bubbleScale: number = 1
    bubblePivotX: number = 0
    bubblePivotY: number = 0
    bubbleTranslateX: number = 0
    bubbleTranslateY: number = 0

    countDownText: string = ''
    countDownLeft: number = 0
    countDownWidth: number = 0
    countDownBottom: number = 0
    countDownAlpha: number = 0

    // 编辑文字时底部的取消、发送原语音、发送
    editActionsVisible: boolean = false
    editActionsLeft: number = 0
    editActionsWidth: number = 0
    editActionsBottom: number = 0
    editActionsAlpha: number = 1
    cancelAlpha: number = 0
    cancelTranslateY: number = 0
    sendVoiceAlpha: number = 0
    sendVoiceTranslateY: number = 0
    sendTextAlpha: number = 0
    sendTextTranslateY: number = 0
    sendVoiceEnabled: boolean = false
    sendTextEnabled: boolean = false
}

/**
 * 浮层和 AudioRecorderPanel 之间的回调和控制器，不参与界面刷新
 */
export class VoiceInputDelegate {
    rootId: string = ''
    textInputId: string = ''
    textController: TextAreaController = new TextAreaController()
    textScroller: Scroller = new Scroller()
    onCanvasReady?: (ctx: CanvasRenderingContext2D) => void
    onLayout?: (width: number, height: number) => void
    onTextChange?: (value: string) => void
    onEditCancel?: () => void
    onSendVoice?: () => void
    onSendText?: () => void
}

const TEXT_SIZE = 22
const HINT_SIZE = 18
const ACTION_CIRCLE_SIZE = 66
const ACTION_WIDTH = 96

@CustomDialog
export default struct VoiceInputDialog {
    controller: CustomDialogController
    @ObjectLink state: VoiceInputState
    delegate: VoiceInputDelegate = new VoiceInputDelegate()
    private settings: RenderingContextSettings = new RenderingContextSettings(true)
    private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

    build() {
        Stack() {
            Canvas(this.ctx)
                .width('100%')
                .height('100%')
                .hitTestBehavior(HitTestMode.Transparent)
                .onReady(() => {
                    this.delegate.onCanvasReady?.(this.ctx)
                })

            Text(this.state.countDownText)
                .fontSize(14)
                .fontColor('#CCFFFFFF')
                .textAlign(TextAlign.Center)
                .width(this.state.countDownWidth)
                .position({ left: this.state.countDownLeft, bottom: this.state.countDownBottom } as Edges)
                .opacity(this.state.countDownAlpha)
                .hitTestBehavior(HitTestMode.None)

            if (this.state.textEditable) {
                TextArea({
                    text: this.state.text,
                    placeholder: this.state.textPlaceholder,
                    controller: this.delegate.textController
                })
                    .id(this.delegate.textInputId)
                    // 识别完成后自动获焦只显示光标，用户点击输入框后才弹出键盘
                    .enableKeyboardOnFocus(false)
                    .fontSize(TEXT_SIZE)
                    .fontColor(this.state.textColor)
                    .placeholderColor(this.state.textPlaceholderColor)
                    .placeholderFont({ size: TEXT_SIZE })
                    .caretColor(this.state.textColor)
                    .selectedBackgroundColor('#4DFFFFFF')
                    .backgroundColor(Color.Transparent)
                    .borderRadius(0)
                    .padding(0)
                    .position({ x: this.state.textLeft, y: this.state.textTop })
                    .width(this.state.textWidth)
                    .height(this.state.textHeight)
                    .opacity(this.state.bubbleAlpha * this.state.textAlpha)
                    .scale(this.bubbleScale(this.state.textLeft, this.state.textTop))
                    .translate({ x: this.state.bubbleTranslateX, y: this.state.bubbleTranslateY })
                    .onChange((value: string) => {
                        this.delegate.onTextChange?.(value)
                    })
            } else {
                Scroll(this.delegate.textScroller) {
                    Text(this.state.text ? this.state.text : this.state.textPlaceholder)
                        .fontSize(TEXT_SIZE)
                        .fontColor(this.state.text ? this.state.textColor : this.state.textPlaceholderColor)
                        .width('100%')
                }
                .scrollBar(BarState.Off)
                .align(Alignment.TopStart)
                .position({ x: this.state.textLeft, y: this.state.textTop })
                .width(this.state.textWidth)
                .height(this.state.textHeight)
                .opacity(this.state.bubbleAlpha * this.state.textAlpha)
                .scale(this.bubbleScale(this.state.textLeft, this.state.textTop))
                .translate({ x: this.state.bubbleTranslateX, y: this.state.bubbleTranslateY })
                .hitTestBehavior(HitTestMode.None)
            }

            Row() {
                VoiceInputIcon({ type: VoiceInputIconType.WARNING, color: this.state.hintColor })
                    .width(22)
                    .height(22)
                Text(this.state.hintText)
                    .fontSize(HINT_SIZE)
                    .fontColor(this.state.hintColor)
                    .maxLines(2)
                    .margin({ left: 6 })
                    .flexShrink(1)
            }
            .justifyContent(FlexAlign.Center)
            .position({ x: this.state.hintLeft, y: this.state.hintTop })
            .width(this.state.hintWidth)
            .height(this.state.hintHeight)
            .opacity(this.state.bubbleAlpha * this.state.hintAlpha)
            .scale(this.bubbleScale(this.state.hintLeft, this.state.hintTop))
            .translate({ x: this.state.bubbleTranslateX, y: this.state.bubbleTranslateY + this.state.hintTranslateY })
            .hitTestBehavior(HitTestMode.None)

            // 一直挂载，只切换可见性，这样按钮升起的动画有起始状态
            this.editActions()
        }
        .id(this.delegate.rootId)
        .width('100%')
        .height('100%')
        .onAreaChange((oldValue: Area, newValue: Area) => {
            this.delegate.onLayout?.(newValue.width as number, newValue.height as number)
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }

    /**
     * 以气泡底部中点为中心缩放，left/top 是组件左上角的位置
     */
    private bubbleScale(left: number, top: number): ScaleOptions {
        return {
            x: this.state.bubbleScale,
            y: this.state.bubbleScale,
            centerX: this.state.bubblePivotX - left,
            centerY: this.state.bubblePivotY - top
        }
    }

    @Builder
    editActions() {
        Row() {
            Column() {
                Stack() {
                    VoiceInputIcon({ type: VoiceInputIconType.CLOSE, color: '#FFFFFFFF' })
                        .width(24)
                        .height(24)
                }
                .width(ACTION_CIRCLE_SIZE)
                .height(ACTION_CIRCLE_SIZE)
                .borderRadius(ACTION_CIRCLE_SIZE / 2)
                .stateStyles({
                    pressed: {
                        .backgroundColor('#6A6A6A')
                    },
                    normal: {
                        .backgroundColor('#575757')
                    }
                })
                .onClick(() => {
                    this.delegate.onEditCancel?.()
                })

                Text('取消')
                    .fontSize(15)
                    .fontColor('#BDBDBD')
                    .margin({ top: 10 })
            }
            .width(ACTION_WIDTH)
            .opacity(this.state.cancelAlpha)
            .translate({ y: this.state.cancelTranslateY })

            Column() {
                Stack() {
                    VoiceInputIcon({ type: VoiceInputIconType.SOUND, color: '#FFFFFFFF' })
                        .width(26)
                        .height(26)
                }
                .width(ACTION_CIRCLE_SIZE)
                .height(ACTION_CIRCLE_SIZE)
                .borderRadius(ACTION_CIRCLE_SIZE / 2)
                .stateStyles({
                    pressed: {
                        .backgroundColor('#6A6A6A')
                    },
                    normal: {
                        .backgroundColor('#575757')
                    }
                })
                .enabled(this.state.sendVoiceEnabled)
                .onClick(() => {
                    this.delegate.onSendVoice?.()
                })

                Text('发送原语音')
                    .fontSize(15)
                    .fontColor('#BDBDBD')
                    .maxLines(1)
                    .margin({ top: 10 })
            }
            .width(ACTION_WIDTH)
            .margin({ left: 10 })
            .opacity(this.state.sendVoiceAlpha * (this.state.sendVoiceEnabled ? 1 : 0.4))
            .translate({ y: this.state.sendVoiceTranslateY })

            Blank()

            Text('发送')
                .fontSize(19)
                .fontColor(this.state.sendTextEnabled ? '#111111' : '#737373')
                .textAlign(TextAlign.Center)
                .width(124)
                .height(74)
                .borderRadius(37)
                .backgroundColor(this.state.sendTextEnabled ? '#DADADA' : '#4E4E4E')
                .stateStyles({
                    pressed: {
                        .opacity(0.8)
                    }
                })
                .enabled(this.state.sendTextEnabled)
                .onClick(() => {
                    this.delegate.onSendText?.()
                })
                .opacity(this.state.sendTextAlpha)
                .translate({ y: this.state.sendTextTranslateY })
        }
        .alignItems(VerticalAlign.Top)
        .padding({ left: 16, right: 24 })
        .width(this.state.editActionsWidth)
        .position({ left: this.state.editActionsLeft, bottom: this.state.editActionsBottom } as Edges)
        .opacity(this.state.editActionsAlpha)
    }
}

export enum VoiceInputIconType {
    CLOSE,
    SOUND,
    // 圆形感叹号，感叹号镂空，透出气泡的颜色
    WARNING
}

@Component
struct VoiceInputIcon {
    type: VoiceInputIconType = VoiceInputIconType.CLOSE
    @Prop @Watch('draw') color: string = '#FFFFFFFF'
    private settings: RenderingContextSettings = new RenderingContextSettings(true)
    private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

    build() {
        Canvas(this.ctx)
            .width('100%')
            .height('100%')
            .hitTestBehavior(HitTestMode.Transparent)
            .onReady(() => {
                this.draw()
            })
    }

    private draw() {
        let ctx = this.ctx
        let size = Math.min(ctx.width, ctx.height)
        if (!(size > 0)) {
            return
        }
        ctx.clearRect(0, 0, ctx.width, ctx.height)
        ctx.save()
        // 图标按 24 的画布设计
        let scale = size / 24
        ctx.scale(scale, scale)
        ctx.fillStyle = this.color
        ctx.strokeStyle = this.color
        ctx.lineCap = 'round'
        if (this.type === VoiceInputIconType.CLOSE) {
            ctx.lineWidth = 2.4
            ctx.beginPath()
            ctx.moveTo(4, 4)
            ctx.lineTo(20, 20)
            ctx.moveTo(20, 4)
            ctx.lineTo(4, 20)
            ctx.stroke()
        } else if (this.type === VoiceInputIconType.SOUND) {
            ctx.beginPath()
            ctx.arc(7, 12, 1.8, 0, Math.PI * 2)
            ctx.fill()
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.arc(7, 12, 5.1, -Math.PI / 4, Math.PI / 4)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(7, 12, 9.6, -Math.PI / 4, Math.PI / 4)
            ctx.stroke()
        } else {
            ctx.beginPath()
            ctx.arc(12, 12, 12, 0, Math.PI * 2)
            ctx.fill()
            ctx.globalCompositeOperation = 'destination-out'
            ctx.lineWidth = 2.8
            ctx.beginPath()
            ctx.moveTo(12, 6.6)
            ctx.lineTo(12, 13.6)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 17.4, 1.6, 0, Math.PI * 2)
            ctx.fill()
            ctx.globalCompositeOperation = 'source-over'
        }
        ctx.restore()
    }
}
