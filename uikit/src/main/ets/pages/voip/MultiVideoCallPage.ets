import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import wfc from '@wfc/client'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import AVCastPicker from '@ohos.multimedia.avCastPicker'
import ParticipantProfile from '@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile'
import PickGroupMemberModal from '../group/PickGroupMemberModal'
import { timestampFormat } from '../../util/helper'
import { PiPWindow, window } from '@kit.ArkUI'
import WFCVideoRenderController, { ScalingMode } from '@wfc/avenginekit/src/main/ets/wfc/av/xcomponent/WFCVideoRenderController'
import { VideoTrack } from '@ohos/webrtc/src/main/libohos_webrtc/webrtc'
import VoipPiPNodeController from './VoipPiPNodeController'
import uikit from '../../uikit'
import { BusinessError } from '@kit.BasicServicesKit'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'

@Component
export default struct MultiVideoCallPage {
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
    private focusUserId: string = ''
    private lastTriggerToShowActionAndDurationViewTimestamp: number = 0
    private updateActionAndDurationViewInterval = 0
    // not include self
    private focusVideoRenderController = new WFCVideoRenderController('focus-xcp')
    private participantVideoRenderControllerMap = new Map<string, WFCVideoRenderController>()
    private pipController?: PiPWindow.PiPController;
    private voipPiPNodeController: VoipPiPNodeController = new VoipPiPNodeController('');

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
        this.getParticipantProfilesAndUpdateVideoRenderControllerMap()

        this.focusUserId = this.selfUserInfo.uid

