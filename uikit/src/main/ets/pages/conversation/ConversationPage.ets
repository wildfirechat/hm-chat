import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'

import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import { eq } from '@wfc/client/src/main/ets/wfc/util/longUtil'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import {
    AgentMetrics,
    AgentState,
    agentConversationKind,
    agentMetricsText,
    agentRobotName,
    agentRobotStatusText,
    agentStateColor,
    agentStateText,
    agentStatusHint,
    getAgentMetrics,
    getAgentRobotStates,
    getAgentState,
    listAgentRobotUids
} from '../../util/agentState'
import NormalMessageContentView from './message/NormalMessageContentView'
import ConversationInputPanelView from './ConversationInputPanelView'
import AgentPanelView from './AgentPanelView'
import AudioPlayManager from './audio/AudioPlayManager'
import { playRawSound } from '../../helper/soundEffectHelper'
import NotificationMessageContent from '@wfc/client/src/main/ets/wfc/messages/notification/notificationMessageContent'
import SimpleNotificationMessageContentView from './message/SimpleNotificationMessageContentView'
import { timeFormat } from '../../util/helper'
import Long from '@wfc/client/src/main/ets/wfc/util/long'
import ReadEntry from '@wfc/client/src/main/ets/wfc/model/readEntry'
import GroupMember from '@wfc/client/src/main/ets/wfc/model/groupMember'
import { showToast } from '../../common/utils/Toast'
import Utils from '../../common/Utils'
import BasicDataSource from '../../common/BasicDataSource'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import ChannelInfo from '@wfc/client/src/main/ets/wfc/model/channelInfo'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import TestCustomNotificationMessageContent from '@wfc/client/src/main/ets/wfc_custom_message/testCustomNotificationMessageContent'
import TestCustomNotificationMessageContentView from './custom_message/TestCustomNotificationMessageContentView'
import UserOnlineState from '@wfc/client/src/main/ets/wfc/model/userOnlineState'
import UserClientState from '@wfc/client/src/main/ets/wfc/model/userClientState'
import RecallNotificationMessageContentView from './message/RecallNotificationMessageContentView'
import RecallMessageNotification from '@wfc/client/src/main/ets/wfc/messages/notification/recallMessageNotification'
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType'
import MessageStatus from '@wfc/client/src/main/ets/wfc/messages/messageStatus'
import RichNotificationMessageContent from '@wfc/client/src/main/ets/wfc/messages/notification/richNotificationMessageContent'
import RichNotificationMessageContentView from './message/RichNotificationMessageContentView'
import { window, KeyboardAvoidMode } from '@kit.ArkUI'
import ArticlesMessageContent from '@wfc/client/src/main/ets/wfc/messages/articlesMessageContent'
import ContextableNotificationMessageContentView from './message/ContextableNotificationMessageContentView'
import StreamingTextGeneratingMessageContent from '@wfc/client/src/main/ets/wfc/messages/streamingTextGeneratingMessageContent'
import StreamingTextGeneratedMessageContent from '@wfc/client/src/main/ets/wfc/messages/streamingTextGeneratedMessageContent'
import StreamingTextCancelledMessageContent from '@wfc/client/src/main/ets/wfc/messages/streamingTextCancelledMessageContent'
import CustomMessageContentType from '@wfc/client/src/main/ets/wfc_custom_message/customMessageContentType'
import AgentQuestionMessageContent from '@wfc/client/src/main/ets/wfc_custom_message/agentQuestionMessageContent'
import AgentApprovalMessageContent from '@wfc/client/src/main/ets/wfc_custom_message/agentApprovalMessageContent'
import AgentGoalMessageContent from '@wfc/client/src/main/ets/wfc_custom_message/agentGoalMessageContent'
import AgentTaskProgressMessageContent from '@wfc/client/src/main/ets/wfc_custom_message/agentTaskProgressMessageContent'
import GroupType from '@wfc/client/src/main/ets/wfc/model/groupType'
import archiveServer from '../../api/archiveServer'
import ArchiveMessageResult from '../../api/model/archiveMessageResult'
import { Emoji } from './emoji/emojis'
import StickerMessageContent from '@wfc/client/src/main/ets/wfc/messages/stickerMessageContent'
import { sendMediaResult, uri2MediaResult } from '../../helper/mediaHelper'
import { RecentPhotoComponent, RecentPhotoOptions, PhotoSource, RecentPhotoCheckResultCallback, RecentPhotoClickCallback } from '@ohos.file.RecentPhotoComponent'
import { BaseItemInfo } from '@ohos.file.PhotoPickerComponent'
import { FontSize, Radius, scaledSize } from '../../common/design/Tokens'
import { STORAGE_KEY_VOICE_EARPIECE } from './audio/VoicePlayModeManager'
import { PttMessageContentType } from '@wfc/ptt'
import { conversationIdentity, STORAGE_KEY_ACTIVE_CONVERSATION } from '../../util/navUtil'

// 「猜你想发送」：上次消失（发送/取消/其他操作）的时间。
// API 12 的最近图片控件回调拿不到图片标识，故用「动态时间窗口」实现“同一张只提示一次”：
// 每次只查询「上次消失之后、且 5 分钟内」拍摄/截图的图片——老图必然落在窗口外，只有更新的截图才会再次出现。
let lastRecentPhotoDismissMillis = 0

// 取流式消息（14 生成中 / 15 已生成）的 streamId；非流式消息返回空串。
// 多 agent（多机器人）并发时同一会话同时存在多条不同 streamId 的 14，所有按流聚合/去重/
// 渲染 key 逻辑都以 streamId 为分组依据，绝不按「会话唯一一条在生成」处理。
function streamingStreamIdOf(message: Message | undefined | null): string {
    if (!message || !message.messageContent) {
        return ''
    }
    let type = message.messageContent.type
    if (type === MessageContentType.Streaming_Text_Generating) {
        return (message.messageContent as StreamingTextGeneratingMessageContent).streamId
    }
    if (type === MessageContentType.Streaming_Text_Generated) {
        return (message.messageContent as StreamingTextGeneratedMessageContent).streamId
    }
    return ''
}

// 多机器人（多 agent）标题栏逐列状态项：机器人显示名 + 状态文案 + 状态颜色
interface AgentRobotStatusRow {
    // 机器人完整 uid（robot_xxx_yyy，不截断；作列表 key 与悬浮提示）
    uid: string
    // 机器人显示名（用户信息接口/缓存；缺失回退完整 uid）
    name: string
    // 状态文案（运行中/等待确认/空闲…）
    text: string
    // 状态颜色
    color: ResourceColor
}

@Component
export default struct ConversationPage {
    @StorageProp('fontScale') fontScale: number = 1.0;
    // 语音「听筒播放」全局开关：开启时标题栏显示「耳朵」图标。
    @StorageProp(STORAGE_KEY_VOICE_EARPIECE) voiceEarpieceMode: boolean = false
    @State toReeditText: string = ''
    @State title: string = ''
    @State conversation?: Conversation = undefined
    @State conversationInfo?: ConversationInfo = undefined
    @State refreshStatus: boolean = false;
    @State hasNoMoreHistoryMessage: boolean = false
    @State readEntries: Map<string, number> = new Map();
    @State collapseConversationInputPanelViewTimestamp: number = 0
    @State enableMultiCheck: boolean = false
    @State checkedMessages: Message[] = []
    // AI 会话设置面板是否打开（由输入面板 AI 按钮经 @Link 置位，本页根 Stack 悬浮呈现）
    @State showAgentPanel: boolean = false
    // 多机器人（多 agent）会话：当前「AI 会话设置」面板的目标机器人 uid（空 = 会话默认机器人）
    @State activeAgentRobotUid: string = ''
    // 多机器人选择弹层：机器人列表（完整 uid）与是否打开；>1 个机器人时先选择目标机器人再打开面板
    @State agentChooserOpen: boolean = false
    @State agentChooserRobots: string[] = []
    // 标题栏多 agent 状态列（机器人名:状态，按机器人分组读取 type=1/type=2）；仅 >1 个有状态机器人的群 AI 会话展示
    @State agentRobotRows: AgentRobotStatusRow[] = []
    // 机器人显示名缺失时后台拉取用户信息（5s 限频，防止状态频繁推送时重复请求）
    private lastRobotNameWarmMillis: number = 0
    @State @Watch('onQuoteMessage') quotedMessage: Message | null = null
    private focusMessageId: number = 0
    private checkValueChangeTriggerByClick = false
    private scroller: Scroller = new Scroller()
    // 首次进入会话时，LazyForEach 布局与消息图片为异步完成，记录上次贴底偏移用于判断内容是否已稳定
    private lastInitialScrollOffset: number = -1
    private touchDownOffsetY: number = 0
    private currentMessageIndex: number = 0
    private unreadStatusCleared: boolean = false
    private timer: number = 0
    private audioPlayerManager: AudioPlayManager = new AudioPlayManager()
    @State autoPlayMessageId: number = 0
    private enableReceipt: boolean = false
    private enableGroupReceipt: boolean = false
    @State groupMembers: GroupMember[] = []
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private conversationMessageDataSource: ConversationMessageDataSource = new ConversationMessageDataSource()
    @State focusMessageBackgroundColor: Color = Color.Green
    @State showGroupMemberNickName: boolean = false
    @State longPressToMentionUser: string = ''
    @State unreadJoinGroupRequestCount: number = 0
    @State private archiveNextStartMid: number = 0 // 归档消息分页起始ID
    @State private previewEmoji: Emoji | null = null
    @State private previewCol: number = 0
    @State private previewColW: number = 0
    @State private previewRowY: number = 0
    @State private suggestedStickers: Emoji[] = []
    @State private panelHeight: number = 320
    @State private pageWidth: number = 0
    @State private pageHeight: number = 0
    // Agent 会话状态（scope=31 type=1 用户设置，键 ..._1）：标题栏副标题/停止按钮/输入框占位/斜杠命令浮层共用；非 Agent 会话为 null
    @State agentState: AgentState | null = null
    // Agent Token 统计（scope=31 type=2 用户设置，键 ..._2）：标题栏合并行展示；回合结束必推，独立于状态；非 Agent 会话为 null
    @State agentMetrics: AgentMetrics | null = null
    // 'single'（单聊机器人）/ 'group'（Agent 群）/ ''（非 Agent 会话），命令集随其变化
    @State agentConvKind: string = ''
    // AI 群（line 2）群主（AI 机器人）的在线状态描述（如 "Web 在线"/"忙碌"），标题栏 "AI <描述>" 副标题；非 AI 群为空
    @State aiOwnerOnlineStateDesc: string = ''
    // AI 群（line 2）群主（AI 机器人）是否在线：不在线时去掉所有 AI 状态段，只显示 "AI 不在线"
    @State aiOwnerOnline: boolean = false
    // 已订阅在线状态的群主 ID（用于去重；进入 AI 群时群信息可能未就绪，待 GroupInfosUpdate 后补订）
    private aiOwnerWatchedId: string = ''
    // 标题栏「停止」按钮 1.5s 防重复点击
    @State agentStopSending: boolean = false
    // 输入面板（含展开的加号/表情面板）的实际高度，用于把悬浮建议层定位到输入栏正上方
    @State private inputPanelHeight: number = 56
    // 「猜你想发送」：点加号时由输入面板置位；浮于输入栏上方（与表情建议同位置）。免权限的系统最近图片控件。
    @State @Watch('onRecentPhotoRequestedChange') private recentPhotoRequested: boolean = false
    @State private recentPhotoExists: boolean = false
    private recentPhotoOptions: RecentPhotoOptions = new RecentPhotoOptions()
    private recentPhotoCheckResultCallback: RecentPhotoCheckResultCallback = (exists: boolean) => {
        if (exists) {
            this.recentPhotoExists = true
        } else {
            // 时间窗口内无符合条件的图片（含已提示过的老图）→ 收起整块
            this.recentPhotoExists = false
            this.recentPhotoRequested = false
        }
    }
    private recentPhotoClickCallback: RecentPhotoClickCallback = (info: BaseItemInfo): boolean => {
        this.onRecentPhotoClick(info)
        return true
    }

