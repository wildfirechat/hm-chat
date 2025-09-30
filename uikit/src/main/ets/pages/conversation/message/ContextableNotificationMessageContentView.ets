import { showToast } from '../../../common/utils/Toast'
import Config from '@wfc/client/src/main/ets/config'
import ActionSheetDialog from '../../../view/ActionSheetDialog'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'
import appServer from '../../../api/appServer'
import AppServerError from '../../../api/appServerError'
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType'
import ArticleMessageContentView from './ArticlesMessageContentView'

@Component
export default struct ContextableNotificationMessageContentView {
    @Prop message: Message
    @Link enableMultiCheck: boolean
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    build() {
        Row() {
            if (this.message!.messageContent.type === MessageContentType.Articles) {
                ArticleMessageContentView({ message: $message })
            }
        }
        .margin(10)
        // .alignItems(HorizontalAlign.End)
        .bindContextMenu(this.MessageContextMenuBuilder, ResponseType.LongPress)
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
                action: () => {
                    this.enableMultiCheck = true
                },
                filter: () => {
                    return [MessageContentType.VOIP_CONTENT_TYPE_START,
                        MessageContentType.Voice].indexOf(this.message.messageContent.type) === -1
                }
            },
            {
                title: '收藏',
                tag: 'fav',
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
        // {
        //     title: '复制',
        //     tag: 'copy',
        //     action: () => {
        //         let pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.message!.messageContent.digest())
        //         let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
        //         systemPasteboard.setData(pasteData)
        //     },
        //     filter: () => {
        //         return this.message.messageContent.type === MessageContentType.Text
        //     }
        // }
        ]

        // do filter
        return menus.filter(item => !item.filter || item.filter())
    }

    @Builder
    MessageContextMenuBuilder() {
        Menu() {
            ForEach(this.messageContextMenus(), (menuItem: MessageContextMenuItem) => {
                MenuItem({ content: menuItem.title })
                    .onClick(menuItem.action)

            }, (menuItem: MessageContextMenuItem) => menuItem.title)
        }
    }
}

interface MessageContextMenuItem {
    title: string,
    tag: string,
    action: () => void
    // 返回 false 时，将不会被包含在最终的长按菜单列表里面
    filter?: () => boolean
}