        this.setupSessionCallback()
        console.log('MultiAudioCallPage aboutToAppear')
    }

    // 交换逻辑
    //
    swapVideo(userId: string) {
        if (!this.callSession || !this.selfUserInfo) {
            return;
        }
        let userVideoRenderController = this.participantVideoRenderControllerMap.get(userId)
        let userVideoTrack = this.callSession.getParticipantVideoTrack(userId)
        if (!userVideoRenderController || !userVideoTrack) {
            return
        }

        if (userId === this.focusUserId) {
            // 当前 xcomponent 原始对应的用户，已经是焦点用户

            // 将用户的视频流，渲染到原始为止
            let localVideoTrack = this.callSession.getParticipantVideoTrack(this.selfUserInfo.uid)
            this.focusVideoRenderController.setVideoTrack(localVideoTrack)

            // 将自己的本地视频流，渲染到焦点位置
            userVideoRenderController?.setVideoTrack(userVideoTrack)
            this.focusUserId = this.selfUserInfo.uid;
        } else {
            // 之前 focus 的用户，恢复到该用户原来的位置
            if (this.focusUserId !== this.selfUserInfo.uid) {
                let lastFocusUserVideoRenderController = this.participantVideoRenderControllerMap.get(this.focusUserId)
                let lastFocusVideoTrack = this.callSession.getParticipantVideoTrack(this.focusUserId)
                lastFocusUserVideoRenderController?.setVideoTrack(lastFocusVideoTrack)
            }

            // 将新的焦点用户，渲染到大屏
            this.focusVideoRenderController.setVideoTrack(userVideoTrack)

            // 将自己的本地视频流，渲染到新的焦点用户原来的位置
            let localVideoTrack = this.callSession.getParticipantVideoTrack(this.selfUserInfo.uid)
            userVideoRenderController?.setVideoTrack(localVideoTrack)

            this.focusUserId = userId;
        }
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

        if (!this.pipController) {
            this.createPipController()
                .then(() => {
                    console.log('xxxxxxx create pip success')
                })
                .catch((reason: BusinessError) => {
                    console.log('xxxxxxxx create pip controller error', reason.message);
                })
        }
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
            this.destroyPipController()

            let index = this.mainNavPathStack.getIndexByName(uikitNavigationDestinations.MultiVideoCallPage)
            if (index.length) {
                this.mainNavPathStack.pop()
            }
        }
        sessionCallback.didParticipantJoined = (userId: string, isScreenSharing) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession!.getParticipantIds()!)
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()
        }
        sessionCallback.didParticipantLeft = (userId: string, callEndReason: number, screenSharing = false) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()
        }
        sessionCallback.didParticipantConnected = (userId: string, isScreenSharing) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()
        }
        sessionCallback.didChangeMode = state => {

        }
        sessionCallback.didVideoMuted = (userId: string, muted: boolean) => {
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()
        }

        sessionCallback.didCreateLocalVideoTrack = (videoTrack: VideoTrack, screenSharing: boolean) => {
            this.focusVideoRenderController?.setVideoTrack(videoTrack)
            this.focusVideoRenderController?.setScalingMode(ScalingMode.AspectFit)
        }

        sessionCallback.didReceiveRemoteVideoTrack = (userId: string, videoTrack: VideoTrack, screenSharing: boolean) => {
            let controller = this.participantVideoRenderControllerMap.get(userId)
            controller?.setVideoTrack(videoTrack)
            controller?.setScalingMode(ScalingMode.AspectFit)
        }

        // 以下回调高级版音视频 SDK 生效
        sessionCallback.didMuteStateChanged = participants => {

        }

        // end
        this.callSession!.sessionCallback = sessionCallback;
    }

    getParticipantProfilesAndUpdateVideoRenderControllerMap() {
        this.participantProfiles = this.callSession!.getParticipantProfiles()
        if (!this.callSession!.audioOnly) {
            let map = new Map<string, WFCVideoRenderController>()
            this.participantProfiles?.forEach(p => {
                let pid = this._participantId(p.userId, p.screenSharing);
                let controller = this.participantVideoRenderControllerMap.get(pid)
                if (!controller) {
                    controller = new WFCVideoRenderController(pid)
                }
                map.set(pid, controller);
            })
            this.participantVideoRenderControllerMap = map;
        }
    }

    // 其实是不支持屏幕共享的
    _participantId(userId: string, screenSharing: boolean) {
        return screenSharing ? 'screen_sharing_' + userId : userId
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

    participantStatus(user: UserInfo): number | undefined {
        if (user.uid === this.selfUserInfo?.uid) {
            let profile = this.callSession?.getSelfProfile();
            return profile?.status
        } else {
            let profile = this.participantProfiles?.find(p => p.userId === user.uid);
            return profile?.status
        }
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
                        this.pipController?.startPiP()
                            .catch((reason: BusinessError) => {
                                console.error('startPiP error', reason.code, reason.name, reason.message)
                            })
                        this.mainNavPathStack.pop()
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
                        controller: this.focusVideoRenderController
                    })
                        .width('100%')
                        .height('100%')
                        .onLoad(() => {
                            let uid = this.selfUserInfo!.uid
                            this.focusVideoRenderController?.setVideoTrack(this.callSession?.getParticipantVideoTrack(uid))
                            this.focusVideoRenderController.setScalingMode(ScalingMode.AspectFit)
                        })
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
                    ForEach(this.targetUserInfos, (userInfo: UserInfo) => {
                        Stack() {
                            XComponent({
                                id: userInfo.uid + this.callSession?.callId,
                                type: XComponentType.SURFACE,
                                controller: this.participantVideoRenderControllerMap.get(userInfo.uid)
                            })
                                .width('100%')
                                .aspectRatio(1)
                                .onLoad(() => {
                                    let controller = this.participantVideoRenderControllerMap.get(userInfo.uid)
                                    controller?.setVideoTrack(this.callSession?.getParticipantVideoTrack(userInfo.uid))
                                })
                            if (this.participantStatus(userInfo) !== 4) {
                                Image(userInfo.portrait)
                                    .width('100%')
                                    .aspectRatio(1)
                            }
                        }
                        .onClick(() => {
                            if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                this.swapVideo(userInfo.uid)
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

    async createPipController() {
        this.pipController = await PiPWindow.create({
            context: getContext(this),
            componentController: this.focusVideoRenderController,
            customUIController: this.voipPiPNodeController,
            navigationId: uikit.bundleName,
            templateType: PiPWindow.PiPTemplateType.VIDEO_CALL,
            contentWidth: 200,
            contentHeight: 300,
        });
        this.pipController.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
            // this.onStateChange(state, reason);
        });
        this.pipController.on('controlPanelActionEvent', (event: PiPWindow.PiPActionEventType, status?: number) => {
            // this.onActionEvent(event, status);
        });
        this.pipController.setAutoStartEnabled(true)
        console.log('createPipController')
    }

    destroyPipController() {
        if (!this.pipController) {
            return;
        }
        this.pipController.setAutoStartEnabled(false)
        this.pipController.off('stateChange');
        this.pipController.off('controlPanelActionEvent');
        this.pipController.stopPiP()
        this.pipController = undefined;
    }
}