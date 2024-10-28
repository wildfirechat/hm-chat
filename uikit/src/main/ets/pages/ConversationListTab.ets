import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import router from '@ohos.router'
import ConnectionStatus from '@wfc/client/src/main/ets/wfc/client/connectionStatus'
import UnreadCount from '@wfc/client/src/main/ets/wfc/model/unreadCount'
import ConversationInfoItemView from '../view/ConversationInfoItemView'
import { showToast } from '../common/utils/Toast'
import BasicDataSource from '../common/BasicDataSource'
import data_preferences from '@ohos.data.preferences'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import { navigationDestinations } from './navigationConfig'
import PCOnlineInfo from '@wfc/client/src/main/ets/wfc/model/pcOnlineInfo'
import { it } from '@ohos/hypium'

@Component
@Preview
export default struct ConversationListTab {
    @State connectionStatus: number = -1
    @State connectionStatusHeader: string = ''
    @State pcOnlineInfos: PCOnlineInfo[] = []
    @State isMuteWhenPCOnline: boolean = false
    @Link conversationListTabUnreadCount: number
    private conversationInfoDataSource: ConversationInfoDataSource = new ConversationInfoDataSource()
    private context?: Context
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        console.log('conversationList', 'aboutToAppear')
        console.log('conversationList status', wfc.getConnectionStatus())

