import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent'
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import Config from '@wfc/client/src/main/ets/config'
import { exist } from '../../common/utils/FileUtil'
import MMMessagePreviewDialog from '../mm/MMMessagePreviewDialog'
import { MMMediaEntry } from '../../common/Types'
import { mediaEntry } from '../../helper/messageHelper'

@Component
export default struct SearchMessagePictureVideoPage {
    @State conversation: Conversation | undefined = undefined
    @State groupedMessages: GroupedMessage[] = []
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State hasMore: boolean = true
    @State isLoading: boolean = false
    private allMessages: Message[] = []
    private mmPreviewDialogController?: CustomDialogController

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conversation = params['conversation'] as Conversation
        this.loadMore()
    }

    loadMore() {
        if (this.isLoading || !this.hasMore) {
            return
        }
        this.isLoading = true

        let timestamp = new Date().getTime()
        if (this.allMessages.length > 0) {
            timestamp = this.allMessages[this.allMessages.length - 1].timestamp
        }

        wfc.getMessagesByTimestampV2(this.conversation!, [MessageContentType.Image, MessageContentType.Video], timestamp, true, 20, '', (msgs) => {
            this.isLoading = false
            if (msgs && msgs.length > 0) {
                // If we want newest first, and getMessagesByTimestampV2 returns New->Old (which it typically does for before=true),
                // then we should just append them.
                // If it returns Old->New, we should reverse.
                // Assuming it returns New->Old (Descending timestamp), we just append.
                // If previously we used reverse(), maybe it was because we wanted Old->New?
                // But Grid of photos usually shows newest at top.
                // Let's assume msgs are New->Old.
                this.allMessages = this.allMessages.concat(msgs)
                this.processMessages(msgs)
                if (msgs.length < 20) {
                    this.hasMore = false
                }
            } else {
                this.hasMore = false
            }
        }, (err) => {
            this.isLoading = false
        })
    }

    processMessages(newMessages: Message[]) {
        let tempGroups = this.groupedMessages

        newMessages.forEach(msg => {
            let date = new Date(msg.timestamp)
            let year = date.getFullYear()
            let month = date.getMonth() + 1 // 1-12

            if (tempGroups.length > 0) {
                let lastGroup = tempGroups[tempGroups.length - 1]
                if (lastGroup.year === year && lastGroup.month === month) {
                    lastGroup.messages.push(msg)
                } else {
                    tempGroups.push(new GroupedMessage(year, month, [msg]))
                }
            } else {
                tempGroups.push(new GroupedMessage(year, month, [msg]))
            }
        })
    }

    onMessageClick(msg: Message) {
        let mediaEntries: MMMediaEntry[] = this.allMessages.map(m => mediaEntry(m))
        let index = this.allMessages.findIndex(m => m.messageId === msg.messageId)

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
    }

    build() {
        NavDestination() {
            Column() {
                if (this.allMessages.length === 0 && !this.isLoading) {
                    Column() {
                        Text('暂无图片与视频')
                            .fontSize(14)
                            .fontColor(Color.Gray)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                } else {
                    List() {
                        ForEach(this.groupedMessages, (group: GroupedMessage) => {
                            ListItemGroup({ header: this.groupHeader(group) }) {
                                ListItem() {
                                    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                                        ForEach(group.messages, (msg: Message) => {
                                            Column() {
                                                this.buildItem(msg)
                                            }
                                            .width('33%')
                                            .aspectRatio(1)
                                            .padding(1)
                                            .onClick(() => {
                                                this.onMessageClick(msg)
                                            })
                                        })
                                    }
                                    .width('100%')
                                }
                            }
                        })
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .onReachEnd(() => {
                        this.loadMore()
                    })
                    .sticky(StickyStyle.Header)
                }
            }
            .width('100%')
            .height('100%')
            .backgroundColor(Color.White)
        }
        .title('图片与视频')
    }

    @Builder
    groupHeader(group: GroupedMessage) {
        Column() {
            Text(`${group.year}年${group.month}月`)
                .fontSize(14)
                .fontColor(Color.Black)
                .fontWeight(FontWeight.Bold)
                .padding({ left: 10, top: 10, bottom: 10 })
        }
        .width('100%')
        .backgroundColor(Color.White)
    }

    @Builder
    buildItem(msg: Message) {
        Stack() {
            if (msg.messageContent.type === MessageContentType.Image) {
                Image(this.imageUrl(msg))
                    .alt(this.thumbnail(msg))
                    .objectFit(ImageFit.Cover)
                    .draggable(false)
                    .width('100%')
                    .height('100%')
            } else if (msg.messageContent.type === MessageContentType.Video) {
                Image((msg.messageContent as VideoMessageContent).thumbnail)
                    .objectFit(ImageFit.Cover)
                    .width('100%')
                    .height('100%')
                Image($r('app.media.img_video_play_session'))
                    .width(30)
                    .height(30)
                    .fillColor(Color.White)
            }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F0F0F0')
    }

    imageUrl(message: Message) {
        let content = message.messageContent as ImageMessageContent;
        let localPath = content.localPath;
        if (exist(localPath)) {
            return 'file://' + localPath
        }
        return content.remotePath
    }

    thumbnail(message: Message) {
        let content = message.messageContent as ImageMessageContent;
        if (content.thumbnail) {
            return 'data:image/jpeg;base64,' + (message.messageContent as ImageMessageContent).thumbnail
        }
        return Config.DEFAULT_THUMBNAIL_URL
    }
}

@Observed
class GroupedMessage {
    year: number
    month: number
    messages: Message[]

    constructor(year: number, month: number, messages: Message[]) {
        this.year = year
        this.month = month
        this.messages = messages
    }
}
