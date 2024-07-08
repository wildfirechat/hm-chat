import router from '@ohos.router'
import { showToast } from '../../../common/utils/Toast'
import Config from '../../../config'
import ActionSheetDialog from '../../../view/ActionSheetDialog'
import wfc from '../../../wfc/client/wfc'
import Message from '../../../wfc/messages/message'
import MessageContentType from '../../../wfc/messages/messageContentType'
import ConversationType from '../../../wfc/model/conversationType'
import AudioPlayManager from '../audio/AudioPlayManager'
import ReadReceipt from '../model/readReceipt'
import AudioMessageContent from './AudioMessageContentView'
import CallStartMessageContentView from './CallStartMessageContentView'
import CompositeMessageContentView from './CompositeMessageContentView'
import ImageMessageContentView from './ImageMessageContentView'
import StickerMessageContentView from './StickerMessageContentView'
import TextMessageContentView from './TextMessageContentView'
import VideoMessageContentView from './VideoMessageContentView'
import { HashMap } from '@kit.ArkTS'
import GroupMember from '../../../wfc/model/groupMember'
import FileMessageContentView from './FileMessageContentView'
import TextMessageContent from '../../../wfc/messages/textMessageContent'
import pasteboard from '@ohos.pasteboard'

@Component
export default struct CompositeMessageContentContainerView {
    @Prop message: Message

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
                ImageMessageContentView({ message: $message })
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
