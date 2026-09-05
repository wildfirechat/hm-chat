import Utils from '../common/Utils';
import { timeFormat } from '../util/helper';
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import MessageStatus from '@wfc/client/src/main/ets/wfc/messages/messageStatus';
import { FontSize, Radius, scaledSize, LayoutScale } from '../common/design/Tokens';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent';
import { AgentState, agentConversationKind, agentStateColor, getAgentState } from '../util/agentState';
import UserOnlineState from '@wfc/client/src/main/ets/wfc/model/userOnlineState'
import UserClientState from '@wfc/client/src/main/ets/wfc/model/userClientState'

@Component
@Preview
export default struct ConversationInfoItemView {
    @StorageProp('fontScale') fontScale: number = 1.0;
    conversationInfo?: ConversationInfo = undefined
    @State conversationItemPortrait: string = ''
    @State conversationItemName: string = ''
    @State unreadJoinGroupRequestCount: number = 0
    // Agent 会话状态与类型（'single'/'group'/''，非 Agent 会话不显示圆点/徽标）
    @State agentState: AgentState | null = null
    @State agentConvKind: string = ''
    // AI 群（line 2）群主（AI 机器人）是否在线：不在线时状态圆点/徽标置灰
    @State aiOwnerOnline: boolean = false

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
        if (!this.basicMode) {
            this.refreshAgentState()
            wfc.eventEmitter!.on(EventType.SettingUpdate, this.onAgentRefresh)
            wfc.eventEmitter!.on(EventType.UserInfosUpdate, this.onAgentRefresh)
            wfc.eventEmitter!.on(EventType.GroupInfosUpdate, this.onAgentRefresh)
            wfc.eventEmitter!.on(EventType.UserOnlineEvent, this.onUserOnline)
        }
    }

    aboutToDisappear() {
        if (!this.basicMode) {
            wfc.eventEmitter!.off(EventType.SettingUpdate, this.onAgentRefresh)
            wfc.eventEmitter!.off(EventType.UserInfosUpdate, this.onAgentRefresh)
            wfc.eventEmitter!.off(EventType.GroupInfosUpdate, this.onAgentRefresh)
            wfc.eventEmitter!.off(EventType.UserOnlineEvent, this.onUserOnline)
        }
    }

    // 在线状态变化（服务端广播 / 列表页 watch 回调转发）：按群主匹配刷新在线判定
    onUserOnline = (states?: UserOnlineState[]) => {
        if (this.agentConvKind !== 'group' || !states) {
            this.refreshAgentState()
            return
        }
        let owner = this.aiOwnerOf(this.conversationInfo?.conversation)
        if (!owner) {
            this.refreshAgentState()
            return
        }
        let mine = states.find((s: UserOnlineState) => s.userId === owner)
        if (mine) {
            this.aiOwnerOnline = mine.clientStates !== undefined
                && mine.clientStates.length > 0
                && mine.clientStates.some((s: UserClientState) => s.state === 0)
        }
    }

    // AI 群（line 2）群主 ID；非 AI 群返回空
    aiOwnerOf(conversation: Conversation | undefined): string {
        if (!conversation || agentConversationKind(conversation) !== 'group') {
            return ''
        }
        let groupInfo = wfc.getGroupInfo(conversation.target)
        return groupInfo && groupInfo.owner ? groupInfo.owner : ''
    }

    onAgentRefresh = () => {
        this.refreshAgentState()
    }

    // 用户/群信息未缓存时判为非 Agent，待 UserInfosUpdate/GroupInfosUpdate 后重新判定
    refreshAgentState() {
        let conversation = this.conversationInfo?.conversation
        this.agentConvKind = agentConversationKind(conversation)
        this.agentState = getAgentState(conversation)
        // AI 群群主（AI 机器人）在线判定：clientStates 中存在 state===0；无状态/未取到视为不在线
        let owner = this.aiOwnerOf(conversation)
        if (owner) {
            let uos = wfc.getUserOnlineState(owner)
            this.aiOwnerOnline = uos !== undefined
                && uos.clientStates !== undefined
                && uos.clientStates.length > 0
                && uos.clientStates.some((s: UserClientState) => s.state === 0)
        } else {
            this.aiOwnerOnline = false
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
                        // Agent 会话状态圆点（running=主色/waiting_user=#f59e0b/idle·done=#22c55e/其他=#22c55e）；
                        // AI 不在线时置灰（不显示运行态颜色）
                        if (!this.basicMode && this.agentState) {
                            Row()
                                .width(8)
                                .height(8)
                                .borderRadius(Radius.full)
                                .backgroundColor(this.aiOwnerOnline ? agentStateColor(this.agentState!.state) : $r('app.color.wf_tertiary_text'))
                                .margin({ left: 6 })
                        }
                        // Agent 群标题旁的描边小徽标；AI 不在线时置灰
                        if (!this.basicMode && this.agentConvKind === 'group') {
                            Text('AI')
                                .fontSize(9)
                                .fontColor(this.aiOwnerOnline ? $r('app.color.wf_primary') : $r('app.color.wf_tertiary_text'))
                                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                                .borderRadius(Radius.xs)
                                .border({ width: 1, color: this.aiOwnerOnline ? $r('app.color.wf_primary') : $r('app.color.wf_tertiary_text') })
                                .margin({ left: 6 })
                        }
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
