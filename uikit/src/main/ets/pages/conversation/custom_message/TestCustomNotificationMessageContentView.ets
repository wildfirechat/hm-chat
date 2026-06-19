import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { FontSize } from '../../../common/design/Tokens'

@Component
export default struct TestCustomNotificationMessageContentView {
    @Prop message: Message

    build() {
        Text(this.message!.messageContent.digest(this.message))
            .padding(12)
            .fontSize(FontSize.xs)
            .constraintSize({ minHeight: 40 })
    }
}