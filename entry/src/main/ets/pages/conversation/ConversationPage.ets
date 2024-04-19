import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'

import wfc from '../../wfc/client/wfc'
import router from '@ohos.router'
import ConversationInfo from '../../wfc/model/conversationInfo'
import GroupInfo from '../../wfc/model/groupInfo'
import ChannelInfo from '../../wfc/model/channelInfo'
import ConversationType from '../../wfc/model/conversationType'
import ChatRoomInfo from '../../wfc/model/chatRoomInfo'

import PutDownRefresh from '../../view/PutDownRefreshLayout';
import Message from '../../wfc/messages/message'
import { eq, stringValue } from '../../wfc/util/longUtil'
import TextMessageContent from '../../wfc/messages/textMessageContent'
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
import UserInfo from '../../wfc/model/userInfo'
import Utils from '../../common/Utils'
import { FaultLogger } from '@kit.PerformanceAnalysisKit'
import { HashMap } from '@kit.ArkTS'

@Entry
@Component
struct ConversationPage {
    @State text: string = ''
    @State title: string = ''
    @State conversation?: Conversation = undefined
    @State conversationInfo?: ConversationInfo = undefined
    @State refreshStatus: boolean = false;
    @State refreshText: Resource = $r('app.string.refresh_text')
    @State messages: Message[] = []
    @State hasNoMoreHistoryMessage: boolean = false
    // for audioRecorderView
    @State showAudioRecorderView: boolean = false
    @State showCancelRecordIndicator: boolean = false
    @State recordCountDown: number = 0
    @State readEntries: HashMap<string, number> = new HashMap();
    @State collapseConversationInputPanelViewTimestamp: number = 0
    @State enableMultiCheck: boolean = false
    @State checkedMessages: Message[] = []
    private checkValueChangeTriggerByClick = false
    private scroller: Scroller = new Scroller()
    private touchDownOffsetY: number = 0
    private currentMessageIndex: number = 0
    private timer: number = 0
    private audioPlayerManager: AudioPlayManager = new AudioPlayManager()
    private enableReceipt: boolean = false
    private enableGroupReceipt: boolean = false
    private groupMembers: GroupMember[] = []

    putDownRefresh(event?: TouchEvent): void {
        if (event === undefined) {
            return;
        }
        switch (event.type) {
            case TouchType.Down:
                this.touchDownOffsetY = event.touches[0].y;
                break;
            case TouchType.Move:
                this.refreshStatus = (this.messages.length === 0 || this.currentMessageIndex === 0) && event.touches[0].y - this.touchDownOffsetY > 100;
                break;
            case TouchType.Cancel:
                break;
            case TouchType.Up:
                this.touchDownOffsetY = event.touches[0].y

                if (this.refreshStatus) {
                    this.loadHistoryMessage()
                }
                break;
        }
    }

