import common from '@ohos.app.ability.common'
import { copyFileUri, fileNameFromFileUri, fileSize } from '../../common/utils/FileUtil'
import { showToast } from '../../common/utils/Toast'
import { MediaResult, selectFile, selectMedia, sendMediaResult, takePhoto } from '../../helper/mediaHelper'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import AudioRecordManager from './audio/AudioRecordManager'
import fs from '@ohos.file.fs'
import SoundMessageContent from '@wfc/client/src/main/ets/wfc/messages/soundMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import BottomActionSheetDialog from '../../view/BottomActionSheetDialog'
import EmojiInputPanelView from './emoji/EmojiInputPanelView'
import { config as emojiConfig } from './emoji/EmojiAndStickerConfig'
import { Emoji } from './emoji/emojis'
import { KeyboardAvoidMode, window } from '@kit.ArkUI'
import MentionGroupMemberView from './mention/MentionGroupMemberView'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import { isWideScreen } from '../../util/navUtil'
import { preferences } from '@kit.ArkData'
import { TextStyleToken, FontSize, Radius } from '../../common/design/Tokens'
import avenginekit from '@wfc/avenginekit'
import MessageContent from '@wfc/client/src/main/ets/wfc/messages/messageContent'
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import { imageThumbnail, videoThumbnail } from '../../helper/imageVideoHelper'
import PickGroupMemberModal from '../group/PickGroupMemberModal'
import Config from '@wfc/client/src/main/ets/config'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import { isImage, isVideo } from '../../util/helper'
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType'
import GroupMember from '@wfc/client/src/main/ets/wfc/model/groupMember'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import ChannelInfo from '@wfc/client/src/main/ets/wfc/model/channelInfo'
import ChannelMenu from '@wfc/client/src/main/ets/wfc/model/channelMenu'
import ChannelMenuEventMessageContent from '@wfc/client/src/main/ets/wfc/messages/channelMenuEventMessageContent'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import QuoteInfo from '@wfc/client/src/main/ets/wfc/model/quoteInfo'
import PickContactModal from '../picker/PickContactModal'
import ForwardMessageDialog from './forward/ForwardMessageDialog'
import CardMessageContent from '@wfc/client/src/main/ets/wfc/messages/cardMessageContent'
import fileUri from '@ohos.file.fileuri'
import { checkAndRequestPermission, checkPermissions } from '../../helper/permissionHelper'
import AudioRecorderDialog, { AudioRecorderDialogState } from './audio/AudioRecorderDialog'
import { playRawSound } from '../../helper/soundEffectHelper'

