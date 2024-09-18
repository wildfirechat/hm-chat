import wfc from '../../wfc/client/wfc'
import ConversationInfo from '../../wfc/model/conversationInfo'
import ConversationType from '../../wfc/model/conversationType'

import Message from '../../wfc/messages/message'
import { eq } from '../../wfc/util/longUtil'
import EventType from '../../wfc/client/wfcEvent'
import Conversation from '../../wfc/model/conversation'
import MessageContentType from '../../wfc/messages/messageContentType'
import NormalMessageContentView from './message/NormalMessageContentView'
import ConversationInputPanelView from './ConversationInputPanelView'
import AudioPlayManager from './audio/AudioPlayManager'
import AudioRecorderView from './audio/AudioRecorderView'
import NotificationMessageContent from '../../wfc/messages/notification/notificationMessageContent'
import SimpleNotificationMessageContentView from './message/SimpleNotificationMessageContentView'
import { timeFormat } from '../../util/helper'
import Long from '../../wfc/util/long'
import ReadEntry from '../../wfc/model/readEntry'
import ReadReceipt from './model/readReceipt'
import GroupMember from '../../wfc/model/groupMember'
import { showToast } from '../../common/utils/Toast'
import Utils from '../../common/Utils'
import { HashMap } from '@kit.ArkTS'
import BasicDataSource from '../../common/BasicDataSource'
import UserInfo from '../../wfc/model/userInfo'
import GroupInfo from '../../wfc/model/groupInfo'
import ChannelInfo from '../../wfc/model/channelInfo'
import { navigationDestinations } from '../navigationConfig'
import TestCustomNotificationMessageContent from '../../wfc_custom_message/testCustomNotificationMessageContent'
import TestCustomMessageContentView from './custom_message/testCustomMessageContentView'
import TestCustomNotificationMessageContentView from './custom_message/TestCustomNotificationMessageContentView'
import UserOnlineState from '../../wfc/model/userOnlineState'

@Entry
@Component
export default struct ConversationPage {
    @State text: string = ''
    @State title: string = ''
    @State conversation?: Conversation = undefined
    @State conversationInfo?: ConversationInfo = undefined
    @State refreshStatus: boolean = false;
    @State refreshText: Resource = $r('app.string.refresh_text')
    @State hasNoMoreHistoryMessage: boolean = false
    // for audioRecorderView
    @State showAudioRecorderView: boolean = false
    @State showCancelRecordIndicator: boolean = false
    @State recordCountDown: number = 0
    @State readEntries: Map<string, number> = new Map();
    @State collapseConversationInputPanelViewTimestamp: number = 0
    @State enableMultiCheck: boolean = false
    @State checkedMessages: Message[] = []
    @State @Watch('onQuoteMessage') quotedMessage: Message | null = null
    private focusMessageId: number = 0
    private checkValueChangeTriggerByClick = false
    private scroller: Scroller = new Scroller()
    private touchDownOffsetY: number = 0
    private currentMessageIndex: number = 0
    private unreadStatusCleared: boolean = false
    private timer: number = 0
    private audioPlayerManager: AudioPlayManager = new AudioPlayManager()
    private enableReceipt: boolean = false
    private enableGroupReceipt: boolean = false
    @State groupMembers: GroupMember[] = []
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private conversationMessageDataSource: ConversationMessageDataSource = new ConversationMessageDataSource()
    @State focusMessageBackgroundColor: Color = Color.Green
    @State showGroupMemberNickName: boolean = false

