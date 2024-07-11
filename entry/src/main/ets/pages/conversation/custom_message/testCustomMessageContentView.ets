import Message from '../../../wfc/messages/message'
import TextMessageContent from '../../../wfc/messages/textMessageContent'

@Component
export default struct TestCustomMessageContentView {
    @Link message: Message
    @Prop textPadding: Length | Padding = 10

    build() {
        Text(this.message.messageContent.digest(this.message))
            .padding(this.textPadding)
            .constraintSize({ minHeight: 40 })
            .backgroundColor(Color.White)
            .borderRadius(4)
    }
}