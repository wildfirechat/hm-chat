import Message from '../../../wfc/messages/message'

@Component
export default struct SimpleNotificationMessageContentView {
    @State message?: Message = undefined

    build() {
        Text(this.message!.messageContent.digest(this.message))
            .padding(10)
            .fontSize(12)
            .constraintSize({ minHeight: 40 })
    }
}