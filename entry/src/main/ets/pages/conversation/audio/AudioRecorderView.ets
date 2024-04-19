@Component
export default struct AudioRecorderView {
    @State message: string = 'TODO正在录音'
    @Link showAudioRecorderView: boolean
    @Link @Watch('onShowCancelRecordIndicator') showCancelRecordIndicator: boolean
    @Link @Watch('onRecordCountDown') recordCountDown: number
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
    @State volumeResource: Resource = this.volumeIcons[0];
    @State recordStateText: string = '手指上滑，取消'
    @State recordStateTextBackgroundColor: string = '#716F66'

    aboutToAppear(): void {
        // TODO
        // FIXME
        setInterval(() => {
            let index = new Date().getTime() % 7
            this.volumeResource = this.volumeIcons[index]
        }, 500)
    }

    onShowCancelRecordIndicator(propName: string) {
        if (this.showCancelRecordIndicator) {
            this.recordStateText = '松开手指，取消'
            this.recordStateTextBackgroundColor = '#CC933432'
        } else {
            this.recordStateText = '手指上滑，取消'
            this.recordStateTextBackgroundColor = '#716F66'
        }
    }

    onRecordCountDown(propName: string) {
        // TODO
    }

    build() {
        Row() {
            Column() {
                Image(this.volumeResource)
                    .width(80)
                    .height(80)
                    .margin({ top: 20 })

                Text(this.recordStateText)
                    .fontSize(20)
                    .fontColor(Color.White)
                    .backgroundColor(this.recordStateTextBackgroundColor)
                    .borderRadius(2)
                    .textAlign(TextAlign.Center)
                    .margin({ top: 20 })
                    .height(40)
                    .width(160)
            }
            .width(200)
            .height(200)
            .borderRadius(5)
            .backgroundColor('#716F66')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .height('100%')
        .width('100%')
    }
}