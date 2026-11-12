import BasicDataSource from '../../common/BasicDataSource'
import { showToast } from '../../common/utils/Toast'
import Config from '@wfc/client/src/main/ets/config'
import { getFiletypeIcon, humanSize } from '../../util/helper'
import OptionItemView from '../../view/OptionItemView'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import FileRecord from '@wfc/client/src/main/ets/wfc/model/fileRecord'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import Long from '@wfc/client/src/main/ets/wfc/util/long'
import { eq, stringValue } from '@wfc/client/src/main/ets/wfc/util/longUtil'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import { FontSize } from '../../common/design/Tokens'
import common from '@ohos.app.ability.common'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { openFile } from '../../helper/fileOpenHelper'

@Component
export default struct FileRecordPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State fileRecordDataSource: FileRecordDataSource = new FileRecordDataSource()
    public static PARAM_MY_FILE = 'myFile'
    public static PARAM_CONVERSATION = 'conversation'
    public static PARAM_USER_ID = 'userId'
    private conversation?: Conversation
    private isLoading: boolean = false

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conversation = params[FileRecordPage.PARAM_CONVERSATION] as Conversation;
        let isMyFile = params[FileRecordPage.PARAM_MY_FILE] as boolean
        let userId = params[FileRecordPage.PARAM_USER_ID] as string
        if (isMyFile) {
            this.loadMyFileRecords(Long.ZERO)
        } else {
            if (userId) {
                this.conversation = new Conversation(ConversationType.Single, userId, 0)
            }
            this.loadConversationFileRecords(Long.ZERO)
        }
    }

    loadMyFileRecords(beforeMessageUid: Long) {
        this.isLoading = true
        wfc.getMyFileRecords(beforeMessageUid, 0, 200, fileRecords => {
            if (eq(beforeMessageUid, 0)) {
                this.fileRecordDataSource.setFileRecords(fileRecords)
            } else {
                this.fileRecordDataSource.appendFileRecords(fileRecords)
            }
            this.isLoading = false
        }, err => {
            showToast('加载文件记录失败: ' + err)
            this.isLoading = false
        })
    }

    loadConversationFileRecords(beforeMessageUid: Long) {
        this.isLoading = true
        wfc.getConversationFileRecords(this.conversation, '', beforeMessageUid, 0, 200, fileRecords => {
            if (eq(beforeMessageUid, 0)) {
                this.fileRecordDataSource.setFileRecords(fileRecords)
            } else {
                this.fileRecordDataSource.appendFileRecords(fileRecords)
            }
            this.isLoading = false
        }, err => {
            showToast('加载文件记录失败: ' + err)
            this.isLoading = false
        })
    }

    /**
     * 点击文件记录弹出的菜单：转发 / 下载后打开
     */
    @Builder
    fileRecordMenu(fileRecord: FileRecord) {
        Menu() {
            MenuItem({ content: '转发' })
                .onClick(() => {
                    this.forwardFileRecord(fileRecord)
                })
            MenuItem({ content: '下载后打开' })
                .onClick(() => {
                    this.openFileRecord(fileRecord)
                })
        }
    }

    /**
     * 转发文件记录对应的消息：优先用本地消息，本地没有时从服务器拉一次
     */
    forwardFileRecord(fileRecord: FileRecord) {
        let message = wfc.getMessageByUid(fileRecord.messageUid)
        if (message) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ForwardMessagePage, {
                'messages': [message]
            } as Record<string, Object>)
            return
        }
        wfc.loadRemoteMessage(fileRecord.messageUid, (msg: Message) => {
            if (msg) {
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ForwardMessagePage, {
                    'messages': [msg]
                } as Record<string, Object>)
            } else {
                showToast('消息不存在，无法转发')
            }
        }, (err: number) => {
            console.error('load remote message failed', err)
            showToast('消息不存在，无法转发')
        })
    }

    /**
     * 点开一条文件记录：和会话里的文件消息一样，先下载再交给系统预览打开。
     * 消息还在就用消息内容里的 remotePath（和聊天里完全一致），
     * 消息已被删除时退化成文件记录自带的 url。
     */
    openFileRecord(fileRecord: FileRecord) {
        let message = wfc.getMessageByUid(fileRecord.messageUid)
        if (message && message.messageContent && message.messageContent.type === MessageContentType.File) {
            let content = message.messageContent as FileMessageContent
            openFile(getContext(this) as common.UIAbilityContext, message.messageUid, content.remotePath,
                content.name ? content.name : fileRecord.name)
            return
        }
        openFile(getContext(this) as common.UIAbilityContext, fileRecord.messageUid, fileRecord.url, fileRecord.name)
    }

    fileRecordIcon(fileRecord: FileRecord): ResourceStr {
        return Config.DEFAULT_PORTRAIT_URL
    }

    fileSenderDisplayName(fileRecord: FileRecord) {
        let sender = fileRecord.userId;
        let displayName = wfc.getUserDisplayName(sender)
        return displayName
    }

    build() {
        NavDestination() {
            Column() {
                Text('文件记录')
                    .backgroundColor($r('app.color.wf_secondary_background'))
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .fontSize(FontSize.sm)
                    .padding({ left: 12 })
                    .width('100%')
                    .height(24)
                if (this.fileRecordDataSource.totalCount() === 0) {
                    Text('没有文件记录')
                        .width('100%')
                        .height('100%')
                        .textAlign(TextAlign.Center)
                        .fontColor($r('app.color.wf_primary_text'))
                } else {
                    List() {
                        LazyForEach(this.fileRecordDataSource, (fileRecord: FileRecord) => {
                            ListItem() {
                                Row() {
                                    Image(getFiletypeIcon(fileRecord.name))
                                        .width(52)
                                        .height(52)
                                        .margin(12)
                                    Column() {
                                        Text(fileRecord.name)
                                            .fontSize(FontSize.md)
                                            .maxLines(1)
                                            .fontColor($r('app.color.wf_primary_text'))
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                        Row() {
                                            Text(this.fileSenderDisplayName(fileRecord))
                                                .maxLines(1)
                                                .fontSize(FontSize.xs)
                                                .fontColor($r('app.color.wf_tertiary_text'))
                                            Text(humanSize(fileRecord.size))
                                                .maxLines(1)
                                                .fontSize(FontSize.xs)
                                                .fontColor($r('app.color.wf_tertiary_text'))
                                                .margin({ left: 12 })
                                        }
                                        .margin({ top: 4 })
                                        .justifyContent(FlexAlign.Start)
                                    }
                                    .layoutWeight(1)
                                    .justifyContent(FlexAlign.Center)
                                    .alignItems(HorizontalAlign.Start)
                                }
                                .width('100%')
                                .justifyContent(FlexAlign.Start)
                                .backgroundColor($r('app.color.wf_background'))
                                .bindMenu(this.fileRecordMenu(fileRecord))
                            }
                        }, (fileRecord: FileRecord) => stringValue(fileRecord.messageUid)
                        )
                    }
                    .onScrollIndex((start, end) => {
                        if (end === this.fileRecordDataSource.totalCount() - 1 && !this.isLoading) {
                            this.loadConversationFileRecords(this.fileRecordDataSource.getData(this.fileRecordDataSource.totalCount() - 1)
                                .messageUid)
                        }
                    })
                    .width('100%')
                    .layoutWeight(1)
                    .divider({
                        strokeWidth: 1,
                        color: $r('app.color.wf_divider'),
                        startMargin: 70
                    })
                }
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
            .alignItems(HorizontalAlign.Start)
        }
        .title('文件记录')
        .height('100%')
        .width('100%')
    }
}

class FileRecordDataSource
extends BasicDataSource
<FileRecord> {
    private fileRecords: FileRecord[] = []

    setFileRecords(fileRecords: FileRecord[]): void {
        this.fileRecords = fileRecords
        this.notifyDataReload()
    }

    appendFileRecords(fileRecords: FileRecord[]) {
        this.fileRecords = this.fileRecords.concat(fileRecords)
        this.notifyDataReload()
    }

    public totalCount(): number {
        return this.fileRecords.length
    }

    public getData(index: number): FileRecord {
        return this.fileRecords[index]
    }
}