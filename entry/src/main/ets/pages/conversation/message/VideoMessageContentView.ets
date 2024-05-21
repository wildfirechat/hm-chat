import router from '@ohos.router'
import { exist } from '../../../common/utils/FileUtil'
import Config from '../../../config'
import Message from '../../../wfc/messages/message'
import VideoMessageContent from '../../../wfc/messages/videoMessageContent'
import MMMessagePreviewDialog from '../../mm/MMMessagePreviewDialog'

@Component
export default struct VideoMessageContentView {
    @Link message: Message
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
