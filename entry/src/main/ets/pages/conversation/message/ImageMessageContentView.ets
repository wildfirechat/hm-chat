import router from '@ohos.router'
import { exist } from '../../../common/utils/FileUtil'
import Config from '../../../config'
import ImageMessageContent from '../../../wfc/messages/imageMessageContent'
import Message from '../../../wfc/messages/message'
import MMMessagePreviewDialog from '../../mm/MMMessagePreviewDialog'

@Component
export default struct ImageMessageContentView {
    @Link message: Message
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
                this.mmPreviewDialogController = new CustomDialogController({
                    builder: MMMessagePreviewDialog({
                        message: this.message,
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
