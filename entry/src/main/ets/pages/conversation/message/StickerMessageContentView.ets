import { exist } from '../../../common/utils/FileUtil'
import Message from '../../../wfc/messages/message'
import StickerMessageContent from '../../../wfc/messages/stickerMessageContent'

@Component
export default struct StickerMessageContentView {
    @Link message: Message

    imageMessageContent() {
        return this.message.messageContent as StickerMessageContent
    }

    imageUrl() {
        let content = this.message.messageContent as StickerMessageContent;
        let localPath = content.localPath;
        if (exist(localPath)) {
            return 'file://' + localPath
        }
        return content.remotePath
    }

    build() {
        Image(this.imageUrl())
            .objectFit(ImageFit.Contain)
            .constraintSize({ maxWidth: 200, maxHeight: 200 })
            .borderRadius(4)
            .onClick(event => {
                // TODO
            })
    }
}