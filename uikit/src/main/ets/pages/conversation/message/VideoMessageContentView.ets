import { MMMediaEntry } from '../../../common/Types'
import { exist } from '../../../common/utils/FileUtil'
import Config from '@wfc/client/src/main/ets/config'
import { mediaEntry } from '../../../helper/messageHelper'
import CompositeMessageContent from '@wfc/client/src/main/ets/wfc/messages/compositeMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent'
import { eq } from '@wfc/client/src/main/ets/wfc/util/longUtil'
import MMMessagePreviewDialog from '../../mm/MMMessagePreviewDialog'

@Component
export default struct VideoMessageContentView {
    @Link message: Message
    @Prop parentCompositeMessage: Message
    private mmPreviewDialogController?: CustomDialogController

    videoMessageContent() {
        return this.message.messageContent as VideoMessageContent
    }

    videoUrl() {
        let content = this.message.messageContent as VideoMessageContent;
        let localPath = content.localPath;
        if (exist(localPath)) {
            return 'file://' + localPath
        }
        return content.remotePath
    }

    thumbnail() {
        let content = this.message.messageContent as VideoMessageContent;
        if (content.thumbnail) {
            return 'data:image/jpeg;base64,' + (this.message.messageContent as VideoMessageContent).thumbnail
        }
        return Config.DEFAULT_THUMBNAIL_URL
    }

    build() {
        Image(this.thumbnail())
            .draggable(false)
            .objectFit(ImageFit.Contain)
            .borderRadius(4)
            .constraintSize({ maxWidth: 200 })
            .autoResize(true)
            .onClick(event => {
                let msg: Message | undefined
                let mediaEntries: MMMediaEntry[] = []
                let index = 0
                if (this.parentCompositeMessage) {
                    let compositeContent = this.parentCompositeMessage.messageContent as CompositeMessageContent
                    let imageVideoMsgs = compositeContent.messages.filter(m => [MessageContentType.Image, MessageContentType.Video].indexOf(m.messageContent.type) >= 0)
                    mediaEntries = imageVideoMsgs.map(m => mediaEntry(m))
                    msg = undefined
                    for (let i = 0; i < imageVideoMsgs.length; i++) {
                        if (eq(imageVideoMsgs[i].messageUid, this.message.messageUid)) {
                            index = i;
                            break
                        }
                    }
                } else {
                    msg = this.message
                }
                this.mmPreviewDialogController = new CustomDialogController({
                    builder: MMMessagePreviewDialog({
                        message: msg,
                        index: index,
                        mediaEntries: mediaEntries,
                        controller: this.mmPreviewDialogController,
                    }),
                    alignment: DialogAlignment.TopStart,
                    autoCancel: false,
                    customStyle: true,
                })
                this.mmPreviewDialogController.open()
            })
    }
}
