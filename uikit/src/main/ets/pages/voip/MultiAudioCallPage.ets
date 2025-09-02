import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import wfc from '@wfc/client'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import ParticipantProfile from '@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile'
import { AVCastPicker } from '@kit.AVSessionKit'
import { timestampFormat } from '../../util/helper'
import VoipPiPNodeController from './VoipPiPNodeController'
import { BusinessError } from '@kit.BasicServicesKit'
import { navigationDestinations } from '../navigationConfig'
import pipHelper from './pipHelper'

@Component
export default struct MultiAudioCallPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State callSession?: CallSession = undefined
    @State participantUserInfosExceptSelf?: UserInfo[] = []
    @State invitor?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State targetUserInfos?: UserInfo[] = []
    @State participantProfiles?: ParticipantProfile[] = []
    @State duration: string = '00:00'
    private updateDurationInterval: number = 0
    private voipPiPNodeController: VoipPiPNodeController = new VoipPiPNodeController('');
    private dummyXComponentController: XComponentController = new XComponentController()

    aboutToAppear(): void {
        let callSession = avengineKit.getCurrentSession();

        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            this.mainNavPathStack.pop()
            return
        }

        this.selfUserInfo = wfc.getUserInfo(wfc.getUserId())
        this.invitor = wfc.getUserInfo((callSession as CallSession).initiatorId);
        let otherParticipantIds = callSession.getParticipantIds().filter(uid => uid !== callSession?.initiatorId)
        otherParticipantIds.push(this.selfUserInfo.uid)
        this.participantUserInfosExceptSelf = wfc.getUserInfos(otherParticipantIds)

        this.targetUserInfos = wfc.getUserInfos(callSession?.getParticipantIds()!)
        this.participantProfiles = callSession.getParticipantProfiles()

        this.callSession = callSession
        this.setupSessionCallback()

        console.log('MultiAudioCallPage aboutToAppear')
    }

    setupSessionCallback() {
        let sessionCallback: CallSessionCallback = new CallSessionCallback()

        let that = this.callSession!;
        sessionCallback.didChangeState = (status: number) => {
            // 强制刷新
            let tmp = this.callSession
            tmp!.status = status;
            this.callSession = undefined;
            this.callSession = tmp;
            if (status === CallState.STATUS_CONNECTED) {
                this.updateDurationInterval = setInterval(() => {
                    let d = Date.now() - this.callSession!.connectedTime
                    this.duration = timestampFormat(d)
                }, 1000)
            }
        }
        sessionCallback.didCallEndWithReason = reason => {
            this.destroyPipController()

            let index = this.mainNavPathStack.getIndexByName(navigationDestinations.MultiAudioCallPage)
            if (index.length) {
                this.mainNavPathStack.pop()
            }
        }
        sessionCallback.didParticipantJoined = (userId: string, isScreenSharing) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession!.getParticipantIds()!)
            this.participantProfiles = this.callSession?.getParticipantProfiles();
        }
        sessionCallback.didParticipantLeft = (userId: string, callEndReason: number, screenSharing = false) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.participantProfiles = this.callSession?.getParticipantProfiles();
        }
        sessionCallback.didParticipantConnected = (userId: string, isScreenSharing) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.participantProfiles = this.callSession?.getParticipantProfiles();
        }
        sessionCallback.didChangeMode = state => {

        }
        sessionCallback.didVideoMuted = (userId: string, muted: boolean) => {
            this.participantProfiles = this.callSession?.getParticipantProfiles();
        }
        // 一下回调高级版音视频 SDK 生效
        sessionCallback.didMuteStateChanged = participants => {

        }

        // end

        this.callSession!.sessionCallback = sessionCallback;
    }

    aboutToDisappear(): void {
        clearInterval(this.updateDurationInterval)
    }

    onPageShow(): void {
        console.log('MultiAudioCallPage show')
        this.createPipController()
            .then(() => {
                console.log('xxxxxxx create pip success')
            })
            .catch((reason: BusinessError) => {
                console.log('xxxxxxxx create pip controller error', reason.message);
            })
    }

    onPageHide(): void {
    }

    @Builder
    incomingView() {
        Column() {
            Image(this.invitor!.portrait)
                .width(120)
                .height(120)
                .borderRadius(8)
                .margin({ top: 120 })
            Text(this.invitor?.displayName)
                .maxLines(1)
                .fontColor(Color.White)
                .fontSize(20)
                .margin({ top: 20 })

            Text('邀请你加入多人通话')
                .maxLines(1)
                .fontColor('#7E7E7E')
                .fontSize(16)
                .margin({ top: 20 })

            Text('参与通话的还有：')
                .maxLines(1)
                .fontColor('#7E7E7E')
                .fontSize(14)
                .margin({ top: 120, bottom: 10 })

            Flex({
                direction: FlexDirection.Row,
                justifyContent: FlexAlign.Center,
                alignContent: FlexAlign.Center,
                wrap: FlexWrap.Wrap
            }) {
                ForEach(this.participantUserInfosExceptSelf, (userInfo: UserInfo) => {
                    Image(userInfo.portrait)
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                        .margin(10)
                }, (userInfo: UserInfo) => userInfo.uid + '-' + userInfo.updateDt)
            }
            .width('100%')

            Blank()

            Column() {
                Row() {
                    Column() {
                        Image($r('app.media.av_hang_up'))
                            .draggable(false)
                            .clickEffect({ level: ClickEffectLevel.MIDDLE })
                            .width(60)
                            .height(60)
                            .onClick(() => {
                                this.callSession?.hangup()
                            })
                        Text('挂断')
                            .margin({ top: 10 })
                            .fontSize(13)
                            .fontColor(Color.White)
                    }

                    Column() {
                        Image($r('app.media.av_voice_answer'))
                            .draggable(false)
                            .width(60)
                            .height(60)
                            .clickEffect({ level: ClickEffectLevel.LIGHT })
                            .onClick(() => {
                                this.callSession?.call()
                            })
                        Text('接听')
                            .margin({ top: 10 })
                            .fontSize(13)
                            .fontColor(Color.White)
                    }
                }
                .padding({ top: 20 })
                .width('100%')
                .justifyContent(FlexAlign.SpaceAround)

            }
            .width('100%')
            .margin({ bottom: 40 })
            .flexGrow(1)
            .justifyContent(FlexAlign.End)

        }
        .width('100%')
        .height('100%')
    }

    participantStatus(user: UserInfo): string | undefined {
        let desc = ''
        let status = 0
        if (user.uid === this.selfUserInfo?.uid) {
            let profile = this.callSession?.getSelfProfile();
            status = profile?.status!
        } else {
            let profile = this.participantProfiles?.find(p => p.userId === user.uid);
            status = profile?.status!
        }
        if (status === CallState.STATUS_OUTGOING) {
            desc = '等待对方接听'
        } else if (status === CallState.STATUS_INCOMING) {
            desc = '等待接听'
        } else if (status === CallState.STATUS_CONNECTING) {
            desc = '接听中...'
        } else {
            // desc = '通话中'
        }
        return desc
    }

    @Builder
    outgoingOrConnectedView() {
        if (this.callSession) {
            Column() {
                // top actions
                Stack() {
                    Text(this.duration)
                        .width('100%')
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Center)
                        .alignSelf(ItemAlign.Center)

                    Row() {
                        Image($r('app.media.av_minimize'))
                            .draggable(false)
                            .width(50)
                            .height(50)
                            .padding(10)
                            .onClick(async () => {
                                pipHelper.startPiP()
                                this.mainNavPathStack.pop()
                            })
                    }
                    .width('100%')
                }
                .width('100%')
                .padding(20)

                Flex({
                    direction: FlexDirection.Row,
                    justifyContent: FlexAlign.Center,
                    alignContent: FlexAlign.Start,
                    wrap: FlexWrap.Wrap
                }) {
                    ForEach(this.targetUserInfos, (userInfo: UserInfo) => {
                        Column() {
                            Stack() {
                                Image(userInfo.portrait)
                                    .width(100)
                                    .height(100)
                                    .borderRadius(4)
                                Text(this.participantStatus(userInfo))
                                    .maxLines(1)
                                    .fontColor('#7E7E7E')
                                    .fontSize(12)
                                    .margin({ top: 5 })
                            }

                            Text(userInfo.displayName)
                                .maxLines(1)
                                .fontColor(Color.White)
                                .fontSize(13)
                                .margin({ top: 10 })
                        }
                        .margin(10)
                        .justifyContent(FlexAlign.Center)
                        .alignItems(HorizontalAlign.Center)
                    }, (userInfo: UserInfo) => userInfo.uid + '-' + userInfo.updateDt)

                    Column() {
                        Stack() {
                            Image(this.selfUserInfo!.portrait)
                                .width(100)
                                .height(100)
                                .borderRadius(4)
                            Text(this.participantStatus(this.selfUserInfo!))
                                .maxLines(1)
                                .fontColor('#7E7E7E')
                                .fontSize(12)
                                .margin({ top: 5 })
                        }

                        Text(this.selfUserInfo!.displayName)
                            .maxLines(1)
                            .fontColor(Color.White)
                            .fontSize(13)
                            .margin({ top: 10 })
                    }
                    .margin(10)
                }
                .width('100%')


                // bottom actions
                Row() {
                    Column() {
                        Image(this.callSession?.audioMuted ? $r('app.media.av_mute_hover') : $r('app.media.av_mute'))
                            .draggable(false)
                            .width(60)
                            .height(60)
                            .onClick(() => {
                                if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                    this.callSession?.muteAudio(!this.callSession?.audioMuted)
                                }
                            })
                        Text('麦克风')
                            .margin({ top: 10 })
                            .fontSize(13)
                            .fontColor(Color.White)
                    }

                    Column() {
                        Image($r('app.media.av_hang_up'))
                            .draggable(false)
                            .width(60)
                            .height(60)
                            .onClick(() => {
                                this.callSession?.hangup()
                            })
                        Text('挂断')
                            .margin({ top: 10 })
                            .fontSize(13)
                            .fontColor(Color.White)
                    }

                    Column() {
                        AVCastPicker({ normalColor: Color.White, activeColor: Color.White })
                            .width(60)
                            .height(60)
                            .border({ width: 1, radius: 30, color: Color.White })

                        Text('扬声器已关')
                            .margin({ top: 10 })
                            .fontSize(13)
                            .fontColor(Color.White)
                    }
                }
                .padding({ top: 20 })
                .width('100%')
                .justifyContent(FlexAlign.SpaceAround)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.SpaceBetween)
        }
    }

    build() {
        NavDestination() {
            if (this.callSession) {
                Stack() {
                    XComponent({
                        id: this.callSession?.callId,
                        type: XComponentType.SURFACE,
                        controller: this.dummyXComponentController,
                    })
                        .enableAnalyzer(false)
                        .width(200)
                        .height(300)
                        .backgroundColor('#e0000000')
                    if (this.callSession?.status === CallState.STATUS_INCOMING) {
                        this.incomingView()
                    } else if (this.callSession?.status > 0) {
                        this.outgoingOrConnectedView()
                    }
                }
            }
        }
        .title('Voip Test')
        .hideTitleBar(true)
        .onShown(() => {
            this.onPageShow()
        })
        .onHidden(() => {
            this.onPageHide()
        })
        .onBackPressed(() => true)
        .backgroundColor('#000000')

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }

    async createPipController() {
        await pipHelper.createPipController(this.getUIContext(), this.dummyXComponentController, this.voipPiPNodeController, this.mainNavPathStack, navigationDestinations.MultiAudioCallPage)
    }

    destroyPipController() {
        pipHelper.destroyPipController()
    }
}