import { showToast } from '../../../common/utils/Toast'
import CompositeMessageContent from '../../../wfc/messages/compositeMessageContent'
import Message from '../../../wfc/messages/message'

@Component
export default struct CompositeMessageContentView {
    @Link message: Message
    private compositeMessageContent?: CompositeMessageContent;

    aboutToAppear(): void {
        this.compositeMessageContent = this.message.messageContent as CompositeMessageContent
    }

    build() {
        Column() {
            Column() {
                Text(this.compositeMessageContent?.title)
                    .fontSize(16)
                Text(this.compositeMessageContent?.compositeDigest())
                    .fontSize(14)
                    .margin({ top: 5, bottom: 5 })
            }
            .borderWidth({ bottom: '1px' })
            .borderColor('#EDEDED')
            .alignItems(HorizontalAlign.Start)

            Text('聊天记录')
                .fontSize(12)
                .margin({ top: 5 })
        }
        .margin({ top: 4 })
        .alignItems(HorizontalAlign.Start)
        .padding(10)
        .borderRadius(4)
        .backgroundColor(Color.White)
        .onClick(() => {
            showToast('TODO: 查看组合消息')
        })
    }
}