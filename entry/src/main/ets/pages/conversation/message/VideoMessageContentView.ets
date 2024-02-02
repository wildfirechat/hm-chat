import router from '@ohos.router'
import { exist } from '../../../common/utils/FileUtil'
import Message from '../../../wfc/messages/message'
import VideoMessageContent from '../../../wfc/messages/videoMessageContent'

@Component
export default struct VideoMessageContentView {
    @Link message: Message

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
        return 'data:image/jpeg;base64,' + (this.message.messageContent as VideoMessageContent).thumbnail
    }

    build() {
        Image(this.thumbnail())
            .objectFit(ImageFit.Contain)
            .borderRadius(4)
            .constraintSize({ maxWidth: 200 })
            .backgroundColor(Color.Green)
            .autoResize(true)
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