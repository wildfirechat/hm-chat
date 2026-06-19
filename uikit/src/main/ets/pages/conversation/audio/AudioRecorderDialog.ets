import { FontSize, Radius } from '../../../common/design/Tokens'
export class AudioRecorderDialogState {
    private _cancelListener?: (show: boolean) => void

    setListener(listener: ((show: boolean) => void) | undefined) {
        this._cancelListener = listener
    }

    updateCancelIndicator(show: boolean) {
        this._cancelListener?.(show)
    }
}

@CustomDialog
export default struct AudioRecorderDialog {
    controller: CustomDialogController
    dialogState: AudioRecorderDialogState = new AudioRecorderDialogState()
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
    @State showCancelRecordIndicator: boolean = false
    private volumeTimer: number = -1

    aboutToAppear(): void {
        this.dialogState.setListener((show: boolean) => {
            this.showCancelRecordIndicator = show
        })
        this.volumeTimer = setInterval(() => {
            let index = new Date().getTime() % 7
            this.volumeResource = this.volumeIcons[index]
        }, 500)
    }

    aboutToDisappear(): void {
        clearInterval(this.volumeTimer)
        this.dialogState.setListener(undefined)
    }

    build() {
        Column() {
            Column() {
                Image(this.volumeResource)
                    .width(80)
                    .height(80)
                    .margin({ top: 20 })
                Text(this.showCancelRecordIndicator ? '松开手指，取消' : '手指上滑，取消')
                    .fontSize(FontSize.xl)
                    .fontColor(Color.White)
                    .backgroundColor(this.showCancelRecordIndicator ? $r('app.color.wf_danger') : $r('app.color.wf_tertiary_text'))
                    .borderRadius(Radius.lg)
                    .textAlign(TextAlign.Center)
                    .margin({ top: 20 })
                    .height(40)
                    .width(160)
            }
            .width(200)
            .height(200)
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
