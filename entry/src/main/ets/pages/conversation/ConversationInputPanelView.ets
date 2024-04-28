import common from '@ohos.app.ability.common'
import { copyFileUri, fileSize } from '../../common/utils/FileUtil'
import { showToast } from '../../common/utils/Toast'
import { MediaHelper } from '../../helper/MediaHelper'
import wfc from '../../wfc/client/wfc'
import ImageMessageContent from '../../wfc/messages/imageMessageContent'
import TextMessageContent from '../../wfc/messages/textMessageContent'
import Conversation from '../../wfc/model/conversation'
import AudioRecordManager from './audio/AudioRecordManager'
import fs from '@ohos.file.fs'
import SoundMessageContent from '../../wfc/messages/soundMessageContent'
import Message from '../../wfc/messages/message'
import router from '@ohos.router'
import ActionSheetDialog from '../../view/ActionSheetDialog'
import EmojiInputPanelView from './emoji/EmojiInputPanelView'
import { GlobalContext } from '../../globalContext'
import { KeyboardAvoidMode, window } from '@kit.ArkUI'
import MentionGroupMemberView from './mention/MentionGroupMemberView'
import UserInfo from '../../wfc/model/userInfo'
import ConversationType from '../../wfc/model/conversationType'
import { preferences } from '@kit.ArkData'


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
    @Link conversation: Conversation
    @State text: string = ''
    @State caretPosition: number = 0
    @State selectionStart: number = 0
    @State selectionEnd: number = 0
    @State textInputFocused: boolean = false
    @State @Watch('onExpandConversationInputPanelView') showEmojiPanel: boolean = false
    @State @Watch('onExpandConversationInputPanelView') showExtPanel: boolean = false
    @State showMentionSheet: boolean = false
    @State keyboardHeight: number = 300
    @State showAudioRecorderButton: boolean = false
    @State enable:boolean = false
    // for audioRecorderView
    @Link showAudioRecorderView: boolean
    @Link showCancelRecordIndicator: boolean
    @Link recordCountDown: number
    @Link @Watch('onCollapseConversationInputPanelView') collapseConversationInputPanelViewTimestamp: number
    // 取消多选时，需要先将 enableMultiCheck 置为 false，在清空 checkedMessages
    @Link enableMultiCheck: boolean
    @Link checkedMessages: Message[]
    private messageListScroller?: Scroller
    private textInputBottomWhenBlur: number = 0
    private textInputController: TextInputController = new TextInputController()
    private mediaHelper: MediaHelper = new MediaHelper(getContext())
    private recordTouchDownY: number = 0
    private recorder?: AudioRecordManager
    private recordOutputAudioFile: string = ''
    private recordOutputAudioFileFd: number = 0
    private recordAudioStartMillis: number = 0
    private forwardMessageDialogController?: CustomDialogController
    private deleteMessageDialogController?: CustomDialogController
    private groupId = ''
    private mentions: MentionBlock[] = []
    private conversationExts: ConversationExt[] = [
        {
            title: '照片',
            icon: $r('app.media.ic_func_pic'),
            action: async () => {
                try {
                    let imgUris = await this.mediaHelper.selectPicture(9);
                    imgUris.forEach(imgUri => {
                        let file = getContext(this).cacheDir + '/' + new Date().getTime() + '.jpg'
                        copyFileUri(imgUri, file);
                        let size = fileSize(file);
                        let content = new ImageMessageContent(file, '', '')
                        wfc.sendConversationMessage(this.conversation, content, [], null, null, null, null, null);
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
                showToast('TODO')
            }
        },
        {
            title: '拍摄',
            icon: $r('app.media.ic_func_shot'),
            action: async () => {
                showToast('TODO')
                try {
                    let imgUri = await this.mediaHelper.takePhoto(getContext() as common.UIAbilityContext)
                    let file = getContext(this).cacheDir + '/' + new Date().getTime() + '.jpg'
                    copyFileUri(imgUri, file);
                    let size = fileSize(file);
                    let content = new ImageMessageContent(file, '', '')
                    wfc.sendConversationMessage(this.conversation, content);
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
                    let fileUri = await this.mediaHelper.selectFile()
                    let file = getContext(this).cacheDir + '/' + new Date().getTime() + '.jpg'
                    copyFileUri(fileUri, file);
                    let size = fileSize(file);
                    let content = new ImageMessageContent(file, '', '')
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
                showToast('TODO')
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
                                alignment: DialogAlignment.Default,
                                gridCount: 3,
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
                                    router.pushUrl({
                                        url: 'pages/conversation/forward/ForwardMessagePage',
                                        params: {
                                            messages: this.checkedMessages,
                                            forwardType: 'oneByOne',
                                        }
                                    })
                                    // TODO 转发完成之后，再重置
                                    this.enableMultiCheck = false
                                    this.checkedMessages = []
                                }
                            },
                            {
                                title: '合并转发',
                                action: () => {
                                    router.pushUrl({
                                        url: 'pages/conversation/forward/ForwardMessagePage',
                                        params: {
                                            messages: this.checkedMessages,
                                            forwardType: 'compose',
                                        }
                                    })
                                    // TODO 转发完成之后，再重置
                                    this.enableMultiCheck = false
                                    this.checkedMessages = []
                                }
                            }
                        ]
                    }),
                    autoCancel: true,
                    alignment: DialogAlignment.Default,
                    gridCount: 3,
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
        if (this.showEmojiPanel || this.showExtPanel) {
            this.messageListScroller!.scrollEdge(Edge.Bottom);
        }
    }

    onMentionGroupMember = (userInfo: UserInfo) => {
        this.showMentionSheet = false;
        let mentionText = '@' + userInfo.displayName;
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

            let preference = preferences.getPreferencesSync(getContext(this), { name: 'wfcstore' })
            let keyboardHeight = preference.getSync('keyboardHeight', 0) as number
            if (keyboardHeight === 0) {
                currentWindow.on('avoidAreaChange', async data => {
                    let property = currentWindow.getWindowProperties();
                    if (data.type === window.AvoidAreaType.TYPE_KEYBOARD) {
                        this.messageListScroller!.scrollEdge(Edge.Bottom);
                        if (data.area.bottomRect.height > 0) {
                            let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR; // 底部导航条
                            let navIndicatorAvoidArea = currentWindow.getWindowAvoidArea(type);
                            this.keyboardHeight = px2vp(data.area.bottomRect.height - navIndicatorAvoidArea.bottomRect.height);
                            preference.put('keyboardHeight', this.keyboardHeight);
                        }
                    }
                })
            } else {
                this.keyboardHeight = keyboardHeight;
            }
        })

        if (this.conversation.type === ConversationType.Group) {
            this.groupId = this.conversation.target;
        }

        this.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    }

    async startRecordAudio() {
        // let audioStreamInfo = {
        //     samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
        //     channels: audio.AudioChannel.CHANNEL_1,
        //     sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        //     encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        // }
        if (!this.recorder) {
            this.recorder = new AudioRecordManager()
            this.recorder.init()
        }

        let cacheDir = getContext(this).cacheDir;
        let audioDir = `${cacheDir}/audio`
        try {
            fs.mkdirSync(audioDir)
        } catch (e) {

        }

        this.recordAudioStartMillis = new Date().getTime()

        this.recordOutputAudioFile = audioDir + '/' + this.recordAudioStartMillis + '.m4a'
        console.log('record audioFile', this.recordOutputAudioFile)

        let fd = fs.openSync(this.recordOutputAudioFile, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
        this.recorder.start(`fd://${fd}`);
    }

    stopRecordAudio(canceled: boolean) {
        this.recorder!.finish()
        fs.closeSync(this.recordOutputAudioFileFd)
        this.recordOutputAudioFileFd = 0
        if (canceled) {
            return;
        }
        let audioMessageContent = new SoundMessageContent(this.recordOutputAudioFile, '', Math.round((new Date().getTime() - this.recordAudioStartMillis) / 1000))
        wfc.sendConversationMessage(this.conversation, audioMessageContent, [], null, null, null, null, null)
        this.recordOutputAudioFile = ''
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
        } else {
            Column() {
                Row() {
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
                            .margin({ left: 10, right: 10 })
                            .height(40)
                            .borderRadius(4)
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
                            .onTouch(event => {
                                event.stopPropagation()
                                if (event.type === TouchType.Down) {
                                    this.startRecordAudio()
                                    this.showAudioRecorderView = true
                                    this.showCancelRecordIndicator = false
                                    this.recordTouchDownY = event.touches[0].screenY
                                } else if (event.type === TouchType.Up) {
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
                                this.textInputController.caretPosition(0)
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

                                wfc.sendConversationMessage(this.conversation, textMessageContent, [], null, null, null, null, null);
                                this.text = '';

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
        let windowStage = GlobalContext.getContext()
            .getObject('windowStage') as window.WindowStage;
        windowStage.getMainWindowSync()
            .getUIContext()
            .setKeyboardAvoidMode(value);
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