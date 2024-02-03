import router from '@ohos.router';
import { MediaEntry } from '../../common/Types';
import wfc from '../../wfc/client/wfc';
import ImageMessageContent from '../../wfc/messages/imageMessageContent';
import Message from '../../wfc/messages/message';
import MessageContentType from '../../wfc/messages/messageContentType';
import VideoMessageContent from '../../wfc/messages/videoMessageContent';
import { exist } from '../../common/utils/FileUtil'

@Entry
@Component
export default struct MMMessagePreviewPage {
    @State mediaMessages: Message[] = null
    private message: Message
    @State index: number = 0
    private isLoadingOldMessage: boolean
    private isLoadingNewMessage: boolean

    async aboutToAppear() {
        const params = router.getParams();
        this.message = params['message']
        this.mediaMessages = [this.message]
        let oldMsgs = await this.loadMoreMessages(this.message, true)
        let newMsgs = await this.loadMoreMessages(this.message, false)
        this.mediaMessages = oldMsgs.concat(this.mediaMessages, this.message, newMsgs)
        this.index = oldMsgs.length
    }

    loadMoreMessages(message: Message, before: boolean): Promise<Message[]> {
        return new Promise((resolve, reject) => {
            wfc.getMessagesByTimestampV2(message.conversation, [MessageContentType.Image, MessageContentType.Video], message.timestamp, before, 5, '', (msgs: Message[]) => {
                resolve(msgs)
            }, (err: number) => {
                reject(err)
            })
        })
    }

    isImageMessageContent(message: Message) {
        return message.messageContent.type === MessageContentType.Image
    }

    mediaEntry(message: Message): MediaEntry {
        if (this.isImageMessageContent(message)) {
            let imageMessageContent = message.messageContent as ImageMessageContent
            return {
                type: 'image',
                url: imageMessageContent.localPath && exist(imageMessageContent.localPath) ? 'file://' + imageMessageContent.localPath : imageMessageContent.remotePath,
                thumbnail: 'data:image/jpeg;base64,' + imageMessageContent.thumbnail
            } as MediaEntry

        } else {
            let videoMessageContent = message.messageContent as VideoMessageContent
            return {
                type: 'video',
                url: videoMessageContent.localPath && exist(videoMessageContent.localPath) ? 'file://' + videoMessageContent.localPath : videoMessageContent.remotePath,
                thumbnail: 'data:image/jpeg;base64,' + videoMessageContent.thumbnail
            } as MediaEntry
        }
    }

    build() {
        Navigation() {
            Swiper() {
                ForEach(this.mediaMessages, (message: Message) => {
                    if (this.isImageMessageContent(message)) {
                        Image(this.mediaEntry(message).url)
                            .alt(this.mediaEntry(message).thumbnail)
                            .objectFit(ImageFit.Contain)
                            .width('100%')
                            .height('100%')
                            .backgroundColor('#EDEDED')
                            .draggable(true)
                    } else {
                        Video({
                            previewUri: this.mediaEntry(message).thumbnail,
                            src: this.mediaEntry(message).url
                        })
                            .autoPlay(true)
                            .controls(false)
                            .objectFit(ImageFit.Contain)
                            .width('100%')
                            .height('100%')
                            .backgroundColor('#EDEDED')
                    }
                }, (message: Message) => message.messageId + '')
            }
            .indicator(false)
            .vertical(false)
            .index(this.index)
            .loop(false)
            .cachedCount(3)
            .onChange((index: number) => {
                this.index = index
                if (index < 3) {
                    if (this.isLoadingOldMessage) {
                        return
                    }
                    this.isLoadingOldMessage = true
                    this.loadMoreMessages(this.mediaMessages[0], true)
                        .then((msgs: Message[]) => {
                            this.index = msgs.length + this.index
                            this.mediaMessages = msgs.concat(this.mediaMessages)
                            this.isLoadingOldMessage = false
                        })
                } else if (index > this.mediaMessages.length - 3) {
                    if (this.isLoadingNewMessage) {
                        return
                    }
                    this.isLoadingNewMessage = true
                    this.loadMoreMessages(this.mediaMessages[this.mediaMessages.length - 1], false)
                        .then((msgs: Message[]) => {
                            this.mediaMessages = this.mediaMessages.concat(msgs)
                            this.isLoadingNewMessage = false
                        })

                }
            })
        }
        .title('媒体文件预览')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
    }
}