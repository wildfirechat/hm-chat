import router from '@ohos.router'
import { exist } from '../../../common/utils/FileUtil'
import wfc from '../../../wfc/client/wfc'
import ImageMessageContent from '../../../wfc/messages/imageMessageContent'
import Message from '../../../wfc/messages/message'

@Component
export default struct ImageMessageContentView {
    @Link message: Message

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
        return 'data:image/jpeg;base64,' + (this.message.messageContent as ImageMessageContent).thumbnail
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
            .objectFit(ImageFit.Contain)
            .width(this.imageWidth())
            .constraintSize({ minWidth: 100, maxWidth: 200 })
            .borderRadius(4)
            .onClick(event => {
                router.pushUrl({
                    url: 'pages/mm/MMMessagePreviewPage',
                    params: {
                        message: this.message
                    }
                })
            })
    }
}