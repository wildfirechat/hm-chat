import Message from '../../../wfc/messages/message'

@Component
export default struct TextMessageContentView {
    @Link message: Message

    build() {
        Text(this.message.messageContent.digest(this.message))
            .padding(10)
            .constraintSize({ minHeight: 40 })
            .backgroundColor(Color.White)
            .borderRadius(4)
    }
}