import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import LinkMessageContent from '@wfc/client/src/main/ets/wfc/messages/linkMessageContent'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import { timeFormat } from '../../util/helper'

@Component
export default struct SearchMessageLinkPage {
    @State conversation: Conversation | undefined = undefined
    @State messages: Message[] = []
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State hasMore: boolean = true
    @State isLoading: boolean = false

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
        if (this.messages.length > 0) {
            timestamp = this.messages[this.messages.length - 1].timestamp
        }

        wfc.getMessagesByTimestampV2(this.conversation!, [MessageContentType.Link], timestamp, true, 20, '', (msgs) => {
            this.isLoading = false
            if (msgs && msgs.length > 0) {
                this.messages = this.messages.concat(msgs)
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

    build() {
        NavDestination() {
            Column() {
                if (this.messages.length === 0 && !this.isLoading) {
                    Column() {
                        Text('暂无链接')
                            .fontSize(14)
                            .fontColor(Color.Gray)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                } else {
                    List() {
                        ForEach(this.messages, (msg: Message) => {
                            ListItem() {
                                this.buildItem(msg)
                            }
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                                    'conversation': this.conversation,
                                    'focusMessageId': msg.messageId
                                } as Record<string, Object>)
                            })
                        })
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .onReachEnd(() => {
                        this.loadMore()
                    })
                }
            }
            .width('100%')
            .height('100%')
            .backgroundColor(Color.White)
        }
        .title('链接')
    }

    @Builder
    buildItem(msg: Message) {
        Row() {
            Column() {
                Text(this.linkMessageContent(msg).title)
                    .fontSize(16)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontColor(Color.Black)

                Row() {
                    Text(wfc.getUserDisplayName(msg.from))
                        .fontSize(12)
                        .fontColor(Color.Gray)
                        .margin({ right: 10 })
                    Text(timeFormat(msg.timestamp))
                        .fontSize(12)
                        .fontColor(Color.Gray)
                }
                .margin({ top: 5 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ right: 10 })

            if (this.linkMessageContent(msg).thumbnail) {
                Image(this.linkMessageContent(msg).thumbnail)
                    .width(60)
                    .height(60)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(4)
            } else {
                // TODO
                Image($r('app.media.ic_file_type_html')) // Assuming this icon exists or similar, or just a default
                    .width(60)
                    .height(60)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(4)
                    .backgroundColor('#F0F0F0')
            }
        }
        .width('100%')
        .padding(10)
        .backgroundColor(Color.White)
    }

    linkMessageContent(message: Message) {
        return message.messageContent as LinkMessageContent
    }
}
