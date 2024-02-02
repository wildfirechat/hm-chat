import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import client from 'marswrapper'

@Component
export default struct AudioRecorderView {
    @State message: string = 'TODO正在录音'
    @Link showAudioRecorderView: boolean
    @Link showCancelRecordIndicator: boolean
    @Link recordCountDown: number

    build() {
        Row() {
            Column() {
                Text(this.showCancelRecordIndicator ? 'TODO取消录音' : this.message)
                    .width(200)
                    .height(200)
                    .backgroundColor(Color.Green)
                    .fontSize(50)
                    .fontWeight(FontWeight.Bold)
                    .onClick(() => {
                        this.showAudioRecorderView = false
                    })
            }
            .width('100%')
        }
        .height('100%')
    }
}