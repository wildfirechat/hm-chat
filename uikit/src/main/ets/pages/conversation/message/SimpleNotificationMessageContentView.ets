import Message from '@wfc/client/src/main/ets/wfc/messages/message'

@Component
export default struct SimpleNotificationMessageContentView {
    @Prop message: Message

    build() {
        Text(this.message!.messageContent.digest(this.message))
            .padding(10)
            .fontSize(12)
            .constraintSize({ minHeight: 40 })
    }
}