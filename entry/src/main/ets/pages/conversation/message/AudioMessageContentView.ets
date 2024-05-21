import Message from '../../../wfc/messages/message'
import SoundMessageContent from '../../../wfc/messages/soundMessageContent'
import AudioPlayManager from '../audio/AudioPlayManager'
import fs from '@ohos.file.fs'
import Config from '../../../config'

@Component
export default struct AudioMessageContent {
    @Link message: Message
    @State imageUrl: Resource = $r('app.media.audio_animation_list_right_1')
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
    private audioPlayManager?: AudioPlayManager

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

    startAudioPlayingAnimation() {
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
        this.animatorImageIndex = 3
        this.imageUrl = this.defaultAudioIndicatorImageUrl()
    }

    build() {
        Row() {
            Image(this.imageUrl)
                .width(20)
                .height(20)
            Text(`${this.soundMessageContent().duration} ''`)
                .margin({ left: 10 })
        }
        .width(`${this.soundMessageContent().duration / 60 * 100}%`)
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)
        .height(40)
        .padding(5)
        .borderRadius(4)
        .constraintSize({ minWidth: 60 })
        .margin({ top: 4 }) // portrait 的高度是 48, (48 - 40) / 2
        .onClick(() => {
            let content = this.message.messageContent as SoundMessageContent
            // audioPlayManager.audioPlayer.on('stateChange', async (state: media.AVPlayerState) => {
            //     switch (state.toString()) {
            //         case 'initialized':
            //         // TODO
            //             break
            //         default:
            //             break
            //     }
            //
            // })
            this.startAudioPlayingAnimation()
            let url: string = content.remotePath;
            if (this.message.direction === 1) {
                url = Config.AMR_TO_MP3_SERVER_ADDRESS + content.remotePath;
            }
            this.audioPlayManager!.play(url, true, (err?: Error) => {
                this.stopAudioPlayingAnimation()
            })

        })
    }
}
