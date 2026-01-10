import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import FileRecord from '@wfc/client/src/main/ets/wfc/model/fileRecord'
import Long from '@wfc/client/src/main/ets/wfc/util/long'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import { getFiletypeIcon, humanSize, timeFormat } from '../../util/helper'

@Component
export default struct SearchMessageFilePage {
    @State conversation: Conversation | undefined = undefined
    @State fileRecords: FileRecord[] = []
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

        let beforeUid = Long.ZERO
        if (this.fileRecords.length > 0) {
            beforeUid = this.fileRecords[this.fileRecords.length - 1].messageUid
        }

        wfc.getConversationFileRecords(this.conversation, '', beforeUid, 0, 20, (records) => {
            this.isLoading = false
            if (records && records.length > 0) {
                this.fileRecords = this.fileRecords.concat(records)
                if (records.length < 20) {
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
                if (this.fileRecords.length === 0 && !this.isLoading) {
                    Column() {
                        Text('暂无文件')
                            .fontSize(14)
                            .fontColor(Color.Gray)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                } else {
                    List() {
                        ForEach(this.fileRecords, (record: FileRecord) => {
                            ListItem() {
                                Row() {
                                    Image(getFiletypeIcon(record.name))
                                        .width(40)
                                        .height(40)
                                        .margin({ right: 10 })

                                    Column() {
                                        Text(record.name)
                                            .fontSize(16)
                                            .maxLines(1)
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                        Row() {
                                            Text(humanSize(record.size))
                                                .fontSize(12)
                                                .fontColor(Color.Gray)
                                                .margin({ right: 10 })
                                            Text(wfc.getUserDisplayName(record.userId))
                                                .fontSize(12)
                                                .fontColor(Color.Gray)
                                                .margin({ right: 10 })
                                            Text(timeFormat(record.timestamp))
                                                .fontSize(12)
                                                .fontColor(Color.Gray)
                                        }
                                        .margin({ top: 5 })
                                    }
                                    .layoutWeight(1)
                                    .alignItems(HorizontalAlign.Start)
                                }
                                .width('100%')
                                .padding(10)
                                .backgroundColor(Color.White)
                                .onClick(() => {
                                    // Jump to message
                                    // But FileRecord only has messageUid.
                                    // ConversationPage needs focusMessageId (number).
                                    // We need to fetch the message by Uid to get ID.
                                    wfc.loadRemoteMessage(record.messageUid, (msg) => {
                                        if (msg) {
                                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                                                'conversation': this.conversation,
                                                'focusMessageId': msg.messageId
                                            } as Record<string, Object>)
                                        }
                                    }, (err) => {
                                        // try local
                                        let msg = wfc.getMessageByUid(record.messageUid)
                                        if (msg) {
                                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                                                'conversation': this.conversation,
                                                'focusMessageId': msg.messageId
                                            } as Record<string, Object>)
                                        }
                                    })
                                })
                            }
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
        .title('文件')
    }
}
