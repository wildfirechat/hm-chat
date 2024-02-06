import common from '@ohos.app.ability.common'
import thermal from '@ohos.thermal'
import { ICON_WIDTH } from '../../common/CommonConstants'
import Utils from '../../common/Utils'
import { copyFileUri, fileSize } from '../../common/utils/FileUtil'
import { showToast } from '../../common/utils/Toast'
import { MediaHelper } from '../../helper/MediaHelper'
import wfc from '../../wfc/client/wfc'
import FileMessageContent from '../../wfc/messages/fileMessageContent'
import ImageMessageContent from '../../wfc/messages/imageMessageContent'
import TextMessageContent from '../../wfc/messages/textMessageContent'
import Conversation from '../../wfc/model/conversation'
import ConversationInfo from '../../wfc/model/conversationInfo'
import audio from '@ohos.multimedia.audio';
import AudioRecordManager from './audio/AudioRecordManager'
import fs from '@ohos.file.fs';
import SoundMessageContent from '../../wfc/messages/soundMessageContent'
import Message from '../../wfc/messages/message'
import router from '@ohos.router'
import ActionSheetDialog from '../../view/ActionSheetDialog'
import EmojiInputPanelView from './emoji/EmojiInputPanelView'


const INPUT_ICON_WIDTH = 30

declare type ConversationExt = {
    title: string,
    icon: ResourceStr,
    action: () => void
}

declare type MultiCheckAction = {
    title: string,
    icon: ResourceStr,
    action: () => void
}

const MAX_RECORDER_DURATION_IN_SECOND = 60

@Component
export default struct ConversationInputPanelView {
    @Link conversation: Conversation
    @State text: string = ''
    @State textInputFocused: boolean = false
    @State showEmojiPanel: boolean = false
    @State showExtPanel: boolean = false
    @State keyboardHeight: number = 300
    @State showAudioRecorderButton: boolean = false

