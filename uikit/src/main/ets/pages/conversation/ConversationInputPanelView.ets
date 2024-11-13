import common from '@ohos.app.ability.common'
import { copyFileUri, fileNameFromFileUri, fileSize } from '../../common/utils/FileUtil'
import { showToast } from '../../common/utils/Toast'
import { selectFile, selectMedia2, takePhoto } from '../../helper/mediaHelper'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import AudioRecordManager from './audio/AudioRecordManager'
import fs from '@ohos.file.fs'
import SoundMessageContent from '@wfc/client/src/main/ets/wfc/messages/soundMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import router from '@ohos.router'
import ActionSheetDialog from '../../view/ActionSheetDialog'
import EmojiInputPanelView from './emoji/EmojiInputPanelView'
import { curves, KeyboardAvoidMode, window } from '@kit.ArkUI'
import MentionGroupMemberView from './mention/MentionGroupMemberView'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import { preferences } from '@kit.ArkData'
import avenginekit from '@wfc/avenginekit'
import MessageContent from '@wfc/client/src/main/ets/wfc/messages/messageContent'
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent'
import cameraPicker from '@ohos.multimedia.cameraPicker';
import media from '@ohos.multimedia.media'
import photoAccessHelper from '@ohos.file.photoAccessHelper'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import { imageSize, imageThumbnail, videoThumbnail } from '../../helper/imageVideoHelper'
import { inputMethod } from '@kit.IMEKit'
import PickGroupMemberModal from '../group/PickGroupMemberModal'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import { isImage, isVideo } from '../../util/helper'
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType'
import GroupMember from '@wfc/client/src/main/ets/wfc/model/groupMember'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import ChannelInfo from '@wfc/client/src/main/ets/wfc/model/channelInfo'
import ChannelMenu from '@wfc/client/src/main/ets/wfc/model/channelMenu'
import ChannelMenuEventMessageContent from '@wfc/client/src/main/ets/wfc/messages/channelMenuEventMessageContent'
import { navigationDestinations } from '../navigationConfig'
import QuoteInfo from '@wfc/client/src/main/ets/wfc/model/quoteInfo'
import PickContactModal from '../picker/PickContactModal'
import ForwardMessageDialog from './forward/ForwardMessageDialog'
import CardMessageContent from '@wfc/client/src/main/ets/wfc/messages/cardMessageContent'
import fileUri from '@ohos.file.fileuri'
import { checkAndRequestPermission, checkPermissions } from '../../helper/permissionHelper'
import { Permissions } from '@kit.AbilityKit'

const INPUT_ICON_WIDTH = 30

interface ConversationExt {
    title: string,
    icon: ResourceStr,
    action: () => void
}

interface MultiCheckAction {
    title: string,
    icon: ResourceStr,
    action: () => void
}

