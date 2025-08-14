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
    xcomponentIdPrefix: string = ''
    swiperIndex: number = 0
    @Prop currentSwiperIndex: number = 0
    onXComponentLoadCallback?: () => void
    _xcomponentId = ''

    aboutToAppear(): void {
        wfc.getUserInfoEx(this.p.userId, false, info => {
            this.participantUserInfo = info;
        }, err => {
            console.error('getUserInfoEx error', this.p.userId, err)
        })
    }

    xcomponentId(){
        if(!this._xcomponentId){
            this._xcomponentId = this.xcomponentIdPrefix ? CallSession.nextPrefixXComponentId(this.xcomponentIdPrefix) :  CallSession.nextXComponentId(this.p);
        }
        return this._xcomponentId
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
                    id: this.xcomponentId(),
                    type: XComponentType.SURFACE,
                    libraryname: 'wfrtc',
                })
                    .width('100%')
                    .height('100%')
                    .enableAnalyzer(false)
                    .onAttach(() => {
                        console.log('xxxx onAttach')
                    })
                    .onLoad((event:object) => {
                        console.log('xxxx XComponent debug', 'onLoad', CallSession.xcomponentUserId(this.p), this._xcomponentId)
                        if (this.onXComponentLoadCallback) {
                            this.onXComponentLoadCallback()
                        } else {
                            if (this.swiperIndex === this.currentSwiperIndex || (this.swiperIndex === 0 && this.currentSwiperIndex === -1)) {
                                this.callSession?.setUserXComponentId(CallSession.xcomponentUserId(this.p), this._xcomponentId)
                            }
                        }
                    })
                    .onDestroy(() => {
                        this._xcomponentId = ''
                        console.log('xxxx XComponent debug', 'onDestroy', CallSession.xcomponentUserId(this.p))
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
