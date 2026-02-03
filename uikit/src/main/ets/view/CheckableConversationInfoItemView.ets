import Utils from '../common/Utils';
import { timeFormat } from '../util/helper';
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo';
import MessageStatus from '@wfc/client/src/main/ets/wfc/messages/messageStatus';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';

@Component
@Preview
export default struct CheckableConversationInfoItemView {
    conversationInfo?: ConversationInfo = undefined
    @State conversationItemPortrait: string = ''
    @State conversationItemName: string = ''
    @State unreadJoinGroupRequestCount: number = 0
    @State _checked: boolean = false
    @Link checkedConversationInfos: ConversationInfo[]

    /**
     * 仅显示头像和名称
     */
    basicMode: boolean = false
    enableCheck: boolean = false

    aboutToAppear() {
        if (this.conversationInfo!.conversation) {
            Utils.computeConversationItemPortraitNameAndUnReadJoinGroupRequestCount(this.conversationInfo!.conversation, !this.basicMode)
                .then(value => {
                    this.conversationItemPortrait = value.portrait
                    this.conversationItemName = value.name
                    this.unreadJoinGroupRequestCount = value.unreadJoinGroupRequestCount ?? 0
                })
        }
    }

    isChecked() {
        return this.checkedConversationInfos.findIndex(info => Conversation.equal(info.conversation, this.conversationInfo!.conversation)) >= 0
    }

    conversationUnreadCount() {
        return this.conversationInfo!.unreadCount ? (this.conversationInfo!.unreadCount.unreadMention + this.conversationInfo!.unreadCount.unread + this.conversationInfo!.unreadCount.unreadMentionAll) : 0
    }

    conversationInfoSpanText(): string {
        let spanText = ''
        if (this.unreadJoinGroupRequestCount > 0) {
            spanText = `[${this.unreadJoinGroupRequestCount}条加群申请]`
        }
        let unreadCount = this.conversationInfo?.unreadCount
        if (unreadCount) {
            if (unreadCount.unreadMention + unreadCount.unreadMentionAll > 0) {
                spanText = '[有人@我] '
            }
        }
        if (this.conversationInfo?.draft) {
            spanText += '[草稿] '
        }
        if (this.conversationInfo?.lastMessage && this.conversationInfo.lastMessage.status === MessageStatus.Sending) {
            spanText = '[发送中]'
        }
        return spanText;
    }

    build() {
        Column() {
            Row() {
                Row() {
                    if (this.enableCheck) {
                        Checkbox()
                            .select(this.isChecked())
                            .enabled(true)
                            .hitTestBehavior(HitTestMode.None)
                            .margin({right: 8})
                    }
                    if (this.basicMode) {
                        Image(this.conversationItemPortrait)
                            .alt($r('app.media.avatar_def'))
                            .draggable(false)
                            .height(44)
                            .width(44)
                            .padding(2)
                            .borderRadius(4)
                    } else if (this.conversationInfo!.isSilent && this.conversationUnreadCount() > 0) {
                        Badge({
                            // count: this.conversationInfo!.unreadCount ? (this.conversationInfo!.unreadCount.unreadMention + this.conversationInfo!.unreadCount.unread + this.conversationInfo!.unreadCount.unreadMentionAll) : 0,
                            // maxCount: 99,
                            value: '',
                            position: BadgePosition.RightTop,
                            style: { badgeSize: 8, badgeColor: '#FA2A2D' }
                        }) {
                            Image(this.conversationItemPortrait)
                                .alt($r('app.media.avatar_def'))
                                .draggable(false)
                                .height(44)
                                .width(44)
                                .padding(2)
                                .borderRadius(4)
                        }
                    } else {
                        Badge({
                            count: this.conversationUnreadCount(),
                            maxCount: 99,
                            position: BadgePosition.RightTop,
                            style: { badgeSize: 14, badgeColor: '#FA2A2D' }
                        }) {
                            Image(this.conversationItemPortrait)
                                .alt($r('app.media.avatar_def'))
                                .draggable(false)
                                .height(44)
                                .width(44)
                                .padding(2)
                                .borderRadius(4)
                        }
                    }
                }
                .height(64)
                .padding({left: 10, right: 10})
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)

                Column() {
                    Row() {
                        Text(this.conversationItemName)
                            .fontColor('#1d1d1d')
                            .fontSize(16)
                            .maxLines(1)
                            .layoutWeight(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        if (!this.basicMode) {
                            Text(timeFormat(this.conversationInfo!.timestamp))
                                .fontSize(12)
                                .fontColor('#b3b3b3')
                        }
                    }

                    if (!this.basicMode) {
                        Row() {
                            if (this.conversationInfoSpanText()) {
                                Text() {
                                    Span(this.conversationInfoSpanText()).fontSize(13).fontColor(Color.Red)
                                }
                            }

                            Text(`${this.conversationInfo!.draft ? this.conversationInfo!.draft : this.conversationInfo!.lastMessage ? (this.conversationInfo!.lastMessage.messageContent!.digest(this.conversationInfo!.lastMessage)) : ''}`)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .wordBreak(WordBreak.BREAK_ALL)
                                .fontSize(13)
                                .fontColor('#b3b3b3')
                                .margin({ right: 10 })
                                .maxLines(1)
                                .layoutWeight(1)
                            if (this.conversationInfo!.isSilent) {
                                Image($r('app.media.block_notification'))
                                    .draggable(false)
                                    .width(14)
                                    .height(14)
                                    .alt('')
                            }
                        }
                        .width('100%')
                    }
                }
                .height('100%')
                .layoutWeight(1)
                .padding({ right: 10, top: 7, bottom: 7 })
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.SpaceAround)
            }
            .height(72)
            .width('100%')
            .padding({ top: 7, bottom: 7 })

            Divider()
                .margin({ left: 60 })
                .color(!this.basicMode && this.conversationInfo!.top ? '#E5E5E5' : '#F7F7F7')
        }
        .width('100%')
        .backgroundColor(!this.basicMode && this.conversationInfo!.top ? '#EEEEEE' : '')
    }
}