@Component
export default struct ConversationInputPanelView {
    @Prop conversation: Conversation
    @Prop conversationInfo: ConversationInfo
    @Link text: string
    @State caretPosition: number = 0
    @State selectionStart: number = 0
    @State selectionEnd: number = 0
    @State textInputFocused: boolean = false
    @State @Watch('onExpandConversationInputPanelView') showEmojiPanel: boolean = false
    @State @Watch('onExpandConversationInputPanelView') showExtPanel: boolean = false
    @State showMentionSheet: boolean = false
    @State keyboardHeight: number = 320
    @State showAudioRecorderButton: boolean = false
    @State showChannelMenu: boolean = false
    @State enable: boolean = false
    @State muted: boolean = false
    @State channelInfo?: ChannelInfo = undefined
    @Link quotedMessage: Message | null
    // for audioRecorderView
    @Link showAudioRecorderView: boolean
    @Link showCancelRecordIndicator: boolean
    @Link recordCountDown: number
    @Link @Watch('onCollapseConversationInputPanelView') collapseConversationInputPanelViewTimestamp: number
    // 取消多选时，需要先将 enableMultiCheck 置为 false，在清空 checkedMessages
    @Link enableMultiCheck: boolean
    @Link checkedMessages: Message[]
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private messageListScroller?: Scroller
    private textInputBottomWhenBlur: number = 0
    private textInputController: TextInputController = new TextInputController()
    private recordTouchDownY: number = 0
    private recorder?: AudioRecordManager
    private recordOutputAudioFile: string = ''
    private recordAudioStartMillis: number = 0
    private forwardMessageDialogController?: CustomDialogController
    private deleteMessageDialogController?: CustomDialogController
    private groupId = ''
    @Link @Watch('onLongPressToMentionUser') longPressToMentionUser: string
    private mentions: MentionBlock[] = []
    @State showExtContentCoverModal: boolean = false
    private voipAudioOnly: boolean = false
    private forwardDialogController?: CustomDialogController
    private conversationExts: ConversationExt[] = [
        {
            title: '相册',
            icon: $r('app.media.ic_func_pic'),
            action: async () => {
                try {
                    let results = await selectMedia2(getContext());
                    results.forEach(async result => {
                        if (result.type === 2) {
                            let filePath = getContext(this)
                                .getApplicationContext()
                                .cacheDir + '/' + new Date().getTime() + '.mp4'
                            copyFileUri(result.uri, filePath);
                            let content = new VideoMessageContent(filePath, '', result.thumbnail, result.duration)
                            wfc.sendConversationMessage(this.conversation, content, [], null, null, null, null, null);
                            return
                        } else {
                            // 通过request包上传时，只能使用 applicationContext.cacheDir 目录下的文件
                            let filePath = getContext(this)
                                .getApplicationContext()
                                .cacheDir + '/' + new Date().getTime() + '.jpg'
                            copyFileUri(result.uri, filePath);
                            let content = new ImageMessageContent(filePath, '', result.thumbnail)
                            content.imageWidth = result.width;
                            content.imageHeight = result.height;
                            wfc.sendConversationMessage(this.conversation, content, [], null, null, null, null, null);
                        }
                    })
                } catch (reason) {
                    showToast('选取照片失败: ' + reason)
                }
            }
        },
        {
            title: '视频通话',
            icon: $r('app.media.ic_func_video'),
            action: () => {
                let voipDialogController = new CustomDialogController({
                    builder: ActionSheetDialog({
                        sheets: [
                            {
                                title: '视频通话',
                                action: async () => {
                                    voipDialogController.close()
                                    let cameraGranted = await checkAndRequestPermission(getContext(this), 'ohos.permission.CAMERA')
                                    let microphoneGranted = await checkAndRequestPermission(getContext(this), 'ohos.permission.MICROPHONE')
                                    if (cameraGranted && microphoneGranted) {
                                        if (this.conversation.type === ConversationType.Single) {
                                            avenginekit.startCall(this.conversation, [this.conversation.target], false)
                                        } else if (this.conversation.type === ConversationType.Group) {
                                            this.showExtContentCoverModal = true
                                            this.extContentCoverBuilderParam = this.pickGroupMemberModal
                                            this.voipAudioOnly = false
                                        } else {

                                        }
                                    } else {
                                        showToast('请授予摄像头和麦克风权限')
                                    }
                                }
                            },
                            {
                                title: '音频通话',
                                action: async () => {
                                    voipDialogController.close()
                                    let granted = await checkAndRequestPermission(getContext(this), 'ohos.permission.MICROPHONE')
                                    if (granted) {
                                        if (this.conversation.type === ConversationType.Single) {
                                            avenginekit.startCall(this.conversation, [this.conversation.target], true)
                                        } else if (this.conversation.type === ConversationType.Group) {
                                            this.showExtContentCoverModal = true
                                            this.extContentCoverBuilderParam = this.pickGroupMemberModal
                                            this.voipAudioOnly = true
                                        }
                                    } else {
                                        showToast('请授予麦克风权限')
                                    }
                                }
                            }
                        ]
                    }),
                    autoCancel: true,
                    alignment: DialogAlignment.Center,
                    gridCount: 6,
                    customStyle: false
                })

                voipDialogController.open()
            }
        },
        {
            title: '拍摄',
            icon: $r('app.media.ic_func_shot'),
            action: async () => {
                try {
                    let results = await takePhoto(getContext() as common.UIAbilityContext)
                    results.forEach(async result => {
                        if (result.type === 2) {
                            let filePath = getContext(this)
                                .getApplicationContext()
                                .cacheDir + '/' + new Date().getTime() + '.mp4'
                            copyFileUri(result.uri, filePath);
                            let content = new VideoMessageContent(filePath, '', result.thumbnail, result.duration)
                            wfc.sendConversationMessage(this.conversation, content, [], null, null, null, null, null);
                            return
                        } else {
                            // 通过request包上传时，只能使用 applicationContext.cacheDir 目录下的文件
                            let filePath = getContext(this)
                                .getApplicationContext()
                                .cacheDir + '/' + new Date().getTime() + '.jpg'
                            copyFileUri(result.uri, filePath);
                            let content = new ImageMessageContent(filePath, '', result.thumbnail)
                            content.imageWidth = result.width;
                            content.imageHeight = result.height;
                            wfc.sendConversationMessage(this.conversation, content, [], null, null, null, null, null);
                        }
                    })
                } catch (reason) {
                    showToast('拍摄照片失败: ' + reason)
                }
            }
        },
        {
            title: '文件',
            icon: $r('app.media.ic_func_file'),
            action: async () => {
                try {
                    let selectedFileUri = await selectFile()
                    let name = fileNameFromFileUri(selectedFileUri)
                    let filePath = getContext(this)
                        .getApplicationContext()
                        .cacheDir + '/' + new Date().getTime() + '-' + name
                    copyFileUri(selectedFileUri, filePath);
                    let size = fileSize(filePath);
                    let content: MessageContent
                    if (isImage(name.substring(name.lastIndexOf('.') + 1))) {
                        let thumbnail = await imageThumbnail(getContext(this), fileUri.getUriFromPath(filePath), { width: 200, height: 200 })
                        content = new ImageMessageContent(filePath, '', thumbnail)
                    } else if (isVideo(name.substring(name.lastIndexOf('.') + 1))) {
                        let durationAndThumbnail = await videoThumbnail(getContext(this), fileUri.getUriFromPath(filePath), { width: 200, height: 200 })
                        content = new VideoMessageContent(filePath, '', durationAndThumbnail.thumbnail, durationAndThumbnail.duration)
                    } else {
                        content = new FileMessageContent(filePath, '', name, size)
                    }
                    wfc.sendConversationMessage(this.conversation, content);
                } catch (reason) {
                    showToast('选择文件失败: ' + reason)
                }
            }
        },
        {
            title: '位置',
            icon: $r('app.media.ic_func_location'),
            action: () => {
                showToast('TODO')
            }
        },
        {
            title: '名片',
            icon: $r('app.media.ic_user_card'),
            action: () => {
                this.showExtContentCoverModal = true
                this.extContentCoverBuilderParam = this.pickSingleContactModal
            }
        }
    ]
    private multiCheckAction: MultiCheckAction[] = [
        {
            title: '删除',
            icon: $r('app.media.ic_delete'),
            action: () => {
                AlertDialog.show({
                    message: '确定删除？',
                    autoCancel: true,
                    alignment: DialogAlignment.Center,
                    gridCount: 4,
                    primaryButton: {
                        value: '取消',
                        action: () => {
                        }
                    },
                    secondaryButton: {
                        value: '确定',
                        fontColor: Color.Red,
                        action: () => {
                            this.deleteMessageDialogController = new CustomDialogController({
                                builder: ActionSheetDialog({
                                    title: '删除消息?',
                                    controller: this.deleteMessageDialogController,
                                    sheets: [
                                        {
                                            title: '删除本地消息',
                                            action: () => {
                                                this.checkedMessages.forEach(msg => {
                                                    wfc.deleteMessage(msg.messageId);
                                                })

                                                this.enableMultiCheck = false
                                                this.checkedMessages = []
                                            }
                                        },
                                        {
                                            title: '删除远程消息',
                                            action: () => {
                                                this.checkedMessages.forEach(msg => {
                                                    wfc.deleteRemoteMessageByUid(msg.messageUid, () => {
                                                    }, (err: number) => {
                                                        showToast('删除远程消息失败' + err)
                                                    })
                                                })

                                                this.enableMultiCheck = false
                                                this.checkedMessages = []
                                            }
                                        }
                                    ]
                                }),
                                autoCancel: true,
                                alignment: DialogAlignment.Center,
                                gridCount: 6,
                                customStyle: false
                            })

                            this.deleteMessageDialogController.open()
                        }
                    }
                })
            }
        },
        {
            title: '转发',
            icon: $r('app.media.ic_forward'),
            action: () => {
                this.forwardMessageDialogController = new CustomDialogController({
                    builder: ActionSheetDialog({
                        title: '',
                        controller: this.forwardMessageDialogController,
                        sheets: [
                            {
                                title: '逐条转发',
                                action: () => {
                                    this.mainNavPathStack.pushPathByName(navigationDestinations.ForwardMessagePage, {
                                        'messages': this.checkedMessages,
                                        'forwardType': 'oneByOne',
                                    } as Record<string, Object>)
                                    // TODO 转发完成之后，再重置
                                    this.enableMultiCheck = false
                                    this.checkedMessages = []
                                }
                            },
                            {
                                title: '合并转发',
                                action: () => {
                                    this.mainNavPathStack.pushPathByName(navigationDestinations.ForwardMessagePage, {
                                        'messages': this.checkedMessages,
                                        'forwardType': 'compose',
                                    } as Record<string, Object>)
                                    // TODO 转发完成之后，再重置
                                    this.enableMultiCheck = false
                                    this.checkedMessages = []
                                }
                            }
                        ]
                    }),
                    autoCancel: true,
                    alignment: DialogAlignment.Center,
                    gridCount: 6,
                    customStyle: false
                })

                this.forwardMessageDialogController.open()
            }
        }
    ]

