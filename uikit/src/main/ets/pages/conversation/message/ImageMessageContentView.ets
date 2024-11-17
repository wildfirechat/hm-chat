import router from '@ohos.router'
import { MediaEntry, MMMediaEntry } from '../../../common/Types'
import { exist } from '../../../common/utils/FileUtil'
import Config from '@wfc/client/src/main/ets/config'
import { mediaEntry } from '../../../helper/messageHelper'
import CompositeMessageContent from '@wfc/client/src/main/ets/wfc/messages/compositeMessageContent'
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import { eq } from '@wfc/client/src/main/ets/wfc/util/longUtil'
import MMMessagePreviewDialog from '../../mm/MMMessagePreviewDialog'
import { getImageSizeByOrgSizeToWeChat } from '../../../util/wechatImageUtil'
import { Size } from '@kit.ArkUI'

@Component
export default struct ImageMessageContentView {
    @Link message: Message
    @Prop parentCompositeMessage: Message
    private mmPreviewDialogController?: CustomDialogController
    private scaledSize?: Size;

    aboutToAppear(): void {
        let content = this.message.messageContent as ImageMessageContent
        this.scaledSize = getImageSizeByOrgSizeToWeChat(content.imageWidth, content.imageHeight)
    }

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

    build() {
        Image(this.imageUrl())
            .alt(this.thumbnail())
            .draggable(false)
            .objectFit(ImageFit.Fill)
            .width(px2vp(this.scaledSize?.width))
            .height(px2vp(this.scaledSize?.height))
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
