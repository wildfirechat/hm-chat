import { showToast } from '../../../common/utils/Toast'
import Config from '@wfc/client/src/main/ets/config'
import ActionSheetDialog from '../../../view/ActionSheetDialog'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import AudioPlayManager from '../audio/AudioPlayManager'
import ReadReceipt from '../model/readReceipt'
import AudioMessageContentView from './AudioMessageContentView'
import CallStartMessageContentView from './CallStartMessageContentView'
import CompositeMessageContentView from './CompositeMessageContentView'
import ImageMessageContentView from './ImageMessageContentView'
import StickerMessageContentView from './StickerMessageContentView'
import TextMessageContentView from './TextMessageContentView'
import VideoMessageContentView from './VideoMessageContentView'
import GroupMember from '@wfc/client/src/main/ets/wfc/model/groupMember'
import FileMessageContentView from './FileMessageContentView'
import pasteboard from '@ohos.pasteboard'
import CustomMessageContentType from '@wfc/client/src/main/ets/wfc_custom_message/customMessageContentType'
import TestCustomMessageContentView from '../custom_message/testCustomMessageContentView'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'
import ConferenceInviteMessageContentView from './ConferenceInviteMessageContentView'
import CardMessageContentView from './CardMessageContentView'
import appServer from '../../../api/appServer'
import AppServerError from '../../../api/appServerError'
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType'
import ArticleMessageContentView from './ArticlesMessageContentView'
import LinkMessageContentView from './LinkMessageContentView'
import StreamingTextMessageContentView from './StreamingTextMessageContentView'
import { ScalingMode } from '@ohos/webrtc'
import { trustedAppService } from '@kit.DeviceSecurityKit'

@Component
export default struct NormaMessageContentView {
    @Prop message: Message
    @Link enableMultiCheck: boolean
    @Link quotedMessage: Message
    audioPlayManager?: AudioPlayManager
    @State readReceipt: ReadReceipt | null = null
    @Prop @Watch('updateMessageReadReceipt') readEntries: Map<string, number> = new Map();
    @Prop groupMembers: GroupMember[] = []
    enableReceipt: boolean = false
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear(): void {
        this.updateMessageReadReceipt()
    }

    build() {
        Column() {
            if (this.message!.messageContent.type === MessageContentType.Text) {
                TextMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Sticker) {
                StickerMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Image) {
                ImageMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Video) {
                VideoMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Voice) {
                AudioMessageContentView({ message: $message, audioPlayManager: this.audioPlayManager })
            } else if (this.message!.messageContent.type === MessageContentType.VOIP_CONTENT_TYPE_START) {
                CallStartMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Composite_Message) {
                CompositeMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.File) {
                FileMessageContentView({ message: $message })
            } else if (this.message.messageContent.type === MessageContentType.CONFERENCE_CONTENT_TYPE_INVITE) {
                ConferenceInviteMessageContentView({ message: $message })
            } else if (this.message.messageContent.type === MessageContentType.UserCard) {
                CardMessageContentView({ message: $message })
            } else if (this.message.messageContent.type === MessageContentType.Link) {
                LinkMessageContentView({ message: $message })
            } else if (this.message.messageContent.type === MessageContentType.Streaming_Text_Generating) {
                StreamingTextMessageContentView({ message: $message })
            } else if (this.message.messageContent.type === MessageContentType.Streaming_Text_Generated) {
                StreamingTextMessageContentView({ message: $message })
            }
            // 自定义消息配置 start
            else if (this.message!.messageContent.type === CustomMessageContentType.MESSAGE_CONTENT_TYPE_CUSTOM_MESSAGE_TEST) {
                TestCustomMessageContentView({ message: $message })
            }
            // 自定义消息配置 end

            else {
                Text(this.message!.messageContent.digest(this.message))
                    .margin({ top: 4 })
                    .padding(10)
            }
            // out
            if (this.message!.direction === 0) {
                if (this.readReceipt) {
                    if (this.message!.conversation.type === ConversationType.Group) {
                        Text(`已读 ${this.readReceipt.readCount}/${this.readReceipt.readCount + this.readReceipt.unreadCount}`)
                            .fontSize(12)
                            .fontColor('#b4b4b4')
                            .margin({ top: 4 })
                            .alignSelf(ItemAlign.End)
                    } else if (this.message!.conversation.type === ConversationType.Single) {
                        Text(this.readReceipt.readCount > 0 ? '已读' : '未读')
                            .fontSize(12)
                            .fontColor('#b4b4b4')
                            .margin({ top: 4 })
                            .alignSelf(ItemAlign.End)
                    }
                }
            }
        }
        .bindContextMenu(this.MessageContextMenuBuilder, ResponseType.LongPress, {
            backgroundColor: '#4c4c4c',
            backgroundBlurStyle: BlurStyle.NONE,
        })
    }

