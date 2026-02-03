import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import SearchResultView from '../../search/SearchPortalResultView'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { showToast } from '../../../common/utils/Toast'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import ConversationInfoItemView from '../../../view/ConversationInfoItemView'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import ForwardMessageDialog from './ForwardMessageDialog'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import { SearchModule } from '../../../common/Types'
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent'
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent'
import CompositeMessageContent from '@wfc/client/src/main/ets/wfc/messages/compositeMessageContent'
import PickMultiContactModal from '../../picker/PickMultiContactModal'
import GroupType from '@wfc/client/src/main/ets/wfc/model/groupType'
import MessageContent from '@wfc/client/src/main/ets/wfc/messages/messageContent'
import CallStartMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/callStartMessageContent'
import SoundMessageContent from '@wfc/client/src/main/ets/wfc/messages/soundMessageContent'
import { window } from '@kit.ArkUI'
import CheckableConversationInfoItemView from '../../../view/CheckableConversationInfoItemView'
import ConversationPortraitView from '../../../view/ConversationPortraitView'
import ConversationInfoDataSource from '../../../pages/datasource/ConversationInfoDataSource'

@Component
@Preview
export default struct ForwardMessagePage {
    @State keyword: string = ''
    private conversationInfoDataSource: ConversationInfoDataSource = new ConversationInfoDataSource()
    private messages: Message[] = []
    private forwardDialogController?: CustomDialogController
    private forwardType: 'oneByOne' | 'compose' = 'oneByOne'
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State showPickContactModal: boolean = false
    @State enableMultiCheck: boolean = false;
    @State checkedConversations: Conversation[] = []
    @State searchInputViewMaxWidth: string = '100%'
    private checkedUserListScroller: Scroller = new Scroller()