    private onRecentPhotoRequestedChange() {
        if (this.recentPhotoRequested) {
            // 仅查询「上次消失之后、且 5 分钟内」的图片，实现“同一张只提示一次、直到有更新截图”
            let sinceDismiss = Math.floor((Date.now() - lastRecentPhotoDismissMillis) / 1000)
            let period = Math.min(5 * 60, sinceDismiss)
            this.recentPhotoOptions.period = period > 0 ? period : 1
            this.recentPhotoExists = false
        } else {
            // 任意消失都记录时间点，使更早的图片落在下次查询窗口之外
            lastRecentPhotoDismissMillis = Date.now()
            this.recentPhotoExists = false
        }
    }

    private async onRecentPhotoClick(info: BaseItemInfo) {
        if (!info || !info.uri || !this.conversation) {
            this.recentPhotoRequested = false
            return
        }
        try {
            // 必须在组件卸载前消费 uri：点击只授予该 uri 临时只读权限，提前卸载会回收权限导致读取失败
            let results = await uri2MediaResult(getContext(this), [info.uri])
            if (results.length > 0) {
                sendMediaResult(getContext(this), this.conversation, results[0])
            }
        } catch (reason) {
            showToast('发送失败: ' + reason)
        }
        this.recentPhotoRequested = false
    }

