import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'

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