    aboutToAppear() {
        let conversationInfos = wfc.getConversationInfoList([0, 1, 2, 3], [0, 1]);
        this.conversationInfoDataSource.setConversationInfos(conversationInfos)
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            let msgs: Message[] = params['messages'] as Message[]
            // 通过 params 传递的对象，会丢失方法，故
            this.messages = msgs.map(msg => {
                if (msg.messageId > 0) {
                    return wfc.getMessageById(msg.messageId)!
                } else {
                    return msg
                }

            })
            this.forwardType = params['forwardType'] as 'oneByOne' | 'compose'
        }
        let win = AppStorage.get<window.Window>('window')
        win?.setWindowLayoutFullScreen(false)
    }

    private toggleConversation(conv: Conversation) {
        let index = this.checkedConversations.findIndex(c => Conversation.equal(c, conv))
        if (index >= 0) {
            this.checkedConversations.splice(index, 1)
        } else {
            this.checkedConversations.push(conv)
        }
    }

    private loadRecentConversations() {
        let conversationInfos = wfc.getConversationInfoList([0, 1, 2, 3], [0, 1]);
        this.conversationInfoDataSource.setConversationInfos(conversationInfos)
    }

    private searchModules: SearchModule[] = [
        {
            tag: 'contact',
            onSearchResultItemClick: value => {
                let userInfo = value as UserInfo
                let conversation = new Conversation(ConversationType.Single, userInfo.uid, 0)
                if (this.enableMultiCheck) {
                    this.toggleConversation(conversation)
                } else {
                    this.forwardMessage([conversation])
                }
                this.keyword = ''
            }
        },
        {
            tag: 'group',
            onSearchResultItemClick: value => {
                let groupInfo = value as GroupInfo
                let conversation = new Conversation(ConversationType.Group, groupInfo.target, 0)
                if (this.enableMultiCheck) {
                    this.toggleConversation(conversation)
                } else {
                    this.forwardMessage([conversation])
                }
                this.keyword = ''
            }
        },
    ]
    forwardMessage = (conversations: Conversation[]) => {
        let forwardMessageDesc = ''
        let forwardMessageImageUri = ''
        let message = this.messages[0]
        if (this.messages.length === 1) {
            let messageContent = message.messageContent
            if (messageContent instanceof ImageMessageContent || messageContent instanceof VideoMessageContent) {
                forwardMessageImageUri = 'data:image/jpeg;base64,' + messageContent.thumbnail
            } else {
                forwardMessageDesc = messageContent.digest(message)
            }
        } else {
            if (this.forwardType === 'oneByOne') {
                forwardMessageDesc = `[逐条转发]共${this.messages.length}条消息`
            } else {
                switch (message.conversation.type) {
                    case ConversationType.Single:
                        let fromName = wfc.getUserDisplayName(message.from)
                        let targetName = wfc.getUserDisplayName(message.conversation.target)
                        forwardMessageDesc = `[合并转发]${fromName}和${targetName}的聊天记录`
                        break
                    case ConversationType.Group:
                        forwardMessageDesc = `[合并转发]群聊的聊天记录`
                        break
                    case ConversationType.ChatRoom:
                        forwardMessageDesc = `[合并转发]聊天室的聊天记录`
                        break
                    case ConversationType.Channel:
                        forwardMessageDesc = `[合并转发]频道的聊天记录`
                        break
                    default:
                        break
                }
            }
        }

        this.forwardDialogController = new CustomDialogController({
            builder: ForwardMessageDialog({
                // message: this.message,
                targetConversations: conversations,
                controller: this.forwardDialogController,
                forwardMessageDesc: forwardMessageDesc,
                forwardMessageImageUri: forwardMessageImageUri,
                cancel: () => {
                    this.forwardDialogController = undefined
                },
                confirm: (text) => {
                    conversations.forEach(conversation => {
                        if (this.messages.length === 1) {
                            wfc.sendConversationMessage(conversation, this.messages[0].messageContent)
                        } else {
                            if (this.forwardType === 'oneByOne') {
                                this.messages.forEach(msg => {
                                    msg.messageContent = this.filterMessageContent(msg)
                                    wfc.sendConversationMessage(conversation, msg.messageContent)
                                })
                            } else {
                                let composeMessageContent = new CompositeMessageContent()
                                let title = ''
                                let msgConv = this.messages[0].conversation
                                if (msgConv.type === ConversationType.Single) {
                                    let name1 = wfc.getUserDisplayName(wfc.getUserId())
                                    let name2 = wfc.getUserDisplayName(msgConv.target)
                                    title = `${name1}和${name2}的聊天记录`
                                } else if (msgConv.type === ConversationType.Group) {
                                    title = '群的聊天记录'
                                } else {
                                    title = '聊天记录'
                                }
                                let msgs = this.messages.map(m => {
                                    m.messageContent = this.filterMessageContent(m)
                                    return m
                                })
                                composeMessageContent.setMessages(msgs)
                                composeMessageContent.title = title
                                wfc.sendConversationMessage(conversation, composeMessageContent)
                            }
                        }
                        if (text) {
                            let textMessageContent = new TextMessageContent(text)
                            wfc.sendConversationMessage(conversation, textMessageContent)
                        }
                    })
                    this.forwardDialogController = undefined
                    this.mainNavPathStack.pop()
                }
            }),
            autoCancel: true,
            alignment: DialogAlignment.Bottom,
            gridCount: 4,
            customStyle: true
        })

        this.forwardDialogController.open()
    }

    filterMessageContent(msg: Message): MessageContent {
        let content = msg.messageContent
        if (content instanceof CallStartMessageContent) {
            content = new TextMessageContent(content.digest())
        } else if (content instanceof SoundMessageContent) {
            content = new TextMessageContent(content.digest() + ' ' + content.duration + "''")
        }
        return content
    }

    @Builder
    pickMultiContactModal() {
        PickMultiContactModal({
            showPickContactModal: $showPickContactModal,
            onCheckUser: (users: UserInfo[]) => {
                // this.createConversation(users)
                showToast('TODO')
                if (users.length === 1) {
                    let conversation = new Conversation(ConversationType.Single, users[0].uid, 0)
                    this.forwardMessage([conversation])
                } else {
                    let memberIds: string[] = users.map(userInfo => userInfo.uid)
                    let first5Members = users.slice(0, 5)
                    let groupName = ''
                    first5Members.forEach(userInfo => {
                        groupName += userInfo.displayName
                        groupName += '、'
                    })
                    groupName = groupName.substring(0, groupName.length - 1)
                    wfc.createGroup('', GroupType.Restricted, groupName, '', '', memberIds, '', [0], null, (groupId) => {
                        let conversation = new Conversation(ConversationType.Group, groupId, 0)
                        this.forwardMessage([conversation])
                    }, err => {

                    })
                }
            },
            onCheckFavGroup: (groupInfo: GroupInfo) => {
                let conversation = new Conversation(ConversationType.Group, groupInfo.target, 0)
                this.forwardMessage([conversation])
            }
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    updateSearchInputViewWidthAndScroll() {
        let checkedConvWidth = 100 / 8 * this.checkedConversations.length
        if (checkedConvWidth > 75) {
            this.searchInputViewMaxWidth = '25%'
        } else {
            this.searchInputViewMaxWidth = (100 - checkedConvWidth) + '%'
        }
        this.checkedUserListScroller.scrollEdge(Edge.End)
    }

    build() {
        NavDestination() {
            Stack() {
                Column() {
                    Row() {
                        List({ scroller: this.checkedUserListScroller }) {
                            ForEach(this.checkedConversations, (conv: Conversation) => {
                                ListItem() {
                                    ConversationPortraitView({
                                        conversation: conv
                                    })
                                        .width(40)
                                        .height(40)
                                        .padding(2)
                                        .borderRadius(4)
                                        .onClick(() => {
                                            this.toggleConversation(conv)
                                            this.updateSearchInputViewWidthAndScroll()
                                        })
                                }
                            }, (conv: Conversation) => conv.type + '-' + conv.target + '-' + conv.line)

                            // ForEach(this.checkedOrganizations, (org: Organization) => {
                            //     ListItem() {
                            //         Image(org.portraitUrl)
                            //             .alt($r('app.media.ic_deparment'))
                            //             .width(40)
                            //             .height(40)
                            //             .borderRadius(4)
                            //             .margin({ left: 10 })
                            //             .onClick(() => {
                            //                 this.checkedOrganizations = this.checkedOrganizations.filter(o => o.id !== org.id)
                            //             })
                            //     }
                            // }, (org: Organization) => 'org-' + org.id)
                            //
                            // ForEach(this.checkedEmployees, (employee: Employee) => {
                            //     ListItem() {
                            //         Image(employee.portraitUrl)
                            //             .alt($r('app.media.avatar_def'))
                            //             .width(40)
                            //             .height(40)
                            //             .borderRadius(4)
                            //             .margin({ left: 10 })
                            //             .onClick(() => {
                            //                 this.checkedEmployees = this.checkedEmployees.filter(e => e.employeeId !== employee.employeeId)
                            //             })
                            //     }
                            // }, (e: Employee) => e.employeeId)

                            ListItem() {
                                Row() {
                                    TextInput({ placeholder: '搜索', text: this.keyword })
                                        .onChange((value: string) => {
                                            this.keyword = value
                                        })
                                        .borderRadius(4)
                                }
                                .constraintSize({ minWidth: '25%', maxWidth: this.searchInputViewMaxWidth })
                            }
                        }
                        .scrollBar(BarState.Off)
                        .listDirection(Axis.Horizontal)
                        .width('100%')
                        .height(60)
                        .alignListItem(ListItemAlign.Center)
                    }
                    .padding({ left: 10, right: 10 })
                    .width('100%')

                    Stack() {
                        Column() {
                            List() {
                                if (!this.enableMultiCheck) {
                                    ListItem() {
                                        Text('创建新聊天')
                                            .fontColor('#989898')
                                            .fontSize(13)
                                            .width('100%')
                                            .height(40)
                                            .padding({ left: 10, right: 10 })
                                            .stateStyles({
                                                pressed: {
                                                    .backgroundColor('#E5E5E5')
                                                },
                                                normal: {
                                                    .backgroundColor(Color.White)
                                                }
                                            })
                                            .enabled(true)
                                            .onClick(() => {
                                                this.showPickContactModal = true
                                            })
                                    }
                                    .bindContentCover($$this.showPickContactModal, this.pickMultiContactModal(), {
                                        modalTransition: ModalTransition.DEFAULT,
                                        onAppear: () => {
                                        },
                                    })
                                }

                                ListItem() {
                                    Text('最近聊天')
                                        .fontColor('#989898')
                                        .fontSize(13)
                                        .width('100%')
                                        .height(40)
                                        .backgroundColor('#E5E5E5')
                                        .padding({ left: 10, right: 10 })
                                }

                                LazyForEach(this.conversationInfoDataSource, (info: ConversationInfo, index: number) => {
                                    ListItem() {
                                        if (this.enableMultiCheck) {
                                            CheckableConversationInfoItemView({
                                                checkedConversations: $checkedConversations,
                                                conversationInfo: info,
                                                basicMode: true,
                                                enableCheck: true
                                            })
                                                .width('100%')
                                                .onClick(() => {
                                                    this.toggleConversation(info.conversation)
                                                    this.updateSearchInputViewWidthAndScroll();
                                                })

                                        } else {
                                            ConversationInfoItemView({
                                                conversationInfo: info,
                                                basicMode: true
                                            })
                                                .onClick(() => {
                                                    this.forwardMessage([info.conversation])
                                                })
                                        }
                                    }
                                    .stateStyles({
                                        pressed: {
                                            .backgroundColor('#E5E5E5')
                                        },
                                        normal: {
                                            .backgroundColor(Color.White)
                                        }
                                    })
                                    .width("100%")
                                }, (info: ConversationInfo) => info.conversation.type + '-' + info.conversation.target + '-' + info.conversation.line)
                            }
                        }
                        .height('100%')
                        .width('100%')

                        if (this.keyword) {
                            SearchResultView({
                                keyword: this.keyword,
                                searchModules: this.searchModules
                            })
                                .height('100%')
                                .backgroundColor(Color.White)
                        }
                    }
                    .width('100%')
                    .layoutWeight(1)
                }
                .padding({ bottom: 40 })
                .width('100%')

                if (this.enableMultiCheck) {
                    Row() {
                        Text(`已选 ${this.checkedConversations.length} 人`)
                        Button('发送')
                            .type(ButtonType.Normal)
                            .height(30)
                            .width(60)
                            .borderRadius(4)
                            .enabled(this.checkedConversations.length > 0)
                            .onClick(e => {
                                this.forwardMessage(this.checkedConversations)
                            })
                    }
                    .padding(10)
                    .height(40)
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .alignItems(VerticalAlign.Center)
                }
            }
            .alignContent(Alignment.Bottom)
            .width('100%')
            .height('100%')
        }
        .title(this.enableMultiCheck ? '选择多个聊天' : '选择一个聊天')
        .menus(this.NavigationMenus())
        .height('100%')
        .width('100%')
    }

    @Builder
    NavigationMenus() {
        Row() {
            Text(this.enableMultiCheck ? '取消多选' : '多选')
                .height(30)
                .fontSize(15)
                .fontColor(Color.Black)
                .padding({ right: 16 })
                .onClick(() => {
                    this.enableMultiCheck = !this.enableMultiCheck
                    if (!this.enableMultiCheck) {
                        this.checkedConversations = []
                        this.searchInputViewMaxWidth = '100%'
                    }
                })
        }
        .height('100%')
        .alignItems(VerticalAlign.Center)
    }
}