const INPUT_ICON_WIDTH = 28
// 软键盘与自定义面板显示/隐藏的过渡动画时间
const PANEL_ANIM_COLLAPSE = 400
const PANEL_ANIM_EXPAND = 400

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
    @Link @Watch('onTextChange') text: string
    @State caretPosition: number = 0
    @State selectionStart: number = 0
    @State selectionEnd: number = 0
    @State @Watch('onFocusStateChanged') textInputFocused: boolean = false
    @State showEmojiPanel: boolean = false
    @State showExtPanel: boolean = false
    // 底部表情/加号面板的「显示高度」，用 animateTo 改变它来模拟软键盘的缓慢顶起/落下。
    // 配合 List.stackFromEnd，消息列表随之平滑移动。
    @State bottomPanelHeight: number = 0
    // 输入栏（图标/输入框那一行）的实测高度。this.keyboardHeight 比软键盘真正占据的高度多了一个
    // 输入栏的高度，面板高度需扣掉它，才能与软键盘等高，且与软键盘升起/落下时幅度相同而相互抵消。
    @State private inputBarHeight: number = 56
    // 软键盘当前是否弹起（用于判断「从软键盘切到面板」走键盘同步、还是「无键盘直接展开面板」走动画）。
    private keyboardShown: boolean = false
    // avoidAreaChange 去重：本机会连续回调多次相同的键盘避让高度。
    private lastKbAvoidPx: number = -1
    @State showMentionSheet: boolean = false
    @State @Watch('onKeyboardHeightChanged') keyboardHeight: number = 320
    @State showAudioRecorderButton: boolean = false
    @State showChannelMenu: boolean = false
    @State enable: boolean = false
    @State muted: boolean = false
    @State channelInfo?: ChannelInfo = undefined
    @Link quotedMessage: Message | null
    @Link @Watch('onCollapseConversationInputPanelView') collapseConversationInputPanelViewTimestamp: number
    // 取消多选时，需要先将 enableMultiCheck 置为 false，在清空 checkedMessages
    @Link enableMultiCheck: boolean
    @Link checkedMessages: Message[]
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    messageListScroller?: Scroller
    private textInputBottomWhenBlur: number = 0
    private textInputController: TextInputController = new TextInputController()
    private recordTouchDownY: number = 0
    private _cancelRecording: boolean = false
    private _recordingActive: boolean = false
    private audioDialogState: AudioRecorderDialogState = new AudioRecorderDialogState()
    private audioDialogController?: CustomDialogController
    private recorder?: AudioRecordManager
    private recordOutputAudioFile: string = ''
    private recordAudioStartMillis: number = 0
    private forwardMessageDialogController?: CustomDialogController
    private deleteMessageDialogController?: CustomDialogController
    private groupId = ''
    @Link @Watch('onLongPressToMentionUser') longPressToMentionUser: string
    private mentions: MentionBlock[] = []
    @State showExtContentCoverModal: boolean = false
    // 「猜你想发送」：与表情建议一样由 ConversationPage 渲染于输入栏上方；此处仅控制其显隐
    @Link recentPhotoRequested: boolean
    // Callbacks for ConversationPage-level overlays
    onPreviewChange?: (emoji: Emoji | null, col: number, colW: number, rowY: number) => void
    onSuggestionsChange?: (stickers: Emoji[]) => void
    onPanelHeightChange?: (h: number) => void
    private allStickers: Emoji[] = []
    private voipAudioOnly: boolean = false
    private forwardDialogController?: CustomDialogController
    private conversationExts: ConversationExt[] = [
        {
            title: '相册',
            icon: $r('app.media.ic_func_pic'),
            action: async () => {
                try {
                    let results = await selectMedia(getContext());
                    results.forEach((result: MediaResult) => {
                        sendMediaResult(getContext(this), this.conversation, result)
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
                    builder: BottomActionSheetDialog({
                        dismiss: () => {
                            voipDialogController.close()
                        },
                        sheets: [
                            {
                                title: '视频通话',
                                action: async () => {
                                    let cameraGranted = await checkAndRequestPermission(getContext(this), 'ohos.permission.CAMERA')
                                    let microphoneGranted = await checkAndRequestPermission(getContext(this), 'ohos.permission.MICROPHONE')
                                    if (cameraGranted && microphoneGranted) {
                                        if (this.conversation.type === ConversationType.Single) {
                                            avenginekit.startCall(this.conversation, [this.conversation.target], false)
                                        } else if (this.conversation.type === ConversationType.Group) {
                                            this.showExtContentCoverModal = true
                                            this.extContentCoverBuilderParam = this.pickGroupMemberToStartCallModal
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
                                    let granted = await checkAndRequestPermission(getContext(this), 'ohos.permission.MICROPHONE')
                                    if (granted) {
                                        if (this.conversation.type === ConversationType.Single) {
                                            avenginekit.startCall(this.conversation, [this.conversation.target], true)
                                        } else if (this.conversation.type === ConversationType.Group) {
                                            this.showExtContentCoverModal = true
                                            this.extContentCoverBuilderParam = this.pickGroupMemberToStartCallModal
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
                    alignment: AppStorage.get<string>('widthBreakpoint') !== 'sm' ? DialogAlignment.Center : DialogAlignment.Bottom,
                    gridCount: 4,
                    customStyle: true
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
                    results.forEach((result: MediaResult) => {
                        sendMediaResult(getContext(this), this.conversation, result)
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
                    let ext = name.substring(name.lastIndexOf('.') + 1).toLowerCase()
                    if (Config.DISABLED_SEND_FILE_TYPES.includes(ext)) {
                        showToast('不能发送该类型文件')
                        return
                    }
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
        // {
        //     title: '位置',
        //     icon: $r('app.media.ic_func_location'),
        //     action: () => {
        //         showToast('暂未实现')
        //     }
        // },
        {
            title: '名片',
            icon: $r('app.media.ic_user_card'),
            action: () => {
                if (isWideScreen()) {
                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PickContactPage, {
                        'onClickUser': (user: UserInfo) => {
                            this.sendUserCard(user)
                        }
                    } as Record<string, Object>)
                } else {
                    this.showExtContentCoverModal = true
                    this.extContentCoverBuilderParam = this.pickSingleContactModal
                }
            }
        },
        {
            title: '接龙',
            icon: $r('app.media.ic_func_collection'),
            action: () => {
                if (this.conversation.type !== ConversationType.Group) {
                    showToast('仅群组支持接龙');
                    return;
                }
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.CreateCollectionPage, {
                    'conversation': this.conversation
                } as Record<string, Object>)
            }
        },
        {
            title: '投票',
            icon: $rawfile('ic_ext_poll.svg'),
            action: () => {
                if (this.conversation.type !== ConversationType.Group) {
                    showToast('仅群组支持投票');
                    return;
                }
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PollHomePage, {
                    'groupId': this.conversation.target
                } as Record<string, Object>)
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
                        fontColor: $r('app.color.wf_danger'),
                        action: () => {
                            this.deleteMessageDialogController = new CustomDialogController({
                                builder: BottomActionSheetDialog({
                                    title: '删除消息?',
                                    dismiss: () => {
                                        this.deleteMessageDialogController?.close()
                                    },
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
                                alignment: AppStorage.get<string>('widthBreakpoint') !== 'sm' ? DialogAlignment.Center : DialogAlignment.Bottom,
                                gridCount: 4,
                                customStyle: true
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
                    builder: BottomActionSheetDialog({
                        title: '',
                        dismiss: () => {
                            this.forwardMessageDialogController?.close()
                        },
                        sheets: [
                            {
                                title: '逐条转发',
                                action: () => {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ForwardMessagePage, {
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
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ForwardMessagePage, {
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
                    alignment: AppStorage.get<string>('widthBreakpoint') !== 'sm' ? DialogAlignment.Center : DialogAlignment.Bottom,
                    gridCount: 4,
                    customStyle: true
                })

                this.forwardMessageDialogController.open()
            }
        }
    ]

    private onKeyboardHeightChanged(propName: string) {
        this.onPanelHeightChange?.(this.keyboardHeight)
    }

    private onFocusStateChanged() {
        if (this.textInputFocused) {
            this.onTextChange()
        }
    }

    onCollapseConversationInputPanelView(propName: string) {
        if (!this.collapseConversationInputPanelViewTimestamp) {
            return
        }
        this.recentPhotoRequested = false
        this.hidePanel()
        setTimeout(() => {
            this.collapseConversationInputPanelViewTimestamp = 0
        }, 100)
    }

    // 面板高度 = 软键盘在内容区撑开的真实高度（来自 avoidAreaChange）。与键盘等高，互切时输入框基本不动。
    private panelTargetHeight(): number {
        return this.keyboardHeight
    }

    // 软键盘显示与隐藏状态处理，配合 KeyboardAvoidMode.NONE 模式实现零抖动无缝切换
    private onKeyboardShownChange(shown: boolean) {
        if (shown) {
            this.showExtPanel = false
            this.showEmojiPanel = false
            this.onTextChange()
            animateTo({ duration: PANEL_ANIM_COLLAPSE, curve: Curve.Friction }, () => {
                this.bottomPanelHeight = this.keyboardHeight
            })
        } else {
            if (!this.showExtPanel && !this.showEmojiPanel) {
                animateTo({ duration: PANEL_ANIM_COLLAPSE, curve: Curve.Friction }, () => {
                    this.bottomPanelHeight = 0
                })
            }
        }
        this.scrollMessageListToBottom()
    }

    // 展开表情(emoji=true)或加号(emoji=false)面板。
    // 点击按钮已使输入框失焦 → 软键盘收起，avoidAreaChange 会与键盘收起并行把面板撑起（输入框不动）。
    // 若当前没有软键盘（直接点加号/表情），则这里直接用动画把面板撑起。
    private showPanel(emoji: boolean) {
        this.showExtPanel = !emoji
        this.showEmojiPanel = emoji
        this.onSuggestionsChange?.([])
        // 列表若不在最底部，先滚动到底，再升起面板（微信效果）
        this.scrollMessageListToBottom()
        if (!this.keyboardShown) {
            animateTo({ duration: PANEL_ANIM_EXPAND, curve: Curve.Friction }, () => {
                this.bottomPanelHeight = this.panelTargetHeight()
            })
        }
    }

    // 收起面板到「无」（点消息列表/语音/频道菜单）：缓慢落下到 0，结束后卸载面板内容。
    private hidePanel() {
        if (!this.showExtPanel && !this.showEmojiPanel) {
            return
        }
        animateTo({
            duration: PANEL_ANIM_COLLAPSE,
            curve: Curve.Friction,
            onFinish: () => {
                this.showExtPanel = false
                this.showEmojiPanel = false
                // 面板关闭后，按当前文本重新计算表情建议
                this.onTextChange()
            }
        }, () => {
            this.bottomPanelHeight = 0
        })
    }

    // 软键盘/表情/加号面板弹出时，消息列表已通过 List.stackFromEnd(true) 底部对齐：视口变矮时内容
    // 会随之上移、始终贴住底部，与面板一起平滑顶起，无需再额外滚动。此处仅作兜底（如运行环境不支持
    // stackFromEnd 时仍能贴底）；正常情况下列表已在底部，isAtEnd() 为真，不会触发多余滚动。
    private scrollMessageListToBottom() {
        if (!this.messageListScroller?.isAtEnd()) {
            // 用无过冲的缓动曲线，避免像弹簧那样冲过头再回弹
            animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
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

    private onTextChange() {
        const trimmed = this.text.trim()
        // 不再用 showEmojiPanel/showExtPanel 抑制：建议已是悬浮于输入栏上方的浮层，
        // 不会与面板冲突；这样用过 emoji/加号面板后输入匹配文字仍能正常出现表情建议
        if (trimmed.length === 0) {
            this.onSuggestionsChange?.([])
            return
        }
        const matches = this.allStickers.filter(emoji =>
        emoji.aliases.some(alias => alias !== 'sticker' && alias === trimmed)
        )
        this.onSuggestionsChange?.(matches)
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
    onMentionAll = () => {
        this.showMentionSheet = false;
        let mentionText = '@' + '所有人'
        this.text = this.text + mentionText + ' ';
        this.mentions.push({
            target: '@all',
            text: mentionText
        })
    }
    onMentionRobot = (userInfo: UserInfo) => {
        this.showMentionSheet = false;
        let mentionText = '@' + userInfo.displayName
        this.text = this.text + mentionText + ' ';
        this.mentions.push({
            target: userInfo.uid,
            text: mentionText
        })
    }

    aboutToAppear() {
        this.audioDialogController = new CustomDialogController({
            builder: AudioRecorderDialog({
                controller: this.audioDialogController!,
                dialogState: this.audioDialogState
            }),
            customStyle: true,
            autoCancel: false
        })

        // 本机不回调 keyboardHeightChange；改用 avoidAreaChange(TYPE_KEYBOARD) 获取真实软键盘高度与显隐时机。
        window.getLastWindow(getContext(this)).then(currentWindow => {
            let preference = preferences.getPreferencesSync(getContext(this).getApplicationContext(), { name: 'wfcstore' })
            let cached = preference.getSync('keyboardHeight', 0) as number
            if (cached > 0) {
                this.keyboardHeight = cached;
            }
            // 软键盘显隐：avoidAreaChange 在键盘开始显隐时给出最终避让高度（本机会连续回调多次相同值，用 lastKbAvoidPx 去重）。
            // 这里在键盘「开始」显隐的同一时刻、用与键盘同样的时长动画面板，使二者并行、输入框基本不动。
            currentWindow.on('avoidAreaChange', (data) => {
                if (data.type !== window.AvoidAreaType.TYPE_KEYBOARD) {
                    return
                }
                let kbPx = data.area.bottomRect.height
                if (kbPx === this.lastKbAvoidPx) {
                    return
                }
                this.lastKbAvoidPx = kbPx
                let shown = kbPx > 0
                this.keyboardShown = shown
                if (shown) {
                    // 真实软键盘在内容区撑开的高度 = 键盘避让高度 - 底部导航条安全区。
                    let navPx = currentWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height
                    let h = px2vp(kbPx - navPx)
                    if (h > 0 && Math.abs(this.keyboardHeight - h) > 0.5) {
                        this.keyboardHeight = h
                        preference.put('keyboardHeight', h)
                    }
                }
                this.onKeyboardShownChange(shown)
            })
        })

        if (this.conversation.type === ConversationType.Group) {
            this.groupId = this.conversation.target;
            this.updateGroupConversationMuteState()
        } else if (this.conversation.type === ConversationType.Channel) {
            this.channelInfo = wfc.getChannelInfo(this.conversation.target)
        }

        // 软键盘不自动避让，通过占位高度手动避让以防抖动
        setTimeout(() => {
            this.setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
        }, 100)

        if (this.conversationInfo.draft) {
            this.text = this.conversationInfo.draft;
        }

        wfc.eventEmitter?.on(EventType.GroupMembersUpdate, this.onGroupMembersUpdate)
        wfc.eventEmitter?.on(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
        wfc.eventEmitter?.on(EventType.ChannelInfosUpdate, this.onChannelInfoUpdate)

        let cfg = emojiConfig()
        this.allStickers = (cfg['emojis'] as Emoji[]).filter(e => e.category.startsWith('Sticker-'))
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
        if (this.text.trim() || this.conversationInfo.draft) {
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
        // playRawSound(getContext(this), 'ptt_begin.mp3')
    }

    async stopRecordAudio(canceled: boolean) {
        await this.recorder!.finish()
        // playRawSound(getContext(this), 'ptt_end.mp3')
        let stat = fs.statSync(this.recordOutputAudioFile)
        console.log('AudioRecordManager', 'record file size', stat.size)

        if (canceled || stat.size === 0) {
            showToast('获取录音文件失败')
            return;
        }
        let audioMessageContent = new SoundMessageContent(this.recordOutputAudioFile, '', Math.round((new Date().getTime() - this.recordAudioStartMillis) / 1000))
        wfc.sendConversationMessage(this.conversation, audioMessageContent, [], null, null, null, null, null)
        playRawSound(getContext(this), 'audido_msg_send_success.mp3')
        this.recordOutputAudioFile = ''
    }

    openChannelMenu(menu: ChannelMenu) {
        let content = new ChannelMenuEventMessageContent(menu)
        wfc.sendConversationMessage(this.conversation, content)

        switch (menu.type) {
            case 'view':
                if (menu.url) {
                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
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
    pickGroupMemberToStartCallModal() {
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
            .backgroundColor($r('app.color.wf_background'))
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
            .backgroundColor($r('app.color.wf_background'))
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
            alignment: AppStorage.get<string>('widthBreakpoint') !== 'sm' ? DialogAlignment.Center : DialogAlignment.Bottom,
            gridCount: 4,
            customStyle: true
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
            .padding(12)
            .height(INPUT_ICON_WIDTH + 10)
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
        } else if (this.muted) {
            Row() {
                Text('群禁言或者群已被解散')
            }
            .padding(12)
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
                            .margin({ right: 12, top: 6, bottom: 6 })
                            .width(INPUT_ICON_WIDTH)
                            .height(INPUT_ICON_WIDTH)
                            .onClick(() => {
                                if (this.channelInfo!.menus.length > 0) {
                                    this.showChannelMenu = !this.showChannelMenu
                                    this.showAudioRecorderButton = false
                                    this.hidePanel()
                                } else {
                                    showToast('频道暂未配置菜单')
                                }
                            })
                    }
                    if (this.showChannelMenu) {
                        Row() {
                            ForEach(this.channelInfo?.menus, (menu: ChannelMenu) => {
                                Text(menu.name)
                                    .height('100%')// .padding(12)
                                    .layoutWeight(1)
                                    .textAlign(TextAlign.Center)
                                    .borderRadius(Radius.sm)
                                    .stateStyles({
                                        pressed: {
                                            .backgroundColor('#E5E5E5')
                                        },
                                        normal: {
                                            .backgroundColor($r('app.color.wf_primary_background_color'))
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
                            .margin({top: 6, bottom: 6})
                            .onClick(() => {
                                this.recentPhotoRequested = false
                                this.showAudioRecorderButton = !this.showAudioRecorderButton
                                this.hidePanel()
                            })
                        if (!this.showAudioRecorderButton) {
                            Column() {
                                TextArea({ text: this.text, controller: this.textInputController })
                                    .id('textInput')
                                    .fontSize(TextStyleToken.inputText)
                                    .onChange(value => {
                                        if (this.text + "@" === value) {
                                            this.showMentionSheet = true;
                                        } else {
                                            this.text = value
                                        }
                                    })// .caretPosition(this.caretPosition)
                                    .onFocus(() => {
                                        this.recentPhotoRequested = false
                                        this.textInputFocused = true
                                        // 列表若不在最底部，先滚动到底，再升起键盘（微信效果）
                                        this.scrollMessageListToBottom()
                                        // 面板→软键盘的收面板动画由 avoidAreaChange（键盘升起时）与键盘并行处理，这里无需另处理。
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
                                    .textOverflow(TextOverflow.Clip)
                                    .wordBreak(WordBreak.BREAK_ALL)
                                    .constraintSize({ maxHeight: 80, minHeight: 40})
                                    .borderRadius(Radius.md)
                                    .backgroundColor($r('app.color.wf_background'))
                                    .fontColor($r('app.color.wf_primary_text'))
                                    .align(Alignment.Center)
                                    .alignSelf(ItemAlign.Center)
                                if (this.quotedMessage) {
                                    Row() {
                                        Text(this.quotedMessage.messageContent.digest(this.quotedMessage))
                                            .maxLines(2)
                                            .layoutWeight(1)
                                            .fontColor($r('app.color.wf_tertiary_text'))
                                        Image($r('app.media.ic_delete'))
                                            .width(16)
                                            .height(16)
                                            .padding(2)
                                            .margin({ left: 12 })
                                            .draggable(false)
                                            .borderRadius(Radius.xl)
                                            .backgroundColor($r('app.color.c_gray'))
                                            .onClick(() => {
                                                this.quotedMessage = null
                                            })
                                    }
                                    .margin({ top: 12 })
                                    .padding(8)
                                    .borderRadius(Radius.sm)
                                    .backgroundColor($r('app.color.wf_primary_background_color'))
                                }
                            }
                            .margin({ left: 12, right: 12 })
                            .layoutWeight(1)
                        } else {
                            Button('按住录音')
                                .layoutWeight(1)
                                .margin({ left: 12, right: 12 })
                                .borderRadius(Radius.sm)
                                .fontColor($r('app.color.wf_secondary_text'))// .backgroundColor('#F3F3F3')
                                .type(ButtonType.Normal)
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor($r('app.color.wf_item_pressed'))
                                    },
                                    normal: {
                                        .backgroundColor($r('app.color.wf_background'))
                                    }
                                })
                                .onTouch(async event => {
                                    event.stopPropagation()
                                    if (event.type === TouchType.Down) {
                                        let deniedPermissions = await checkPermissions(getContext(this), ['ohos.permission.MICROPHONE'])
                                        if (deniedPermissions.length === 0) {
                                            this.startRecordAudio()
                                            this._cancelRecording = false
                                            this._recordingActive = true
                                            this.audioDialogState.updateCancelIndicator(false)
                                            this.audioDialogController?.open()
                                            this.recordTouchDownY = event.touches[0].screenY
                                        } else {
                                            checkAndRequestPermission(getContext(this), 'ohos.permission.MICROPHONE')
                                        }
                                    } else {
                                        if (!this._recordingActive) {
                                            return
                                        }
                                        if (event.type === TouchType.Up) {
                                            this._recordingActive = false
                                            this.stopRecordAudio(this._cancelRecording)
                                            this._cancelRecording = false
                                            this.audioDialogController?.close()
                                        } else if (event.type === TouchType.Move) {
                                            let y = event.touches[0].screenY;
                                            let shouldCancel = this.recordTouchDownY - y > 100
                                            if (shouldCancel !== this._cancelRecording) {
                                                this._cancelRecording = shouldCancel
                                                this.audioDialogState.updateCancelIndicator(shouldCancel)
                                            }
                                        } else if (event.type === TouchType.Cancel) {
                                            this._recordingActive = false
                                            this.stopRecordAudio(false)
                                            this._cancelRecording = false
                                            this.audioDialogController?.close()
                                        }
                                    }
                                })
                        }

                        Image(this.textInputFocused || !this.showEmojiPanel ? $r('app.media.ic_chat_emo') : $r('app.media.ic_chat_keyboard'))
                            .width(INPUT_ICON_WIDTH)
                            .height(INPUT_ICON_WIDTH)
                            .margin({top: 6, bottom: 6})
                            .focusable(true)
                            .defaultFocus(false)
                            .focusOnTouch(true)
                            .onClick(() => {
                                this.recentPhotoRequested = false
                                if (this.showEmojiPanel) {
                                    // 已是表情面板 → 切回软键盘：聚焦输入框升起键盘，onFocus 里会收起面板
                                    focusControl.requestFocus('textInput')
                                } else {
                                    // 切到表情面板（点击按钮已移走输入框焦点 → 软键盘落下）
                                    this.showPanel(true)
                                }
                                this.textInputFocused = false;
                                this.showAudioRecorderButton = false
                            })
                        if (this.text.trim().length > 0) {
                            Button('发送')
                                .type(ButtonType.Normal)
                                .padding({
                                    left: 10,
                                    right: 10,
                                    top: 6,
                                    bottom: 6
                                })
                                .margin({ left: 12, top: 6, bottom: 6 })
                                .height(INPUT_ICON_WIDTH)
                                .borderRadius(Radius.sm)
                                .onClick(() => {
                                    this.recentPhotoRequested = false
                                    let textMessageContent = new TextMessageContent(this.text.trim());
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
                                                    textMessageContent.mentionedType = 1;
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
                                .margin({ left: 12, top: 6, bottom: 6 })
                                .focusable(true)
                                .focusOnTouch(true)
                                .onClick(() => {
                                    // 点加号：切换「猜你想发送」（再次点击则消失）；是否真正显示由 ConversationPage 按是否有新截图决定
                                    this.recentPhotoRequested = !this.recentPhotoRequested
                                    // 切到加号面板（点击按钮已移走输入框焦点 → 软键盘落下）
                                    this.showPanel(false)
                                    this.showAudioRecorderButton = false
                                })
                        }
                    }
                }
                .alignItems(VerticalAlign.Bottom)
                .padding(10)
                .width('100%')
                .onAreaChange((_, area) => {
                    // 实测输入栏高度，用于把面板高度修正到与软键盘等高
                    this.inputBarHeight = area.height as number
                })

                // 底部面板区：高度由 bottomPanelHeight 经 animateTo 缓慢变化（模拟软键盘顶起/落下），
                // clip 裁掉超出部分；内容随当前面板类型切换。高度与软键盘一致，配合 List.stackFromEnd
                // 让消息列表随之平滑移动。
                Column() {
                    if (this.showExtPanel) {
                        Grid() {
                            ForEach(this.conversationExts, (ext: ConversationExt) => {
                                GridItem() {
                                    Column() {
                                        Image(ext.icon)
                                            .width(60)
                                            .draggable(false)
                                            .height(60)
                                            .borderRadius(Radius.lg)
                                            .stateStyles({
                                                pressed: {
                                                    .backgroundColor($r('app.color.wf_item_pressed'))
                                                },
                                                normal: {
                                                    .backgroundColor($r('app.color.wf_background'))
                                                }
                                            })
                                        // 标签宽度不影响格子大小：占满格宽、居中、单行省略，
                                        // 避免「视频通话」等较长文案把扩展项撑得比别人大
                                        Text(ext.title)
                                            .margin({ top: 8 })
                                            .fontSize(FontSize.xs)
                                            .fontColor($r('app.color.wf_secondary_text'))
                                            .width('100%')
                                            .textAlign(TextAlign.Center)
                                            .maxLines(1)
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                    }
                                    .width('100%')
                                    .borderRadius(Radius.sm)
                                    .padding({ top: 8, bottom: 8 })
                                    .alignItems(HorizontalAlign.Center)
                                    .onClick(ext.action)
                                }

                            }, (ext: ConversationExt) => ext.title)
                        }
                        .columnsTemplate('1fr 1fr 1fr 1fr')
                        .columnsGap(10)
                        .rowsGap(10)
                        .margin(0)
                        .padding(0)
                        .width('100%')
                        .height('100%')
                        // 面板靠容器高度动画+裁剪平滑展开，自身不要默认的「从右侧滑入」出现动画
                        .transition(TransitionEffect.IDENTITY)
                        .backgroundColor($r('app.color.wf_primary_background_color'))
                        .bindContentCover(!isWideScreen() && this.showExtContentCoverModal, this.extContentCoverBuilderParam, {
                            modalTransition: ModalTransition.DEFAULT,
                            onAppear: () => {
                            },

                            onDisappear: () => {
                                this.showExtContentCoverModal = false
                            }
                        })
                    } else if (this.showEmojiPanel) {
                        EmojiInputPanelView({
                            text: $text,
                            caretPosition: $caretPosition,
                            selectionStart: this.selectionStart,
                            selectionEnd: this.selectionEnd,
                            conversation: this.conversation,
                            textInputController: this.textInputController,
                            onPreviewChange: this.onPreviewChange
                        })
                            .focusable(true)
                            .width('100%')
                            .margin(0)
                            .padding(0)
                            .height('100%')
                            .transition(TransitionEffect.IDENTITY)
                    }
                }
                .width('100%')
                .height(this.bottomPanelHeight)
                .clip(true)
            }
            .enabled(this.enable)
            .onAppear(() => {
                this.enable = true
            })
            .backgroundColor($r('app.color.wf_primary_background_color'))

            .bindSheet(this.showMentionSheet, MentionGroupMemberView(this.groupId, this.onMentionGroupMember, this.onMentionRobot, this.onMentionAll), {
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
