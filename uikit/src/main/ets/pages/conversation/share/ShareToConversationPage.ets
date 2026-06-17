import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import SearchResultView from '../../search/SearchPortalResultView'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import ConversationInfoItemView from '../../../view/ConversationInfoItemView'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ForwardMessageDialog from '../forward/ForwardMessageDialog'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent'
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import MessageContent from '@wfc/client/src/main/ets/wfc/messages/messageContent'
import { SearchModule, ShareItem } from '../../../common/Types'
import ConversationInfoDataSource from '../../datasource/ConversationInfoDataSource'
import { imageThumbnail, videoThumbnail } from '../../../helper/imageVideoHelper'
import { showToast } from '../../../common/utils/Toast'
import fileUri from '@ohos.file.fileuri'
import { window } from '@kit.ArkUI'

@Component
export default struct ShareToConversationPage {
    @State keyword: string = ''
    private conversationInfoDataSource: ConversationInfoDataSource = new ConversationInfoDataSource()
    private shareItems: ShareItem[] = []
    private shareDialogController?: CustomDialogController
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        let conversationInfos = wfc.getConversationInfoList([0, 1, 2, 3], [0, 1]);
        this.conversationInfoDataSource.setConversationInfos(conversationInfos)
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            let items = params['shareItems'] as ShareItem[]
            if (items) {
                this.shareItems = items
            }
        }
        let win = AppStorage.get<window.Window>('window')
        win?.setWindowLayoutFullScreen(false)
    }

    private shareDesc(): string {
        if (this.shareItems.length === 0) {
            return ''
        }
        if (this.shareItems.length > 1) {
            return `共${this.shareItems.length}个文件`
        }
        let item = this.shareItems[0]
        switch (item.type) {
            case 'text':
                return item.text ?? ''
            case 'image':
                return '[图片]'
            case 'video':
                return '[视频]'
            default:
                return `[文件] ${item.name ?? ''}`
        }
    }

    private async buildMessageContent(item: ShareItem): Promise<MessageContent | null> {
        try {
            switch (item.type) {
                case 'text':
                    return new TextMessageContent(item.text ?? '')
                case 'image': {
                    let thumbnail = await imageThumbnail(getContext(this), fileUri.getUriFromPath(item.filePath!), { width: 200, height: 200 })
                    return new ImageMessageContent(item.filePath, '', thumbnail)
                }
                case 'video': {
                    let durationAndThumbnail = await videoThumbnail(getContext(this), fileUri.getUriFromPath(item.filePath!), { width: 200, height: 200 })
                    return new VideoMessageContent(item.filePath, '', durationAndThumbnail.thumbnail, durationAndThumbnail.duration)
                }
                default:
                    return new FileMessageContent(item.filePath, '', item.name ?? '', item.size ?? 0)
            }
        } catch (e) {
            // 缩略图等生成失败时降级：视频用空缩略图发送，其余按文件兜底。
            if (item.type === 'video') {
                return new VideoMessageContent(item.filePath, '', '', 0)
            }
            if (item.type === 'image' || item.type === 'file') {
                return new FileMessageContent(item.filePath, '', item.name ?? '', item.size ?? 0)
            }
            return null
        }
    }

    private async sendToConversation(conversation: Conversation, leaveMessage: string) {
        for (let item of this.shareItems) {
            let content = await this.buildMessageContent(item)
            if (content) {
                wfc.sendConversationMessage(conversation, content)
            }
        }
        if (leaveMessage) {
            wfc.sendConversationMessage(conversation, new TextMessageContent(leaveMessage))
        }
    }

    private openSendDialog(conversation: Conversation) {
        this.shareDialogController = new CustomDialogController({
            builder: ForwardMessageDialog({
                targetConversations: [conversation],
                controller: this.shareDialogController,
                forwardMessageDesc: this.shareDesc(),
                forwardMessageImageUri: '',
                cancel: () => {
                    this.shareDialogController = undefined
                },
                confirm: (text) => {
                    this.sendToConversation(conversation, text)
                    this.shareDialogController = undefined
                    showToast('已发送')
                    this.mainNavPathStack.pop()
                }
            }),
            autoCancel: true,
            alignment: DialogAlignment.Bottom,
            gridCount: 4,
            customStyle: true
        })
        this.shareDialogController.open()
    }

    private searchModules: SearchModule[] = [
        {
            tag: 'contact',
            onSearchResultItemClick: value => {
                let userInfo = value as UserInfo
                this.openSendDialog(new Conversation(ConversationType.Single, userInfo.uid, 0))
                this.keyword = ''
            }
        },
        {
            tag: 'group',
            onSearchResultItemClick: value => {
                let groupInfo = value as GroupInfo
                this.openSendDialog(new Conversation(ConversationType.Group, groupInfo.target, 0))
                this.keyword = ''
            }
        },
    ]

    build() {
        NavDestination() {
            Column() {
                Row() {
                    TextInput({ placeholder: '搜索', text: this.keyword })
                        .onChange((value: string) => {
                            this.keyword = value
                        })
                        .borderRadius(4)
                        .backgroundColor($r('app.color.wf_background'))
                        .fontColor($r('app.color.wf_primary_text'))
                        .placeholderColor($r('app.color.wf_tertiary_text'))
                }
                .padding({ left: 10, right: 10 })
                .width('100%')
                .height(60)
                .alignItems(VerticalAlign.Center)

                Stack() {
                    Column() {
                        List() {
                            ListItem() {
                                Text('最近聊天')
                                    .fontColor($r('app.color.wf_tertiary_text'))
                                    .fontSize(13)
                                    .width('100%')
                                    .height(40)
                                    .backgroundColor($r('app.color.wf_primary_background_color'))
                                    .padding({ left: 10, right: 10 })
                            }

                            LazyForEach(this.conversationInfoDataSource, (info: ConversationInfo) => {
                                ListItem() {
                                    ConversationInfoItemView({
                                        conversationInfo: info,
                                        basicMode: true
                                    })
                                        .onClick(() => {
                                            this.openSendDialog(info.conversation)
                                        })
                                }
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor($r('app.color.wf_item_pressed'))
                                    },
                                    normal: {
                                        .backgroundColor($r('app.color.wf_background'))
                                    }
                                })
                                .width('100%')
                            }, (info: ConversationInfo) => info.conversation.type + '-' + info.conversation.target + '-' + info.conversation.line)
                        }
                        .backgroundColor($r('app.color.wf_background'))
                    }
                    .height('100%')
                    .width('100%')

                    if (this.keyword) {
                        SearchResultView({
                            keyword: this.keyword,
                            searchModules: this.searchModules
                        })
                            .height('100%')
                            .backgroundColor($r('app.color.wf_background'))
                    }
                }
                .width('100%')
                .layoutWeight(1)
            }
            .padding({ bottom: 40 })
            .width('100%')
            .height('100%')
        }
        .title('选择一个聊天')
        .height('100%')
        .width('100%')
    }
}
