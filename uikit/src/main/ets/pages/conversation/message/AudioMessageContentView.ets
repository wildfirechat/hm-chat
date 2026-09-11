import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import SoundMessageContent from '@wfc/client/src/main/ets/wfc/messages/soundMessageContent'
import AudioPlayManager from '../audio/AudioPlayManager'
import Config from '@wfc/client/src/main/ets/config'
import MessageStatus from '@wfc/client/src/main/ets/wfc/messages/messageStatus'
import { Radius, TextStyleToken } from '../../../common/design/Tokens'
import { voicePlayModeManager } from '../audio/VoicePlayModeManager'
import { showTipToast } from '../../../common/utils/TipToast'
import { PttMessageContentType } from '@wfc/ptt'

@Component
export default struct AudioMessageContentView {
    @Link message: Message
    @State imageUrl: Resource = $r('app.media.audio_animation_list_right_1')
    // When this prop is set to this message's ID, auto-start playback
    @Prop @Watch('onAutoPlayChanged') autoPlayMessageId: number = 0
    // Called when playback starts, so the parent can update the source-of-truth played status
    onPlayStart?: (messageId: number) => void
    // Called when playback completes (or errors), used by parent to trigger next message
    onPlayComplete?: (messageId: number, err?: Error) => void
    // 转文字识别出的文本，识别过程中逐段更新
    @Prop speechToText: string = ''
    // 是否正在转文字
    @Prop speechToTextRecognizing: boolean = false
    private animatorInternal: number = 0
    private animatorImageIndex = 3;
    private outAudioPlayingImageUrl: Resource[] = [
        $r('app.media.audio_animation_list_right_1'),
        $r('app.media.audio_animation_list_right_2'),
        $r('app.media.audio_animation_list_right_3')
    ]
    private inAudioPlayingImageUrl: Resource[] = [
        $r('app.media.audio_animation_list_left_1'),
        $r('app.media.audio_animation_list_left_2'),
        $r('app.media.audio_animation_list_left_3')
    ]
    audioPlayManager?: AudioPlayManager

    soundMessageContent() {
        return this.message.messageContent as SoundMessageContent
    }

    defaultAudioIndicatorImageUrl() {
        // out
        let imgUrl: Resource
        if (this.message.direction === 0) {
            imgUrl = $r('app.media.audio_animation_list_right_3')
        } else {
            imgUrl = $r('app.media.audio_animation_list_left_3')
        }
        return imgUrl
    }

    aboutToAppear() {
        this.imageUrl = this.defaultAudioIndicatorImageUrl()
        this.animatorImageIndex = 3
    }

    onAutoPlayChanged() {
        if (this.autoPlayMessageId === this.message.messageId && this.message.messageId > 0) {
            this.startPlay()
        }
    }

    startPlay() {
        let content = this.message.messageContent as SoundMessageContent
        this.startAudioPlayingAnimation()
        let url: string = content.remotePath;
        // 对讲留底语音一定是 amr，且自己发出去的那条，本地文件在发送成功后就删掉了，
        // 所以不管收发方向，都从服务器取转码后的音频
        if (this.message.direction === 1 || !content.localPath
            || content.type === PttMessageContentType.Ptt_Sound) {
            url = Config.getAmrToMp3ServerAddress() + content.remotePath;
        }
        // Immediate local feedback (hide red dot on this copy); the parent updates the
        // source-of-truth status + persistence by stable messageId so it survives list rebuilds.
        this.message.status = MessageStatus.Played
        this.onPlayStart?.(this.message.messageId)
        let earpiece = voicePlayModeManager.isEarpiece()
        if (earpiece) {
            // 听筒播放：提示用户贴近手机聆听
            this.showEarpieceHint()
        }
        this.audioPlayManager!.startProximitySensing(earpiece)
        this.audioPlayManager!.play(url, true, (err?: Error) => {
            this.stopAudioPlayingAnimation()
            if (err && err.message === AudioPlayManager.INTERRUPTED) {
                // Another voice message took over playback. Only stop this view's animation; the new
                // playback now owns proximity sensing / the chain, so skip completion handling (don't
                // release the screen lock or play the completion sound).
                return
            }
            // Whether to stop proximity sensing / play the completion sound is decided by the
            // parent (ConversationPage), so continuous playback doesn't release the screen lock
            // between consecutive messages.
            this.onPlayComplete?.(this.message.messageId, err)
        })
    }

    // 仿微信：听筒模式下点击语音，居中弹出带「耳朵」图标的提示，约 2s 后自动消失。
    showEarpieceHint() {
        showTipToast(this.getUIContext(), '听筒播放，请贴近手机聆听', $r('app.media.ic_voice_earpiece'))
    }

    startAudioPlayingAnimation() {
        this.stopAudioPlayingAnimation()
        this.animatorInternal = setInterval(() => {
            this.animatorImageIndex++
            if (this.animatorImageIndex > 3) {
                this.animatorImageIndex = 0
            }

            if (this.message.direction === 0) {
                this.imageUrl = this.outAudioPlayingImageUrl[this.animatorImageIndex]
            } else {
                this.imageUrl = this.inAudioPlayingImageUrl[this.animatorImageIndex]
            }
        }, 200)
    }

    stopAudioPlayingAnimation() {
        clearInterval(this.animatorInternal)
        this.animatorInternal = 0
        this.animatorImageIndex = 3
        this.imageUrl = this.defaultAudioIndicatorImageUrl()
    }

    duration(){
        return Math.ceil(this.soundMessageContent().duration)
    }

    build() {
        Column() {
            Row() {
                Row() {
                    Image(this.imageUrl)
                        .width(16)
                        .height(16)
                    Text(`${this.duration() } ''`)
                        .margin({ left: 12 })
                }
                .width(`${this.duration() / 60 * 100}%`)
                .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                .alignItems(VerticalAlign.Center)
                .height(40)
                .padding(4)
                .borderRadius(Radius.sm)
                .constraintSize({ minWidth: 60 })
                .margin({ top: 4 }) // portrait 的高度是 48, (48 - 40) / 2
                .onClick(() => {
                    this.startPlay()
                })

                if (this.message.direction === 1 && this.message.status !== MessageStatus.Played) {
                    Text()
                        .width(8)
                        .height(8)
                        .margin({ left: 8 })
                        .backgroundColor($r('app.color.wf_danger'))
                        .borderRadius(Radius.lg)
                }
            }

            // 转文字结果，识别中还没有文本时只显示加载动画
            if (this.speechToText.length > 0 || this.speechToTextRecognizing) {
                Row() {
                    if (this.speechToText.length > 0) {
                        Text(this.speechToText)
                            .fontSize(TextStyleToken.messageText)
                            .fontColor($r('app.color.wf_primary_text'))
                            .flexShrink(1)
                    }
                    if (this.speechToTextRecognizing) {
                        LoadingProgress()
                            .width(20)
                            .height(20)
                            .margin({ left: this.speechToText.length > 0 ? 8 : 0 })
                    }
                }
                .alignItems(VerticalAlign.Center)
                .constraintSize({ minHeight: 40, maxWidth: 560 })
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                .borderRadius(Radius.sm)
                .margin({ top: 4 })
            }
        }
        .alignItems(this.message.direction === 0 ? HorizontalAlign.End : HorizontalAlign.Start)
    }
}
