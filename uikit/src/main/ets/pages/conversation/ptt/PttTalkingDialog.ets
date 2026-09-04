import { FontSize, LayoutScale, Radius, scaledSize } from '../../../common/design/Tokens'

/**
 * 对讲说话中的浮层状态，由 {@link ConversationInputPanelView} 驱动。
 *
 * 和录音浮层一样，弹窗是 @CustomDialog，拿不到外面的 @State，所以用这个对象做单向的状态透传。
 */
export class PttTalkingDialogState {
    private amplitudeListener?: (amplitude: number) => void
    private countDownListener?: (seconds: number) => void

    setListeners(amplitudeListener: ((amplitude: number) => void) | undefined,
        countDownListener: ((seconds: number) => void) | undefined) {
        this.amplitudeListener = amplitudeListener
        this.countDownListener = countDownListener
    }

    /** 说话音量，取值和 PCM 采样的平均振幅一致（0 ~ 32767）。 */
    updateAmplitude(amplitude: number) {
        this.amplitudeListener?.(amplitude)
    }

    /** 剩余秒数，<= 0 表示还不到倒计时的时候，显示音量图标。 */
    updateCountDown(seconds: number) {
        this.countDownListener?.(seconds)
    }
}

@CustomDialog
export default struct PttTalkingDialog {
    controller: CustomDialogController
    dialogState: PttTalkingDialogState = new PttTalkingDialogState()
    private volumeIcons: Resource[] = [
        $r('app.media.ic_volume_1'),
        $r('app.media.ic_volume_2'),
        $r('app.media.ic_volume_3'),
        $r('app.media.ic_volume_4'),
        $r('app.media.ic_volume_5'),
        $r('app.media.ic_volume_6'),
        $r('app.media.ic_volume_7'),
        $r('app.media.ic_volume_8')
    ]
    @State volumeResource: Resource = this.volumeIcons[0]
    @State countDownSeconds: number = 0

    aboutToAppear(): void {
        this.dialogState.setListeners((amplitude: number) => {
            // 平均振幅是 0 ~ 32767，正常说话大概在 1000 ~ 8000，每 1000 一档，超出的都按最大档
            let level = Math.floor(amplitude / 1000)
            level = level < 0 ? 0 : (level > 7 ? 7 : level)
            this.volumeResource = this.volumeIcons[level]
        }, (seconds: number) => {
            this.countDownSeconds = seconds
        })
    }

    aboutToDisappear(): void {
        this.dialogState.setListeners(undefined, undefined)
    }

    build() {
        Column() {
            Column() {
                if (this.countDownSeconds > 0) {
                    Text(`${this.countDownSeconds}`)
                        .fontSize(FontSize.huge)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.wf_danger'))
                        .minFontScale(1)
                        .maxFontScale(1)
                        .textAlign(TextAlign.Center)
                        .width(80)
                        .height(80)
                        .margin({ top: 20 })
                } else {
                    Image(this.volumeResource)
                        .width(80)
                        .height(80)
                        .margin({ top: 20 })
                }
                Text('松手结束对讲')
                    .fontSize(FontSize.xl)
                    .fontColor(Color.White)
                    .backgroundColor($r('app.color.wf_tertiary_text'))
                    .borderRadius(Radius.lg)
                    .textAlign(TextAlign.Center)
                    .margin({ top: 28 })
                    .constraintSize({ minHeight: 40 })
                    .width(scaledSize(160, LayoutScale.cap))
            }
            .width(scaledSize(200, LayoutScale.cap))
            .height(scaledSize(200, LayoutScale.cap))
            .borderRadius(Radius.xl)
            .backgroundColor($r('app.color.wf_record_view_background_color'))
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
}