        this.loadConversationList()
        this.loadPCOnlineInfos()
        this.isMuteWhenPCOnline = wfc.isMuteNotificationWhenPcOnline()
        this.context = getContext(this)
        wfc.eventEmitter!.on(EventType.ReceiveMessage, this.onSendMessage)
        wfc.eventEmitter!.on(EventType.SendMessage, this.onReceiveMessage)
        wfc.eventEmitter!.on(EventType.RecallMessage, this.onRecallMessage)
        wfc.eventEmitter!.on(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
        wfc.eventEmitter!.on(EventType.ConversationInfoUpdate, this.onConversationInfoUpdate)
        wfc.eventEmitter!.on(EventType.SettingUpdate, this.onSettingUpdate)

        wfc.eventEmitter!.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        wfc.eventEmitter!.on(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter!.on(EventType.ChannelInfosUpdate, this.onChannelInfosUpdate)
        wfc.eventEmitter!.on(EventType.MessageStatusUpdate, this.onMessageStatusUpdate)
        wfc.eventEmitter!.on(EventType.FriendListUpdate, this.onFriendListUpdate)
    }

    aboutToDisappear() {
        wfc.eventEmitter!.off(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter!.on(EventType.SendMessage, this.onSendMessage)
        wfc.eventEmitter!.on(EventType.RecallMessage, this.onRecallMessage)
        wfc.eventEmitter!.off(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
        wfc.eventEmitter!.off(EventType.ConversationInfoUpdate, this.onConversationInfoUpdate)
        wfc.eventEmitter!.on(EventType.SettingUpdate, this.onSettingUpdate)

        wfc.eventEmitter!.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        wfc.eventEmitter!.off(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter!.off(EventType.ChannelInfosUpdate, this.onChannelInfosUpdate)
        wfc.eventEmitter!.off(EventType.MessageStatusUpdate, this.onMessageStatusUpdate)
        wfc.eventEmitter!.off(EventType.FriendListUpdate, this.onFriendListUpdate)
    }

    onPageShow() {
    }

    // TODO
    // FIXME
    // 不是所有情况，都需要完整的重新加载会话列表
    loadConversationList() {
        if (this.connectionStatus === ConnectionStatus.ConnectionStatusConnecting) {
            return;
        }
        let conversationInfos = wfc.getConversationInfoList([0, 1, 2, 3], [0, 1]);
        this.conversationInfoDataSource.setConversationInfos(conversationInfos)
        let totalUnreadCount = 0
        conversationInfos.forEach(info => {
            if (!info.isSilent) {
                let unreadCount: UnreadCount = info.unreadCount
                totalUnreadCount += unreadCount.unread + unreadCount.unreadMention + unreadCount.unreadMentionAll
            }
        })

        this.conversationListTabUnreadCount = totalUnreadCount
    }

    loadPCOnlineInfos() {
        this.pcOnlineInfos = wfc.getPCOnlineInfos();
    }

    onConnectionStatusChange = (status: number) => {
        this.connectionStatus = status
        if (status === ConnectionStatus.ConnectionStatusTokenIncorrect
            || status === ConnectionStatus.ConnectionStatusSecretKeyMismatch
            || status === ConnectionStatus.ConnectionStatusRejected
            || status === ConnectionStatus.ConnectionStatusLogout
            || status === ConnectionStatus.ConnectionStatusKickedOff) {
            showToast(ConnectionStatus.desc(status))

            data_preferences.deletePreferences(this.context, 'wfcstore')
            if (status === ConnectionStatus.ConnectionStatusLogout) {
                router.replaceUrl({ url: 'pages/LoginPage' }, router.RouterMode.Standard)
            } else {
                wfc.disconnect(true, false)
                if (status === ConnectionStatus.ConnectionStatusKickedOff) {
                    router.replaceUrl({ url: 'pages/LoginPage' }, router.RouterMode.Standard)
                }
            }

            return
        }

        if (status === ConnectionStatus.ConnectionStatusTimeInconsistent) {
            showToast(ConnectionStatus.desc(status))
            return
        }

        this.computeConnectionStatusHeader()
        if (status === ConnectionStatus.ConnectionStatusConnected) {
            this.loadConversationList();
            this.loadPCOnlineInfos()
        } else {
            // TODO
        }
    }
    onConversationInfoUpdate = (info: ConversationInfo) => {
        this.loadConversationList()
    }
    // why？
    // 不用箭头函数的话，evenHub 里面调用时，this 并不是当前组件
    onReceiveMessage = (msg: Message) => {
        this.loadConversationList()
    }
    onRecallMessage = (operator: string, messageUid: object) => {
        this.loadConversationList()
    }
    onSendMessage = (msg: Message) => {
        this.loadConversationList()
    }
    onSettingUpdate = () => {
        this.loadConversationList()
        this.loadPCOnlineInfos()
        this.isMuteWhenPCOnline = wfc.isMuteNotificationWhenPcOnline()
    }
    onUserInfosUpdate = () => {
        this.loadConversationList();
    }
    onGroupInfosUpdate = () => {
        this.loadConversationList();

    }
    onChannelInfosUpdate = () => {
        this.loadConversationList();
    }
    onMessageStatusUpdate = () => {
        this.loadConversationList();
    }
    onFriendListUpdate = () => {
        this.loadConversationList();
    }

    conversationKey(conversationInfo: ConversationInfo): string {
        let conversation = conversationInfo.conversation!;
        let key = conversation.type + '-' + conversation.target + '-' + conversation.line
        key += '-' + conversationInfo.timestamp
        let unreadCount = conversationInfo.unreadCount
        if (unreadCount) {
            key += '-' + (unreadCount.unreadMentionAll + unreadCount.unread + unreadCount.unreadMention)
        } else {
            key += '-0'
        }
        key += '-' + conversationInfo.top
        key += '-' + conversationInfo.isSilent
        if (conversationInfo.lastMessage) {
            key += '-' + conversationInfo.lastMessage.status + '-' + conversationInfo.lastMessage.messageContent.type
        } else {
            key += '-null'
        }

        if (conversation.type === ConversationType.Single) {
            let userInfo = wfc.getUserInfo(conversation.target);
            // friendAlias 更新，并不会导致userInfo.update 更新
            key += '-' + userInfo.updateDt + '-' + userInfo.friendAlias
        } else if (conversation.type === ConversationType.Group) {
            let groupInfo = wfc.getGroupInfo(conversation.target);
            key += '-' + groupInfo.updateDt + '-' + groupInfo.remark
        } else if (conversation.type === ConversationType.Channel) {
            let channelInfo = wfc.getChannelInfo(conversation.target);
            key += '-' + channelInfo.updateDt
        }

        return key
    }

    computeConnectionStatusHeader() {
        let text: string = ''
        switch (this.connectionStatus) {
            case ConnectionStatus.ConnectionStatusConnecting:
                text = '正在连接...'
                break
            case ConnectionStatus.ConnectionStatusReceiveing:
                text = '正在同步...'
                break
            case ConnectionStatus.ConnectionStatusConnected:
                break
            case ConnectionStatus.ConnectionStatusUnconnected:
                text = '连接失败'
                break
            default:
                break;

        }
        this.connectionStatusHeader = text
    }

    build() {
        Column() {
            Divider()
                .color('#F7F7F7')
            List() {
                // headers
                if (this.connectionStatusHeader) {
                    ListItem() {
                        Text(this.connectionStatusHeader)
                            .height(40)
                            .width('100%')
                            .backgroundColor('#F7F7F7')
                            .textAlign(TextAlign.Center)

                    }
                    .width('100%')
                }
                if (this.pcOnlineInfos.length > 0) {
                    ForEach(this.pcOnlineInfos, (info: PCOnlineInfo, index: number) => {
                        ListItem() {
                            Text(`${info.desc() + (this.isMuteWhenPCOnline ? '，手机通知已关闭' : '')}`)
                                .height(40)
                                .width('100%')
                                .backgroundColor('#F7F7F7')
                                .textAlign(TextAlign.Center)

                        }
                        .width('100%')
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(navigationDestinations.PCSessionPage, {
                                'pcOnlineInfo': info
                            } as Record<string, object>)
                        })
                    }, (item: PCOnlineInfo, index: number) => {
                        return item.type + '-' + item.platform.platform + '-' + item.clientId
                    })
                }

                // TODO lazyForEach https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/ui-ts-performance-improvement-recommendation-0000001477981001-V2
                LazyForEach(this.conversationInfoDataSource, (info: ConversationInfo, index: number) => {
                    ListItem() {
                        ConversationInfoItemView({ conversationInfo: info })
                            .onClick(() => {
                                wfc.clearConversationUnreadStatus(info.conversation!)
                                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                                    'conversation': info.conversation
                                } as Record<string, Object>)
                            })
                            .bindContextMenu(this.MenuBuilder(info), ResponseType.LongPress, { preview: MenuPreviewMode.IMAGE })
                    }
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })
                }, (info: ConversationInfo) => this.conversationKey(info))
            }
            .width('100%')
            .cachedCount(5)
        }
        .width('100%')
        .height('100%')
    }

    conversationItemContextMenus(conversationInfo: ConversationInfo): MenuItem[] {
        let menuItems: MenuItem[] = [
            {
                title: '删除会话',
                action: () => {
                    wfc.removeConversation(conversationInfo.conversation!, false);
                    this.conversationInfoDataSource.removeConversationInfo(conversationInfo)
                }
            }
        ]
        if (conversationInfo.top) {
            menuItems.push({
                title: '取消置顶',
                action: () => {
                    wfc.setConversationTop(conversationInfo.conversation, 0, () => {
                        // this.conversationInfo.top = 0
                    }, err => {
                        console.log('setTop error', err)
                    })
                }
            })
        } else {
            menuItems.push({
                title: '置顶',
                action: () => {
                    wfc.setConversationTop(conversationInfo.conversation, 1, () => {
                        // this.conversationInfo.top = 1
                    }, err => {
                        console.log('setTop error', err)
                    })
                }
            })
        }

        // if (this.conversationInfo.isSilent) {
        //     menuItems.push({
        //         title: '取消免打扰',
        //         func: () => {
        //         }
        //     })
        // } else {
        //     menuItems.push({
        //         title: '会话免打扰',
        //         func: () => {
        //         }
        //     })
        // }


        let unreadCount = conversationInfo.unreadCount
        if ((unreadCount.unread || unreadCount.unreadMention || unreadCount.unreadMentionAll)) {
            menuItems.push({
                title: '标为已读',
                action: () => {
                    wfc.clearConversationUnreadStatus(conversationInfo.conversation)
                }
            })
        } else {
            menuItems.push({
                title: '标为未读',
                action: () => {
                    wfc.markConversationAsUnread(conversationInfo.conversation, true)
                }
            })
        }

        return menuItems
    }

    @Builder
    MenuBuilder(conversationInfo: ConversationInfo) {
        Menu() {
            ForEach(this.conversationItemContextMenus(conversationInfo), (menuItem: MenuItem) => {
                MenuItem({ content: menuItem.title })
                    .onClick(menuItem.action)

            }, (menuItem: MenuItem) => menuItem.title)
        }
    }
}

class ConversationInfoDataSource extends BasicDataSource<ConversationInfo> {
    private conversationInfos: ConversationInfo[] = [];

    public setConversationInfos(conversationInfos: ConversationInfo[]): void {
        this.conversationInfos = conversationInfos
        this.notifyDataReload()
    }

    public removeConversationInfo(conversationInfo: ConversationInfo): void {
        let index = this.conversationInfos.findIndex((info: ConversationInfo) => Conversation.equal(info.conversation, conversationInfo.conversation))
        if (index >= 0) {
            this.conversationInfos.splice(index, 1)
            this.notifyDataDelete(index)
        }
    }

    public update(index: number, data: ConversationInfo): void {
        this.notifyDataChange(index)
    }

    public totalCount(): number {
        return this.conversationInfos.length;
    }

    public getData(index: number): ConversationInfo {
        return this.conversationInfos[index];
    }

    public addData(index: number, data: ConversationInfo): void {
        this.conversationInfos.splice(index, 0, data);
        this.notifyDataAdd(index);
    }

    public pushData(data: ConversationInfo): void {
        this.conversationInfos.push(data);
        this.notifyDataAdd(this.conversationInfos.length - 1);
    }
}

interface MenuItem {
    title: string,
    action: () => void
}