    onCollapseConversationInputPanelView(propName: string) {
        if (!this.collapseConversationInputPanelViewTimestamp) {
            return
        }
        this.showEmojiPanel = false
        this.showExtPanel = false
        this.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)
        setTimeout(() => {
            this.collapseConversationInputPanelViewTimestamp = 0
        }, 100)
    }

    onExpandConversationInputPanelView(propName: string) {
        console.log('on onExpandConversationInputPanelView', this.showEmojiPanel, this.showExtPanel);
        if (this.showEmojiPanel || this.showExtPanel) {
            this.scrollMessageListToBottom();
        }
    }

    private scrollMessageListToBottom() {
        if (!this.messageListScroller?.isAtEnd()) {
            animateTo({ curve: curves.responsiveSpringMotion() }, () => {
                this.messageListScroller!.scrollEdge(Edge.Bottom);
            })
        }
    }

    private onLongPressToMentionUser(propName: string) {
        if (!this.longPressToMentionUser) {
            return
        }
        let userInfo = wfc.getUserInfo(this.longPressToMentionUser, false, this.groupId!)
        this.onMentionGroupMember(userInfo)
        this.longPressToMentionUser = ''
    }

    onMentionGroupMember = (userInfo: UserInfo) => {
        this.showMentionSheet = false;
        let mentionText = '@' + wfc.getGroupMemberDisplayNameEx(userInfo, true)
        this.text = this.text + mentionText + ' ';
        this.mentions.push({
            target: userInfo.uid,
            text: mentionText
        })
    }

    aboutToAppear() {
        // 计算软键盘高度
        window.getLastWindow(getContext(this)).then(currentWindow => {
            let property = currentWindow.getWindowProperties();

            let preference = preferences.getPreferencesSync(getContext(this).getApplicationContext(), { name: 'wfcstore' })
            let keyboardHeight = preference.getSync('keyboardHeight', 0) as number
            if (keyboardHeight > 0) {
                this.keyboardHeight = keyboardHeight;
            }
            // currentWindow.on('avoidAreaChange', async data => {
            //     if (data.type === window.AvoidAreaType.TYPE_KEYBOARD) {
            //         this.messageListScroller!.scrollEdge(Edge.Bottom);
            //         if (data.area.bottomRect.height > 0) {
            //             this.scrollMessageListToBottom()
            //         }
            //     }
            // })
            currentWindow.on('keyboardHeightChange', async (data: number) => {

                if (data > 0) {
                    let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR; // 底部导航条
                    let navIndicatorAvoidArea = currentWindow.getWindowAvoidArea(type);
                    let h = px2vp(data - navIndicatorAvoidArea.bottomRect.height);
                    if (this.keyboardHeight !== h) {
                        this.keyboardHeight = h
                        preference.put('keyboardHeight', h);
                    }
                }
                this.scrollMessageListToBottom()
            })
        })

        if (this.conversation.type === ConversationType.Group) {
            this.groupId = this.conversation.target;
            this.updateGroupConversationMuteState()
        } else if (this.conversation.type === ConversationType.Channel) {
            this.channelInfo = wfc.getChannelInfo(this.conversation.target)
        }

        this.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);

        if (this.conversationInfo.draft) {
            this.text = this.conversationInfo.draft;
        }

        wfc.eventEmitter?.on(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
        wfc.eventEmitter?.on(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter?.on(EventType.ChannelInfosUpdate, this.onChannelInfoUpdate)
    }

    updateGroupConversationMuteState() {
        let groupInfo = wfc.getGroupInfo(this.conversation.target, true)
        let groupMember = wfc.getGroupMember(this.groupId, wfc.getUserId())
        if (groupInfo.mute === 1) {
            if ([GroupMemberType.Owner, GroupMemberType.Manager, GroupMemberType.Allowed].indexOf(groupMember.type) >= 0) {
                this.muted = false;
            } else {
                this.muted = true;
            }
        } else {
            if ([GroupMemberType.Muted, GroupMemberType.Removed].indexOf(groupMember.type) >= 0) {
                this.muted = true
            } else {
                this.muted = false
            }
        }
    }

    aboutToDisappear(): void {
        if (this.text.trim()) {
            wfc.setConversationDraft(this.conversation, this.text.trim())
        }
        wfc.eventEmitter?.off(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
        wfc.eventEmitter?.off(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter?.off(EventType.ChannelInfosUpdate, this.onChannelInfoUpdate)
    }

    onGroupMembersUpdate = (groupId: string, groupMembers: GroupMember[]) => {
        if (this.conversation.type === ConversationType.Group && groupId === this.groupId) {
            this.updateGroupConversationMuteState()
        }
    }
    onChannelInfoUpdate = (channelInfos: ChannelInfo[]) => {
        if (this.conversation.type === ConversationType.Channel) {
            for (let info of channelInfos) {
                if (info.channelId === this.conversation.target) {
                    this.channelInfo = info
                    break
                }
            }
        }

    }
    onGroupInfosUpdate = (groupInfos: GroupInfo[]) => {
        if (this.conversation.type === ConversationType.Group) {
            for (let info of groupInfos) {
                if (info.target === this.groupId) {
                    this.updateGroupConversationMuteState()
                    break
                }
            }
        }
    }

    async startRecordAudio() {
        if (!this.recorder) {
            this.recorder = new AudioRecordManager()
        }

        let cacheDir = getContext(this).getApplicationContext().cacheDir;
        let audioDir = `${cacheDir}/audio`
        try {
            fs.mkdirSync(audioDir)
        } catch (e) {

        }

        this.recordAudioStartMillis = new Date().getTime()

        this.recordOutputAudioFile = audioDir + '/' + this.recordAudioStartMillis + '.m4a'
        console.log('record audioFile', this.recordOutputAudioFile)

        let fd = fs.openSync(this.recordOutputAudioFile, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
        this.recorder.start(fd.fd);
    }

    async stopRecordAudio(canceled: boolean) {
        await this.recorder!.finish()
        let stat = fs.statSync(this.recordOutputAudioFile)
        console.log('AudioRecordManager', 'record file size', stat.size)

        if (canceled || stat.size === 0) {
            showToast('获取录音文件失败')
            return;
        }
        let audioMessageContent = new SoundMessageContent(this.recordOutputAudioFile, '', Math.round((new Date().getTime() - this.recordAudioStartMillis) / 1000))
        wfc.sendConversationMessage(this.conversation, audioMessageContent, [], null, null, null, null, null)
        this.recordOutputAudioFile = ''
    }

    openChannelMenu(menu: ChannelMenu) {
        let content = new ChannelMenuEventMessageContent(menu)
        wfc.sendConversationMessage(this.conversation, content)

        switch (menu.type) {
            case 'view':
                if (menu.url) {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.WebViewPage, {
                        'url': menu.url,
                        'title': menu.name
                    } as Record<string, Object>)
                }
                break
            case 'miniprogram':
                break
            default:
                break
        }
    }

    @Builder
    channelSubMenus(channelMenu: ChannelMenu) {
        if (channelMenu.subMenus.length > 0) {
            Menu() {
                ForEach(channelMenu.subMenus, (subMenu: ChannelMenu) => {
                    MenuItem({ content: subMenu.name })
                        .onClick(() => {
                            this.openChannelMenu(subMenu)
                        })
                })
            }

        } else {
            // nothing
        }
    }

    @Builder
    dummyContentCoverBuilder() {
    }

    // 发送名片、发起群音视频通话时，为其赋不同的具体 builder
    @BuilderParam extContentCoverBuilderParam: () => void = this.dummyContentCoverBuilder

    @Builder
    pickGroupMemberModal() {
        PickGroupMemberModal({
            groupId: this.conversation.target,
            title: '选择群成员',
            initialCheckedUserIds: [wfc.getUserId()],
            uncheckableUserIds: [wfc.getUserId()],
            showPickGroupMemberModal: $showExtContentCoverModal,
            onPickResult: (users: UserInfo[]) => {
                avenginekit.startCall(this.conversation, users.map(user => user.uid), this.voipAudioOnly)
            }
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    @Builder
    pickSingleContactModal() {
        PickContactModal({
            showPickContactModal: $showExtContentCoverModal,
            onClickUser: (user: UserInfo) => {
                this.showExtContentCoverModal = false
                this.sendUserCard(user)
            },
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    sendUserCard(userInfo: UserInfo) {
        let userCard = new CardMessageContent(0, userInfo.uid, userInfo.displayName, userInfo.portrait, wfc.getUserId())
        this.forwardDialogController = new CustomDialogController({
            builder: ForwardMessageDialog({
                targetConversations: [this.conversation],
                controller: this.forwardDialogController,
                forwardMessageDesc: userCard.digest(),
                forwardMessageImageUri: userInfo.portrait,
                cancel: () => {
                    this.forwardMessageDialogController = undefined
                },
                confirm: (text) => {
                    wfc.sendConversationMessage(this.conversation, userCard)
                    this.forwardMessageDialogController = undefined
                }
            }),
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            customStyle: false
        })

        this.forwardDialogController.open()
    }

    build() {
        if (this.enableMultiCheck) {
            Row() {
                ForEach(this.multiCheckAction, (mcaction: MultiCheckAction) => {
                    Image(mcaction.icon)
                        .width(20)
                        .height(20)
                        .onClick(mcaction.action)
                }, (mcaction: MultiCheckAction, index: number) => {
                    return index + ''
                })
            }
            .enabled(this.checkedMessages.length > 0)
            .padding(10)
            .height(INPUT_ICON_WIDTH + 10)
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
        } else if (this.muted) {
            Row() {
                Text('群禁言或者群已被解散')
            }
            .padding(10)
            .height(INPUT_ICON_WIDTH + 10)
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
        } else {
            Column() {
                Row() {
                    if (this.conversation.type === ConversationType.Channel) {
                        Image(this.showChannelMenu ? $r('app.media.ic_chat_keyboard') : $r('app.media.ic_chat_menu'))
                            .draggable(false)
                            .id('channelMenu')
                            .margin({ right: 10 })
                            .width(INPUT_ICON_WIDTH)
                            .height(INPUT_ICON_WIDTH)
                            .onClick(() => {
                                if (this.channelInfo!.menus.length > 0) {
                                    this.showChannelMenu = !this.showChannelMenu
                                    this.showAudioRecorderButton = false
                                    this.showExtPanel = false
                                    this.showEmojiPanel = false
                                } else {
                                    showToast('频道暂未配置菜单')
                                }
                            })
                    }
                    if (this.showChannelMenu) {
                        Row() {
                            ForEach(this.channelInfo?.menus, (menu: ChannelMenu) => {
                                Text(menu.name)
                                    .height('100%')// .padding(10)
                                    .layoutWeight(1)
                                    .textAlign(TextAlign.Center)
                                    .borderRadius(4)
                                    .stateStyles({
                                        pressed: {
                                            .backgroundColor('#E5E5E5')
                                        },
                                        normal: {
                                            .backgroundColor('#F7F7F7')
                                        }
                                    })
                                    .onClick(() => {
                                        if (menu.subMenus.length === 0) {
                                            this.openChannelMenu(menu)
                                        }
                                    })
                                    .bindMenu(this.channelSubMenus(menu))
                            })
                        }
                        .justifyContent(FlexAlign.SpaceAround)
                        .height(40)
                        .layoutWeight(1)
                    } else {
                        Image($r('app.media.ic_chat_voice'))
                            .id('audio')
                            .width(INPUT_ICON_WIDTH)
                            .height(INPUT_ICON_WIDTH)
                            .onClick(() => {
                                this.showAudioRecorderButton = !this.showAudioRecorderButton
                                this.showExtPanel = false
                                this.showEmojiPanel = false
                            })
                        if (!this.showAudioRecorderButton) {
                            Column() {
                                TextInput({ text: this.text, controller: this.textInputController })
                                    .id('textInput')
                                    .onChange(value => {
                                        // TODO 优化，mentionview 弹出逻辑
                                        // FIXME
                                        if (this.text + "@" === value && this.conversation.type === ConversationType.Group) {
                                            this.showMentionSheet = true;
                                        } else {
                                            this.text = value
                                        }
                                    })// .caretPosition(this.caretPosition)
                                    .onFocus(() => {
                                        this.textInputFocused = true
                                    })
                                    .focusable(this.collapseConversationInputPanelViewTimestamp === 0)
                                    .onBlur(() => {
                                        this.textInputFocused = false
                                    })
                                    .onClick((event) => {
                                        // this.showExtPanel = false
                                        // this.showEmojiPanel = false
                                    })
                                    .onTextSelectionChange((selectionStart, selectionEnd) => {
                                        this.selectionStart = selectionStart;
                                        this.selectionEnd = selectionEnd;
                                        this.caretPosition = selectionStart;
                                    })
                                    .height(40)
                                    .borderRadius(4)
                                    .backgroundColor('#FDFDFD')

                                if (this.quotedMessage) {
                                    Row() {
                                        Text(this.quotedMessage.messageContent.digest(this.quotedMessage))
                                            .maxLines(2)
                                            .layoutWeight(1)
                                        Image($r('app.media.ic_delete'))
                                            .width(15)
                                            .height(15)
                                            .padding(2)
                                            .margin({ left: 10 })
                                            .draggable(false)
                                            .borderRadius(10)
                                            .backgroundColor('#B3B3B3')
                                            .onClick(() => {
                                                this.quotedMessage = null
                                            })
                                    }
                                    .margin({ top: 10 })
                                    .padding(8)
                                    .borderRadius(4)
                                    .backgroundColor('#EAEAEA')
                                }
                            }
                            .margin({ left: 10, right: 10 })
                            .layoutWeight(1)
                        } else {
                            Button('按住录音')
                                .layoutWeight(1)
                                .margin({ left: 10, right: 10 })
                                .borderRadius(4)
                                .fontColor('#7E7E7E')// .backgroundColor('#F3F3F3')
                                .type(ButtonType.Normal)
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor('#E5E5E5')
                                    },
                                    normal: {
                                        .backgroundColor(Color.White)
                                    }
                                })
                                .onTouch(async event => {
                                    event.stopPropagation()
                                    if (event.type === TouchType.Down) {
                                        let deniedPermissions = await checkPermissions(getContext(this), ['ohos.permission.MICROPHONE'])
                                        if (deniedPermissions.length === 0) {
                                            this.startRecordAudio()
                                            this.showAudioRecorderView = true
                                            this.showCancelRecordIndicator = false
                                            this.recordTouchDownY = event.touches[0].screenY
                                        } else {
                                            checkAndRequestPermission(getContext(this), 'ohos.permission.MICROPHONE')
                                        }
                                    } else {
                                        if (!this.showAudioRecorderView) {
                                            return
                                        }
                                        if (event.type === TouchType.Up) {
                                            this.stopRecordAudio(this.showCancelRecordIndicator)
                                            this.showAudioRecorderView = false
                                            this.showCancelRecordIndicator = false
                                        } else if (event.type === TouchType.Move) {
                                            let y = event.touches[0].screenY;
                                            if (this.recordTouchDownY - y > 100) {
                                                this.showCancelRecordIndicator = true;
                                            } else {
                                                this.showCancelRecordIndicator = false;
                                            }
                                        } else if (event.type === TouchType.Cancel) {
                                        }
                                    }
                                })
                        }

                        Image(this.textInputFocused || !this.showEmojiPanel ? $r('app.media.ic_chat_emo') : $r('app.media.ic_chat_keyboard'))
                            .width(INPUT_ICON_WIDTH)
                            .height(INPUT_ICON_WIDTH)
                            .focusable(true)
                            .defaultFocus(false)
                            .focusOnTouch(true)
                            .onClick(() => {
                                this.showExtPanel = false
                                this.showEmojiPanel = !this.showEmojiPanel;
                                if (!this.showEmojiPanel) {
                                    focusControl.requestFocus('textInput')
                                    this.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)
                                }
                                this.textInputFocused = false;
                                this.showAudioRecorderButton = false
                            })
                        if (this.text.trim().length > 0) {
                            Button('发送')
                                .type(ButtonType.Normal)
                                .margin({ left: 10 })
                                .height(INPUT_ICON_WIDTH)
                                .borderRadius(4)
                                .onClick(() => {
                                    let textMessageContent = new TextMessageContent(this.text);
                                    if (this.mentions.length > 0) {
                                        for (const mention of this.mentions) {
                                            if (this.text.indexOf(mention.text) >= 0) {
                                                if (mention.target === '@all') {
                                                    textMessageContent.mentionedType = 2;
                                                    break
                                                } else {
                                                    if (textMessageContent.mentionedTargets.indexOf(mention.target) === -1) {
                                                        textMessageContent.mentionedTargets.push(mention.target)
                                                    }
                                                }
                                            }
                                        }
                                        this.mentions = []
                                    }

                                    if (this.quotedMessage) {
                                        textMessageContent.quoteInfo = QuoteInfo.initWithMessage(this.quotedMessage!)
                                    }
                                    wfc.sendConversationMessage(this.conversation, textMessageContent, [], null, null, null, null, null);
                                    wfc.setConversationDraft(this.conversation, '')
                                    this.text = '';
                                    this.quotedMessage = null
                                })
                        } else {
                            Image($r('app.media.ic_chat_add'))
                                .width(INPUT_ICON_WIDTH)
                                .height(INPUT_ICON_WIDTH)
                                .margin({ left: 10 })
                                .focusable(true)
                                .focusOnTouch(true)
                                .onClick(() => {
                                    this.showExtPanel = true
                                    this.showEmojiPanel = false
                                    this.showAudioRecorderButton = false
                                })
                        }
                    }
                }
                .alignItems(VerticalAlign.Center)
                .padding(10)
                .width('100%')

                if (this.showExtPanel) {
                    Grid() {
                        ForEach(this.conversationExts, (ext: ConversationExt) => {
                            GridItem() {
                                Column() {
                                    Image(ext.icon)
                                        .width(60)
                                        .draggable(false)
                                        .height(60)
                                    Text(ext.title)
                                        .margin({ top: 8 })
                                        .fontSize(12)
                                }
                                .borderRadius(4)
                                .margin(10)
                                .padding(4)
                                .onClick(ext.action)
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor('#E5E5E5')
                                    },
                                    normal: {
                                        .backgroundColor(Color.White)
                                    }
                                })
                            }

                        }, (ext: ConversationExt) => ext.title)
                    }
                    .columnsTemplate('1fr 1fr 1fr 1fr')
                    .columnsGap(10)
                    .rowsGap(10)
                    .margin(0)
                    .padding(0)
                    .width('100%')
                    .height(this.keyboardHeight)
                    .onAppear(() => {
                        this.setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET)
                    })
                    .bindContentCover(this.showExtContentCoverModal, this.extContentCoverBuilderParam, {
                        modalTransition: ModalTransition.DEFAULT,
                        onAppear: () => {
                        },

                        onDisappear: () => {
                            this.showExtContentCoverModal = false
                        }
                    })
                }

                if (this.showEmojiPanel) {
                    EmojiInputPanelView({
                        text: $text,
                        caretPosition: $caretPosition,
                        selectionStart: this.selectionStart,
                        selectionEnd: this.selectionEnd,
                        conversation: this.conversation,
                    })
                        .focusable(true)
                        .width('100%')
                        .margin(0)
                        .padding(0)
                        .height(this.keyboardHeight)
                        .onAppear(() => {
                            this.setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET)
                        })
                }
            }
            .enabled(this.enable)
            .onAppear(() => {
                this.enable = true
            })
            .backgroundColor('#F7F7F7')

            .bindSheet(this.showMentionSheet, MentionGroupMemberView(this.groupId, this.onMentionGroupMember), {
                height: '70%',
                dragBar: false,
                showClose: false,
                onDisappear: () => {
                    this.showMentionSheet = false
                }
            })
        }
    }

    setKeyboardAvoidMode(value: KeyboardAvoidMode) {
        let windowStage = AppStorage.get<window.Window>('window')
        windowStage?.getUIContext().setKeyboardAvoidMode(value);
    }
}

interface MentionBlock {
    /**
     * \@all 表示@所有人
     */
    target: string,

    /**
     * \@小火
     */
    text: string
}
