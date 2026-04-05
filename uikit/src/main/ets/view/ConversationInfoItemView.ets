import Utils from '../common/Utils';
import { timeFormat } from '../util/helper';
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo';
import MessageStatus from '@wfc/client/src/main/ets/wfc/messages/messageStatus';

@Component
@Preview
export default struct ConversationInfoItemView {
    conversationInfo?: ConversationInfo = undefined
    @State conversationItemPortrait: string = ''
    @State conversationItemName: string = ''
    @State unreadJoinGroupRequestCount: number = 0

    /**
     * 仅显示头像和名称
     */
    basicMode: boolean = false

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
                    if (this.basicMode) {
                        Image(this.conversationItemPortrait)
                            .alt($r('app.media.avatar_def'))
                            .draggable(false)
                            .height(48)
                            .width(48)
                            .borderRadius(6)
                    } else if (this.conversationInfo!.isSilent && this.conversationUnreadCount() > 0) {
                        Badge({
                            // count: this.conversationInfo!.unreadCount ? (this.conversationInfo!.unreadCount.unreadMention + this.conversationInfo!.unreadCount.unread + this.conversationInfo!.unreadCount.unreadMentionAll) : 0,
                            // maxCount: 99,
                            value: '',
                            position: BadgePosition.RightTop,
                            style: { badgeSize: 10, badgeColor: $r('app.color.wf_badge_color') }
                        }) {
                            Image(this.conversationItemPortrait)
                                .alt($r('app.media.avatar_def'))
                                .draggable(false)
                                .height(52)
                                .width(52)
                                .padding(2)
                                .borderRadius(6)
                        }
                    } else {
                        Badge({
                            count: this.conversationUnreadCount(),
                            maxCount: 99,
                            position: BadgePosition.RightTop,
                            style: { badgeSize: 16, badgeColor: $r('app.color.wf_badge_color') }
                        }) {
                            Image(this.conversationItemPortrait)
                                .alt($r('app.media.avatar_def'))
                                .draggable(false)
                                .height(52)
                                .width(52)
                                .padding(2)
                                .borderRadius(6)
                        }
                    }
                }
                .width(64)
                .height(64)
                .margin({
                    left: 8,
                    right: 8,
                })
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)

                Column() {
                    Row() {
                        Text(this.conversationItemName)
                            .fontColor($r('app.color.wf_primary_text'))
                            .fontSize(16)
                            .maxLines(1)
                            .layoutWeight(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        if (!this.basicMode) {
                            Text(timeFormat(this.conversationInfo!.timestamp))
                                .fontSize(12)
                                .fontColor($r('app.color.wf_tertiary_text'))
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
                                .fontColor($r('app.color.wf_tertiary_text'))
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
                .color(!this.basicMode && this.conversationInfo!.top ? $r('app.color.wf_divider') : Color.Transparent)
        }
        .width('100%')
        .backgroundColor(!this.basicMode && this.conversationInfo!.top ? $r('app.color.wf_conversation_top_background') : Color.Transparent)
    }
}
