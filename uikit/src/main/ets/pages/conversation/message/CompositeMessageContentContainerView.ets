import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import CallStartMessageContentView from './CallStartMessageContentView'
import CompositeMessageContentView from './CompositeMessageContentView'
import ImageMessageContentView from './ImageMessageContentView'
import StickerMessageContentView from './StickerMessageContentView'
import TextMessageContentView from './TextMessageContentView'
import VideoMessageContentView from './VideoMessageContentView'
import FileMessageContentView from './FileMessageContentView'

@Component
export default struct CompositeMessageContentContainerView {
    // 组合消息里面的具体一条消息
    @Prop message: Message
    // 组合消息本身
    @Prop parentCompositeMessage: Message

    aboutToAppear(): void {
    }

    build() {
        Column() {
            if (this.message!.messageContent.type === MessageContentType.Text) {
                TextMessageContentView({
                    message: $message,
                    textPadding: 0,
                })
            } else if (this.message!.messageContent.type === MessageContentType.Sticker) {
                StickerMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Image) {
                ImageMessageContentView({ message: $message, parentCompositeMessage: this.parentCompositeMessage })
            } else if (this.message!.messageContent.type === MessageContentType.Video) {
                VideoMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Voice) {
                //AudioMessageContent({ message: $message, audioPlayManager: this.audioPlayManager })
                TextMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.VOIP_CONTENT_TYPE_START) {
                CallStartMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Composite_Message) {
                CompositeMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.File) {
                FileMessageContentView({ message: $message })
            } else {
                Text(this.message!.messageContent.digest(this.message))
                    .margin({ top: 4 })
                    .padding(10)
            }
        }
    }
}