    aboutToAppear() {
        this.audioPlayerManager.init(getContext(this))

        // 「猜你想发送」：展示拍摄或截图的图片/视频（period 在每次点加号时按动态窗口设置）
        this.recentPhotoOptions.photoSource = PhotoSource.ALL

        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let conversation = params['conversation'] as Conversation;
        let title = params['title'] as string;
        this.focusMessageId = params['focusMessageId'] as number
        this.setupConversation(conversation, title);

        wfc.eventEmitter!.on(EventType.SendMessage, this.onSendMessage)
        wfc.eventEmitter!.on(EventType.MessageStatusUpdate, this.onMessageStatusUpdate)
        wfc.eventEmitter!.on(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter!.on(EventType.DeleteMessage, this.onDeleteMessage)
        wfc.eventEmitter!.on(EventType.MessageDeleted, this.onRemoteDeleteMessage)
        wfc.eventEmitter!.on(EventType.RecallMessage, this.onRecallMessage)
        wfc.eventEmitter!.on(EventType.MessageRead, this.onReadMessage)
        wfc.eventEmitter!.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        wfc.eventEmitter!.on(EventType.FriendListUpdate, this.onFriendListUpdate)
        wfc.eventEmitter!.on(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter!.on(EventType.ChannelInfosUpdate, this.onChannelInfosUpdate)
        wfc.eventEmitter!.on(EventType.ConversationInfoUpdate, this.onConversationInfoUpdate)
        wfc.eventEmitter!.on(EventType.GroupJoinRequestUpdate, this.onGroupJoinRequestUpdate)
        wfc.eventEmitter!.on(EventType.SettingUpdate, this.onSettingUpdate)
        // 在线状态变化（含订阅推送）：刷新 AI 群群主在线状态标题
        wfc.eventEmitter!.on(EventType.UserOnlineEvent, this.onUserOnlineEvent)

        // 监听 observer.on('navDestinationUpdate')，处理重入问题
    }

    // navigation 导航时，生命周期回调并不会回调次方法
    // 可通过 NavDestination.onShow 触发
    onPageShow(): void {
        let params = (this.mainNavPathStack.getParamByName('conversation') as Record<string, Object>[])[0]
        // let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (!params) {
            if (this.conversation?.type === ConversationType.Group) {
                this.showGroupMemberNickName = !wfc.isHiddenGroupMemberName(this.conversation.target)
            }
            return
        }
        let title = params['title'] as string;
        let conversation = params['conversation'] as Conversation;

        if (!Conversation.equal(this.conversation!, conversation)) {
            if (this.conversation!.type === ConversationType.Group && conversation.type !== ConversationType.Group) {
                wfc.eventEmitter!.off(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
            }
            this.setupConversation(conversation, title);
        }
    }

    aboutToDisappear() {
        clearTimeout(this.timer);
        // 会话页销毁时清除高亮标识；仅当仍指向本会话才清（replace 到别的会话时，
        // 新页已写入新标识，这里的判等避免把新标识误清掉，规避销毁/创建的时序竞态）。
        if (this.conversation && AppStorage.get<string>(STORAGE_KEY_ACTIVE_CONVERSATION) === conversationIdentity(this.conversation)) {
            AppStorage.setOrCreate(STORAGE_KEY_ACTIVE_CONVERSATION, '')
        }
        this.audioPlayerManager.release()

        wfc.eventEmitter!.off(EventType.SendMessage, this.onSendMessage)
        wfc.eventEmitter!.off(EventType.MessageStatusUpdate, this.onMessageStatusUpdate)
        wfc.eventEmitter!.off(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter!.off(EventType.DeleteMessage, this.onDeleteMessage)
        wfc.eventEmitter!.off(EventType.MessageDeleted, this.onRemoteDeleteMessage)
        wfc.eventEmitter!.off(EventType.RecallMessage, this.onRecallMessage)
        wfc.eventEmitter!.off(EventType.MessageRead, this.onReadMessage)
        if (this.conversation!.type === ConversationType.Group) {
            wfc.eventEmitter!.off(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
        } else if (this.conversation!.type === ConversationType.ChatRoom) {
            wfc.quitChatroom(this.conversation!.target, null, null)
        }
        wfc.eventEmitter!.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        wfc.eventEmitter!.off(EventType.FriendListUpdate, this.onFriendListUpdate)
        wfc.eventEmitter!.off(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter!.off(EventType.ChannelInfosUpdate, this.onChannelInfosUpdate)
        wfc.eventEmitter!.off(EventType.ConversationInfoUpdate, this.onConversationInfoUpdate)
        wfc.eventEmitter!.off(EventType.GroupJoinRequestUpdate, this.onGroupJoinRequestUpdate)
        wfc.eventEmitter!.off(EventType.SettingUpdate, this.onSettingUpdate)
        wfc.eventEmitter!.off(EventType.UserOnlineEvent, this.onUserOnlineEvent)

        this.unwatchOnlineState(this.conversation!)
    }

    // Called when a voice message starts playing. Updates the source-of-truth status (dataSource +
    // persistence) by stable messageId, so the unplayed red dot clears reliably even across the
    // LazyForEach rebuilds that happen during continuous playback.
    onVoicePlayStart = (messageId: number) => {
        this.conversationMessageDataSource.markMessagePlayed(messageId)
        wfc.updateMessageStatus(messageId, MessageStatus.Played)
    }
    // Called when a voice message finishes playing. Auto-plays the next unplayed received voice
    // message if any. Proximity sensing / the screen lock is kept held across consecutive messages
    // and only released when the chain ends, so the screen doesn't flicker on between messages.
    onVoicePlayComplete = (messageId: number, err?: Error) => {
        if (!err) {
            let messages = this.conversationMessageDataSource.getMessages()
            let foundCurrent = false
            for (let msg of messages) {
                if (foundCurrent) {
                    // 对讲留底语音消息也参与连续播放，和普通语音消息一样
                    let type = msg.messageContent.type
                    if (msg.direction === 1
                        && (type === MessageContentType.Voice || type === PttMessageContentType.Ptt_Sound)
                        && msg.status !== MessageStatus.Played) {
                        // Continue the chain; keep proximity sensing active (no flicker).
                        this.autoPlayMessageId = msg.messageId
                        return
                    }
                } else if (msg.messageId === messageId) {
                    foundCurrent = true
                }
            }
        }
        // Chain ended (or errored): release proximity sensing + screen lock, play completion sound.
        this.autoPlayMessageId = 0
        this.audioPlayerManager.stopProximitySensing()
        if (!err) {
            playRawSound(getContext(this), 'audio_msg_play_completion.mp3')
        }
    }

    unwatchOnlineState(conversation: Conversation) {
        if (
            wfc.isUserOnlineStateEnabled()
                && (conversation.type === ConversationType.Single && !wfc.isMyFriend(conversation.target))
                && (conversation.type === ConversationType.Group)
        ) {
            wfc.unwatchOnlineState(conversation.type, [conversation.target], () => {

            }, err => {

            })
        }
        // AI 群（line 2，群主=AI 机器人）：离开时取消订阅群主在线状态，并清空标题显示
        if (conversation.type === ConversationType.Group && conversation.line === 2) {
            let owner = this.aiOwnerWatchedId || this.agentGroupOwnerOf(conversation)
            if (owner && wfc.isUserOnlineStateEnabled()) {
                wfc.unwatchOnlineState(ConversationType.Single, [owner], () => {

                }, err => {

                })
            }
            this.aiOwnerWatchedId = ''
            this.aiOwnerOnlineStateDesc = ''
        }
    }

    // AI 群（line 2）的群主 ID（=AI 机器人）；非 AI 群/群信息未就绪返回空
    agentGroupOwnerOf(conversation: Conversation): string {
        if (conversation.type !== ConversationType.Group || conversation.line !== 2) {
            return ''
        }
        let groupInfo = wfc.getGroupInfo(conversation.target, false)
        return groupInfo.owner ? groupInfo.owner : ''
    }

    // AI 群（line 2）：进入时订阅群主（AI 机器人）在线状态，状态变化刷新标题。
    // 群信息未就绪（owner 为空）时暂不订阅，待 GroupInfosUpdate 后由 ensureAiOwnerOnlineStateWatched 补订。
    ensureAiOwnerOnlineStateWatched() {
        if (!this.conversation || !wfc.isUserOnlineStateEnabled()) {
            return
        }
        let owner = this.agentGroupOwnerOf(this.conversation)
        if (!owner) {
            this.aiOwnerOnlineStateDesc = ''
            return
        }
        if (this.aiOwnerWatchedId !== owner) {
            // 防止换会话后重复订阅旧群主
            if (this.aiOwnerWatchedId) {
                wfc.unwatchOnlineState(ConversationType.Single, [this.aiOwnerWatchedId], () => {

                }, err => {

                })
            }
            this.aiOwnerWatchedId = owner
            wfc.watchOnlineState(ConversationType.Single, [owner], 1000, (states: UserOnlineState[]) => {
                this.refreshAiOwnerOnlineState()
            }, err => {
            })
        }
        this.refreshAiOwnerOnlineState()
    }

    // 读取群主（AI 机器人）在线状态描述并刷新标题；非 AI 群/无群主时清空
    refreshAiOwnerOnlineState() {
        if (!this.conversation
            || this.conversation.type !== ConversationType.Group
            || this.conversation.line !== 2) {
            this.aiOwnerOnlineStateDesc = ''
            this.aiOwnerOnline = false
            return
        }
        let owner = this.agentGroupOwnerOf(this.conversation)
        if (!owner) {
            this.aiOwnerOnlineStateDesc = ''
            this.aiOwnerOnline = false
            return
        }
        let userOnlineState = wfc.getUserOnlineState(owner)
        this.aiOwnerOnlineStateDesc = userOnlineState ? userOnlineState.desc() : ''
        // 在线判定：clientStates 中存在 state===0（在线）；无状态/未取到视为不在线
        this.aiOwnerOnline = userOnlineState !== undefined
            && userOnlineState.clientStates !== undefined
            && userOnlineState.clientStates.length > 0
            && userOnlineState.clientStates.some((s: UserClientState) => s.state === 0)
    }

    // 在线状态变化（订阅推送/服务端广播）：刷新 AI 群群主在线状态标题（非 AI 群时为无害空操作）
    onUserOnlineEvent = (states: UserOnlineState[]) => {
        this.refreshAiOwnerOnlineState()
    }

    setupConversation(conversation: Conversation, title: string) {
        if (this.conversation) {
            this.unwatchOnlineState(this.conversation!)
        }

        this.conversation = conversation;

        // 记录当前展示的会话，供分栏下会话列表高亮当前项
        AppStorage.setOrCreate(STORAGE_KEY_ACTIVE_CONVERSATION, conversationIdentity(conversation))

        // 重置归档消息分页状态
        this.archiveNextStartMid = 0;
        this.hasNoMoreHistoryMessage = false;

        this.conversationInfo = wfc.getConversationInfo(this.conversation)
        this.readEntries = wfc.getConversationRead(this.conversation)
        this.enableReceipt = wfc.isReceiptEnabled() && wfc.isUserReceiptEnabled()
        if(conversation.type === ConversationType.Single){
            let targetUserInfo = wfc.getUserInfo(conversation.target, false, '')
            // bot
            if(targetUserInfo.type === 1){
                this.enableReceipt = false;
            }
        }
        this.enableGroupReceipt = wfc.isGroupReceiptEnabled()

        if (this.conversation.type === ConversationType.Group) {
            this.groupMembers = wfc.getGroupMembers(this.conversation.target, false);
        } else if (this.conversation.type === ConversationType.ChatRoom) {
            wfc.joinChatroom(this.conversation.target, () => {
                console.log('join chatroom success', this.conversation!.target)
            }, err => {
                showToast('加入聊天室失败')
                this.mainNavPathStack.pop(true)
            })
        }

        if (wfc.isUserOnlineStateEnabled()
            && (this.conversation.type === ConversationType.Single && !wfc.isMyFriend(this.conversation.target))
            && (this.conversation.type === ConversationType.Group)
        ) {
            wfc.watchOnlineState(ConversationType.Group, [this.conversation.target], 60, (states: UserOnlineState[]) => {
                if (this.conversation?.type === ConversationType.Single) {
                    let userOnlineState = wfc.getUserOnlineState(this.conversation.target)
                    if (userOnlineState) {
                        this.title += userOnlineState.desc()
                    }
                }

            }, err => {
            })
        }

        // AI 群（line 2，群主=AI 机器人）：进入时订阅群主在线状态，状态变化刷新标题
        this.ensureAiOwnerOnlineStateWatched()

        if (!title) {
            Utils.computeConversationItemPortraitAndName(this.conversation)
                .then(value => {
                    this.title = value.name + this.title
                })
        } else {
            this.title = title;
        }

        let userOnlineState = wfc.getUserOnlineState(this.conversation.target)
        let userOnlineStateDesc = userOnlineState?.desc()
        if (userOnlineStateDesc) {
            this.title += `(${userOnlineStateDesc})`
        }

        if (this.focusMessageId) {
            let aroundMessages: Message[] = []
            let scrollIndex = 0
            wfc.getMessagesV2(this.conversation, this.focusMessageId, true, 20, '', (messages) => {
                aroundMessages = aroundMessages.concat(messages)

                let focusMessage = wfc.getMessageById(this.focusMessageId)!;
                scrollIndex = aroundMessages.length
                aroundMessages.push(focusMessage)

                wfc.getMessagesV2(this.conversation!, this.focusMessageId, false, 20, '', (messages) => {
                    aroundMessages = aroundMessages.concat(messages)
                    this.conversationMessageDataSource.setMessages(aroundMessages);
                    this.scroller.scrollToIndex(scrollIndex)
                }, err => {
                    console.error('getMessageV2 error', err)
                })

            }, err => {
                console.error('getMessageV2 error', err)
            })

        } else {
            wfc.getMessagesV2(this.conversation, 0, true, 20, '', (messages) => {
                this.conversationMessageDataSource.setMessages(messages);

                this.lastInitialScrollOffset = -1
                this.scrollToBottomOnEnter(8)
            }, err => {
                console.error('getMessageV2 error', err)
            })
        }

        if (this.conversation.type === ConversationType.Group) {
            wfc.eventEmitter!.on(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
            this.showGroupMemberNickName = !wfc.isHiddenGroupMemberName(this.conversation.target)
            this.updateUnreadJoinGroupRequestCount()
        }

        // Agent 会话判定/状态、Token 统计初始化；用户或群信息未缓存时判为非 Agent，待 UserInfosUpdate/GroupInfosUpdate 后重新判定
        this.refreshAgentState()
    }

    // Agent 会话状态（type=1）与 Token 统计（type=2）：scope=31 用户设置变化时重读当前会话 key
    // （type=2 变化也会触发同一事件，事件驱动，无轮询）
    onSettingUpdate = () => {
        this.refreshAgentState()
    }

    refreshAgentState() {
        if (!this.conversation) {
            this.agentState = null
            this.agentMetrics = null
            this.agentConvKind = ''
            this.agentRobotRows = []
            this.agentChooserRobots = []
            this.agentChooserOpen = false
            return
        }
        this.agentConvKind = agentConversationKind(this.conversation)
        this.agentState = getAgentState(this.conversation)
        this.agentMetrics = getAgentMetrics(this.conversation)
        // 多机器人（多 agent）：按机器人分组读取状态，标题栏逐列展示（仅群 AI 会话）
        this.refreshAgentRobotRows()
    }

    // 标题栏多 agent 状态列：读取会话内每个有状态机器人的 type=1/type=2 并按机器人分组；
    // 名称缺失（回退 uid）时后台限频拉取用户信息，UserInfosUpdate 后本方法会被再次调用重算
    refreshAgentRobotRows() {
        const rows: AgentRobotStatusRow[] = []
        if (this.conversation && this.agentConvKind === 'group') {
            const states = getAgentRobotStates(this.conversation)
            for (const r of states) {
                const st = r.state
                if (!st) {
                    continue
                }
                const row: AgentRobotStatusRow = {
                    uid: r.uid,
                    name: agentRobotName(r.uid),
                    text: agentRobotStatusText(st),
                    color: agentStateColor(st.state)
                }
                rows.push(row)
            }
        }
        this.agentRobotRows = rows
        this.warmRobotNamesIfNeeded()
    }

    // 机器人显示名缺失（agentRobotName 回退为完整 uid 时）后台批量拉取用户信息并限频；
    // 拉取完成后客户端会触发 UserInfosUpdate → onUserInfosUpdate → refreshAgentState 重算名称
    private warmRobotNamesIfNeeded() {
        if (!this.conversation || this.agentConvKind !== 'group') {
            return
        }
        const uids = listAgentRobotUids(this.conversation)
        if (uids.length === 0) {
            return
        }
        const missing: string[] = []
        for (const uid of uids) {
            // 名称等于完整 uid 说明缓存中没有该用户信息（可能恰好同名，重复拉取无害且限频）
            if (agentRobotName(uid) === uid) {
                missing.push(uid)
            }
        }
        if (missing.length === 0) {
            return
        }
        const now = Date.now()
        if (now - this.lastRobotNameWarmMillis < 5000) {
            return
        }
        this.lastRobotNameWarmMillis = now
        wfc.getUserInfosEx(missing, this.conversation.target, (infos: UserInfo[]) => {
            this.refreshAgentState()
        }, (err: number) => {
            // 拉取失败忽略：下次状态更新/用户信息事件再试
        })
    }

    // Agent 运行态提示（type=1 状态）：等待确认/审批、出错、已取消；无提示返回空字符串
    private get agentStatusHintLine(): string {
        return this.agentState ? agentStatusHint(this.agentState) : ''
    }

    // Agent Token 统计一行（type=2 计量，如 "上下文 0.8% · 缓存 98% · 70.5 tok/s · 本轮 179 tok · 累计 15992 tok"）；
    // 无可展示统计字段时返回空字符串，标题栏不占位。
    // sessionId 校验：统计属于当前会话才显示——type=2 统计带 sessionId 且与 type=1 状态（agentState）
    // 的 sessionId 不一致时（切目录后旧会话统计残留）返回空，不显示统计段；AI 在线/运行提示/lastChange
    // 仍正常显示。任一侧 sessionId 缺失（旧数据）时不拦截，按现状显示。（参考 PC 端 agentMetricsText computed）
    private get agentMetricsLine(): string {
        if (!this.agentMetrics) {
            return ''
        }
        if (this.agentMetrics.sessionId && this.agentState && this.agentState.sessionId
            && this.agentMetrics.sessionId !== this.agentState.sessionId) {
            return ''
        }
        return agentMetricsText(this.agentMetrics)
    }

    // 标题下方状态行：AI 在线状态 + 运行态提示 + 最近变更 + Token 统计合并为一行
    // （如 "AI Web 在线 · 🤔 等待确认 · 模型 → deepseek-official/deepseek-v4-pro · 上下文 0.8% · 缓存 98%"）。
    // 各段非空时用 " · " 连接，为空跳过；全部为空返回空字符串（不渲染不占位）。
    // 非 AI/Agent 会话均为空，不影响原有副标题逻辑（参考 PC 端 conversationStatusLine()）。
    private get conversationStatusLine(): string {
        // AI 群：群主（AI 机器人）不在线 → 去掉所有 AI 状态段（运行态提示/lastChange/Token 统计），只显示 "AI 不在线"
        if (this.agentConvKind === 'group' && !this.aiOwnerOnline) {
            return 'AI 不在线'
        }
        let online = this.aiOwnerOnlineStateDesc ? 'AI ' + this.aiOwnerOnlineStateDesc : ''
        let hint = this.agentStatusHintLine
        // 最近一次面板变更（type=1 lastChange，207 set 后插件写入，变更可见）
        let lastChange = this.agentState && this.agentState.lastChange ? this.agentState.lastChange : ''
        let metrics = this.agentMetricsLine
        let parts: string[] = []
        if (online) {
            parts.push(online)
        }
        if (hint) {
            parts.push(hint)
        }
        if (lastChange) {
            parts.push(lastChange)
        }
        if (metrics) {
            parts.push(metrics)
        }
        return parts.join(' · ')
    }

    // 标题栏停止按钮：向当前 Agent 会话发送 /stop 命令文本，中断当前 Agent turn（1.5s 防重复点击）
    stopAgent() {
        if (this.agentStopSending || !this.conversation) {
            return
        }
        this.agentStopSending = true
        wfc.sendConversationMessage(this.conversation, new TextMessageContent('/stop'))
        setTimeout(() => {
            this.agentStopSending = false
        }, 1500)
    }

    // ─── AI 会话设置面板打开：多机器人先列表选择目标机器人再打开（对齐 PC 端 MessageInputView） ───
    // 机器人列表来自 scope=31 type=1 条目后缀 + 群机器人成员兜底（listAgentRobotUids，完整 uid）
    openAgentPanel() {
        if (!this.conversation) {
            return
        }
        const robots = listAgentRobotUids(this.conversation)
        if (robots.length > 1) {
            // 多机器人：先弹选择列表
            this.agentChooserRobots = robots
            this.agentChooserOpen = true
            this.showAgentPanel = false
            this.activeAgentRobotUid = ''
            return
        }
        // 单机器人/无条目：直接打开（空 uid = 会话默认机器人）
        this.activeAgentRobotUid = robots.length === 1 ? robots[0] : ''
        this.agentChooserOpen = false
        this.showAgentPanel = true
    }

    /** 机器人选择列表：选中目标机器人（完整 uid）后关闭列表并打开其面板。 */
    pickAgentRobot(uid: string) {
        this.activeAgentRobotUid = uid || ''
        this.agentChooserOpen = false
        this.showAgentPanel = true
    }

    /** 关闭机器人选择列表（不打开面板）。 */
    closeAgentChooser() {
        this.agentChooserOpen = false
    }

    onGroupJoinRequestUpdate = () => {
        this.updateUnreadJoinGroupRequestCount()
    }

    async updateUnreadJoinGroupRequestCount() {
        if (this.conversation?.type !== ConversationType.Group) {
            return
        }
        let groupInfo = wfc.getGroupInfo(this.conversation.target, false)
        if (groupInfo.type !== GroupType.Restricted || groupInfo.joinType !== 3) {
            return;
        }

        let groupMember = wfc.getGroupMember(this.conversation.target, wfc.getUserId())
        if (groupInfo && groupMember && (groupMember.type === GroupMemberType.Owner || groupMember.type === GroupMemberType.Manager)) {
            let unread = wfc.getJoinGroupRequestUnread(this.conversation.target)
            console.log('updateUnreadJoinRequestCount', unread)
            this.unreadJoinGroupRequestCount = unread
        } else {
            this.unreadJoinGroupRequestCount = 0
        }
    }

    /**
     * 首次进入会话时贴底。
     * LazyForEach 的首帧布局在下一帧才完成，消息中的图片等内容还会异步加载使高度继续变化，
     * 同帧只调用一次 scrollEdge 会基于不完整布局，导致未真正滚动到最底部。
     * 这里在内容布局稳定前重复贴底：每次贴底后比较滚动偏移，偏移不再变化即认为已稳定并停止。
     */
    scrollToBottomOnEnter(remaining: number) {
        // 页面被 replace 重建时，旧页面延迟触发的本方法可能在 scroller 已与 List 解绑后执行，
        // 此时 currentOffset() 运行时返回 undefined，直接读 .yOffset 会崩溃，这里做防御性判空。
        this.scroller.scrollEdge(Edge.Bottom)
        let offset = this.scroller.currentOffset()
        if (!offset) {
            return
        }
        let yOffset = offset.yOffset
        if (remaining > 0 && yOffset !== this.lastInitialScrollOffset) {
            this.lastInitialScrollOffset = yOffset
            setTimeout(() => {
                this.scrollToBottomOnEnter(remaining - 1)
            }, 80)
        }
    }

    async loadHistoryMessage() {
        let oldestMessageId = 0;
        let oldestMessageUid = Long.ZERO
        if (this.conversationMessageDataSource.totalCount() > 0) {
            let oldestMsg = this.conversationMessageDataSource.getData(0)
            oldestMessageId = oldestMsg.messageId
            oldestMessageUid = oldestMsg.messageUid
        }
        wfc.getMessagesV2(this.conversation!, oldestMessageId, true, 20, '', async (messages) => {
            if (messages.length === 0) {
                wfc.loadRemoteConversationMessages(this.conversation!, [], oldestMessageUid, 20, async msgs => {
                    if (msgs.length === 0) {
                        // 远程IM服务没有更多消息，尝试从归档服务获取
                        await this.loadArchivedHistoryMessages()
                    } else {
                        let filteredMsgs = msgs.filter(m => {
                            return m.messageId != 0 && this.conversationMessageDataSource.getMessages().findIndex(dm => eq(dm.messageUid, m.messageUid)) === -1
                        })
                        this.conversationMessageDataSource.insertMessages(0, filteredMsgs)
                        this.scroller.scrollToIndex(msgs.length - 1, false)
                        this.refreshStatus = false;
                    }
                }, async err => {
                    // 远程IM服务出错，尝试从归档服务获取
                    await this.loadArchivedHistoryMessages()
                })
            } else {
                this.conversationMessageDataSource.insertMessages(0, messages)
                this.scroller.scrollToIndex(messages.length - 1, false)
                this.refreshStatus = false;
            }
        }, err => {
            console.error('getMessageV2 error', err)
            this.refreshStatus = false;
        })
    }

    /**
     * 加载归档历史消息
     * 当本地和远程IM都没有更多消息时，尝试从归档服务加载
     */
    async loadArchivedHistoryMessages() {
        // 检查归档服务是否可用
        if (!archiveServer.getBaseUrl() || archiveServer.getBaseUrl().length === 0) {
            this.hasNoMoreHistoryMessage = true
            this.refreshStatus = false;
            return
        }

        // 获取当前最早消息的消息ID作为起始ID
        let startMid = this.archiveNextStartMid
        if (startMid === 0 && this.conversationMessageDataSource.totalCount() > 0) {
            // 首次加载归档消息，使用当前最早消息的 messageUid
            let oldestMsg = this.conversationMessageDataSource.getData(0)
            if (oldestMsg && oldestMsg.messageUid) {
                try {
                    // messageUid 是 Long 类型，转换为 number
                    startMid = parseInt(oldestMsg.messageUid.toString())
                } catch (e) {
                    console.error('Failed to convert messageUid to number', e)
                }
            }
        }

        try {
            const result: ArchiveMessageResult = await archiveServer.getArchivedMessages(
                this.conversation!.type,
                this.conversation!.target,
                this.conversation!.line,
                startMid,
                true, // before: 获取更早的消息
                10     // limit: 每次加载10条
            )

            if (result.messages && result.messages.length > 0) {
                // 过滤掉已存在的消息
                let filteredMsgs = result.messages.filter((m: Message) => {
                    return m.messageId != 0 && this.conversationMessageDataSource.getMessages().findIndex((dm: Message) => eq(dm.messageUid, m.messageUid)) === -1
                })

                if (filteredMsgs.length > 0) {
                    this.conversationMessageDataSource.insertMessages(0, filteredMsgs)
                    this.scroller.scrollToIndex(filteredMsgs.length - 1, false)
                }

                // 更新分页状态
                this.archiveNextStartMid = result.nextStartMid

                // 如果没有更多归档消息
                if (!result.hasMore) {
                    this.hasNoMoreHistoryMessage = true
                }
            } else {
                // 没有归档消息
                this.hasNoMoreHistoryMessage = true
            }
        } catch (error) {
            console.error('Failed to load archived messages:', error)
            this.hasNoMoreHistoryMessage = true
        } finally {
            this.refreshStatus = false;
        }
    }

    showUserInfo(userId: string) {
        let allow = true
        if (this.conversation?.type === ConversationType.Group) {
            let groupInfo = wfc.getGroupInfo(this.conversation.target, false)
            let me = wfc.getGroupMember(this.conversation.target, wfc.getUserId())
            if (groupInfo.privateChat === 1 && [GroupMemberType.Owner, GroupMemberType.Manager].indexOf(me.type) === -1) {
                allow = false
            }
        }
        if (allow) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                'userInfo': wfc.getUserInfo(userId)
            } as Record<string, Object>)
        } else {
            showToast('禁止私聊')
        }
    }

    isDisplayMessage(message: Message) {
        // AGENT_Command (207) 是 AI 面板静默指令（透明消息，不落库、不显示在消息流）
        if (message.messageContent.type === MessageContentType.AGENT_COMMAND) {
            return false;
        }
        // return [PersistFlag.Persist, PersistFlag.Persist_And_Count].indexOf(MessageConfig.getMessageContentPersitFlag(message.messageContent.type)) > -1;
        return message.messageId !== 0 || message.messageContent.type === MessageContentType.Streaming_Text_Generating;
    }

    isMessageChecked(msg: Message): boolean {
        return this.checkedMessages.findIndex(m => m.messageId === msg.messageId) >= 0
    }

    checkOrUncheckMessage(msg: Message) {
        if (!this.enableMultiCheck) {
            return
        }
        let index = this.checkedMessages.findIndex(m => m.messageId === msg.messageId)
        if (index >= 0) {
            this.checkedMessages.splice(index, 1)
        } else {
            this.checkedMessages.push(msg)
        }
    }

    onQuoteMessage() {
        this.scroller.scrollEdge(Edge.Bottom)
    }

    onSendMessage = (message: Message) => {
        let conversation = new Conversation(message.conversation.type, message.conversation.target, message.conversation.line)
        if (this.isDisplayMessage(message) && Conversation.equal(conversation, this.conversation!)) {
            this.conversationMessageDataSource.appendOrUpdateMessage(message);
            this.scroller.scrollEdge(Edge.Bottom)
        }
    }
    onMessageStatusUpdate = (message: Message) => {
        if (this.isDisplayMessage(message) && Conversation.equal(message.conversation, this.conversation!)) {
            this.conversationMessageDataSource.updateMessage(message);
        }
    }
    onReceiveMessage = (messages: Message[]) => {
        this.unreadStatusCleared = false
        let hasUnloadMsg = false
        if (this.conversation?.type === ConversationType.Group && wfc.isCommercialServer()) {
            for (const msg of messages) {
                if (msg.messageContent.notLoaded) {
                    hasUnloadMsg = true
                    break
                }
            }
        }
        if (hasUnloadMsg) {
            messages = messages.slice(messages.length - 15)
            if (Conversation.equal(messages[0].conversation, this.conversation!)) {
                this.conversationMessageDataSource.setMessages(messages);
                this.scroller.scrollEdge(Edge.Bottom)
            }
            return
        }

        messages.forEach(message => {
            // 取消消息（20）是删除信号：按 streamId 移除对应的生成中(14)/已生成(15)消息，
            // 取消消息自身不显示任何内容、不进入列表
            if (message.messageContent.type === MessageContentType.Streaming_Text_Cancelled) {
                if (Conversation.equal(message.conversation, this.conversation!)) {
                    let cancelledContent = message.messageContent as StreamingTextCancelledMessageContent;
                    this.conversationMessageDataSource.removeStreamingMessageByStreamId(cancelledContent.streamId);
                }
                return;
            }
            if (this.isDisplayMessage(message) && Conversation.equal(message.conversation, this.conversation!)) {
                this.conversationMessageDataSource.appendOrUpdateMessage(message);
                this.scroller.scrollEdge(Edge.Bottom)
            }
        })
    }
    onDeleteMessage = (messageId: number) => {
        this.conversationMessageDataSource.removeMessageById(messageId)
        console.log('onDeleteMessage', messageId)
    }
    onRemoteDeleteMessage = (messageUid: Long) => {
        this.conversationMessageDataSource.removeMessageByUid(messageUid)
        console.log('onRemoteDeleteMessage', messageUid)
    }
    onRecallMessage = (operator: string, messageUid: Long) => {
        let msg = wfc.getMessageByUid(messageUid)
        if (msg) {
            this.conversationMessageDataSource.updateMessage(msg)
        }
        console.log('onRecallMessage', messageUid)
    }
    onReadMessage = (readEntries: ReadEntry[]) => {
        this.readEntries = wfc.getConversationRead(this.conversation!);
    }
    onFriendListUpdate = (friendIds: string[]) => {
        if (this.conversation?.type === ConversationType.Single) {
            let index = friendIds.findIndex(id => id === this.conversation?.target)
            if (index >= 0) {
                Utils.computeConversationItemPortraitAndName(this.conversation)
                    .then(value => {
                        this.title = value.name
                    })
            }
        }
    }
    onUserInfosUpdate = (userInfos: UserInfo[]) => {
        // 机器人用户信息拉取回来后，重新判定是否为 Agent 会话
        this.refreshAgentState()
        if (this.conversation?.type === ConversationType.Single) {
            let index = userInfos.findIndex(info => info.uid === this.conversation?.target)
            if (index >= 0) {
                Utils.computeConversationItemPortraitAndName(this.conversation)
                    .then(value => {
                        this.title = value.name
                    })
            }
        }
        // TODO 消息发送者的头像等可能也需要更新
    }
    onGroupInfosUpdate = (groupInfos: GroupInfo[]) => {
        // 群信息拉取回来后，刷新 Agent 会话状态（AI 会话判定仅依据 line，不再使用群 extra {"dsh":true} 标记）
        this.refreshAgentState()
        // AI 群：群信息（含群主 owner）就绪后，补订/刷新群主在线状态
        this.ensureAiOwnerOnlineStateWatched()
        if (this.conversation?.type === ConversationType.Group) {
            let index = groupInfos.findIndex(info => info.target === this.conversation?.target)
            if (index >= 0) {

                Utils.computeConversationItemPortraitAndName(this.conversation)
                    .then(value => {
                        this.title = value.name
                    })
            }
        }
    }
    onConversationInfoUpdate = (conversationInfo: ConversationInfo) => {
        // 清空会话消息
        if (!conversationInfo.lastMessage && conversationInfo.conversation.type !== ConversationType.ChatRoom) {
            this.conversationMessageDataSource.setMessages([])
            // 重置归档消息分页状态
            this.archiveNextStartMid = 0;
            this.hasNoMoreHistoryMessage = false;
        }
    }
    onChannelInfosUpdate = (channelInfos: ChannelInfo[]) => {
        if (this.conversation?.type === ConversationType.Channel) {
            let index = channelInfos.findIndex(info => info.channelId === this.conversation?.target)
            if (index >= 0) {
                Utils.computeConversationItemPortraitAndName(this.conversation)
                    .then(value => {
                        this.title = value.name
                    })
            }
        }

    }
    onGroupMembersUpdate = (groupId: string, groupMembers: GroupMember[]) => {
        if (groupId === this.conversation!.target) {
            this.groupMembers = wfc.getGroupMembers(groupId, false);
        }
    }

    showMessageTimeInfo(index: number) {
        // index 值，可能为 length
        if (index < 0 || index >= this.conversationMessageDataSource.totalCount()) {
            return false
        }
        if (index === 0) {
            return true
        } else {
            let preMsg = this.conversationMessageDataSource.getData(index - 1);
            let curMsg = this.conversationMessageDataSource.getData(index)

            if (curMsg.timestamp - preMsg.timestamp > 5 * 60 * 1000) {
                return true;
            }
            return false
        }
    }

    // why?
    // forEach 需要 key 变化，对应项才会更新
    messageItemKey(message: Message) {
        // 流式消息，结束之前是透传消息，没有 messageId

        // key = type - messageId - send status - receipt status
        // type 撤回消息时，会更新 type
        // receipt status： 已读、未读，不支持送达报告

        let key: string = message.messageContent.type + '-' + message.messageId + '-' + message.status + '-' + message.timestamp
        // 流式消息（14/15）：把 streamId 并入 key。多 agent 并发多条流时，不同流的 14 更新
        // 可能在同一接收批次里 messageId 同为 0、status/timestamp 相同，没有 streamId 会 key 冲突
        // 导致气泡互相覆盖/错乱；加入 streamId 后每条流独立成泡、互不干扰。
        let streamId = streamingStreamIdOf(message)
        if (streamId) {
            key += '-' + streamId
        }
        if (this.enableReceipt && this.readEntries && this.readEntries.size > 0) {
            if (this.conversation!.type === ConversationType.Group) {
                if (this.enableGroupReceipt) {
                    // TODO
                }
            } else if (this.conversation!.type === ConversationType.Single) {
                // TODO
                let readDt = this.readEntries.get(this.conversation!.target)
                if (readDt && readDt >= message.timestamp) {
                    key += '-1'
                } else {
                    key += '-0'
                }
            }
        }
        return key
    }

    // 消息行发送者显示名：多机器人（多 agent）会话（line=2 的群/单聊）里，流式消息/普通消息
    // 均按发送机器人 uid 显示「用户信息显示名」，缺失时回退完整 uid（agentRobotName，不截断
    // robot_xxx_yyy），保证多条机器人并发生成时每条气泡归属各自的机器人名，不与群成员昵称混用。
    groupSenderDisplayName(fromUid: string): string {
        if (!fromUid) {
            return ''
        }
        if (this.conversation && this.conversation.line === 2) {
            return agentRobotName(fromUid)
        }
        if (fromUid.startsWith('robot_') || fromUid.startsWith('robot-')) {
            return agentRobotName(fromUid)
        }
        return wfc.getGroupMemberDisplayName(this.conversation!.target, fromUid)
    }

    resendMessage(message: Message) {
        wfc.deleteMessage(message.messageId)
        wfc.sendMessage(message, null, null, null, null, null)
    }

    conversationInfoPageName(): string {
        let name: string = ''
        switch (this.conversation!.type) {
            case ConversationType.Single:
                name = uikitNavigationDestinations.SingleConversationInfoPage
                break
            case ConversationType.Group:
                name = uikitNavigationDestinations.GroupConversationInfoPage
                break
            case ConversationType.Channel:
                name = uikitNavigationDestinations.ChannelConversationInfoPage
                break
            case ConversationType.ChatRoom:
                name = uikitNavigationDestinations.ChatroomConversationInfoPage
                break
            default:
                break
        }
        return name
    }

    onUserPortraitLongClick(userId: string) {
        if (this.conversation?.type === ConversationType.Group) {
            this.longPressToMentionUser = userId
        }
    }

    private previewCardSize(): number {
        return this.previewEmoji?.category === 'Peoples' ? 88 : 130
    }

    private previewCardX(): number {
        const size = this.previewCardSize()
        const cx = (this.previewCol + 0.5) * this.previewColW
        return Math.max(0, Math.min(this.pageWidth - size, cx - size / 2))
    }

    private previewCardY(): number {
        const GRID_OFFSET = 50 // tab list (40) + stack top padding (10) inside EmojiInputPanelView
        const size = this.previewCardSize()
        const rowTopY = this.pageHeight - this.panelHeight + GRID_OFFSET + this.previewRowY
        return Math.max(0, rowTopY - size - 4)
    }

    // 自定义标题区宽度不受约束，百分比 maxWidth 不生效；用实测页宽减去左右返回/更多按钮与耳朵图标的占位，
    // 算出标题文本可用的最大宽度（vp），才能正确触发中间截断。
    titleMaxWidth(): number {
        let avail = (this.pageWidth > 0 ? this.pageWidth : 360) - 112
        if (this.voiceEarpieceMode) {
            avail -= 46
        }
        return avail > 1 ? avail : 1
    }

    // 机器人选择列表项：主行显示机器人显示名（用户信息接口/缓存，缺失回退完整 uid），
    // 副行小字常驻展示完整 uid（ArkTS 无 title 悬浮提示，用副行代替「title=uid」），点选打开其面板
    @Builder
    agentRobotChoiceRow(uid: string) {
        Row() {
            Text('🤖')
                .fontSize(FontSize.md)
            Column() {
                Text(agentRobotName(uid))
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_primary_text'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(uid)
                    .fontSize(FontSize.xs)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 10 })
        }
        .width('100%')
        .constraintSize({ minHeight: 50 })
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(Radius.md)
        .stateStyles({
            pressed: {
                .backgroundColor($r('app.color.wf_item_pressed'))
            },
            normal: {
                .backgroundColor($r('app.color.wf_background'))
            }
        })
        .onClick(() => {
            this.pickAgentRobot(uid)
        })
    }

    @Builder
    ConversationTitleBuilder() {
        Column() {
            Row() {
                Text(this.title)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.wf_primary_text'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    // 标题过长时从中间截断，保证末尾的「耳朵」图标始终可见
                    .ellipsisMode(EllipsisMode.CENTER)
                    .constraintSize({ maxWidth: this.titleMaxWidth() })
                    .minFontScale(1)
                    .maxFontScale(1)
                if (this.voiceEarpieceMode) {
                    Image($r('app.media.ic_voice_earpiece'))
                        .width(18)
                        .height(18)
                        .fillColor($r('app.color.wf_secondary_text'))
                        .margin({ left: 6 })
                }
            }

            // Agent 会话状态区：
            // 多机器人（多 agent，>1 个有状态机器人）→ 逐列显示「🤖机器人名:状态」（颜色随状态），
            // 默认机器人（会话默认，agentState）运行中时在末尾附「■ 停止」（/stop 语义同前）；
            // 其余（单机器人/非 AI 群）沿用单行布局：状态副标题 + 停止按钮 + 状态/统计行
            if (this.agentRobotRows.length > 1) {
                Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                    ForEach(this.agentRobotRows, (row: AgentRobotStatusRow) => {
                        Text(`🤖 ${row.name}:${row.text}`)
                            .fontSize(FontSize.xs)
                            .fontColor(row.color)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .constraintSize({ maxWidth: 180 })
                            .margin({ right: 10, bottom: 2 })
                    }, (row: AgentRobotStatusRow) => row.uid)
                    if (this.agentState && this.agentState.state === 'running') {
                        Text('■ 停止')
                            .fontSize(FontSize.xs)
                            .fontColor($r('app.color.wf_danger'))
                            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                            .borderRadius(Radius.md)
                            .border({ width: 1, color: $r('app.color.wf_danger') })
                            .opacity(this.agentStopSending ? 0.5 : 1)
                            .enabled(!this.agentStopSending)
                            .margin({ bottom: 2 })
                            .onClick(() => {
                                this.stopAgent()
                            })
                    }
                }
                .width('100%')
                .margin({ top: 2 })
            } else {
                // Agent 会话状态副标题（空闲/运行中/等待确认/已完成；phase=tool 时追加工具名），仅 Agent 会话显示；
                // AI 群群主不在线时不显示任何 AI 状态（状态文本/停止按钮），由下方 "AI 不在线" 替代
                if (this.agentState && !(this.agentConvKind === 'group' && !this.aiOwnerOnline)) {
                    Row({ space: 6 }) {
                        Text(agentStateText(this.agentState))
                            .fontSize(FontSize.xs)
                            .fontColor(agentStateColor(this.agentState!.state))
                            .maxLines(1)
                        if (this.agentState!.state === 'running') {
                            Text('■ 停止')
                                .fontSize(FontSize.xs)
                                .fontColor($r('app.color.wf_danger'))
                                .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                                .borderRadius(Radius.md)
                                .border({ width: 1, color: $r('app.color.wf_danger') })
                                .opacity(this.agentStopSending ? 0.5 : 1)
                                .enabled(!this.agentStopSending)
                                .onClick(() => {
                                    this.stopAgent()
                                })
                        }
                    }
                    .margin({ top: 2 })
                }

                // AI 群（line 2）在线状态 + 运行态提示 + Agent Token 统计合并为一行
                // （如 "AI Web 在线 · 🤔 等待确认 · 上下文 0.8% · 缓存 98%"）；
                // 各段均无内容时不渲染（不占位）
                if (this.conversationStatusLine) {
                    Text(this.conversationStatusLine)
                        .fontSize(FontSize.xs)
                        .fontColor($r('app.color.wf_secondary_text'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 2 })
                }
            }
        }
        .height('100%')
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
    }

    build() {
        NavDestination() {
            Stack() {
                Column() {
                    Scroll() {
                        Stack() {
                            Refresh({ refreshing: $$this.refreshStatus }) {
                                Column() {
                                    if (this.hasNoMoreHistoryMessage) {
                                        Text('没有更多消息')
                                            .padding(4)
                                            .fontSize(FontSize.sm)
                                            .fontColor($r('app.color.wf_tertiary_text'))
                                    }
                                    Blank()
                                        .width('100%')
                                        .layoutWeight(1)

                                    List({ scroller: this.scroller }) {
                                        LazyForEach(this.conversationMessageDataSource,
                                            (msg: Message, index: number) => {
                                                ListItem() {
                                                    if (msg.messageContent instanceof NotificationMessageContent) {
                                                        Row() {
                                                            // 自定义通知消息 start
                                                            if (msg.messageContent instanceof TestCustomNotificationMessageContent) {
                                                                TestCustomNotificationMessageContentView({ message: msg })
                                                            }
                                                            // 自定义通知消息 end
                                                            else if (msg.messageContent.type === MessageContentType.RecallMessage_Notification) {
                                                                RecallNotificationMessageContentView({
                                                                    message: msg, onClickReedit: () => {
                                                                        let recallMsgContent = msg.messageContent as RecallMessageNotification
                                                                        this.toReeditText = recallMsgContent.originalSearchableContent
                                                                    }
                                                                })
                                                            } else if (msg.messageContent instanceof RichNotificationMessageContent) {
                                                                RichNotificationMessageContentView({ message: msg })
                                                            } else {
                                                                SimpleNotificationMessageContentView({ message: msg })
                                                            }
                                                        }
                                                        .width('100%')
                                                        .justifyContent(FlexAlign.Center)

                                                        // contextable notificaiton like messages
                                                        // 支持长按菜单的类通知消息，居中显示，不显示发送者，长按支持显示菜单
                                                    } else if (msg.messageContent instanceof ArticlesMessageContent) {
                                                        ContextableNotificationMessageContentView({ message: msg, enableMultiCheck: this.enableMultiCheck })
                                                        // out
                                                    } else if (msg.direction === 0) {
                                                        Column() {
                                                            if (this.showMessageTimeInfo(index)) {
                                                                Text(timeFormat(msg.timestamp))
                                                                    .fontSize(FontSize.xs)
                                                                    .fontColor($r('app.color.wf_tertiary_text'))
                                                                    .padding(12)
                                                            }
                                                            Row() {
                                                                if (this.enableMultiCheck) {
                                                                    Row() {
                                                                        Checkbox()
                                                                            .select(this.isMessageChecked(msg))
                                                                            .margin({ left: 12 })
                                                                            .onChange((value => {
                                                                                // if (!this.enableMultiCheck) {
                                                                                //     return
                                                                                // }
                                                                                if (this.checkValueChangeTriggerByClick) {
                                                                                    this.checkValueChangeTriggerByClick = false
                                                                                    return
                                                                                }
                                                                                this.checkOrUncheckMessage(msg)
                                                                            }))
                                                                    }
                                                                    .margin({ top: 12 })
                                                                    .height(40)
                                                                    .alignItems(VerticalAlign.Center)
                                                                }
                                                                Row() {

                                                                    if (msg.status === MessageStatus.SendFailure) {
                                                                        // 重试
                                                                        Row() {
                                                                            Text('重试')
                                                                                .fontSize(FontSize.xs)
                                                                                .padding({ right: 4 })
                                                                            Image($r('app.media.img_error'))
                                                                                .width(20)
                                                                                .height(20)
                                                                                .objectFit(ImageFit.ScaleDown)

                                                                        }
                                                                        .padding({ right: 4 })
                                                                        .alignItems(VerticalAlign.Bottom)
                                                                        .onClick(() => {
                                                                            this.resendMessage(msg)
                                                                        })
                                                                    }

                                                                    if (msg.status === MessageStatus.Sending) {
                                                                        LoadingProgress().width(20).height(20)
                                                                    }

                                                                    NormalMessageContentView({
                                                                        message: msg,
                                                                        enableMultiCheck: $enableMultiCheck,
                                                                        quotedMessage: $quotedMessage,
                                                                        audioPlayManager: this.audioPlayerManager,
                                                                        autoPlayMessageId: this.autoPlayMessageId,
                                                                        onVoicePlayStart: this.onVoicePlayStart,
                                                                        onVoicePlayComplete: this.onVoicePlayComplete,
                                                                        enableReceipt: this.enableReceipt,
                                                                        readEntries: this.readEntries,
                                                                        groupMembers: this.groupMembers
                                                                    })//.layoutWeight(1)
                                                                        .margin({ top: 12 })
                                                                        .enabled(!this.enableMultiCheck)
                                                                }
                                                                .justifyContent(FlexAlign.End)
                                                                .layoutWeight(1)
                                                                .margin({ left: 72 })

                                                                Image(wfc.getUserInfo(msg.from).portrait)
                                                                    .width(scaledSize(40, this.fontScale))
                                                                    .height(scaledSize(40, this.fontScale))
                                                                    .borderRadius(Radius.sm)
                                                                    .draggable(false)
                                                                    .margin(12)
                                                                    .enabled(!this.enableMultiCheck)
                                                                    .onClick(() => {
                                                                        this.showUserInfo(msg.from)
                                                                    })
                                                            }
                                                            .width('100%')
                                                            .justifyContent(FlexAlign.End)
                                                            .alignItems(VerticalAlign.Top)
                                                            .backgroundColor(this.focusMessageId && msg.messageId === this.focusMessageId ? this.focusMessageBackgroundColor : undefined)
                                                            .animation(this.focusMessageId && msg.messageId === this.focusMessageId ? {
                                                                curve: Curve.Linear,
                                                                duration: 1000,
                                                                iterations: 5,
                                                                playMode: PlayMode.Normal,
                                                                onFinish: () => {
                                                                    this.focusMessageBackgroundColor = Color.Red
                                                                }
                                                            } : undefined)
                                                            .onClick((event) => {
                                                                if (!this.enableMultiCheck) {
                                                                    return
                                                                }
                                                                this.checkValueChangeTriggerByClick = true
                                                                this.checkOrUncheckMessage(msg)
                                                            })
                                                        }
                                                        .width('100%')
                                                        .alignItems(HorizontalAlign.Center)

                                                        // in
                                                    } else {
                                                        Column() {
                                                            if (this.showMessageTimeInfo(index)) {
                                                                Text(timeFormat(msg.timestamp))
                                                                    .fontSize(FontSize.xs)
                                                                    .fontColor($r('app.color.wf_tertiary_text'))
                                                                    .padding(12)
                                                            }
                                                            Row() {
                                                                if (this.enableMultiCheck) {
                                                                    Row() {
                                                                        Checkbox()
                                                                            .select(this.isMessageChecked(msg))
                                                                            .margin({ left: 12 })
                                                                            .onChange((value => {
                                                                                if (this.checkValueChangeTriggerByClick) {
                                                                                    this.checkValueChangeTriggerByClick = false
                                                                                    return
                                                                                }
                                                                                this.checkOrUncheckMessage(msg)
                                                                            }))
                                                                    }
                                                                    .margin({ top: 12 })
                                                                    .height(40)
                                                                    .alignItems(VerticalAlign.Center)

                                                                    // .alignSelf(ItemAlign.Center)
                                                                }
                                                                Image(wfc.getUserInfo(msg.from).portrait)
                                                                    .width(scaledSize(40, this.fontScale))
                                                                    .height(scaledSize(40, this.fontScale))
                                                                    .margin(12)
                                                                    .draggable(false)
                                                                    .borderRadius(Radius.sm)
                                                                    .enabled(!this.enableMultiCheck)
                                                                    .onClick(() => {
                                                                        this.showUserInfo(msg.from)
                                                                    })
                                                                    .gesture(
                                                                        LongPressGesture({ repeat: false })
                                                                            .onAction(evt => {
                                                                                this.onUserPortraitLongClick(msg.from)
                                                                            })
                                                                        , GestureMask.Normal
                                                                    )
                                                                Column() {
                                                                    if (this.showGroupMemberNickName) {
                                                                        Text(this.groupSenderDisplayName(msg.from))
                                                                            .fontSize(FontSize.xs)
                                                                            .fontColor($r('app.color.wf_tertiary_text'))
                                                                            .padding({ bottom: 2 })
                                                                    }
                                                                    NormalMessageContentView({
                                                                        message: msg,
                                                                        enableMultiCheck: $enableMultiCheck,
                                                                        quotedMessage: $quotedMessage,
                                                                        audioPlayManager: this.audioPlayerManager,
                                                                        autoPlayMessageId: this.autoPlayMessageId,
                                                                        onVoicePlayStart: this.onVoicePlayStart,
                                                                        onVoicePlayComplete: this.onVoicePlayComplete
                                                                    })//.layoutWeight(1)
                                                                        .enabled(!this.enableMultiCheck)
                                                                }
                                                                .justifyContent(FlexAlign.Start)
                                                                .alignItems(HorizontalAlign.Start)
                                                                .layoutWeight(1)
                                                                .margin({ right: 72, top: 12 })
                                                            }
                                                            .width('100%')
                                                            .justifyContent(FlexAlign.Start)
                                                            .alignItems(VerticalAlign.Top)
                                                            .backgroundColor(this.focusMessageId && msg.messageId === this.focusMessageId ? this.focusMessageBackgroundColor : undefined)
                                                            .animation(this.focusMessageId && msg.messageId === this.focusMessageId ? {
                                                                curve: Curve.Linear,
                                                                duration: 1000,
                                                                iterations: 5,
                                                                playMode: PlayMode.Normal,
                                                                onFinish: () => {
                                                                    this.focusMessageBackgroundColor = Color.Red
                                                                }
                                                            } : undefined)
                                                            .onClick((event) => {
                                                                if (!this.enableMultiCheck) {
                                                                    return
                                                                }
                                                                this.checkValueChangeTriggerByClick = true
                                                                this.checkOrUncheckMessage(msg)
                                                            })
                                                        }
                                                        .width('100%')
                                                        .alignItems(HorizontalAlign.Center)
                                                    }
                                                }
                                            },
                                            (msg: Message) => this.messageItemKey(msg))

                                    }
                                    .onScrollIndex((start, end) => {
                                        this.currentMessageIndex = start;
                                        if (!this.unreadStatusCleared && end == this.conversationMessageDataSource.totalCount() - 1) {
                                            this.unreadStatusCleared = true
                                            // wfc.clearUnreadStatusBeforeMessage(this.conversation, )
                                            wfc.clearConversationUnreadStatus(this.conversation!);
                                        }
                                        if (this.focusMessageId && end === this.conversationMessageDataSource.totalCount() - 1) {
                                            wfc.getMessagesV2(this.conversation!, this.conversationMessageDataSource.getData(this.conversationMessageDataSource.totalCount() - 1)
                                                .messageId, false, 20, '', (messages) => {
                                                if (messages.length > 0) {
                                                    this.conversationMessageDataSource.appendMessages(messages)
                                                } else {
                                                    this.focusMessageId = 0
                                                }
                                            }, err => {
                                                console.error('getMessageV2 error', err)
                                            })
                                        }
                                    })
                                    .listDirection(Axis.Vertical)
                                    // 聊天列表底部对齐：视口因软键盘/表情/加号面板变矮时，内容随之
                                    // 上移、始终贴住底部，与面板一起平滑顶起（微信效果），无需事后再滚动一下。
                                    .stackFromEnd(true)
                                    .height('100%')
                                    .width('100%')
                                }
                                .justifyContent(FlexAlign.End)
                                .width('100%')
                                .height('100%')
                            }
                            .onRefreshing(() => {
                                this.loadHistoryMessage()
                            })
                            .refreshOffset(64)
                            .pullToRefresh(true)

                            Column() {
                                if (this.unreadJoinGroupRequestCount > 0) {
                                    Row() {
                                        Text(this.unreadJoinGroupRequestCount + '条加群申请')
                                            .padding(4)
                                            .fontSize(FontSize.sm)
                                            .fontColor(Color.Red)
                                            .backgroundColor($r('app.color.wf_background'))
                                            .width('100%')
                                            .height(40)
                                            .textAlign(TextAlign.Center)
                                            .onClick(() => {
                                                wfc.clearJoinGroupRequestUnread(this.conversation!.target)
                                                this.unreadJoinGroupRequestCount = 0
                                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupJoinRequestListPage, {
                                                    'groupId': this.conversation?.target
                                                } as Record<string, Object>)
                                            })
                                    }
                                    .alignItems(VerticalAlign.Center)
                                }
                            }
                        }
                        .height('100%')
                        .width('100%')
                        .alignContent(Alignment.Top)
                    }
                    .scrollBar(BarState.Off)
                    .edgeEffect(EdgeEffect.Spring)
                    .width('100%')
                    .layoutWeight(1)
                    .backgroundColor($r('app.color.wf_secondary_background'))
                    .onTouch((event?: TouchEvent) => {
                        this.collapseConversationInputPanelViewTimestamp = new Date().getTime()
                    })

                    if (this.conversation) {
                        ConversationInputPanelView({
                            text: this.toReeditText,
                            conversation: this.conversation,
                            conversationInfo: this.conversationInfo,
                            agentState: this.agentState,
                            agentConvKind: this.agentConvKind,
                            enableMultiCheck: $enableMultiCheck,
                            checkedMessages: $checkedMessages,
                            showAgentPanel: $showAgentPanel,
                            aiOwnerOnline: this.aiOwnerOnline,
                            quotedMessage: $quotedMessage,
                            collapseConversationInputPanelViewTimestamp: $collapseConversationInputPanelViewTimestamp,
                            messageListScroller: this.scroller,
                            recentPhotoRequested: $recentPhotoRequested,
                            longPressToMentionUser: $longPressToMentionUser,
                            onPreviewChange: (emoji, col, colW, rowY) => {
                                this.previewEmoji = emoji
                                this.previewCol = col
                                this.previewColW = colW
                                this.previewRowY = rowY
                            },
                            onSuggestionsChange: (stickers) => {
                                this.suggestedStickers = stickers
                            },
                            onPanelHeightChange: (h) => {
                                this.panelHeight = h
                            },
                            // 「AI 会话设置」入口：多机器人先列表选择目标机器人再打开面板（由本页接管）
                            onOpenAgentPanel: () => {
                                this.openAgentPanel()
                            }
                        })
                            .onAreaChange((_, area) => {
                                this.inputPanelHeight = area.height as number
                            })
                    }

                } // end Column
                .width('100%')
                .height('100%')

                // 表情建议：内容尺寸的悬浮卡片，靠 Stack 的 BottomEnd 对齐定位到输入栏右上方。
                // 不做成全屏浮层，避免覆盖消息列表导致点击/滑动被透传到列表（从而误触发收起键盘）。
                if (this.suggestedStickers.length > 0) {
                    Scroll() {
                        Row() {
                            ForEach(this.suggestedStickers, (sticker: Emoji) => {
                                Image(sticker.data)
                                    .width(60)
                                    .height(60)
                                    .objectFit(ImageFit.Contain)
                                    .borderRadius(Radius.md)
                                    .margin({ left: 4, right: 4 })
                                    .onClick(() => {
                                        let stickerMsg = new StickerMessageContent('', sticker.data, 200, 200)
                                        wfc.sendConversationMessage(this.conversation!, stickerMsg)
                                        this.toReeditText = ''
                                        this.suggestedStickers = []
                                    })
                            }, (sticker: Emoji, index: number) => index + '')
                        }
                    }
                    .scrollable(ScrollDirection.Horizontal)
                    .scrollBar(BarState.Off)
                    .edgeEffect(EdgeEffect.Spring)
                    .constraintSize({ maxWidth: '75%' })
                    .padding(8)
                    .backgroundColor($r('app.color.wf_background'))
                    .borderRadius(Radius.xl)
                    .shadow({
                        radius: 8,
                        color: '#30000000',
                        offsetX: 0,
                        offsetY: -3
                    })
                    .margin({ bottom: this.inputPanelHeight + 4, right: 12 })
                }

                // 「猜你想发送」：内容尺寸的悬浮卡片，与表情建议同位置。recentPhotoRequested 时即挂载组件查询
                // （opacity=0 不可见，既能完成查询/回调，又隐藏嵌入式组件挂载瞬间的闪烁），确认有图后整体显现。
                if (this.recentPhotoRequested) {
                    Column() {
                        Text('猜你想发送')
                            .fontSize(FontSize.xs)
                            .fontColor($r('app.color.wf_secondary_text'))
                            .margin({ bottom: 8 })
                        RecentPhotoComponent({
                            recentPhotoOptions: this.recentPhotoOptions,
                            onRecentPhotoCheckResult: this.recentPhotoCheckResultCallback,
                            onRecentPhotoClick: this.recentPhotoClickCallback,
                        })
                            .width(60)
                            .height(92)
                            .clip(true)
                            .borderRadius(Radius.sm)
                    }
                    .alignItems(HorizontalAlign.Center)
                    .padding(8)
                    .backgroundColor($r('app.color.wf_background'))
                    .borderRadius(Radius.xl)
                    .shadow({
                        radius: 8,
                        color: '#30000000',
                        offsetX: 0,
                        offsetY: -3
                    })
                    .opacity(this.recentPhotoExists ? 1 : 0)
                    .margin({ bottom: this.inputPanelHeight + 4, right: 12 })
                }

                // Long-press preview: floating card above pressed emoji/sticker
                if (this.previewEmoji !== null) {
                    Column() {
                        if (this.previewEmoji!.category === 'Peoples') {
                            Text(this.previewEmoji!.data)
                                .maxFontScale(1)
                                .fontSize(FontSize.huge)
                        } else {
                            Image(this.previewEmoji!.data)
                                .width(this.previewCardSize() - 20)
                                .height(this.previewCardSize() - 20)
                                .objectFit(ImageFit.Contain)
                                .borderRadius(Radius.lg)
                        }
                    }
                    .width(this.previewCardSize())
                    .height(this.previewCardSize())
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .backgroundColor($r('app.color.wf_background'))
                    .borderRadius(Radius.xl)
                    .shadow({
                        radius: 14,
                        color: '#50000000',
                        offsetX: 0,
                        offsetY: 4
                    })
                    .position({ x: this.previewCardX(), y: this.previewCardY() })
                    .hitTestBehavior(HitTestMode.None)
                }

                // 多机器人选择列表：页面根 Stack 的悬浮覆盖层（全屏遮罩 + 居中卡片）。
                // 多机器人（>1）会话打开「AI 会话设置」时先选目标机器人，再打开该机器人的面板
                if (this.agentChooserOpen && this.agentChooserRobots.length > 0) {
                    Stack({ alignContent: Alignment.Center }) {
                        // 半透明遮罩，点击关闭
                        Column()
                            .width('100%')
                            .height('100%')
                            .backgroundColor('#66000000')
                            .onClick(() => {
                                this.closeAgentChooser()
                            })
                        // 居中卡片
                        Column() {
                            Row() {
                                Text('选择机器人')
                                    .fontSize(FontSize.md)
                                    .fontWeight(FontWeight.Medium)
                                    .fontColor($r('app.color.wf_primary_text'))
                                    .layoutWeight(1)
                                Text('×')
                                    .fontSize(FontSize.lg)
                                    .fontColor($r('app.color.wf_secondary_text'))
                                    .padding({ left: 8, right: 8 })
                                    .onClick(() => {
                                        this.closeAgentChooser()
                                    })
                            }
                            .width('100%')
                            .padding({ left: 16, right: 16, top: 14, bottom: 8 })

                            Divider()
                                .color($r('app.color.wf_divider'))
                                .width('100%')

                            Text('选择要设置的目标机器人')
                                .fontSize(FontSize.xs)
                                .fontColor($r('app.color.wf_tertiary_text'))
                                .width('100%')
                                .padding({ left: 16, right: 16, top: 10 })

                            List({ space: 4 }) {
                                ForEach(this.agentChooserRobots, (uid: string) => {
                                    ListItem() {
                                        this.agentRobotChoiceRow(uid)
                                    }
                                }, (uid: string) => uid)
                            }
                            .width('100%')
                            .layoutWeight(1)
                            .scrollBar(BarState.Off)
                            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                        }
                        .width('88%')
                        .constraintSize({ maxWidth: 380, maxHeight: '70%' })
                        .borderRadius(Radius.xl)
                        .backgroundColor($r('app.color.wf_background'))
                        .shadow({ radius: 24, color: '#33000000', offsetY: 8 })
                        .clip(true)
                    }
                    .width('100%')
                    .height('100%')
                }

                // AI 会话设置面板：页面根 Stack 的悬浮覆盖层（全屏遮罩 + 居中卡片），
                // 与输入面板布局完全隔离，不影响消息列表/输入栏；由输入面板 AI 按钮经 @Link 打开；
                // 多机器人会话经 openAgentPanel/pickAgentRobot 选中目标机器人（robotUid，完整 uid）
                if (this.showAgentPanel && this.conversation) {
                    AgentPanelView({
                        conversation: this.conversation!,
                        robotUid: this.activeAgentRobotUid,
                        dismiss: () => {
                            this.showAgentPanel = false
                        }
                    })
                        .width('100%')
                        .height('100%')
                }

            } // end Stack
            .alignContent(Alignment.BottomEnd)
            .width('100%')
            .height('100%')
            .onAreaChange((_, area) => {
                this.pageWidth = area.width as number
                this.pageHeight = area.height as number
            })

        }
        .onReady(ctx => {
            // let params = ctx.pathInfo.param as Record<string, Object>;
            // let conversation = params['conversation'] as Conversation;
            // let title = params['title'] as string;
            // this.setupConversation(conversation, title);
        })
        .onShown(() => {
            this.onPageShow();
        })
        .onWillDisappear(() => {
            let windowStage = AppStorage.get<window.Window>('window')
            windowStage?.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET);
        })
        .mode(NavDestinationMode.STANDARD)
        .title({
            builder: () => {
                this.ConversationTitleBuilder()
            }, height: TitleHeight.MainOnly
        })
        .menus([
            {
                value: '',
                icon: 'resources/base/media/ic_public_more.svg',
                action: () => {
                    this.mainNavPathStack.pushPathByName(this.conversationInfoPageName(), {
                        'conversationInfo': this.conversationInfo
                    } as Record<string, Object>, true)
                }
            }
        ])
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.wf_primary_background_color'))
    }
}

