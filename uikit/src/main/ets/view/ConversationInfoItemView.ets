import Utils from '../common/Utils';
import { timeFormat } from '../util/helper';
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo';
import MessageStatus from '@wfc/client/src/main/ets/wfc/messages/messageStatus';
import { FontSize, Radius, scaledSize, LayoutScale } from '../common/design/Tokens';

@Component
@Preview
export default struct ConversationInfoItemView {
    @StorageProp('fontScale') fontScale: number = 1.0;
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
                            .height(scaledSize(48, this.fontScale))
                            .width(scaledSize(48, this.fontScale))
                            .borderRadius(Radius.md)
                    } else if (this.conversationInfo!.isSilent && this.conversationUnreadCount() > 0) {
                        Badge({
                            // count: this.conversationInfo!.unreadCount ? (this.conversationInfo!.unreadCount.unreadMention + this.conversationInfo!.unreadCount.unread + this.conversationInfo!.unreadCount.unreadMentionAll) : 0,
                            // maxCount: 99,
                            value: '',
                            position: BadgePosition.RightTop,
                            style: { badgeSize: scaledSize(10, this.fontScale), badgeColor: $r('app.color.wf_badge_color') }
                        }) {
                            Image(this.conversationItemPortrait)
                                .alt($r('app.media.avatar_def'))
                                .draggable(false)
                                .height(scaledSize(52, this.fontScale))
                                .width(scaledSize(52, this.fontScale))
                                .padding(2)
                                .borderRadius(Radius.md)
                        }
                    } else {
                        Badge({
                            count: this.conversationUnreadCount(),
                            maxCount: 99,
                            position: BadgePosition.RightTop,
                            style: { badgeSize: scaledSize(16, this.fontScale), badgeColor: $r('app.color.wf_badge_color') }
                        }) {
                            Image(this.conversationItemPortrait)
                                .alt($r('app.media.avatar_def'))
                                .draggable(false)
                                .height(scaledSize(52, this.fontScale))
                                .width(scaledSize(52, this.fontScale))
                                .padding(2)
                                .borderRadius(Radius.md)
                        }
                    }
                }
                .width(scaledSize(64, this.fontScale))
                .height(scaledSize(64, this.fontScale))
                .margin({ left: 8,
                    right: 8, })
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)

                Column() {
                    Row() {
                        Text(this.conversationItemName)
                            .fontColor($r('app.color.wf_primary_text'))
                            .fontSize(FontSize.md)
                            .maxLines(1)
                            .layoutWeight(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        if (!this.basicMode) {
                            Text(timeFormat(this.conversationInfo!.timestamp))
                                .fontSize(FontSize.xs)
                                .fontColor($r('app.color.wf_tertiary_text'))
                        }
                    }

                    if (!this.basicMode) {
                        Row() {
                            if (this.conversationInfoSpanText()) {
                                Text() {
                                    Span(this.conversationInfoSpanText()).fontSize(FontSize.sm).fontColor($r('app.color.wf_danger'))
                                }
                            }

                            Text(`${this.conversationInfo!.draft ? this.conversationInfo!.draft : this.conversationInfo!.lastMessage ? (this.conversationInfo!.lastMessage.messageContent!.digest(this.conversationInfo!.lastMessage)) : ''}`)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .wordBreak(WordBreak.BREAK_ALL)
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_tertiary_text'))
                                .margin({ right: 12 })
                                .maxLines(1)
                                .layoutWeight(1)
                            if (this.conversationInfo!.isSilent) {
                                Image($r('app.media.block_notification'))
                                    .draggable(false)
                                    .width(12)
                                    .height(12)
                                    .alt('')
                            }
                        }
                        .width('100%')
                        .padding({ top: 8 })
                    }
                }
                .layoutWeight(1)
                .padding({ right: 12, top: 8, bottom: 8 })
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center)
            }
            // 用 minHeight 而非固定高度，放大字体时随内容撑高
            .constraintSize({ minHeight: scaledSize(72, this.fontScale, this.basicMode ? LayoutScale.cap : LayoutScale.row) })
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ top: 4, bottom: 4 })

            Divider()
                .margin({ left: 60 })
                .color(!this.basicMode && this.conversationInfo!.top ? $r('app.color.wf_divider') : Color.Transparent)
        }
        .width('100%')
    }
}