    aboutToAppear() {
        this.audioPlayerManager.init(getContext(this))

        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let conversation = params['conversation'] as Conversation;
        let title = params['title'] as string;
        this.focusMessageId = params['focusMessageId'] as number
        this.setupConversation(conversation, title);

        wfc.eventEmitter!.on(EventType.SendMessage, this.onSendMessage)
        wfc.eventEmitter!.on(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter!.on(EventType.DeleteMessage, this.onDeleteMessage)
        wfc.eventEmitter!.on(EventType.MessageDeleted, this.onRemoteDeleteMessage)
        wfc.eventEmitter!.on(EventType.RecallMessage, this.onRecallMessage)
        wfc.eventEmitter!.on(EventType.MessageRead, this.onReadMessage)
        wfc.eventEmitter!.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        wfc.eventEmitter!.on(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter!.on(EventType.ChannelInfosUpdate, this.onChannelInfosUpdate)
        wfc.eventEmitter!.on(EventType.ConversationInfoUpdate, this.onConversationInfoUpdate)

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
        this.audioPlayerManager.release()

        wfc.eventEmitter!.off(EventType.SendMessage, this.onSendMessage)
        wfc.eventEmitter!.off(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter!.off(EventType.DeleteMessage, this.onDeleteMessage)
        wfc.eventEmitter!.on(EventType.MessageDeleted, this.onRemoteDeleteMessage)
        wfc.eventEmitter!.off(EventType.RecallMessage, this.onRecallMessage)
        wfc.eventEmitter!.off(EventType.MessageRead, this.onReadMessage)
        if (this.conversation!.type === ConversationType.Group) {
            wfc.eventEmitter!.off(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
        } else if (this.conversation!.type === ConversationType.ChatRoom) {
            wfc.quitChatroom(this.conversation!.target, null, null)
        }
        wfc.eventEmitter!.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        wfc.eventEmitter!.off(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter!.off(EventType.ChannelInfosUpdate, this.onChannelInfosUpdate)
        wfc.eventEmitter!.off(EventType.ConversationInfoUpdate, this.onConversationInfoUpdate)

        this.unwatchOnlineState(this.conversation!)
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
    }

    setupConversation(conversation: Conversation, title: string) {
        if (this.conversation) {
            this.unwatchOnlineState(this.conversation!)
        }

        this.conversation = conversation;

        this.conversationInfo = wfc.getConversationInfo(this.conversation)
        this.readEntries = wfc.getConversationRead(this.conversation)
        this.enableReceipt = wfc.isReceiptEnabled() && wfc.isUserReceiptEnabled()
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

                this.scroller.scrollEdge(Edge.Bottom)
            }, err => {
                console.error('getMessageV2 error', err)
            })
        }

        if (this.conversation.type === ConversationType.Group) {
            wfc.eventEmitter!.on(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
            this.showGroupMemberNickName = !wfc.isHiddenGroupMemberName(this.conversation.target)
        }
    }

    loadHistoryMessage() {
        let oldestMessageId = 0;
        let oldestMessageUid = Long.ZERO
        if (this.conversationMessageDataSource.totalCount() > 0) {
            let oldestMsg = this.conversationMessageDataSource.getData(0)
            oldestMessageId = oldestMsg.messageId
            oldestMessageUid = oldestMsg.messageUid
        }
        wfc.getMessagesV2(this.conversation!, oldestMessageId, true, 20, '', (messages) => {
            if (messages.length === 0) {
                wfc.loadRemoteConversationMessages(this.conversation!, [], oldestMessageUid, 20, msgs => {
                    if (msgs.length === 0) {
                        this.hasNoMoreHistoryMessage = true
                    } else {
                        this.conversationMessageDataSource.insertMessages(0, msgs)
                        this.scroller.scrollToIndex(msgs.length - 1, false)
                    }
                    this.refreshStatus = false;
                }, err => {
                    this.hasNoMoreHistoryMessage = true
                    this.refreshStatus = false;
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

    showUserInfo(userId: string) {
        this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, {
            'userInfo': wfc.getUserInfo(userId)
        } as Record<string, Object>)
    }

    isDisplayMessage(message: Message) {
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
            this.conversationMessageDataSource.appendMessages([message]);
            this.scroller.scrollEdge(Edge.Bottom)
        }
    }
    onReceiveMessage = (message: Message, hasMore: boolean) => {
        this.unreadStatusCleared = false
        if (this.isDisplayMessage(message) && Conversation.equal(message.conversation, this.conversation!)) {
            this.conversationMessageDataSource.appendMessages([message]);
            this.scroller.scrollEdge(Edge.Bottom)
        }
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
        console.log('xxxx onReadMessage')
    }
    onUserInfosUpdate = (userInfos: UserInfo[]) => {
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
        if (!conversationInfo.lastMessage) {
            this.conversationMessageDataSource.setMessages([])
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

        let key: string = message.messageContent.type + '-' + message.messageId + '-' + message.status
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

    conversationInfoPageName(): string {
        let name: string = ''
        switch (this.conversation!.type) {
            case ConversationType.Single:
                name = navigationDestinations.SingleConversationInfoPage
                break
            case ConversationType.Group:
                name = navigationDestinations.GroupConversationInfoPage
                break
            case ConversationType.Channel:
                name = navigationDestinations.ChannelConversationInfoPage
                break
            default:
                break
        }
        return name
    }

    build() {
        NavDestination() {
            Scroll() {
                Stack() {
                    Refresh({ refreshing: $$this.refreshStatus }) {
                        Column() {
                            if (this.hasNoMoreHistoryMessage) {
                                Text('没有更多消息')
                                    .padding(5)
                                    .fontSize(13)
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
                                                    else {
                                                        SimpleNotificationMessageContentView({ message: msg })
                                                    }
                                                }
                                                .width('100%')
                                                .justifyContent(FlexAlign.Center)

                                                // out
                                            } else if (msg.direction === 0) {
                                                Column() {
                                                    if (this.showMessageTimeInfo(index)) {
                                                        Text(timeFormat(msg.timestamp))
                                                            .fontSize(12)
                                                            .fontColor('#b4b4b4')
                                                            .padding(10)
                                                    }
                                                    Row() {
                                                        if (this.enableMultiCheck) {
                                                            Row() {
                                                                Checkbox()
                                                                    .select(this.isMessageChecked(msg))
                                                                    .margin({ left: 10 })
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
                                                            .margin({ top: 10 })
                                                            .height(40)
                                                            .alignItems(VerticalAlign.Center)
                                                        }
                                                        Row() {
                                                            NormalMessageContentView({
                                                                message: msg,
                                                                enableMultiCheck: $enableMultiCheck,
                                                                quotedMessage: $quotedMessage,
                                                                audioPlayManager: this.audioPlayerManager,
                                                                enableReceipt: this.enableReceipt,
                                                                readEntries: this.readEntries,
                                                                groupMembers: this.groupMembers
                                                            })//.layoutWeight(1)
                                                                .margin({ top: 10 })
                                                                .enabled(!this.enableMultiCheck)
                                                        }
                                                        .justifyContent(FlexAlign.End)
                                                        .layoutWeight(1)
                                                        .margin({ left: 70 })

                                                        Image(wfc.getUserInfo(msg.from).portrait)
                                                            .width(40)
                                                            .height(40)
                                                            .borderRadius(4)
                                                            .margin(10)
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
                                                            .fontSize(12)
                                                            .fontColor('#b4b4b4')
                                                            .padding(10)
                                                    }
                                                    Row() {
                                                        if (this.enableMultiCheck) {
                                                            Row() {
                                                                Checkbox()
                                                                    .select(this.isMessageChecked(msg))
                                                                    .margin({ left: 10 })
                                                                    .onChange((value => {
                                                                        if (this.checkValueChangeTriggerByClick) {
                                                                            this.checkValueChangeTriggerByClick = false
                                                                            return
                                                                        }
                                                                        this.checkOrUncheckMessage(msg)
                                                                    }))
                                                            }
                                                            .margin({ top: 10 })
                                                            .height(40)
                                                            .alignItems(VerticalAlign.Center)

                                                            // .alignSelf(ItemAlign.Center)
                                                        }
                                                        Image(wfc.getUserInfo(msg.from).portrait)
                                                            .width(40)
                                                            .height(40)
                                                            .margin(10)
                                                            .borderRadius(4)
                                                            .enabled(!this.enableMultiCheck)
                                                            .onClick(() => {
                                                                this.showUserInfo(msg.from)
                                                            })
                                                        Column() {
                                                            if (this.showGroupMemberNickName) {
                                                                Text(wfc.getGroupMemberDisplayName(this.conversation!.target, msg.from))
                                                                    .fontSize(12)
                                                                    .padding({ bottom: 2 })
                                                            }
                                                            NormalMessageContentView({
                                                                message: msg,
                                                                enableMultiCheck: $enableMultiCheck,
                                                                quotedMessage: $quotedMessage,
                                                                audioPlayManager: this.audioPlayerManager
                                                            })//.layoutWeight(1)
                                                                .enabled(!this.enableMultiCheck)
                                                        }
                                                        .justifyContent(FlexAlign.Start)
                                                        .alignItems(HorizontalAlign.Start)
                                                        .layoutWeight(1)
                                                        .margin({ right: 70, top: 10 })
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

                    if (this.showAudioRecorderView) {
                        AudioRecorderView({
                            showAudioRecorderView: $showAudioRecorderView,
                            showCancelRecordIndicator: $showCancelRecordIndicator,
                            recordCountDown: $recordCountDown
                        })
                            .width('100%')
                            .height('100%')
                            .backgroundColor('#A0E5E5E5')
                    }
                }
                .height('100%')
                .width('100%')
                .alignContent(Alignment.Center)
            }
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('#F3F3F3')
            .onTouch((event?: TouchEvent) => {
                this.collapseConversationInputPanelViewTimestamp = new Date().getTime()
            })

            if (this.conversation) {
                ConversationInputPanelView({
                    conversation: this.conversation,
                    conversationInfo: this.conversationInfo,
                    showAudioRecorderView: $showAudioRecorderView,
                    showCancelRecordIndicator: $showCancelRecordIndicator,
                    recordCountDown: $recordCountDown,
                    enableMultiCheck: $enableMultiCheck,
                    checkedMessages: $checkedMessages,
                    quotedMessage: $quotedMessage,
                    collapseConversationInputPanelViewTimestamp: $collapseConversationInputPanelViewTimestamp,
                    messageListScroller: this.scroller
                })
            }

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
        .mode(NavDestinationMode.STANDARD)
        .title(this.title)
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
    }
}

class ConversationMessageDataSource extends BasicDataSource<Message> {
    private messages: Message[] = []

    setMessages(messages: Message[]): void {
        this.messages = messages
        this.notifyDataReload()
    }

    insertMessages(index: number, messages: Message[]) {
        this.messages.splice(0, 0, ...messages)
        this.notifyDataReload();
    }

    appendMessages(messages: Message[]) {
        this.messages = this.messages.concat(messages)
        this.notifyDataReload();
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

    updateMessage(message: Message) {
        if (message.messageId !== 0) {
            let index = this.messages.findIndex(msg => msg.messageId === message.messageId);
            if (index >= 0) {
                this.messages[index] = message;
                this.notifyDataChange(index);
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
