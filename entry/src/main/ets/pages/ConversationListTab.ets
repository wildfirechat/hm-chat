import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import wfc from '../wfc/client/wfc'
import ConversationType from '../wfc/model/conversationType'
import UserInfo from '../wfc/model/userInfo'
import EventType from '../wfc/client/wfcEvent'
import Message from '../wfc/messages/message'
import TextMessageContent from '../wfc/messages/textMessageContent'
import ConversationInfo from '../wfc/model/conversationInfo'
import GroupInfo from '../wfc/model/groupInfo'
import ChannelInfo from '../wfc/model/channelInfo'
import helper from '../util/helper'
import router from '@ohos.router'
import ConnectionStatus from '../wfc/client/connectionStatus'
import UnreadCount from '../wfc/model/unreadCount'
import ConversationInfoItemView from '../view/ConversationInfoItemView'
import { showToast } from '../common/utils/Toast'
import BasicDataSource from '../common/BasicDataSource'
import data_preferences from '@ohos.data.preferences';

@Component
@Preview
export default struct ConversationListTab {
    @State connectionStatus: number = -1
    @State connectionStatusHeader: string = ''
    @Link conversationListTabUnreadCount: number
    private conversationInfoDataSource: ConversationInfoDataSource = new ConversationInfoDataSource()
    private context: Context

    aboutToAppear() {
        console.log('conversationList', 'aboutToAppear')
        console.log('conversationList status', wfc.getConnectionStatus())

        this.loadConversationList()
        this.context = getContext(this)
        this.context.eventHub.on(EventType.ReceiveMessage, this.onSendMessage)
        this.context.eventHub.on(EventType.SendMessage, this.onReceiveMessage)
        this.context.eventHub.on(EventType.RecallMessage, this.onRecallMessage)
        this.context.eventHub.on(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
        this.context.eventHub.on(EventType.ConversationInfoUpdate, this.onConversationInfoUpdate)
        this.context.eventHub.on(EventType.SettingUpdate, this.onSettingUpdate)
    }

    aboutToDisappear() {
        this.context.eventHub.off(EventType.ReceiveMessage, this.onReceiveMessage)
        this.context.eventHub.on(EventType.SendMessage, this.onSendMessage)
        this.context.eventHub.on(EventType.RecallMessage, this.onRecallMessage)
        this.context.eventHub.off(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
        this.context.eventHub.off(EventType.ConversationInfoUpdate, this.onConversationInfoUpdate)
        this.context.eventHub.on(EventType.SettingUpdate, this.onSettingUpdate)
    }

    onPageShow() {
    }

    loadConversationList() {
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

    onConnectionStatusChange = status => {
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
    }

    conversationKey(conversationInfo: ConversationInfo): string {
        let conversation = conversationInfo.conversation;
        let key = conversation.type + '-' + conversation.target + '-' + conversation.line
        key += '-' + conversationInfo.timestamp
        // @ts-ignore
        let unreadCount = conversationInfo.unreadCount
        if (unreadCount) {
            key += '-' + (unreadCount.unreadMentionAll + unreadCount.unread + unreadCount.unreadMention)
        } else {
            key += '-0'
        }
        key += '-' + conversationInfo.top
        key += '-' + conversationInfo.isSilent
        if (conversationInfo.lastMessage) {
            key += '-' + conversationInfo.lastMessage.messageContent.type
        }
        return key
    }

    computeConnectionStatusHeader() {
        let text: string
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

                // TODO lazyForEach https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/ui-ts-performance-improvement-recommendation-0000001477981001-V2
                LazyForEach(this.conversationInfoDataSource, (info: ConversationInfo, index: number) => {
                    ListItem() {
                        ConversationInfoItemView({ conversationInfo: info })
                            .onClick(() => {
                                wfc.clearConversationUnreadStatus(info.conversation)
                                router.pushUrl({
                                    url: "pages/conversation/ConversationPage",
                                    // url: "pages/Login",
                                    params: {
                                        conversation: info.conversation
                                    }
                                }, router.RouterMode.Standard)
                            })
                            .bindContextMenu(this.MenuBuilder(info), ResponseType.LongPress)
                    }
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })
                }, info => this.conversationKey(info))
            }
            .width('100%')
            .cachedCount(5)
        }
        .width('100%')
        .height('100%')
    }

    conversationItemContextMenus(conversationInfo: ConversationInfo): {
        title: string,
        action: () => void
    }[] {
        let menuItems = [
            {
                title: '删除会话',
                action: () => {
                    wfc.removeConversation(conversationInfo.conversation, false);
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
                    }, null)
                }
            })
        } else {
            menuItems.push({
                title: '置顶',
                action: () => {
                    wfc.setConversationTop(conversationInfo.conversation, 1, () => {
                        // this.conversationInfo.top = 1
                    }, null)
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
        if (UnreadCount && (unreadCount.unread || unreadCount.unreadMention || unreadCount.unreadMentionAll)) {
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
            ForEach(this.conversationItemContextMenus(conversationInfo), menuItem => {
                MenuItem({ content: menuItem.title })
                    .onClick(menuItem.action)

            }, menuItem => menuItem.title)
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
        let index = this.conversationInfos.findIndex((info: ConversationInfo) => info.conversation.equal(conversationInfo.conversation))
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

