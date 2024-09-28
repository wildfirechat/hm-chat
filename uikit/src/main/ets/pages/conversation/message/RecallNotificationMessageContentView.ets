import { showToast } from '../../../common/utils/Toast'
import Config from '@wfc/client/src/main/ets/config'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'

@Component
export default struct RecallNotificationMessageContentView {
    @Prop message: Message
    @State enableReEdit: boolean = false
    public onClickReedit?: () => void
    private tickInterval: number = 0

    aboutToAppear(): void {
        if (this.message.direction === 0) {
            let now = new Date().getTime()
            let delta = wfc.getServerDeltaTime()
            if (now - (this.message.timestamp - delta) < Config.RECALL_REEDIT_TIME_LIMIT * 1000) {
                this.enableReEdit = true
                this.tickInterval = setInterval(this.updateEditable, 100)
            }
        } else {
            this.enableReEdit = false
        }
    }

    aboutToDisappear(): void {
        if (this.tickInterval) {
            clearInterval(this.tickInterval)
        }
    }

    updateEditable = () => {
        let now = new Date().getTime()
        let delta = wfc.getServerDeltaTime()
        if (now - (this.message.timestamp - delta) < Config.RECALL_REEDIT_TIME_LIMIT * 1000) {
            this.enableReEdit = true
        } else {
            this.enableReEdit = false
            clearInterval(this.tickInterval)
        }
    }

    build() {
        Row() {
            Text(this.message!.messageContent.digest(this.message))
                .padding(10)
                .fontSize(12)
                .constraintSize({ minHeight: 40 })
            if (this.enableReEdit) {
                Text('编辑')
                    .margin({ left: 8 })
                    .fontSize(13)
                    .fontColor('#3066EC')
                    .onClick(() => {
                        this.onClickReedit?.()
                    })
            }
        }
    }
}