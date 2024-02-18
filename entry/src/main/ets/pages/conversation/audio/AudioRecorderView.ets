import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import client from 'marswrapper'

@Component
export default struct AudioRecorderView {
    @Prop showCancelRecordIndicator: boolean
    @Prop recordCountDown: number
    @State audioVolumeIndicatorImageUrl: Resource = $r('app.media.ic_volume_3')
    @State countDownText: string = ''
    @State stateText: string = '手指上滑，取消'

    build() {
        Row() {
            Column() {
                if (!this.recordCountDown || this.showCancelRecordIndicator) {
                    Image(this.showCancelRecordIndicator ? $r('app.media.ic_volume_cancel') : this.audioVolumeIndicatorImageUrl)
                        .width(100)
                        .height(100)
                } else {
                    Text(this.recordCountDown + '')
                        .fontSize(70)
                        .fontColor(Color.White)
                }
                Text(this.stateText)
                    .margin({ top: 20 })
                    .fontSize(15)
                    .width(160)
                    .height(40)
                    .fontColor(Color.White)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(this.showCancelRecordIndicator ? '#CC933432' : '')
                    .borderRadius(2)
            }
            .width(200)
            .height(200)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .borderRadius(10)
            .backgroundColor('#736F65')
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
    }
}