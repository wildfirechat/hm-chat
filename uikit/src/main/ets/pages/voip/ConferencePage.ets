import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import wfc from '@wfc/client'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import AVCastPicker from '@ohos.multimedia.avCastPicker'
import ParticipantProfile from '@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile'
import PickGroupMemberModal from '../group/PickGroupMemberModal'
import { HashMap } from '@kit.ArkTS'
import { timestampFormat } from '../../util/helper'
import { window } from '@kit.ArkUI'

@Component
export default struct ConferencePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State targetUserInfos?: UserInfo[] = []
    @State participantProfiles?: ParticipantProfile[] = []
    @State invitor?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State callSession?: CallSession = undefined
    @State showPickGroupMemberModal: boolean = false
    @State participantWidth: string = '33%'
    @State durationStr: string = ''
    @State showActionAndDurationView: boolean = true
    private statusBarHeight = 0
    private userXComponentMap: HashMap<string, string> = new HashMap<string, string>()
    private focusXComponentId: string = ''
    private lastTriggerToShowActionAndDurationViewTimestamp: number = 0
    private updateActionAndDurationViewInterval = 0

    aboutToAppear(): void {
        let callSession = avengineKit.getCurrentSession();

        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            this.mainNavPathStack.pop()
            return
        }
        this.statusBarHeight = px2vp(AppStorage.get<number>('SafeAreaTopHeight')!)

        this.selfUserInfo = wfc.getUserInfo(wfc.getUserId())
        this.targetUserInfos = wfc.getUserInfos(callSession?.getParticipantIds()!)

        this.callSession = callSession
        this.participantProfiles = callSession.getParticipantProfiles()

        this.focusXComponentId = this.selfUserInfo.uid + this.callSession.callId
        this.userXComponentMap.set(this.selfUserInfo.uid, this.focusXComponentId)

        for (const p of this.participantProfiles) {
            this.userXComponentMap.set(`${p.userId}-${p.screenSharing}`, `${p.userId} - ${p.screenSharing} - ${this.callSession.callId}`);
        }
        this.setupInitialXComponentViews()

        this.setupSessionCallback()
        console.log('MultiAudioCallPage aboutToAppear')
    }

    swapVideo(xcomponentId: string) {
        let nextFocusUserId = ''
        let preFocusUserId = ''
        this.userXComponentMap.forEach((value, key) => {
            if (value === xcomponentId) {
                nextFocusUserId = key!;
            }
            if (value === this.focusXComponentId) {
                preFocusUserId = key!;
            }
        })

        this.userXComponentMap.set(nextFocusUserId, this.focusXComponentId)
        this.userXComponentMap.set(preFocusUserId, xcomponentId)

        this.setupInitialXComponentViews()
    }

    setupInitialXComponentViews() {
        this.userXComponentMap.forEach((xcomponentId, userId) => {
            this.callSession?.setUserXComponentId(userId!, xcomponentId!)
        })
    }

    aboutToDisappear(): void {
        let win = AppStorage.get<window.Window>('window')
        win?.setWindowLayoutFullScreen(false)
        let sysBarProps: window.SystemBarProperties = {
            // statusBarColor: '#00000000',
            // navigationBarColor: '#00000000',
            // 以下两个属性从API Version 8开始支持
            navigationBarContentColor: '#000000',
            statusBarContentColor: '#000000',
        };
        win?.setWindowSystemBarProperties(sysBarProps)
    }

    onPageShow(): void {
        let win = AppStorage.get<window.Window>('window')
        win?.setWindowLayoutFullScreen(true)

        let sysBarProps: window.SystemBarProperties = {
            // statusBarColor: '#00000000',
            // navigationBarColor: '#00000000',
            // 以下两个属性从API Version 8开始支持
            statusBarContentColor: '#ffffff',
            navigationBarContentColor: '#ffffff'
        };
        win?.setWindowSystemBarProperties(sysBarProps)
    }

    onPageHide(): void {
        // TODO
    }

    onPageHidden() {

    }

    updateActionAndDurationView = () => {
        // TODO is page shown?
        let millis = new Date().getTime() - this.callSession!.connectedTime
        this.durationStr = timestampFormat(millis)
        if (this.lastTriggerToShowActionAndDurationViewTimestamp > 0 && Date.now() - this.lastTriggerToShowActionAndDurationViewTimestamp > 5000) {
            this.showActionAndDurationView = false
        }
        let sysBarProps: window.SystemBarProperties = {
            // statusBarColor: '#00000000',
            // navigationBarColor: '#00000000',
            // 以下两个属性从API Version 8开始支持
            statusBarContentColor: this.showActionAndDurationView ? '#ffffff' : '#00ffffff',
            navigationBarContentColor: this.showActionAndDurationView ? '#ffffff' : '#00ffffff'
        };
        let win = AppStorage.get<window.Window>('window')
        win?.setWindowSystemBarProperties(sysBarProps)
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
                this.lastTriggerToShowActionAndDurationViewTimestamp = Date.now()
                this.updateActionAndDurationViewInterval = setInterval(this.updateActionAndDurationView, 1000)
            }
        }
        sessionCallback.didCallEndWithReason = reason => {
            if (this.updateActionAndDurationViewInterval) {
                clearInterval(this.updateActionAndDurationViewInterval)
            }
            this.mainNavPathStack.pop()
        }
        sessionCallback.didParticipantJoined = (userId: string, isScreenSharing?: boolean) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession!.getParticipantIds()!)
            this.participantProfiles = this.callSession?.getParticipantProfiles();

            this.callSession?.setUserXComponentId(`${userId}-${isScreenSharing}`, `${userId} - ${isScreenSharing} - ${this.callSession.callId}`)
        }
        sessionCallback.didParticipantLeft = (userId: string, callEndReason: number, screenSharing = false) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.participantProfiles = this.callSession?.getParticipantProfiles();
        }
        sessionCallback.didParticipantConnected = (userId: string, isScreenSharing?: boolean) => {
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
            desc = `
            $
            {
                this.invitor?.displayName
            }
            邀请你通话`
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

    participantPortrait(p: ParticipantProfile): string | undefined {
        let u = this.targetUserInfos?.find(u => u.uid === p.userId);
        return u?.portrait;
    }

    participantIdsIncludeSelf() {
        return [...this.callSession?.getParticipantIds()!, wfc.getUserId()]
    }

    @Builder
    pickGroupMemberModal() {
        PickGroupMemberModal({
            groupId: this.callSession?.conversation?.target,
            title: '选择群成员',
            showPickGroupMemberModal: $showPickGroupMemberModal,
            initialCheckedUserIds: this.participantIdsIncludeSelf(),
            uncheckableUserIds: this.participantIdsIncludeSelf(),
            onPickResult: (users: UserInfo[]) => {
                this.callSession?.inviteNewParticipants(users.map(user => user.uid), '', false)
            }
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    @Builder
    actionAndDurationView() {
        // actions
        Column() {
            // top actions
            Row() {
                Image($r('app.media.av_minimize'))
                    .draggable(false)
                    .width(50)
                    .height(50)
                    .padding(10)
                    .onClick(async () => {
                        // TODO
                    })

                Text(this.durationStr)
                    .fontColor(Color.White)
                    .textAlign(TextAlign.Center)
                    .alignSelf(ItemAlign.Center)

                Image($r('app.media.ic_tab_add'))
                    .fillColor(Color.Red)
                    .draggable(false)
                    .width(50)
                    .height(50)
                    .padding(10)
                    .onClick(() => {
                        this.showPickGroupMemberModal = true;
                    })
                    .bindContentCover(this.showPickGroupMemberModal, this.pickGroupMemberModal(), {
                        modalTransition: ModalTransition.DEFAULT,
                        onAppear: () => {
                        },

                        onDisappear: () => {
                            this.showPickGroupMemberModal = false
                        }
                    })
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            .margin({ top: this.statusBarHeight })

            // bottom actions
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
                .margin({ bottom: 30 })
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
                .margin({ bottom: 30 })
                .flexGrow(1)
                .justifyContent(FlexAlign.End)
            }
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)
        .transition(TransitionEffect.OPACITY
            .animation({ duration: 400, curve: Curve.Friction, delay: 0 }))
    }

    build() {
        NavDestination() {
            Stack() {
                Column() {
                    XComponent({
                        id: this.selfUserInfo!.uid + this.callSession?.callId,
                        type: XComponentType.SURFACE,
                        libraryname: 'wfrtc',
                    })
                        .width('100%')
                        .height('100%')
                }
                .onClick(() => {
                    if (this.callSession?.status !== CallState.STATUS_CONNECTED) {
                        return
                    }
                    this.showActionAndDurationView = !this.showActionAndDurationView
                    this.lastTriggerToShowActionAndDurationViewTimestamp = Date.now()
                })

                Flex({
                    direction: FlexDirection.Row,
                    justifyContent: FlexAlign.Start,
                    alignContent: FlexAlign.Start,
                    wrap: FlexWrap.Wrap,
                }) {
                    ForEach(this.participantProfiles, (p: ParticipantProfile) => {
                        Stack() {
                            XComponent({
                                id: `${p.userId} - ${p.screenSharing}} - ${this.callSession?.callId}`,
                                type: XComponentType.SURFACE,
                                libraryname: 'wfrtc'
                            })
                                .width('100%')
                                .aspectRatio(1)
                            if (p.status !== 4) {
                                Image(this.participantPortrait(p))
                                    .width('100%')
                                    .aspectRatio(1)
                            }
                        }
                        .onClick(() => {
                            if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                this.swapVideo(`${p.userId} - ${p.screenSharing}} - ${this.callSession?.callId}`)
                            }
                        })
                        .padding(5)
                        .width(this.participantWidth)
                    }, (userInfo: UserInfo) => userInfo.uid + '-' + userInfo.updateDt)
                }
                .width('100%')
                .height('100%')
                .padding({ top: this.statusBarHeight + 50 })
                .hitTestBehavior(HitTestMode.Transparent)

                if (this.showActionAndDurationView) {
                    this.actionAndDurationView()
                }
            }
            .width('100%')
            .height('100%')
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
}