class ConversationMessageDataSource extends BasicDataSource<Message> {
    private messages: Message[] = []

    setMessages(messages: Message[]): void {
        this.messages = this.normalizeStreaming(messages)
        this.notifyDataReload()
    }

    getMessages() {
        return this.messages
    }

    insertMessages(index: number, messages: Message[]) {
        // 历史消息插到列表头部后，对「整个合并列表」按 streamId 归一化去重：翻页加载到的
        // 旧 14 片段若与列表尾部已有的同一流更新片段（14 新文本/15 最终结果）成组，旧片段整体
        // 丢弃，保证任意时刻每个正在生成/已生成的 stream 在列表里只有一条（跨批去重）。
        this.messages.splice(index, 0, ...messages)
        this.messages = this.normalizeStreaming(this.messages)
        this.notifyDataReload();
    }

    // 对流式消息按 streamId 归一化去重（单批内 + 调用方传入合并后的整个列表，跨批同样生效）：
    // - 同 streamId 的多条「生成中(14)」只保留最新一条（机器人逐字推送，全部入库），
    //   多 agent 并发时多个不同 streamId 各自成组、互不折叠；
    // - 同 streamId 已有「已生成(15)」时，丢弃所有「生成中(14)」，只保留最终结果。
    private normalizeStreaming(messages: Message[]): Message[] {
        if (messages.length === 0) {
            return messages
        }
        // 第一遍：按 streamId 统计「已生成」是否存在、该组最后一条「生成中」的下标
        let streamIds: string[] = []
        let hasGenerated: boolean[] = []
        let lastGeneratingIndex: number[] = []
        for (let i = 0; i < messages.length; i++) {
            let m = messages[i]
            let type = m.messageContent.type
            let streamId = ''
            if (type === MessageContentType.Streaming_Text_Generating) {
                streamId = (m.messageContent as StreamingTextGeneratingMessageContent).streamId
            } else if (type === MessageContentType.Streaming_Text_Generated) {
                streamId = (m.messageContent as StreamingTextGeneratedMessageContent).streamId
            }
            if (!streamId) {
                continue
            }
            let idx = streamIds.indexOf(streamId)
            if (idx < 0) {
                streamIds.push(streamId)
                hasGenerated.push(false)
                lastGeneratingIndex.push(-1)
                idx = streamIds.length - 1
            }
            if (type === MessageContentType.Streaming_Text_Generated) {
                hasGenerated[idx] = true
            } else if (type === MessageContentType.Streaming_Text_Generating) {
                lastGeneratingIndex[idx] = i
            }
        }
        if (streamIds.length === 0) {
            return messages
        }
        // 第二遍：过滤重复的「生成中」
        let result: Message[] = []
        for (let i = 0; i < messages.length; i++) {
            let m = messages[i]
            if (m.messageContent.type === MessageContentType.Streaming_Text_Generating) {
                let streamId = (m.messageContent as StreamingTextGeneratingMessageContent).streamId
                let idx = streamIds.indexOf(streamId)
                if (hasGenerated[idx] || lastGeneratingIndex[idx] !== i) {
                    continue
                }
            }
            result.push(m)
        }
        return result
    }

