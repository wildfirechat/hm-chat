import router from '@ohos.router'
import { showToast } from '../../../common/utils/Toast'
import Config from '../../../config'
import ActionSheetDialog from '../../../view/ActionSheetDialog'
import wfc from '../../../wfc/client/wfc'
import Message from '../../../wfc/messages/message'
import MessageContentType from '../../../wfc/messages/messageContentType'
import ConversationType from '../../../wfc/model/conversationType'
import AudioPlayManager from '../audio/AudioPlayManager'
import ReadReceipt from '../model/readReceipt'
import AudioMessageContent from './AudioMessageContentView'
import CallStartMessageContentView from './CallStartMessageContentView'
import CompositeMessageContentView from './CompositeMessageContentView'
import ImageMessageContentView from './ImageMessageContentView'
import StickerMessageContentView from './StickerMessageContentView'
import TextMessageContentView from './TextMessageContentView'
import VideoMessageContentView from './VideoMessageContentView'
import { HashMap } from '@kit.ArkTS'
import GroupMember from '../../../wfc/model/groupMember'
import FileMessageContentView from './FileMessageContentView'
import TextMessageContent from '../../../wfc/messages/textMessageContent'
import pasteboard from '@ohos.pasteboard'

@Component
export default struct NormaMessageContentView {
    @Prop message: Message
    @Link enableMultiCheck: boolean
    @Link quotedMessage: Message
    private audioPlayManager?: AudioPlayManager
    @State readReceipt: ReadReceipt | null = null
    @Prop @Watch('updateMessageReadReceipt') readEntries: Map<string, number> = new Map();
    @Prop groupMembers: GroupMember[] = []
    private enableReceipt: boolean = false
    private deleteMessageDialogController?: CustomDialogController

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
                AudioMessageContent({ message: $message, audioPlayManager: this.audioPlayManager })
            } else if (this.message!.messageContent.type === MessageContentType.VOIP_CONTENT_TYPE_START) {
                CallStartMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.Composite_Message) {
                CompositeMessageContentView({ message: $message })
            } else if (this.message!.messageContent.type === MessageContentType.File) {
                FileMessageContentView({ message: $message })
            } else {
                Text(this.message!.messageContent.digest(this.message))
                    .margin({ top: 4 })
                    .padding(10)
                    .onClick(() => {
                        router.pushUrl({
                            url: 'pages/conversation/forward/ForwardMessagePage',
                            params: {
                                messages: [this.message]
                            }
                        })
                            .then(value => {
                                console.log('xxxxxxxxxxxx th', value)
                            })
                            .catch((r: Error) => console.log('xxxxxxxxxxxx', r))
                    })
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
        // .alignItems(HorizontalAlign.End)
        .bindContextMenu(this.MessageContextMenuBuilder, ResponseType.LongPress)
    }

    messageContextMenus = () => {
        let menus: MessageContextMenuItem[] = [
            {
                title: '删除',
                tag: 'delete',
                action: () => {
                    this.deleteMessageDialogController = new CustomDialogController({
                        builder: ActionSheetDialog({
                            title: '删除消息?',
                            controller: this.deleteMessageDialogController,
                            sheets: [
                                {
                                    title: '删除本地消息',
                                    action: () => {
                                        wfc.deleteMessage(this.message!.messageId)
                                    }
                                },
                                {
                                    title: '删除远程消息',
                                    action: () => {
                                        wfc.deleteRemoteMessageByUid(this.message!.messageUid, () => {

                                        }, (err: number) => {
                                            showToast('删除远程消息失败' + err)
                                        })
                                    }
                                }
                            ]
                        }),
                        autoCancel: true,
                        alignment: DialogAlignment.Bottom,
                        gridCount: 6,
                        customStyle: false
                    })

                    this.deleteMessageDialogController.open()
                }
            },
            {
                title: '转发',
                tag: 'forward',
                action: () => {
                    router.pushUrl({
                        url: 'pages/conversation/forward/ForwardMessagePage',
                        params: {
                            messages: [this.message]
                        }
                    })
                        .then(value => {
                            console.log('xxxxxxxxxxxx th', value)
                        })
                        .catch((r: Error) => console.log('xxxxxxxxxxxx', r))
                }
            },
            {
                title: '多选',
                tag: 'multiCheck',
                action: () => {
                    this.enableMultiCheck = true
                }
            },
            {
                title: '引用',
                tag: 'quote',
                action: () => {
                    showToast('TODO引用')
                    this.quotedMessage = this.message;
                }
            }
        ]

        // recall
        let enableRecall: boolean = false
        if (this.message!.conversation.type === ConversationType.Group) {
            // TODO 撤回权限验证
        }
        let delta = wfc.getServerDeltaTime()
        let now = new Date().getTime()
        if (this.message!.direction === 0 && this.message!.from === wfc.getUserId() && now - (this.message!.timestamp - delta) < Config.RECALL_TIME_LIMIT * 1000) {
            enableRecall = true
        }

        if (enableRecall) {
            menus.push({
                title: '撤回',
                tag: 'recall',
                action: () => {
                    wfc.recallMessage(this.message!.messageUid, () => {

                    }, err => {
                        console.error('recall error', err)
                    })
                }
            })
        }

        // copy
        if (this.message!.messageContent instanceof TextMessageContent) {
            menus.push({
                title: '复制',
                tag: 'copy',
                action: () => {
                    let pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.message!.messageContent.digest())
                    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
                    systemPasteboard.setData(pasteData)

                }
            })
        }


        // TODO more context menus

        return menus
    }

    @Builder
    MessageContextMenuBuilder() {
        Menu() {
            ForEach(this.messageContextMenus(), (menuItem: MessageContextMenuItem) => {
                MenuItem({ content: menuItem.title })
                    .onClick(menuItem.action)

            }, (menuItem: MessageContextMenuItem) => menuItem.title)
        }

        // Row() {
        //     Text('Test')
        //     Text('Hello2')
        //         .backgroundColor(Color.Red)
        // }
    }

    updateMessageReadReceipt(): void {
        let message = this.message!
        console.log('xxxxxxxxx updateMessageReadReceipt', message.direction, this.readEntries, this.readEntries.size)
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

            let readCount = 0
            this.readEntries.forEach(readDt => {
                if (readDt! >= message.timestamp) {
                    readCount++
                }
            })
            readReceipt.readCount = readCount
            let groupMembersJoinBeforeMessage = this.groupMembers.filter(member => member.createDt < message.timestamp)
            readReceipt.unreadCount = groupMembersJoinBeforeMessage.length - readCount
            this.readReceipt = readReceipt
        }
    }
}

interface MessageContextMenuItem {
    title: string,
    tag: string,
    action: () => void
}
