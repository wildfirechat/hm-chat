import Message from '../../../wfc/messages/message'
import TextMessageContent from '../../../wfc/messages/textMessageContent'

@Component
export default struct TextMessageContentView {
    @Link message: Message
    @Prop textPadding: Length | Padding = 10

    quoteInfoDesc() {
        let quoteInfo = (this.message.messageContent as TextMessageContent).quoteInfo
        return `${quoteInfo?.userDisplayName}: ${quoteInfo?.messageDigest}`
    }

    build() {
        if ((this.message.messageContent as TextMessageContent).quoteInfo) {
            Column() {
                Text(this.message.messageContent.digest(this.message))
                    .padding(this.textPadding)
                    .constraintSize({ minHeight: 40 })
                    .backgroundColor(Color.White)
                    .borderRadius(4)

                Text(this.quoteInfoDesc())
                    .padding(this.textPadding)
                    .margin({ top: 8 })
                    .constraintSize({ minHeight: 40 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .backgroundColor('#E7E7E7')
                    .borderRadius(4)
            }
            // 0 out
            .alignItems(this.message.direction === 0 ? HorizontalAlign.End : HorizontalAlign.Start)

        } else {
            Text(this.message.messageContent.digest(this.message))
                .padding(this.textPadding)
                .constraintSize({ minHeight: 40 })
                .backgroundColor(Color.White)
                .borderRadius(4)
        }
    }
}