    // for audioRecorderView
    @Link showAudioRecorderView: boolean
    @Link showCancelRecordIndicator: boolean
    @Link recordCountDown: number
    @Link @Watch('onCollapseConversationInputPanelView') collapseConversationInputPanelViewTimestamp: number
    // 取消多选时，需要先将 enableMultiCheck 置为 false，在清空 checkedMessages
    @Link enableMultiCheck: boolean
    @Link checkedMessages: Message[]
    @Link messages: Message[]
    private checkKeyboardHeightInternal: number = 0
    private textInputBottomWhenBlur: number = 0
    private textInputController: TextInputController = new TextInputController()
    private mediaHelper: MediaHelper = new MediaHelper(getContext())
    private recordTouchDownY: number
    private recorder: AudioRecordManager
    private recordOutputAudioFile: string = ''
    private recordOutputAudioFileFd: number = 0
    private forwardMessageDialogController: CustomDialogController
    private deleteMessageDialogController: CustomDialogController
    private recordStartTimestamp: number = 0
    private recordTimerInternal: number = 0
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
                        wfc.sendConversationMessage(this.conversation, content);
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
                // try {
                //     let imgUri = await this.mediaHelper.takePhoto(getContext() as common.UIAbilityContext)
                //     let file = getContext(this).cacheDir + '/' + new Date().getTime() + '.jpg'
                //     copyFileUri(imgUri, file);
                //     let size = fileSize(file);
                //     let content = new ImageMessageContent(file, '', '')
                //     wfc.sendConversationMessage(this.conversationInfo.conversation, content);
                // } catch (reason) {
                //     showToast('拍摄照片失败: ' + reason)
                // }
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
                                        } })
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
                                        } })
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
        setTimeout(() => {
            this.collapseConversationInputPanelViewTimestamp = 0
        }, 100)
    }

    aboutToAppear() {
        this.checkKeyboardHeightInternal = setInterval(() => {
            let rect = Utils.getComponentRect('textInput')
            if (rect) {
                let {top, bottom} = rect
                this.textInputBottomWhenBlur = bottom
                console.log('textInputBottomWhenBlur', bottom)
                clearInterval(this.checkKeyboardHeightInternal)
                this.checkKeyboardHeightInternal = 0
            }
        }, 100)

        // TODO 输入法将页面网上顶的问题，追踪下面链接
        // https://developer.huawei.com/consumer/cn/forum/topic/0204139962705742016?fid=0102683795438680754
    }

    async startRecordAudio() {
        let audioStreamInfo = {
            samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
            channels: audio.AudioChannel.CHANNEL_1,
            sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
            encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        }
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

        this.recordStartTimestamp = new Date().getTime()

        this.recordOutputAudioFile = audioDir + '/' + this.recordStartTimestamp + '.m4a'
        console.log('record audioFile', this.recordOutputAudioFile)

        let fd = fs.openSync(this.recordOutputAudioFile, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
        this.recorder.start(`fd://${fd}`);


        this.recordTimerInternal = setInterval(() => {
            let now = new Date().getTime()
            let duration = now - this.recordStartTimestamp

            let countDown = MAX_RECORDER_DURATION_IN_SECOND * 1000 - duration
            if (countDown <= 0) {
                this.stopRecordAudio()
            } else if (countDown < 10 * 1000) {
                this.recordCountDown = Math.round(countDown / 1000)
            }
        }, 1000)
    }

    stopRecordAudio() {
        if (this.recordStartTimestamp === 0) {
            return
        }

        this.recorder.finish()

        let durationInSecond = Math.round((new Date().getTime() - this.recordStartTimestamp) / 1000)
        durationInSecond = Math.min(durationInSecond, MAX_RECORDER_DURATION_IN_SECOND)

        this.recordCountDown = 0
        this.recordStartTimestamp = 0
        this.showAudioRecorderView = false
        clearInterval(this.recordTimerInternal)

        if (this.showCancelRecordIndicator) {
            this.showCancelRecordIndicator = false
            return
        }

        fs.closeSync(this.recordOutputAudioFileFd)
        this.recordOutputAudioFileFd = 0
        let audioMessageContent = new SoundMessageContent(this.recordOutputAudioFile, '', durationInSecond)
        wfc.sendConversationMessage(this.conversation, audioMessageContent)
        this.recordOutputAudioFile = null
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
                                this.text = value

                                if (!this.keyboardHeight) {
                                    let inputRect = Utils.getComponentRect('textInput')
                                    const {bottom} = inputRect
                                    if (bottom < this.textInputBottomWhenBlur) {
                                        let audioIconRect = Utils.getComponentRect('audio')
                                        this.keyboardHeight = (this.textInputBottomWhenBlur - inputRect['bottom']) * INPUT_ICON_WIDTH / (audioIconRect['bottom'] - audioIconRect['top'])
                                        console.log('keyboardHeight', this.keyboardHeight)
                                    }
                                }
                            })
                            .onFocus(() => {
                                // this.showExtPanel = false
                                // this.showEmojiPanel = false
                                this.textInputFocused = true
                            })
                            .focusable(this.collapseConversationInputPanelViewTimestamp === 0)
                            .onBlur(() => {
                                this.textInputFocused = false
                            })
                            .onClick(() => {
                                // this.showExtPanel = false
                                // this.showEmojiPanel = false
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
                            .fontColor('#7E7E7E')
                                // .backgroundColor('#F3F3F3')
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
                                    this.stopRecordAudio()
                                } else if (event.type === TouchType.Move) {
                                    let y = event.touches[0].screenY;
                                    if (this.recordTouchDownY - y > 200) {
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
                        .focusOnTouch(true)
                        .onClick(() => {
                            this.showExtPanel = false
                            this.showEmojiPanel = !this.textInputFocused
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
                                wfc.sendConversationMessage(this.conversation, textMessageContent, []);
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
                    Flex({
                        justifyContent: FlexAlign.Start,
                        alignContent: FlexAlign.SpaceAround,
                        wrap: FlexWrap.Wrap
                    }) {
                        ForEach(this.conversationExts, (ext: ConversationExt) => {
                            Column() {
                                Image(ext.icon)
                                    .width(60)
                                    .height(60)
                                Text(ext.title)
                                    .margin({ top: 8 })
                                    .fontSize(12)
                            }
                            .borderRadius(4)
                            .width('20%')
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

                        }, (ext: ConversationExt) => ext.title)
                    }
                    .width('100%')
                    .height(this.keyboardHeight)
                }

                if (this.showEmojiPanel) {
                    EmojiInputPanelView({
                        text: $text,
                        conversation: this.conversation
                    })
                        .focusable(true)
                        .width('100%')
                        .height(this.keyboardHeight)
                }
            }
            .backgroundColor('#F7F7F7')
        }
    }
}