    appendOrUpdateMessage(message: Message) {
        // 流式消息（14/15）：完全按 streamId 处理（见 applyStreamingMessage），同一流原地替换、
        // 不同流互不影响；其余消息走通用的 messageId 匹配追加/更新。
        let streamId = streamingStreamIdOf(message)
        if (streamId) {
            this.applyStreamingMessage(message, streamId)
            // 收到新消息追加/AI 流式消息更新后，把进行中的 AI 元素（流式生成中、
            // 进度卡、选择/审批卡等）钉回列表末尾
            this.pinLiveAIToBottom();
            return
        }
        let index = this.messages.findIndex(m => {
            return m.messageId > 0 && m.messageId === message.messageId
        });
        if (index >= 0) {
            this.messages[index] = message;
            this.notifyDataChange(index)
        } else {
            this.messages = this.messages.concat(message)
            this.notifyDataReload();
        }
        // 收到新消息追加/自己发送消息追加/AI 消息更新后，把进行中的 AI 元素（流式生成中、
        // 进度卡、选择/审批卡等）钉回列表末尾
        this.pinLiveAIToBottom();
    }

    // 多 agent（多机器人）流式消息更新：同一会话同一时刻可能有多个 streamId 各自在生成。
    // 语义（对齐 PC 端 vue 参考实现按「会话+streamId」处理）：
    // - 每个 streamId 在列表里最多一条气泡，14 逐字更新原地替换该流气泡（15/20 不影响其它流）；
    // - 15（完成）原地替换该流的 14 占位（若该流已完成且 15 已在列表，仅同 messageId 的重复 15 才更新）；
    // - 已完成（15 已展示）之后迟到的 14 片段直接丢弃，避免把最终结果回退成生成中；
    // - 收尾清理同 streamId 的其它残留气泡（如重开会话后列表里混入的旧 14 分片），自愈去重。
    private applyStreamingMessage(message: Message, streamId: string) {
        let incomingGenerated = message.messageContent.type === MessageContentType.Streaming_Text_Generated
        let existingGeneratedIndex = -1
        let existingGeneratingIndex = -1
        for (let i = this.messages.length - 1; i >= 0; i--) {
            let m = this.messages[i]
            if (streamingStreamIdOf(m) !== streamId) {
                continue
            }
            if (m.messageContent.type === MessageContentType.Streaming_Text_Generated && existingGeneratedIndex < 0) {
                existingGeneratedIndex = i
            } else if (m.messageContent.type === MessageContentType.Streaming_Text_Generating && existingGeneratingIndex < 0) {
                existingGeneratingIndex = i
            }
        }
        let keptIndex = -1
        if (incomingGenerated) {
            if (existingGeneratedIndex >= 0) {
                // 该流最终结果已在列表：只有 messageId 相同的重复 15 才原地更新，否则忽略不重复加泡
                let cur = this.messages[existingGeneratedIndex]
                if (cur.messageId > 0 && cur.messageId === message.messageId) {
                    this.messages[existingGeneratedIndex] = message
                    this.notifyDataChange(existingGeneratedIndex)
                    keptIndex = existingGeneratedIndex
                }
            } else if (existingGeneratingIndex >= 0) {
                this.messages[existingGeneratingIndex] = message
                this.notifyDataChange(existingGeneratingIndex)
                keptIndex = existingGeneratingIndex
            } else {
                this.messages = this.messages.concat(message)
                keptIndex = this.messages.length - 1
                this.notifyDataReload()
            }
        } else {
            // 生成中（14）：已完成（15 已展示）之后迟到的分片直接丢弃
            if (existingGeneratedIndex >= 0) {
                return
            }
            if (existingGeneratingIndex >= 0) {
                this.messages[existingGeneratingIndex] = message
                this.notifyDataChange(existingGeneratingIndex)
                keptIndex = existingGeneratingIndex
            } else {
                this.messages = this.messages.concat(message)
                keptIndex = this.messages.length - 1
                this.notifyDataReload()
            }
        }
        // 自愈：同一 streamId 的其它残留气泡（同流旧 14 分片等）全部移除，只保留刚更新的这条
        if (keptIndex >= 0) {
            let removed = 0
            for (let i = this.messages.length - 1; i >= 0; i--) {
                if (i === keptIndex) {
                    continue
                }
                if (streamingStreamIdOf(this.messages[i]) === streamId) {
                    this.messages.splice(i, 1)
                    removed++
                }
            }
            if (removed > 0) {
                this.notifyDataReload()
            }
        }
    }

