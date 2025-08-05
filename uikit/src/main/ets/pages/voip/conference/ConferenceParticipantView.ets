import WfcAVEngineKit from "@wfc/avenginekit/src/main/ets/wfc/av/engine/avenginekit"
import CallSession from "@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession"
import CallState from "@wfc/avenginekit/src/main/ets/wfc/av/engine/callState"
import ParticipantProfile from "@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile"
import wfc from "@wfc/client"
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'

@Component
export default struct ConferenceParticipantView {
    @Prop p: ParticipantProfile
    @Prop callSession: CallSession
    @State participantUserInfo: UserInfo | undefined = undefined
    xcomponentId: string = ''
    swiperIndex: number = 0
    @Prop currentSwiperIndex: number = 0
    onXComponentLoadCallback?: () => void

    aboutToAppear(): void {
        wfc.getUserInfoEx(this.p.userId, false, info => {
            this.participantUserInfo = info;
        }, err => {
            console.error('getUserInfoEx error', this.p.userId, err)
        })
    }

    build() {
        if (!this.p || !this.callSession) {
            Column()
        } else {
            // TODO
            // 使用 stack，xcomponent onload 之前，显示上层的头像等信息

            // 会 crash，临时注释掉
            // if (!this.p.audience && this.p.status === CallState.STATUS_CONNECTED && !this.p.videoMuted && (this.swiperIndex === this.currentSwiperIndex || (this.swiperIndex === 0 && this.currentSwiperIndex === -1))) {
            if (!this.p.audience && this.p.status === CallState.STATUS_CONNECTED && !this.p.videoMuted) {
                XComponent({
                    id: this.xcomponentId ? this.xcomponentId : this.p.xcomponentId(),
                    type: XComponentType.SURFACE,
                    libraryname: 'wfrtc',
                })
                    .width('100%')
                    .height('100%')
                    .enableAnalyzer(false)
                    .onLoad(() => {
                        console.log('XComponent debug', 'onLoad', this.p.xcomponentUserId(), this.p.xcomponentId())
                        if (this.onXComponentLoadCallback) {
                            this.onXComponentLoadCallback()
                        } else {
                            if (this.swiperIndex === this.currentSwiperIndex || (this.swiperIndex === 0 && this.currentSwiperIndex === -1)) {
                                this.callSession?.setUserXComponentId(this.p.xcomponentUserId(), this.xcomponentId ? this.xcomponentId : this.p.xcomponentId())
                            }
                        }
                    })
                    .onDestroy(() => {
                        console.log('XComponent debug', 'onDestroy', this.p.xcomponentUserId(), this.p.xcomponentId())
                    })
            } else {
                Stack() {
                    Image(this.participantUserInfo?.portrait)
                        .width('100%')
                        .aspectRatio(1)
                    Text(this.participantUserInfo?.name)
                }
                .width('100%')
                .height('100%')
                .backgroundColor(Color.Green)
            }
        }
    }
}
