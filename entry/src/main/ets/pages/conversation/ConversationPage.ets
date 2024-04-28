import wfc from '../../wfc/client/wfc'
import ConversationInfo from '../../wfc/model/conversationInfo'
import ConversationType from '../../wfc/model/conversationType'

import PutDownRefresh from '../../view/PutDownRefreshLayout'
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
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private conversationMessageDataSource: ConversationMessageDataSource = new ConversationMessageDataSource()

    putDownRefresh(event?: TouchEvent): void {
        if (event === undefined) {
            return;
        }
        switch (event.type) {
            case TouchType.Down:
                this.touchDownOffsetY = event.touches[0].y;
                break;
            case TouchType.Move:
                this.refreshStatus = (this.conversationMessageDataSource.totalCount() === 0 || this.currentMessageIndex === 0) && event.touches[0].y - this.touchDownOffsetY > 100;
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
        this.audioPlayerManager.init(getContext(this))

        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let conversation = params['conversation'] as Conversation;
        let title = params['title'] as string;
        this.setupConversation(conversation, title);

        wfc.eventEmitter!.on(EventType.SendMessage, this.onSendMessage)
        wfc.eventEmitter!.on(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter!.on(EventType.DeleteMessage, this.onDeleteMessage)
        wfc.eventEmitter!.on(EventType.MessageDeleted, this.onRemoteDeleteMessage)
        wfc.eventEmitter!.on(EventType.RecallMessage, this.onRecallMessage)
        wfc.eventEmitter!.on(EventType.MessageRead, this.onReadMessage)
    }

    // navigation 导航时，声明周期回调并不会回调次方法
    // 可通过 NavDestination.onShow 触发
    onPageShow(): void {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (!params) {
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
    }

    setupConversation(conversation: Conversation, title: string) {
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

        if (!title) {
            Utils.computeConversationItemPortraitAndName(this.conversation)
                .then(value => {
                    this.title = value.name
                })
        } else {
            this.title = title;
        }

        wfc.getMessagesV2(this.conversation, 0, true, 20, '', (messages) => {
            this.conversationMessageDataSource.setMessages(messages);

            this.scroller.scrollEdge(Edge.Bottom)
        }, err => {
            console.error('getMessageV2 error', err)
        })

        if (this.conversation.type === ConversationType.Group) {
            wfc.eventEmitter!.on(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
        }
    }

    loadHistoryMessage() {
        let oldestMessageId = 0;
        if (this.conversationMessageDataSource.totalCount() > 0) {
            oldestMessageId = this.conversationMessageDataSource.getData(0).messageId
        }
        wfc.getMessagesV2(this.conversation!, oldestMessageId, true, 20, '', (messages) => {
            this.conversationMessageDataSource.insertMessages(0, messages)
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
        this.mainNavPathStack.pushPathByName('userInfoPage', {
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

    onSendMessage = (message: Message) => {
        let conversation = new Conversation(message.conversation.type, message.conversation.target, message.conversation.line)
        if (this.isDisplayMessage(message) && Conversation.equal(conversation, this.conversation!)) {
            this.conversationMessageDataSource.appendMessages([message]);
            this.scroller.scrollEdge(Edge.Bottom)
        }
    }
    onReceiveMessage = (message: Message, hasMore: boolean) => {
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

    conversationInfoPageName(): string {
        let name: string = ''
        switch (this.conversation!.type) {
            case ConversationType.Single:
                name = 'singleConversationInfo'
                break
            case ConversationType.Group:
                name = 'groupConversationInfo'
                break
            case ConversationType.Channel:
                name = 'channelConversationInfo'
                break
            default:
                break
        }
        return name
    }

    build() {
        NavDestination() {
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
                                LazyForEach(this.conversationMessageDataSource,
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
                                if (end == this.conversationMessageDataSource.totalCount() - 1) {
                                    // wfc.clearUnreadStatusBeforeMessage(this.conversation, )
                                    wfc.clearConversationUnreadStatus(this.conversation!);
                                }
                            })
                            .listDirection(Axis.Vertical)
                            .height('100%')
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
                        checkedMessages: $checkedMessages,
                        collapseConversationInputPanelViewTimestamp: $collapseConversationInputPanelViewTimestamp,
                        messageListScroller: this.scroller
                    })
                }
            }
            .title(this.title)
            .titleMode(NavigationTitleMode.Mini)
            .hideBackButton(false)
            .menus([
                {
                    value: '',
                    icon: "common/image/ic_session_info.png",
                    action: () => {
                        this.mainNavPathStack.pushPathByName(this.conversationInfoPageName(), {
                            'conversationInfo': this.conversationInfo
                        } as Record<string, Object>, true)
                    }
                }
            ])

        }
        .onShown(() => {
            this.onPageShow();
        })
        .mode(NavDestinationMode.STANDARD)
        .hideTitleBar(true)
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