    appendMessages(messages: Message[]) {
        // 尾部追加后同样对合并后的整个列表归一化去重，避免同 streamId 的旧/新分片跨批重复
        this.messages = this.messages.concat(messages)
        this.messages = this.normalizeStreaming(this.messages)
        this.notifyDataReload();
        this.pinLiveAIToBottom();
    }

    // 判断消息是否为"进行中的 AI 交互元素"（需要固定在列表最新位置）：
    // - 14 流式文本生成中（Streaming_Text_Generating）
    // - 200 提问卡（state=pending，等待用户选择）
    // - 202 审批卡（state=pending，等待用户审批）
    // （goal 206 / 任务 208 等其余消息按默认排序，不参与钉底）
    isLiveAIMessage(message: Message): boolean {
        let type = message.messageContent.type
        if (type === MessageContentType.Streaming_Text_Generating) {
            return true
        }
        if (type === CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_QUESTION) {
            return (message.messageContent as AgentQuestionMessageContent).content.state === 'pending'
        }
        if (type === CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_APPROVAL) {
            return (message.messageContent as AgentApprovalMessageContent).content.state === 'pending'
        }
        return false
    }

    // 进行中的 AI 交互元素（流式生成中、进度卡、选择/审批卡等）固定在列表最新位置（视觉最底部）。
    // 生成/等待期间用户自己发消息、或其它消息插入/更新，都可能把它们顶到中间；
    // 这里在每次列表变更后把所有"进行中的 AI 元素"移到数组末尾（保持它们之间以及
    // 其余消息的相对顺序），顺序未变则不动。移动后整体刷新 LazyForEach。
    pinLiveAIToBottom(): void {
        if (this.messages.length <= 1) {
            return
        }
        let live: Message[] = []
        let rest: Message[] = []
        for (let m of this.messages) {
            if (this.isLiveAIMessage(m)) {
                live.push(m)
            } else {
                rest.push(m)
            }
        }
        if (live.length === 0) {
            return
        }
        // 已是末尾连续一段（顺序未变）则无需移动/刷新
        let tailStart = this.messages.length - live.length
        let unchanged = true
        for (let i = 0; i < live.length; i++) {
            if (this.messages[tailStart + i] !== live[i]) {
                unchanged = false
                break
            }
        }
        if (unchanged) {
            return
        }
        this.messages = rest.concat(live)
        this.notifyDataReload()
    }