    aboutToAppear() {

        setTimeout(() => {
            this.scroller.scrollEdge(Edge.Bottom)
        }, 100)
        this.audioPlayerManager.init(getContext(this))

        const params = router.getParams() as Record<string, Object>;
        this.title = params['title'] as string;
        this.conversation = params['conversation'] as Conversation;
        this.conversationInfo = wfc.getConversationInfo(this.conversation)
        this.readEntries = wfc.getConversationRead(this.conversation)
        this.enableReceipt = wfc.isReceiptEnabled() && wfc.isUserReceiptEnabled()
        this.enableGroupReceipt = wfc.isGroupReceiptEnabled()

        if (this.conversation.type === ConversationType.Group) {
            this.groupMembers = wfc.getGroupMembers(this.conversation.target, false);
        }

        Utils.computeConversationItemPortraitAndName(this.conversation)
            .then(value => {
                this.title = value.name
            })

        wfc.getMessagesV2(this.conversation, 0, true, 20, '', (messages) => {
            this.messages = messages;
        }, err => {
            console.error('getMessageV2 error', err)
        })

        getContext(this).eventHub.on(EventType.SendMessage, this.onSendMessage)
        getContext(this).eventHub.on(EventType.ReceiveMessage, this.onReceiveMessage)
        getContext(this).eventHub.on(EventType.DeleteMessage, this.onDeleteMessage)
        getContext(this).eventHub.on(EventType.MessageDeleted, this.onRemoteDeleteMessage)
        getContext(this).eventHub.on(EventType.RecallMessage, this.onRecallMessage)
        getContext(this).eventHub.on(EventType.MessageRead, this.onReadMessage)
        if (this.conversation.type === ConversationType.Group) {
            getContext(this).eventHub.on(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
        }
    }

    aboutToDisappear() {
        clearTimeout(this.timer);
        this.audioPlayerManager.release()

        getContext(this).eventHub.off(EventType.SendMessage, this.onSendMessage)
        getContext(this).eventHub.off(EventType.ReceiveMessage, this.onReceiveMessage)
        getContext(this).eventHub.off(EventType.DeleteMessage, this.onDeleteMessage)
        getContext(this).eventHub.on(EventType.MessageDeleted, this.onRemoteDeleteMessage)
        getContext(this).eventHub.off(EventType.RecallMessage, this.onRecallMessage)
        getContext(this).eventHub.off(EventType.MessageRead, this.onReadMessage)
        if (this.conversation!.type === ConversationType.Group) {
            getContext(this).eventHub.off(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
        }
    }

    loadHistoryMessage() {
        let oldestMessageId = 0;
        if (this.messages.length > 0) {
            oldestMessageId = this.messages[0].messageId
        }
        wfc.getMessagesV2(this.conversation!, oldestMessageId, true, 20, '', (messages) => {
            this.messages = messages.concat(...this.messages);
            this.refreshStatus = false;
            this.scroller.scrollToIndex(messages.length - 1)
            if (messages.length === 0) {
                this.hasNoMoreHistoryMessage = true
            }
        }, err => {
            console.error('getMessageV2 error', err)
            this.refreshStatus = false;
        })
    }

    showUserInfo(userId: string) {
        router.pushUrl({
            url: 'pages/user/UserInfoPage',
            params: {
                userInfo: wfc.getUserInfo(userId)
            }
        })

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

    onSendMessage = (message: Message) => {
        let conversation = new Conversation(message.conversation.type, message.conversation.target, message.conversation.line)
        if (this.isDisplayMessage(message) && Conversation.equal(conversation, this.conversation!)) {
            this.messages.push(message);
            this.scroller.scrollEdge(Edge.Bottom)
        }
    }
    onReceiveMessage = (message: Message, hasMore: boolean) => {
        if (this.isDisplayMessage(message) && Conversation.equal(message.conversation, this.conversation!)) {
            this.messages.push(message);
            this.scroller.scrollEdge(Edge.Bottom)
        }
    }
    onDeleteMessage = (messageId: number) => {
        this.messages = this.messages.filter(msg => msg.messageId !== messageId)
        console.log('onDeleteMessage', messageId)
    }
    onRemoteDeleteMessage = (messageUid: Long) => {
        this.messages = this.messages.filter(msg =>!eq(msg.messageUid, messageUid))
        console.log('onRemoteDeleteMessage', messageUid)
    }
    onRecallMessage = (operator: string, messageUid: Long) => {
        //this.messages = this.messages.filter(msg =>!eq(msg.messageUid, messageUid))
        let index = this.messages.findIndex(msg => eq(msg.messageUid, messageUid))
        if (index >= 0) {
            let msg = wfc.getMessageByUid(messageUid)
            this.messages[index] = msg!
        }
        console.log('onRecallMessage', messageUid)
    }
    onReadMessage = (readEntries: ReadEntry[]) => {
        this.readEntries = wfc.getConversationRead(this.conversation!);
    }
    onGroupMembersUpdate = (groupId: string, groupMembers: GroupMember[]) => {
        if (groupId === this.conversation!.target) {
            this.groupMembers = wfc.getGroupMembers(groupId, false);
        }
    }

    showMessageTimeInfo(index: number) {
        // index 值，可能为 length
        if (index < 0 || index >= this.messages.length) {
            return false
        }
        if (index === 0) {
            return true
        } else {
            let preMsg = this.messages[index -1];
            let curMsg = this.messages[index]

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
        if (this.enableReceipt && this.readEntries && this.readEntries.length > 0) {
            if (this.conversation!.type === ConversationType.Group) {
                if (this.enableGroupReceipt) {
                    // TODO
                }
            } else if (this.conversation!.type === ConversationType.Single) {
                // TODO
                let readDt: number = this.readEntries.get(this.conversation!.target)
                if (readDt >= message.timestamp) {
                    key += '-1'
                } else {
                    key += '-0'
                }
            }
        }
        return key
    }

    messageReadReceipt(message: Message): ReadReceipt | null {
        if (!this.enableReceipt) {
            return null
        }
        if (message.conversation.type === ConversationType.Single) {
            let readReceipt: ReadReceipt = new ReadReceipt()
            readReceipt.conversationType = ConversationType.Single
            if (this.readEntries.length > 0) {
                //let readDt = this.readEntries[0].value
                let readDt = this.readEntries.get(message.conversation.target)
                if (readDt >= message.timestamp) {
                    readReceipt.readCount = 1
                    readReceipt.unreadCount = 0
                }
            } else {
                readReceipt.readCount = 0
                readReceipt.unreadCount = 0
            }
            return readReceipt
        } else if (message.conversation.type === ConversationType.Group) {
            let readReceipt: ReadReceipt = new ReadReceipt()
            readReceipt.conversationType = ConversationType.Group

            let readCount = 0
            this.readEntries.forEach(readDt => {
                if (readDt! >= message.timestamp) {
                    readCount++
                }
            })
            readReceipt.readCount = readCount
            let groupMembersJoinBeforeMessage = this.groupMembers.filter(member => member.createDt < message.timestamp)
            readReceipt.unreadCount = groupMembersJoinBeforeMessage.length - readCount
            return readReceipt
        }
        return null
    }

    conversationInfoPageUrl(): string {
        let url: string = ''
        switch (this.conversation!.type) {
            case ConversationType.Single:
                url = 'pages/conversation/SingleConversationInfoPage'
                break
            case ConversationType.Group:
                url = 'pages/conversation/GroupConversationInfoPage'
                break
            case ConversationType.Channel:
                url = 'pages/conversation/ChannelConversationInfoPage'
                break
            default:
                break
        }
        return url
    }

    build() {
        Navigation() {
            Scroll() {
                Stack() {
                    Column() {
                        if (this.refreshStatus) {
                            PutDownRefresh({ refreshText: $refreshText })
                        }
                        if (this.hasNoMoreHistoryMessage) {
                            Text('没有更多消息')
                                .padding(5)
                                .fontSize(13)
                        }

                        Blank()
                            .width('100%')
                            .layoutWeight(1)

                        List({ scroller: this.scroller }) {
                            ForEach(this.messages,
                                (msg: Message, index: number) => {
                                    ListItem() {
                                        if (msg.messageContent instanceof NotificationMessageContent) {
                                            Row() {
                                                SimpleNotificationMessageContentView({ message: msg })
                                            }
                                            .width('100%')
                                            .justifyContent(FlexAlign.Center)

                                            // out
                                        } else if (msg.direction === 0) {
                                            Column() {
                                                if (this.showMessageTimeInfo(index)) {
                                                    Text(timeFormat(msg.timestamp))
                                                        .fontSize(12)
                                                        .padding(10)
                                                }
                                                Row() {
                                                    if (this.enableMultiCheck) {
                                                        Row() {
                                                            Checkbox()
                                                                .select(this.isMessageChecked(msg))
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
                                                        .height(48)
                                                        .alignItems(VerticalAlign.Center)
                                                    }
                                                    Row() {
                                                        NormalMessageContentView({
                                                            message: msg,
                                                            enableMultiCheck: $enableMultiCheck,
                                                            audioPlayManager: this.audioPlayerManager,
                                                            readReceipt: this.messageReadReceipt(msg)
                                                        })//.layoutWeight(1)
                                                            .margin({ top: 10 })
                                                            .enabled(!this.enableMultiCheck)
                                                    }
                                                    .justifyContent(FlexAlign.End)
                                                    .layoutWeight(1)
                                                    .margin({ left: 70 })

                                                    Image(wfc.getUserInfo(msg.from).portrait)
                                                        .width(48)
                                                        .height(48)
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
                                                        .padding(10)
                                                }
                                                Row() {
                                                    if (this.enableMultiCheck) {
                                                        Row() {
                                                            Checkbox()
                                                                .select(this.isMessageChecked(msg))
                                                                .onChange((value => {
                                                                    if (this.checkValueChangeTriggerByClick) {
                                                                        this.checkValueChangeTriggerByClick = false
                                                                        return
                                                                    }
                                                                    this.checkOrUncheckMessage(msg)
                                                                }))
                                                        }
                                                        .margin({ top: 10 })
                                                        .height(48)
                                                        .alignItems(VerticalAlign.Center)

                                                        // .alignSelf(ItemAlign.Center)
                                                    }
                                                    Image(wfc.getUserInfo(msg.from).portrait)
                                                        .width(48)
                                                        .height(48)
                                                        .margin(10)
                                                        .borderRadius(4)
                                                        .enabled(!this.enableMultiCheck)
                                                        .onClick(() => {
                                                            this.showUserInfo(msg.from)
                                                        })
                                                    Row() {
                                                        NormalMessageContentView({
                                                            message: msg,
                                                            enableMultiCheck: $enableMultiCheck,
                                                            audioPlayManager: this.audioPlayerManager
                                                        })//.layoutWeight(1)
                                                            .margin({ top: 10 })
                                                            .enabled(!this.enableMultiCheck)
                                                    }
                                                    .justifyContent(FlexAlign.Start)
                                                    .layoutWeight(1)
                                                    .margin({ right: 70 })
                                                }
                                                .width('100%')
                                                .justifyContent(FlexAlign.Start)
                                                .alignItems(VerticalAlign.Top)
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
                        .onScrollIndex((star, end) => {
                            this.currentMessageIndex = star;
                        })
                        .listDirection(Axis.Vertical)
                        .width('100%')

                    }
                    .justifyContent(FlexAlign.End)
                    .width('100%')
                    .height('100%')

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
                this.putDownRefresh(event);
                this.collapseConversationInputPanelViewTimestamp = new Date().getTime()
            })

            if (this.conversation) {
                ConversationInputPanelView({
                    conversation: $conversation,
                    showAudioRecorderView: $showAudioRecorderView,
                    showCancelRecordIndicator: $showCancelRecordIndicator,
                    recordCountDown: $recordCountDown,
                    enableMultiCheck: $enableMultiCheck,
                    messages: $messages,
                    checkedMessages: $checkedMessages,
                    collapseConversationInputPanelViewTimestamp: $collapseConversationInputPanelViewTimestamp,
                    messageListScroller: this.scroller
                })
            }
        }
        .title(this.title)
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
        .menus([
            {
                value: '',
                icon: "common/image/ic_session_info.png",
                action: () => {
                    let url = this.conversationInfoPageUrl()
                    if (url) {
                        router.pushUrl({
                            url: url,
                            params: {
                                conversationInfo: this.conversationInfo
                            }
                        }, router.RouterMode.Standard)
                    } else {
                        showToast('not implement')
                    }
                }
            }
        ])
    }
}