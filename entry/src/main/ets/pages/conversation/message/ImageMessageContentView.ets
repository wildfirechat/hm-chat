import router from '@ohos.router'
import { MediaEntry, MMMediaEntry } from '../../../common/Types'
import { exist } from '../../../common/utils/FileUtil'
import Config from '../../../config'
import { mediaEntry } from '../../../helper/messageHelper'
import CompositeMessageContent from '../../../wfc/messages/compositeMessageContent'
import ImageMessageContent from '../../../wfc/messages/imageMessageContent'
import Message from '../../../wfc/messages/message'
import MessageContentType from '../../../wfc/messages/messageContentType'
import { eq } from '../../../wfc/util/longUtil'
import MMMessagePreviewDialog from '../../mm/MMMessagePreviewDialog'

@Component
export default struct ImageMessageContentView {
    @Link message: Message
    @Prop parentCompositeMessage: Message
    private mmPreviewDialogController?: CustomDialogController

    imageMessageContent() {
        return this.message.messageContent as ImageMessageContent
    }

    imageUrl() {
        let content = this.message.messageContent as ImageMessageContent;
        let localPath = content.localPath;
        if (exist(localPath)) {
            return 'file://' + localPath
        }
        return content.remotePath
    }

    thumbnail() {
        let content = this.message.messageContent as ImageMessageContent;
        if (content.thumbnail) {
            return 'data:image/jpeg;base64,' + (this.message.messageContent as ImageMessageContent).thumbnail
        }
        return Config.DEFAULT_THUMBNAIL_URL
    }

    imageWidth() {
        let content = this.message.messageContent as ImageMessageContent;
        if (content.imageWidth) {
            return content.imageWidth
        }
        return -1
    }

    build() {
        Image(this.imageUrl())
            .alt(this.thumbnail())
            .draggable(false)
            .objectFit(ImageFit.Contain)
            .width(this.imageWidth())
            .constraintSize({ minWidth: 100, maxWidth: 200 })
            .borderRadius(4)
            .onClick(event => {
                let msg: Message | undefined
                let mediaEntries: MMMediaEntry[] = []
                let index = 0;
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
                        mediaEntries: mediaEntries,
                        message: msg,
                        index: index,
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