    // 取消消息（20）：按 streamId 从消息列表删除对应的生成中(14)/已生成(15)消息，
    // 界面上的"生成中/已生成"气泡直接消失。只影响被取消的这一条 stream——
    // 同会话其它 agent 仍在生成的 14 不受影响（按各自 streamId 继续更新）。
    // 同一 stream 若存在多条残留气泡（重开会话混入的旧分片等）一并移除。
    removeStreamingMessageByStreamId(streamId: string) {
        let removed: number[] = []
        for (let i = 0; i < this.messages.length; i++) {
            let m = this.messages[i]
            if ((m.messageContent.type === MessageContentType.Streaming_Text_Generating
                || m.messageContent.type === MessageContentType.Streaming_Text_Generated)
                && (m.messageContent as StreamingTextGeneratingMessageContent).streamId === streamId) {
                removed.push(i)
            }
        }
        if (removed.length === 0) {
            return
        }
        if (removed.length === 1) {
            this.messages.splice(removed[0], 1)
            this.notifyDataDelete(removed[0])
        } else {
            for (let i = removed.length - 1; i >= 0; i--) {
                this.messages.splice(removed[i], 1)
            }
            this.notifyDataReload()
        }
    }

    removeMessageById(messageId: number) {
        let index = this.messages.findIndex(msg => msg.messageId === messageId);
        if (index >= 0) {
            this.messages.splice(index, 1)
            this.notifyDataDelete(index)
        }
    }