    recallContextMenuFilter: () => boolean = () => {
        if ([MessageContentType.VOIP_CONTENT_TYPE_ADD_PARTICIPANT, MessageContentType.VOIP_CONTENT_TYPE_START].indexOf(this.message.messageContent.type) >= 0) {
            return false
        }
        let enableRecall: boolean = false
        let conversation = this.message.conversation;
        // callstart 消息不允许撤回，撤回无意义
        if ([MessageContentType.VOIP_CONTENT_TYPE_START].indexOf(this.message.messageContent.type) >= 0) {
            enableRecall = false
            return enableRecall
        } else {
            if (conversation.type === ConversationType.Group) {
                // TODO 撤回权限验证
                let groupMember = wfc.getGroupMember(conversation.target, wfc.getUserId())
                let fromMember = wfc.getGroupMember(conversation.target, this.message.from)
                if (groupMember.type === GroupMemberType.Owner) {
                    enableRecall = true
                } else if (groupMember.type === GroupMemberType.Manager && [GroupMemberType.Owner, GroupMemberType.Manager].indexOf(fromMember.type) === -1) {
                    enableRecall = true
                }
            }
            if (!enableRecall) {
                let delta = wfc.getServerDeltaTime()
                let now = new Date().getTime()
                if (this.message!.direction === 0 && this.message!.from === wfc.getUserId() && now - (this.message!.timestamp - delta) < Config.RECALL_TIME_LIMIT * 1000) {
                    enableRecall = true
                }
            }
            return enableRecall
        }
    }
    messageContextMenus = () => {
        let menus: MessageContextMenuItem[] = [
            {
                title: '删除',
                tag: 'delete',
                icon: $r('app.media.ic_msg_delete'),
                action: () => {
                    let deleteMessageDialogController = new CustomDialogController({
                        builder: ActionSheetDialog({
                            title: '删除消息?',
                            sheets: [
                                {
                                    title: '删除本地消息',
                                    action: () => {
                                        deleteMessageDialogController.close()
                                        wfc.deleteMessage(this.message!.messageId)
                                    }
                                },
                                {
                                    title: '删除远程消息',
                                    action: () => {
                                        deleteMessageDialogController.close()
                                        wfc.deleteRemoteMessageByUid(this.message!.messageUid, () => {

                                        }, (err: number) => {
                                            showToast('删除远程消息失败' + err)
                                        })
                                    }
                                }
                            ]
                        }),
                        autoCancel: true,
                        alignment: DialogAlignment.Center,
                        gridCount: 6,
                        customStyle: false
                    })

                    deleteMessageDialogController.open()
                }
            },
            {
                title: '转发',
                tag: 'forward',
                icon: $r('app.media.ic_msg_forward'),
                action: () => {
                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ForwardMessagePage,
                        {
                            'messages': [this.message]
                        } as Record<string, Object>
                    )
                },
                filter: () => {
                    return [MessageContentType.VOIP_CONTENT_TYPE_START,
                        MessageContentType.VOIP_CONTENT_TYPE_ADD_PARTICIPANT,
                        MessageContentType.Voice].indexOf(this.message.messageContent.type) === -1
                }
            },
            {
                title: '多选',
                tag: 'multiCheck',
                icon: $r('app.media.ic_msg_select'),
                action: () => {
                    this.enableMultiCheck = true
                },
                filter: () => {
                    return [MessageContentType.VOIP_CONTENT_TYPE_START,
                        MessageContentType.Voice].indexOf(this.message.messageContent.type) === -1
                }
            },
            {
                title: '引用',
                tag: 'quote',
                icon: $r('app.media.ic_msg_quote'),
                action: () => {
                    this.quotedMessage = this.message;
                },
                filter: () => {
                    return [MessageContentType.VOIP_CONTENT_TYPE_START,
                        MessageContentType.Voice,
                        MessageContentType.VOIP_CONTENT_TYPE_ADD_PARTICIPANT].indexOf(this.message.messageContent.type) === -1
                }
            },
            {
                title: '收藏',
                tag: 'fav',
                icon: $r('app.media.ic_msg_collect'),
                action: () => {
                    appServer.favMessage(this.message)
                        .catch((e: AppServerError) => {
                            showToast('收藏消息失败 ' + e.message)
                        })
                },
                filter: () => {
                    return [MessageContentType.VOIP_CONTENT_TYPE_START,
                        MessageContentType.VOIP_CONTENT_TYPE_ADD_PARTICIPANT,
                        MessageContentType.Sticker].indexOf(this.message.messageContent.type) === -1
                }
            },
            {
                title: '撤回',
                tag: 'recall',
                icon: $r('app.media.ic_msg_rollback'),
                action: () => {
                    wfc.recallMessage(this.message!.messageUid, () => {
                    }, err => {
                        console.error('recall error', err)
                    })
                },
                filter: this.recallContextMenuFilter
            },
            {
                title: '复制',
                tag: 'copy',
                icon: $r('app.media.ic_msg_copy'),
                action: () => {
                    let pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.message!.messageContent.digest())
                    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
                    systemPasteboard.setData(pasteData)
                },
                filter: () => {
                    return this.message.messageContent.type === MessageContentType.Text
                }
            }
        ]

        // do filter
        return menus.filter(item => !item.filter || item.filter())
    }


    @Builder
    MessageContextMenuBuilder() {
        Grid() {
            ForEach(this.messageContextMenus(), (menuItem: MessageContextMenuItem) => {
                GridItem() {
                    Column({ space: 8 }) {
                        Image(menuItem.icon)
                            .objectFit(ImageFit.Contain)
                            .width(24)
                            .height(24)
                        Text(menuItem.title)
                            .fontSize(13)
                            .fontColor('#FFFFFF')
                    }
                    .justifyContent(FlexAlign.Center)
                    .width(60)
                    .height(70)
                    .onClick(() => {
                        menuItem.action()
                    })
                    .stateStyles({
                        normal: {
                            .backgroundColor(Color.Transparent)
                        },
                        pressed: {
                            // .backgroundColor('#444444')
                            .backgroundColor(Color.Red)
                        }
                    })
                }
            }, (menuItem: MessageContextMenuItem) => menuItem.tag)
        }
        .columnsTemplate('repeat(auto-fit, 60)')
        .width(Math.min(this.messageContextMenus().length, 5) * 60 + 20)
        .padding({
            left: 10,
            right: 10,
            top: 10,
            bottom: 10
        })
    }

    updateMessageReadReceipt(): void {
        let message = this.message!
        console.log('updateMessageReadReceipt', message.direction, this.readEntries, this.readEntries.size)
        if (!this.enableReceipt || message.direction === 1) {
            return
        }
        if (message.conversation.type === ConversationType.Single) {
            let readReceipt: ReadReceipt = new ReadReceipt()
            readReceipt.conversationType = ConversationType.Single
            if (this.readEntries.size > 0) {
                //let readDt = this.readEntries[0].value
                let readDt = this.readEntries.get(message.conversation.target)
                if (readDt && readDt! >= message.timestamp) {
                    readReceipt.readCount = 1
                    readReceipt.unreadCount = 0
                }
            } else {
                readReceipt.readCount = 0
                readReceipt.unreadCount = 0
            }
            this.readReceipt = readReceipt
        } else if (message.conversation.type === ConversationType.Group) {
            let readReceipt: ReadReceipt = new ReadReceipt()
            readReceipt.conversationType = ConversationType.Group

            // sender
            let readCount = 1
            this.readEntries.forEach(readDt => {
                if (readDt! >= message.timestamp) {
                    readCount++
                }
            })
            readReceipt.readCount = readCount
            // 未读列表，默认包含消息发送之后，加入的群成员
            // 如果需要不包含的话，请过滤一下
            //let groupMembersJoinBeforeMessage = this.groupMembers.filter(member => member.createDt < message.timestamp)
            let groupMembersJoinBeforeMessage = this.groupMembers
            readReceipt.unreadCount = groupMembersJoinBeforeMessage.length - readCount
            this.readReceipt = readReceipt
        }
    }
}

interface MessageContextMenuItem {
    title: string,
    tag: string,
    icon: ResourceStr,
    action: () => void
    // 返回 false 时，将不会被包含在最终的长按菜单列表里面
    filter?: () => boolean
}
