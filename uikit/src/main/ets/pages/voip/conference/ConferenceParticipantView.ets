import { VideoRenderController } from "@ohos/webrtc"
import avenginekit from "@wfc/avenginekit"
import CallSession from "@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession"
import CallState from "@wfc/avenginekit/src/main/ets/wfc/av/engine/callState"
import ParticipantProfile from "@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile"
import wfc from "@wfc/client"
import Config from '@wfc/client/src/main/ets/config'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import WFCVideoRenderController, { ScalingMode } from '@wfc/avenginekit/src/main/ets/wfc/av/xcomponent/WFCVideoRenderController'

@Component
export default struct ConferenceParticipantView {
    @Prop p: ParticipantProfile
    @Prop currentSwiperIndex: number = 0
    @State participantUserInfo: UserInfo | undefined = undefined
    xcomponentIdPrefix: string = ''
    swiperIndex: number = 0
    onXComponentLoadCallback?: () => void
    xcomponentController?: WFCVideoRenderController
    _xcomponentId = ''

    aboutToAppear(): void {
        wfc.getUserInfoEx(this.p.userId, false, info => {
            this.participantUserInfo = info;
        }, err => {
            console.error('getUserInfoEx error', this.p.userId, err)
        })
    }

    xcomponentId() {
        if (!this._xcomponentId) {
            this._xcomponentId = this.xcomponentIdPrefix ? CallSession.nextPrefixXComponentId(this.xcomponentIdPrefix) : CallSession.nextXComponentId(this.p);
        }
        return this._xcomponentId
    }

    build() {
        if (!this.p) {
            Column()
        } else {
            // TODO
            // 使用 stack，xcomponent onload 之前，显示上层的头像等信息

            // 会 crash，临时注释掉
            // if (!this.p.audience && this.p.status === CallState.STATUS_CONNECTED && !this.p.videoMuted && (this.swiperIndex === this.currentSwiperIndex || (this.swiperIndex === 0 && this.currentSwiperIndex === -1))) {
            if (!this.p.audience && this.p.status === CallState.STATUS_CONNECTED && !this.p.videoMuted) {
                XComponent({
                    id: this.xcomponentId(),
                    type: XComponentType.SURFACE,
                    controller: this.xcomponentController
                })
                    .width('100%')
                    .height('100%')
                    .enableAnalyzer(false)
                    .onAttach(() => {
                        console.log('xxxx onAttach')
                    })
                    .onLoad((event: object) => {
                        console.log('xxxx XComponent debug', 'onLoad',  this._xcomponentId)
                        this.xcomponentController?.setVideoTrack(avenginekit.getCurrentSession()!.getParticipantVideoTrack(this.p.userId, this.p.screenSharing))
                        this.xcomponentController?.setScalingMode(ScalingMode.AspectFit)
                        // if (this.onXComponentLoadCallback) {
                        //     this.onXComponentLoadCallback()
                        // } else {
                        //     if (this.swiperIndex === this.currentSwiperIndex || (this.swiperIndex === 0 && this.currentSwiperIndex === -1)) {
                        //         // this.callSession?.setUserXComponentId(CallSession.xcomponentUserId(this.p), this._xcomponentId)
                        //         // this.xcomponentController?.setVideoTrack(this.p!.videoTrack)
                        //     }
                        // }
                    })
                    .onDestroy(() => {
                        this._xcomponentId = ''
                        console.log('xxxx XComponent debug', 'onDestroy', this._xcomponentId)
                    })
            } else {
                Stack() {
                    Image(this.participantUserInfo?.portrait || Config.DEFAULT_PORTRAIT_URL)
                        .width('100%')
                        .aspectRatio(1)
                    Text(this.participantUserInfo?.name)
                }
                .width('100%')
                .height('100%')
            }
        }
    }
}