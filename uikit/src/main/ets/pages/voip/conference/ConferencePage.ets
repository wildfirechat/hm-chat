import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import wfc from '@wfc/client'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import AVCastPicker from '@ohos.multimedia.avCastPicker'
import ParticipantProfile from '@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile'
import PickGroupMemberModal from '../../group/PickGroupMemberModal'
import { timestampFormat } from '../../../util/helper'
import { window, PiPWindow } from '@kit.ArkUI'
import ConferenceInfo from '@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo'
import { showToast } from '../../../common/utils/Toast'
import { WHITE_FILTER } from '../../../api/Util'
import ConferenceParticipantView from './ConferenceParticipantView'
import ConferenceMoreActionView from './ConferenceMoreActionView'
import { VideoTrack } from '@ohos/webrtc/src/main/libohos_webrtc/webrtc'
import WFCVideoRenderController, { ScalingMode } from '@wfc/avenginekit/src/main/ets/wfc/av/xcomponent/WFCVideoRenderController'
import VoipPiPNodeController from '../VoipPiPNodeController'
import uikit from '../../../uikit'
import { BusinessError } from '@kit.BasicServicesKit'
import { navigationDestinations } from '../../navigationConfig'
import ConferenceInviteMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/conferenceInviteMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'

@Component
export default struct ConferencePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State targetUserInfos?: UserInfo[] = []
    @State participantProfiles?: ParticipantProfile[] = []
    @State invitor?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State callSession?: CallSession = undefined
    @State showPickGroupMemberModal: boolean = false
    @State durationStr: string = ''
    @State showActionAndDurationView: boolean = true
    @State focusProfile?: ParticipantProfile = undefined
    @State previewProfile?: ParticipantProfile = undefined
    @State showConferenceMoreActionSheet: boolean = false
    @State selfProfile?: ParticipantProfile = undefined
    @State currentSwiperIndex: number = -1;
    private statusBarHeight = 0
    private lastTriggerToShowActionAndDurationViewTimestamp: number = 0
    private updateActionAndDurationViewInterval = 0
    private conferenceInfo?: ConferenceInfo
    private participantVideoRenderControllerMap = new Map<string, WFCVideoRenderController>()
    private focusXComponentController: WFCVideoRenderController = new WFCVideoRenderController('focus-xcp')
    private previewXComponentController: WFCVideoRenderController = new WFCVideoRenderController('preview-xcp')
    pipController?: PiPWindow.PiPController;
    private voipPiPNodeController: VoipPiPNodeController = new VoipPiPNodeController('');
    static COUNT_PER_PAGE = 4;

    aboutToAppear(): void {
        let callSession = avengineKit.getCurrentSession();

        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            this.mainNavPathStack.pop()
            return
        }

        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conferenceInfo = params['conferenceInfo'] as ConferenceInfo

        this.statusBarHeight = px2vp(AppStorage.get<number>('SafeAreaTopHeight')!)

        this.selfUserInfo = wfc.getUserInfo(wfc.getUserId())
        this.targetUserInfos = wfc.getUserInfos(callSession?.getParticipantIds()!)

        this.callSession = callSession

        this.selfProfile = callSession.getSelfProfile()
        this.getParticipantProfilesAndUpdateVideoRenderControllerMap()

        this.updateFocusAndPreviewProfile()

        this.setupSessionCallback()
    }

    getParticipantProfilesAndUpdateVideoRenderControllerMap() {
        this.participantProfiles = this.callSession!.getParticipantProfiles()
        if (!this.callSession!.audioOnly) {
            let map = new Map<string, WFCVideoRenderController>()
            let profiles = [this.selfProfile!, ...this.participantProfiles]
            profiles.forEach(p => {
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

    swapVideo(xcomponentId: string) {
        // TODO
        // let nextFocusUserId = ''
        // let preFocusUserId = ''
        // this.userXComponentMap.forEach((value, key) => {
        //     if (value === xcomponentId) {
        //         nextFocusUserId = key!;
        //     }
        //     if (value === this.focusXComponentId) {
        //         preFocusUserId = key!;
        //     }
        // })
        //
        // this.userXComponentMap.set(nextFocusUserId, this.focusXComponentId)
        // this.userXComponentMap.set(preFocusUserId, xcomponentId)
        //
        // this.setupInitialXComponentViews()
    }

    setupFocusAndPreviewVideoTrack() {
        // console.log('setupFocusAndPreviewXComponentId focus', this.focusProfile!.videoTrack?.id)
        if (this.focusProfile) {
            this.focusXComponentController.setVideoTrack(this.callSession?.getParticipantVideoTrack(this.focusProfile.userId, this.focusProfile.screenSharing))
            this.focusXComponentController.setScalingMode(ScalingMode.AspectFill)
            if (this.previewProfile) {
                this.previewXComponentController.setVideoTrack(this.callSession?.getParticipantVideoTrack(this.previewProfile.userId, this.previewProfile.screenSharing))
                this.previewXComponentController.setScalingMode(ScalingMode.AspectFit)
            }
        }
    }

    updateFocusAndPreviewProfile() {
        if (!this.participantProfiles || this.participantProfiles?.length === 0) {
            this.focusProfile = this.selfProfile
            this.previewProfile = undefined
        } else {
            // TODO
            // 用户主动设置的焦点视频流
            let foundFocusProfile = false
            for (let i = 0; i < this.participantProfiles.length; i++) {
                if (!this.participantProfiles[i].audience && !this.participantProfiles[i].videoMuted) {
                    this.focusProfile = this.participantProfiles[i]
                    this.previewProfile = this.selfProfile
                    foundFocusProfile = true
                    break
                }
            }

            if (!foundFocusProfile) {
                this.focusProfile = this.selfProfile
                this.previewProfile = undefined;
            }
        }
    }

    updateFocusAndPreviewView() {
        this.updateFocusAndPreviewProfile()
        if (this.currentSwiperIndex === -1 || this.currentSwiperIndex === 0) {
            this.setupFocusAndPreviewVideoTrack()
        }
    }

    // 支持 unset
    setupParticipantFlexXComponentIds(swiperIndex: number, unset: boolean) {
        // 0 is focus/preview view
        // if (swiperIndex === 0) {
        //     this.setupFocusAndPreviewVideoTrack()
        // } else if (swiperIndex == 1) {
        //     let selfProfile = this.callSession?.getSelfProfile()!
        //     this.callSession?.setUserXComponentId(CallSession.xcomponentUserId(selfProfile), unset ? '' : CallSession.currentXComponentId(selfProfile))
        //     for (let i = 0; i < ConferencePage.COUNT_PER_PAGE - 1; i++) {
        //         let index = (swiperIndex - 1) * ConferencePage.COUNT_PER_PAGE + i
        //         if (index < this.participantProfiles!.length) {
        //             let p = this.participantProfiles![index]
        //             this.callSession?.setUserXComponentId(CallSession.xcomponentUserId(p), unset ? '' : CallSession.currentXComponentId(p))
        //         }
        //     }
        // } else if (swiperIndex > 1) {
        //     for (let i = 0; i < ConferencePage.COUNT_PER_PAGE; i++) {
        //         let index = (swiperIndex - 1) * ConferencePage.COUNT_PER_PAGE + i
        //         if (index < this.participantProfiles!.length) {
        //             let p = this.participantProfiles![index]
        //             this.callSession?.setUserXComponentId(CallSession.xcomponentUserId(p), unset ? '' : CallSession.currentXComponentId(p))
        //         }
        //     }
        // }
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
        if (this.lastTriggerToShowActionAndDurationViewTimestamp > 0 && !this.showConferenceMoreActionSheet && Date.now() - this.lastTriggerToShowActionAndDurationViewTimestamp > 5000) {
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
            this.selfProfile = this.callSession?.getSelfProfile()!;

            this.updateFocusAndPreviewView()
        }
        sessionCallback.didCallEndWithReason = reason => {
            if (this.updateActionAndDurationViewInterval) {
                clearInterval(this.updateActionAndDurationViewInterval)
            }
            this.destroyPipController()

            let index = this.mainNavPathStack.getIndexByName(navigationDestinations.ConferencePage)
            if (index.length) {
                this.mainNavPathStack.pop()
            }
        }
        sessionCallback.didParticipantJoined = (userId: string, isScreenSharing?: boolean) => {

            this.targetUserInfos = wfc.getUserInfos(this.callSession!.getParticipantIds()!)
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()

            // 主页只显示两个
            if (this.participantProfiles?.length === 1) {
                this.previewProfile = this.focusProfile;
                this.focusProfile = this.participantProfiles[0]
            }
            this.updateFocusAndPreviewView()
        }
        sessionCallback.didParticipantLeft = (userId: string, callEndReason: number, screenSharing = false) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()

            this.updateFocusAndPreviewView();

        }
        sessionCallback.didChangeType = (userId: string, audience: boolean, screenSharing?: boolean) => {
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()
            this.selfProfile = this.callSession?.getSelfProfile()!;
            this.updateFocusAndPreviewView()
        }

        sessionCallback.didParticipantConnected = (userId: string, isScreenSharing?: boolean) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()
            console.log('didParticipantConnected', userId, isScreenSharing)
        }
        sessionCallback.didChangeMode = state => {

        }
        sessionCallback.didMuteStateChanged = participants => {
            if (participants.indexOf(wfc.getUserId()) >= 0) {
                this.selfProfile = this.callSession?.getSelfProfile()!
            }
            this.getParticipantProfilesAndUpdateVideoRenderControllerMap()
            this.updateFocusAndPreviewProfile()
        }

        // 可能会调用多次，切换摄像头等情况下，会多次回调
        sessionCallback.didCreateLocalVideoTrack = (videoTrack: VideoTrack, screenSharing: boolean) => {
            let controller = this.participantVideoRenderControllerMap.get(this._participantId(wfc.getUserId(), screenSharing));
            controller?.setVideoTrack(videoTrack)

            if (this.currentSwiperIndex === -1 || this.currentSwiperIndex === 0) {
                this.setupFocusAndPreviewVideoTrack()
            }
        }
        sessionCallback.didReceiveRemoteVideoTrack = (userId: string, videoTrack: VideoTrack, screenSharing: boolean) => {
            let controller = this.participantVideoRenderControllerMap.get(this._participantId(userId, screenSharing));
            controller?.setVideoTrack(videoTrack)

            if (this.currentSwiperIndex === -1 || this.currentSwiperIndex === 0) {
                this.setupFocusAndPreviewVideoTrack()
            }
        }

        // end
        this.callSession!.sessionCallback = sessionCallback;
    }

    _participantId(userId: string, screenSharing: boolean) {
        return screenSharing ? 'screen_sharing_' + userId : userId
    }

    tip() {
        let desc = ''
        if (this.callSession?.status === CallState.STATUS_OUTGOING) {
            desc = '等待对方接听'
        } else if (this.callSession?.status === CallState.STATUS_INCOMING) {
            desc = `${this.invitor?.displayName} 邀请你通话`
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
    conferenceMoreActionSheet() {
        ConferenceMoreActionView({
            conferencePage: this,
        })
            .width('100%')
            .height('100%')
            .padding({
                top: 5
            })
    }

    @Builder
    actionAndDurationView() {
        // actions
        Column() {
            // top actions
            Row() {
                AVCastPicker({ normalColor: Color.White, activeColor: Color.White })
                    .width(50)
                    .height(50)
                    .border({ width: 1, radius: 4, color: Color.Transparent })

                Image($r('app.media.av_conference_switch_camera'))
                    .draggable(false)
                    .width(50)
                    .height(50)
                    .colorFilter(WHITE_FILTER)
                    .objectFit(ImageFit.Contain)
                    .padding({ left: 10, right: 10 })
                    .onClick(async () => {
                        if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                            this.callSession?.switchCamera()
                        }
                    })

                Column() {
                    Text('会议标题')
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Center)
                        .alignSelf(ItemAlign.Center)
                    Text(this.durationStr)
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Center)
                        .alignSelf(ItemAlign.Center)
                }
                .layoutWeight(1)

                Image($r('app.media.av_conference_hangup'))
                    .draggable(false)
                    .clickEffect({ level: ClickEffectLevel.MIDDLE })
                    .width(50)
                    .height(50)
                    .objectFit(ImageFit.Contain)
                    .padding({ left: 10, right: 10 })
                    .onClick(() => {
                        this.callSession?.hangup()
                    })
                // Image($r('app.media.ic_tab_add'))
                //     .fillColor(Color.Red)
                //     .draggable(false)
                //     .width(50)
                //     .height(50)
                //     .padding(10)
                //     .onClick(() => {
                //         this.showPickGroupMemberModal = true;
                //     })
                //     .bindContentCover(this.showPickGroupMemberModal, this.pickGroupMemberModal(), {
                //         modalTransition: ModalTransition.DEFAULT,
                //         onAppear: () => {
                //         },
                //
                //         onDisappear: () => {
                //             this.showPickGroupMemberModal = false
                //         }
                //     })
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 10, right: 10 })
            .width('100%')
            .margin({ top: this.statusBarHeight })

            // bottom actions
            if (this.callSession!.status === CallState.STATUS_CONNECTED) {
                Column() {
                    Row() {
                        Column() {
                            Image(this.callSession?.audioMuted ? $r('app.media.av_conference_audio_mute') : $r('app.media.av_conference_audio'))
                                .draggable(false)
                                .width(30)
                                .height(30)
                                .colorFilter(WHITE_FILTER)
                                .onClick(() => {
                                    this.lastTriggerToShowActionAndDurationViewTimestamp = Date.now()
                                    let toMute = !this.callSession?.audioMuted
                                    if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                        if (toMute) {
                                            if (!this.callSession.audience && this.callSession.videoMuted) {
                                                this.callSession.switchAudience(true)
                                            }
                                            this.callSession?.muteAudio(true)
                                        } else {
                                            let participantFull = false
                                            if (this.callSession.audience && participantFull) {
                                                showToast('超过最大互动者人数')
                                                return;
                                            } else {
                                                this.callSession.muteAudio(false)
                                                if (this.callSession.audience) {
                                                    this.callSession.switchAudience(false)
                                                }
                                            }
                                        }
                                    }
                                })
                            Text('麦克风')
                                .margin({ top: 10 })
                                .fontSize(13)
                                .fontColor(Color.White)
                        }

                        Column() {
                            Image(this.callSession?.videoMuted ? $r('app.media.av_conference_video_mute') : $r('app.media.av_conference_video'))
                                .draggable(false)
                                .width(30)
                                .height(30)
                                .colorFilter(WHITE_FILTER)
                                .hitTestBehavior(HitTestMode.Block)
                                .onClick(() => {
                                    this.lastTriggerToShowActionAndDurationViewTimestamp = Date.now()
                                    let toMute = !this.callSession?.videoMuted
                                    if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                        if (toMute) {
                                            if (!this.callSession.audience && this.callSession.audioMuted) {
                                                this.callSession.switchAudience(true)
                                            }
                                            this.callSession?.muteVideo(true)
                                        } else {
                                            // TODO
                                            let participantFull = false
                                            if (this.callSession.audience && participantFull) {
                                                showToast('超过最大互动者人数')
                                                return;
                                            } else {
                                                this.callSession.muteVideo(false)
                                                if (this.callSession.audience) {
                                                    this.callSession.switchAudience(false)
                                                }
                                            }
                                        }
                                    }
                                })
                            Text('视频')
                                .margin({ top: 10 })
                                .fontSize(13)
                                .fontColor(Color.White)
                        }

                        Column() {
                            Image($r('app.media.av_conference_screen_sharing'))
                                .draggable(false)
                                .width(30)
                                .height(30)
                                .colorFilter(WHITE_FILTER)
                                .onClick(() => {
                                    this.callSession?.startScreenShare()
                                })
                            Text('共享屏幕')
                                .margin({ top: 10 })
                                .fontSize(13)
                                .fontColor(Color.White)
                        }

                        Column() {
                            Image($r('app.media.av_conference_members'))
                                .draggable(false)
                                .width(30)
                                .height(30)
                                .colorFilter(WHITE_FILTER)
                                .onClick(() => {
                                    let params = {} as Record<string, Object>
                                    params['callId'] = this.callSession!.callId
                                    params['conferenceInfo'] = this.conferenceInfo!
                                    this.mainNavPathStack.pushPathByName(navigationDestinations.ConferenceParticipantListPage, params)
                                })
                            Text('管理')
                                .margin({ top: 10 })
                                .fontSize(13)
                                .fontColor(Color.White)
                        }

                        Column() {
                            Image($r('app.media.av_conference_more'))
                                .draggable(false)
                                .width(30)
                                .height(30)
                                .colorFilter(WHITE_FILTER)
                            Text('更多')
                                .margin({ top: 10 })
                                .fontSize(13)
                                .fontColor(Color.White)
                        }
                        .enabled(true)
                        .onClick(() => {
                            this.showConferenceMoreActionSheet = true
                        })
                        .bindSheet(this.showConferenceMoreActionSheet, this.conferenceMoreActionSheet(), {
                            height: '50%',
                            dragBar: false,
                            showClose: false,
                            onDisappear: () => {
                                this.showConferenceMoreActionSheet = false
                            }
                        })
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
            Swiper() {
                Stack() {
                    if (this.focusProfile) {
                        ConferenceParticipantView({
                            p: this.focusProfile,
                            xcomponentIdPrefix: 'focus-xcp',
                            swiperIndex: 0,
                            currentSwiperIndex: this.currentSwiperIndex,
                            xcomponentController: this.focusXComponentController,
                            onXComponentLoadCallback: () => {
                                // this.setupFocusAndPreviewVideoTrack()
                            }

                        })
                            .onClick(() => {
                                if (this.callSession?.status !== CallState.STATUS_CONNECTED) {
                                    return
                                }
                                this.showActionAndDurationView = !this.showActionAndDurationView

                                this.lastTriggerToShowActionAndDurationViewTimestamp = Date.now()
                            })
                    }

                    // preview
                    if (this.previewProfile) {
                        ConferenceParticipantView({
                            p: this.previewProfile,
                            xcomponentIdPrefix: 'preview-xcp',
                            swiperIndex: 0,
                            currentSwiperIndex: this.currentSwiperIndex,
                            xcomponentController: this.previewXComponentController,
                            onXComponentLoadCallback: () => {
                                // this.setupFocusAndPreviewVideoTrack()
                            }
                        })
                            .padding(5)
                            .margin({ top: this.statusBarHeight + 50 })
                            .width(100)
                            .height(200)
                            .onClick(() => {
                                if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                    // this.swapVideo(`${p.userId}-${this.callSession.callId}`)
                                }
                            })
                    }

                    if (this.showActionAndDurationView) {
                        this.actionAndDurationView()
                    }
                }
                .width('100%')
                .height('100%')
                .alignContent(Alignment.TopStart)

                if (this.participantProfiles && this.participantProfiles.length >= 1) {
                    ForEach(new Array(Math.ceil(this.participantIdsIncludeSelf().length / ConferencePage.COUNT_PER_PAGE)).fill(0), (item: number, participantFlexIndex) => {
                        Flex({
                            direction: FlexDirection.Row,
                            justifyContent: FlexAlign.Start,
                            alignContent: FlexAlign.Start,
                            wrap: FlexWrap.Wrap,
                        }) {
                            if (participantFlexIndex == 0) {
                                ConferenceParticipantView({
                                    p: this.selfProfile,
                                    swiperIndex: participantFlexIndex + 1,
                                    currentSwiperIndex: this.currentSwiperIndex,
                                    xcomponentController: this.participantVideoRenderControllerMap.get(this.selfProfile!.userId)
                                })
                                    .width('50%')
                                    .height('50%')
                            }

                            ForEach(this.participantProfiles, (item: number, flexIndex) => {
                                if (participantFlexIndex * ConferencePage.COUNT_PER_PAGE + flexIndex > this.participantProfiles!.length) {
                                    // 占位
                                    Column()
                                        .width('50%')
                                        .height('50%')
                                        .backgroundColor(Color.Gray)
                                } else {
                                    ConferenceParticipantView({
                                        p: this.participantProfiles![participantFlexIndex * 3 + flexIndex],
                                        swiperIndex: participantFlexIndex + 1,
                                        currentSwiperIndex: this.currentSwiperIndex,
                                        xcomponentController: this.participantVideoRenderControllerMap.get(this.participantProfiles![participantFlexIndex * 3 + flexIndex].userId)
                                        // xcomponentController: new VideoRenderController()
                                    })
                                        .width('50%')
                                        .height('50%')
                                }
                            }, (item: number, flexIndex) => flexIndex + '')
                        }
                        .backgroundColor(Color.Orange)
                        .width('100%')
                        .height('100%')
                    }, (item: number, swiperIndex) => swiperIndex + '')
                }
            }
            .indicator(true)
            .vertical(false)
            .onChange(index => {
                console.log('swiper onChange', this.currentSwiperIndex, index)
                if (this.currentSwiperIndex != -1) {
                    this.setupParticipantFlexXComponentIds(this.currentSwiperIndex, true)
                }
                this.currentSwiperIndex = index
                this.setupParticipantFlexXComponentIds(index, false)
            })
        }
        .title('VOIP Conference')
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

    minimize() {
        this.showConferenceMoreActionSheet = false
        this.pipController?.startPiP()
            .catch((reason: BusinessError) => {
                console.error('startPiP error', reason.code, reason.name, reason.message)
            })
        this.mainNavPathStack.pop()
    }

    async createPipController() {
        this.pipController = await PiPWindow.create({
            context: this.getUIContext().getHostContext(),
            componentController: this.focusXComponentController,
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

    inviteNewParticipant() {
        this.showConferenceMoreActionSheet = false

        let info = this.conferenceInfo!
        let inviteMessageContent = new ConferenceInviteMessageContent(info.conferenceId, info.owner, info.conferenceTitle, '', info.startTime, false, false, info.advance, info.pin, info.password)
        let dummyConversation = new Conversation(0, '', 0)
        let message = new Message(dummyConversation, inviteMessageContent)
        this.mainNavPathStack.pushPathByName(navigationDestinations.ForwardMessagePage,
            {
                'messages': [message]
            } as Record<string, Object>
        )
    }
}