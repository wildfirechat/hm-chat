import Message from '@wfc/client/src/main/ets/wfc/messages/message'

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