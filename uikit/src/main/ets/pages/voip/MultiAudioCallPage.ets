import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import wfc from '@wfc/client'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { router } from '@kit.ArkUI'
import { common, Permissions, Want, WantAgent, wantAgent } from '@kit.AbilityKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { showVoipFloatingWindow } from '../../helper/floatingWindowHelper'
import { checkPermissions, requestPermissions } from '../../helper/permissionHelper'
import AVCastPicker from '@ohos.multimedia.avCastPicker'
import ParticipantProfile from '@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile'
import { showToast } from '../../common/utils/Toast'

@Entry({routeName: 'multiAudioCallPage'})
@Component
export default struct MultiAudioCallPage {
    @State targetUserInfos?: UserInfo[] = []
    @State participantProfiles?: ParticipantProfile[] = []
    @State invitor?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State callSession?: CallSession = undefined

    aboutToAppear(): void {
        let callSession = avengineKit.getCurrentSession();

        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            router.back()
            return
        }
        this.selfUserInfo = wfc.getUserInfo(wfc.getUserId())
        this.targetUserInfos = wfc.getUserInfos(callSession?.getParticipantIds()!)

        this.callSession = callSession
        this.participantProfiles = callSession.getParticipantProfiles()
        this.setupSessionCallback()
        console.log('MultiAudioCallPage aboutToAppear')
    }

    aboutToDisappear(): void {
    }

    onPageShow(): void {
        console.log('MultiAudioCallPage show')
    }

    // router 路由才生效
    onBackPress(): boolean | void {
        return true
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
        }
        sessionCallback.didCallEndWithReason = reason => {
            router.back()
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

    tip() {
        let desc = ''
        if (this.callSession?.status === CallState.STATUS_OUTGOING) {
            desc = '等待对方接听'
        } else if (this.callSession?.status === CallState.STATUS_INCOMING) {
            desc = `${this.invitor?.displayName}邀请你通话`
        } else if (this.callSession?.status === CallState.STATUS_CONNECTING) {
            desc = '接听中...'
        } else {
            desc = '通话中'
        }
        return desc;
    }

    participantKey(user: UserInfo): string {
        let profile = this.participantProfiles?.find(p => p.userId === user.uid);
        //return user.uid + '-' + user.updateDt + '-' + profile?.status + '-' + profile?.audioMuted
        return user.uid + '-' + user.updateDt
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

    build() {
        Navigation() {
            Stack() {
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

                Column() {
                    Stack() {
                        Text(`status:${this.callSession!.status}`)
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
                                    let permissions: Permissions[] = ['ohos.permission.SYSTEM_FLOAT_WINDOW'];
                                    let ungrantedPermissions = await checkPermissions(getContext(this), permissions)
                                    if (ungrantedPermissions.length === 0) {
                                        showVoipFloatingWindow(getContext(this), 'voipFloatingWindow', 'pages/voip/VoipFloatingPage', 300, 400, 100, 100)
                                            .then(() => {
                                                router.back()
                                            })
                                            .catch((reason: BusinessError) => {
                                                console.log('xxxxx', reason)
                                                showToast('缩小到悬浮窗失败 ' + reason.code)
                                            })
                                    } else {
                                        requestPermissions(getContext(this), ungrantedPermissions)
                                    }
                                })
                        }
                        .width('100%')
                    }
                    .width('100%')
                    .padding(20)

                    if (this.callSession!.status === CallState.STATUS_INCOMING || this.callSession!.status === CallState.STATUS_OUTGOING) {
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

                                if (this.callSession?.status === CallState.STATUS_INCOMING) {
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
                            }
                            .padding({ top: 20 })
                            .width('100%')
                            .justifyContent(FlexAlign.SpaceAround)

                        }
                        .width('100%')
                        .flexGrow(1)
                        .justifyContent(FlexAlign.End)
                    } else {
                        Column() {

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
                                    // Image($r('app.media.av_handfree'))
                                    //     .draggable(false)
                                    //     .width(60)
                                    //     .height(60)
                                    //     .onClick(() => {
                                    //         if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                    //             // TODO
                                    //         }
                                    //     })
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
                        .flexGrow(1)
                        .justifyContent(FlexAlign.End)
                    }
                }
                .justifyContent(FlexAlign.Start)
                .width('100%')
                .height('100%')
            }
        }
        .title('Voip Test')
        .hideTitleBar(true)
        .backgroundColor('#000000')

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
}