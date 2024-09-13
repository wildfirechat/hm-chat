import UserInfo from '../../../wfc/model/userInfo'
import router from '@ohos.router'
import SearchResultView from '../../search/SearchPortalResultView'
import GroupInfo from '../../../wfc/model/groupInfo'
import { showToast } from '../../../common/utils/Toast'
import ConversationInfo from '../../../wfc/model/conversationInfo'
import wfc from '../../../wfc/client/wfc'
import ConversationType from '../../../wfc/model/conversationType'
import ConversationInfoItemView from '../../../view/ConversationInfoItemView'
import Conversation from '../../../wfc/model/conversation'
import Message from '../../../wfc/messages/message'
import ForwardMessageDialog from './ForwardMessageDialog'
import TextMessageContent from '../../../wfc/messages/textMessageContent'
import { SearchModule } from '../../../common/Types'
import ImageMessageContent from '../../../wfc/messages/imageMessageContent'
import VideoMessageContent from '../../../wfc/messages/videoMessageContent'
import CompositeMessageContent from '../../../wfc/messages/compositeMessageContent'
import PickContactModal from '../../picker/PickContactModal'
import GroupType from '../../../wfc/model/groupType'

@Entry
@Component
@Preview
export default struct ForwardMessagePage {
    @State keyword: string = ''
    @State recentConversationInfos: ConversationInfo[] = [];
    private messages: Message[] = []
    private forwardDialogController?: CustomDialogController
    private forwardType: 'oneByOne' | 'compose' = 'oneByOne'
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State showPickContactModal: boolean = false

    aboutToAppear() {
        this.recentConversationInfos = wfc.getConversationInfoList([0, 1, 2, 3], [0, 1]);
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            let msgs: Message[] = params['messages'] as Message[]
            // 通过 params 传递的对象，会丢失方法，故
            this.messages = msgs.map(msg => wfc.getMessageById(msg.messageId)!)
            this.forwardType = params['forwardType'] as 'oneByOne' | 'compose'
        }
    }

    private searchModules: SearchModule[] = [
        {
            tag: 'contact',
            onSearchResultItemClick: value => {
                let userInfo = value as UserInfo
                let conversation = new Conversation(ConversationType.Single, userInfo.uid, 0)
                this.forwardMessage([conversation])
            }
        },
        {
            tag: 'group',
            onSearchResultItemClick: value => {
                let groupInfo = value as GroupInfo
                let conversation = new Conversation(ConversationType.Group, groupInfo.target, 0)
                this.forwardMessage([conversation])
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
                                    wfc.sendConversationMessage(conversation, msg.messageContent)
                                })
                            } else {
                                let composeMessageContent = new CompositeMessageContent()
                                composeMessageContent.setMessages(this.messages)
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
            alignment: DialogAlignment.Center,
            gridCount: 4,
            customStyle: false
        })

        this.forwardDialogController.open()
    }

    @Builder
    pickContactModal() {
        PickContactModal({
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
                    wfc.createGroup('', GroupType.Normal, groupName, '', '', memberIds, '', [0], null, (groupId) => {
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

    build() {
        NavDestination() {
            Column() {
                Row() {
                    TextInput({ placeholder: '搜索...' })
                        .type(InputType.Normal)
                        .layoutWeight(1)
                        .borderRadius(4)
                        .onChange((value: string) => {
                            this.keyword = value
                        })
                }
                .padding(10)
                .width('100%')

                Stack() {
                    Column() {
                        List() {
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
                            .bindContentCover($$this.showPickContactModal, this.pickContactModal(), {
                                modalTransition: ModalTransition.DEFAULT,
                                onAppear: () => {
                                },
                            })

                            ListItem() {
                                Text('最近聊天')
                                    .fontColor('#989898')
                                    .fontSize(13)
                                    .width('100%')
                                    .height(40)
                                    .backgroundColor('#E5E5E5')
                                    .padding({ left: 10, right: 10 })
                            }

                            ForEach(this.recentConversationInfos, (info: ConversationInfo, index: number) => {
                                ListItem() {
                                    ConversationInfoItemView({
                                        conversationInfo: info,
                                        basicMode: true
                                    })
                                        .onClick(() => {
                                            this.forwardMessage([info.conversation])
                                        })
                                }
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor('#E5E5E5')
                                    },
                                    normal: {
                                        .backgroundColor(Color.White)
                                    }
                                })
                            }, (info: ConversationInfo) => info.conversation.type + info.conversation.target + '-' + info.conversation.line)
                        }
                    }
                    .height('100%')

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
            .height('100%')
            .width('100%')
        }
        .title('选择一个聊天')
        .height('100%')
        .width('100%')
    }
}
