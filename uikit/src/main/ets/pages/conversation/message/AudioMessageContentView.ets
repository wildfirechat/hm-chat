import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import SoundMessageContent from '@wfc/client/src/main/ets/wfc/messages/soundMessageContent'
import AudioPlayManager from '../audio/AudioPlayManager'
import Config from '@wfc/client/src/main/ets/config'
import MessageStatus from '@wfc/client/src/main/ets/wfc/messages/messageStatus'
import { Radius } from '../../../common/design/Tokens'
import { voicePlayModeManager } from '../audio/VoicePlayModeManager'
import { showTipToast } from '../../../common/utils/TipToast'

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
        if (this.message.direction === 1 || !content.localPath) {
            url = Config.AMR_TO_MP3_SERVER_ADDRESS + content.remotePath;
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

    build() {
        Row() {
            Row() {
                Image(this.imageUrl)
                    .width(16)
                    .height(16)
                Text(`${this.soundMessageContent().duration} ''`)
                    .margin({ left: 12 })
            }
            .width(`${this.soundMessageContent().duration / 60 * 100}%`)
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
    }
}