    removeMessageByUid(messageUid: Long) {
        let index = this.messages.findIndex(msg => eq(msg.messageUid, messageUid));
        if (index >= 0) {
            this.messages.splice(index, 1)
            this.notifyDataDelete(index)
        }
    }

    // Mark a message as played on the source-of-truth object, by stable messageId.
    // Deliberately does NOT call notifyDataChange: status is part of the LazyForEach key, so a
    // notify would change the key and recreate the currently-playing item (killing its animation).
    // The dataSource object is updated so any later rebuild reads the correct (Played) status and
    // the red dot does not reappear.
    markMessagePlayed(messageId: number) {
        let index = this.messages.findIndex(msg => msg.messageId === messageId);
        if (index >= 0) {
            this.messages[index].status = MessageStatus.Played;
        }
    }

    updateMessage(message: Message) {
        if (message.messageId !== 0) {
            let index = this.messages.findIndex(msg => msg.messageId === message.messageId);
            if (index >= 0) {
                this.messages[index] = message;
                this.notifyDataChange(index);
                // 消息更新/状态更新后，若进行中的 AI 元素（流式生成中、进度卡、选择/审批卡等）
                // 被顶到中间，移回列表末尾
                this.pinLiveAIToBottom();
            }
        }
    }

    public totalCount(): number {
        return this.messages.length
    }

    public getData(index: number): Message {
        return this.messages[index]
    }
}
