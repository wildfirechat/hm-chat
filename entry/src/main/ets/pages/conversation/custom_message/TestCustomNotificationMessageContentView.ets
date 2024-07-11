import Message from '../../../wfc/messages/message'

@Component
export default struct TestCustomNotificationMessageContentView {
    @Prop message: Message

    build() {
        Text(this.message!.messageContent.digest(this.message))
            .padding(10)
            .fontSize(12)
            .constraintSize({ minHeight: 40 })
    }
}