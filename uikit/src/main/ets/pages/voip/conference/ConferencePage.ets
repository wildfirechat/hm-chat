import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKitImpl from '@wfc/avenginekit'
import avengineKit from '@wfc/avenginekit/src/main/ets/wfc/av/engine/avenginekit'
import wfc from '@wfc/client'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import AVCastPicker from '@ohos.multimedia.avCastPicker'
import ParticipantProfile from '@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile'
import PickGroupMemberModal from '../../group/PickGroupMemberModal'
import { timestampFormat } from '../../../util/helper'
import { window, PiPWindow, KeyboardAvoidMode } from '@kit.ArkUI'
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
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'
import ConferenceInviteMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/conferenceInviteMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import TranscriptionMessageContent from '@wfc/client/src/main/ets/wfc/messages/transcriptionMessageContent'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import VideoType from '@wfc/avenginekit/src/main/ets/wfc/av/engine/videoType'
import BasicDataSource from '../../../common/BasicDataSource'
import { FontSize, Radius } from '../../../common/design/Tokens'

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
    @State latest5ConferenceChatroomMessages: Message[] = []
    @State latest5TranscriptionMessages: Message[] = []
    @State showInputPanel: boolean = false
    @State keyboardHeight: number = 0
    @State inputText: string = ''
    private swiperParticipantGridItemDataSource: SwiperParticipantGridItemDataSource = new SwiperParticipantGridItemDataSource()
    static COUNT_PER_PAGE = 4;

    aboutToAppear(): void {
        let callSession = avengineKitImpl.getCurrentSession();

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
        wfc.eventEmitter?.on(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter?.on(EventType.SendMessage, this.onSendMessage)
    }

    getParticipantProfilesAndUpdateVideoRenderControllerMap() {
        let newProfiles = this.callSession!.getParticipantProfiles()
        if (!this.callSession!.audioOnly) {
            let map = new Map<string, WFCVideoRenderController>()
            let profiles = [this.selfProfile!, ...newProfiles]
            profiles.forEach(p => {
                let pid = this._participantIdForVideoRenderController(p.userId, p.screenSharing);
                let controller = this.participantVideoRenderControllerMap.get(pid)
                if (!controller) {
                    controller = new WFCVideoRenderController(pid)
                }
                map.set(pid, controller);
            })
            this.participantVideoRenderControllerMap = map;
        }
        this.participantProfiles = newProfiles.sort((p1, p2) => p1.joinTime - p2.joinTime)
        this.swiperParticipantGridItemDataSource.setupParticipantProfiles(this.selfProfile!, this.participantProfiles)
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
            this.focusXComponentController.setScalingMode(ScalingMode.AspectFit)
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
            let preFocusProfile = this.focusProfile
            for (let i = 0; i < this.participantProfiles.length; i++) {
                if (!this.participantProfiles[i].audience && !this.participantProfiles[i].videoMuted) {
                    this.focusProfile = this.participantProfiles[i]
                    this.previewProfile = this.selfProfile
                    foundFocusProfile = true
                    break
                }
            }

            if (foundFocusProfile) {
                if (this.focusProfile) {
                    console.log('av-c', 'found focusProfile', this.focusProfile.userId)
                    this.callSession?.setParticipantVideoType(this.focusProfile.userId, this.focusProfile.screenSharing, VideoType.BIG_STREAM)
                }
                if (preFocusProfile && preFocusProfile.userId !== this.focusProfile?.userId) {
                    this.callSession?.setParticipantVideoType(preFocusProfile.userId, preFocusProfile.screenSharing, VideoType.SMALL_STREAM)
                }
            }

            if (!foundFocusProfile) {
                this.focusProfile = this.selfProfile
                this.previewProfile = undefined;
            }
        }
        this.swiperParticipantGridItemDataSource.setupFocusProfile(this.focusProfile, this.previewProfile)
    }

    updateFocusAndPreviewView() {
        this.updateFocusAndPreviewProfile()
        if (this.currentSwiperIndex === -1 || this.currentSwiperIndex === 0) {
            this.setupFocusAndPreviewVideoTrack()
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
        wfc.eventEmitter?.off(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter?.off(EventType.SendMessage, this.onSendMessage)
    }

    onPageShow(): void {
        let win = AppStorage.get<window.Window>('window')
        win?.setWindowLayoutFullScreen(true)

        // 禁止 ArkUI 内部自动上移防键盘，确保视频页面完全不动
        this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE)

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

        // 监听键盘高度，手动将 sheet 内容顶到键盘上方（KeyboardAvoidMode.NONE 禁用了自动避让）
        win?.off('keyboardHeightChange')
        win?.on('keyboardHeightChange', (height: number) => {
            this.keyboardHeight = px2vp(height)
        })

    }

    onPageHide(): void {
        // 离开页面时恢复默认键盘避让模式，不影响其他页面
        this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)
        let win = AppStorage.get<window.Window>('window')
        win?.off('keyboardHeightChange')
        this.keyboardHeight = 0
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
                wfc.joinChatroom(this.callSession!.callId, () => {
                    console.log('join conference chatroom success')
                }, err => {
                    console.error('join conference chatroom fail', err)
                })
            }
            this.selfProfile = this.callSession?.getSelfProfile()!;

            this.updateFocusAndPreviewView()
        }
        sessionCallback.didCallEndWithReason = reason => {
            if (this.updateActionAndDurationViewInterval) {
                clearInterval(this.updateActionAndDurationViewInterval)
            }
            this.destroyPipController()

            let index = this.mainNavPathStack.getIndexByName(uikitNavigationDestinations.ConferencePage)
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
            let controller = this.participantVideoRenderControllerMap.get(this._participantIdForVideoRenderController(wfc.getUserId(), screenSharing));
            controller?.setVideoTrack(videoTrack)

            if (this.currentSwiperIndex === -1 || this.currentSwiperIndex === 0) {
                this.setupFocusAndPreviewVideoTrack()
            }
        }
        sessionCallback.didReceiveRemoteVideoTrack = (userId: string, videoTrack: VideoTrack, screenSharing: boolean) => {
            let controller = this.participantVideoRenderControllerMap.get(this._participantIdForVideoRenderController(userId, screenSharing));
            controller?.setVideoTrack(videoTrack)

            if (this.currentSwiperIndex === -1 || this.currentSwiperIndex === 0) {
                this.setupFocusAndPreviewVideoTrack()
            }
        }

        // end
        this.callSession!.sessionCallback = sessionCallback;
    }

    _participantIdForVideoRenderController(userId: string, screenSharing: boolean) {
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
            .padding({ top: 4 })
    }

    @Builder
    actionAndDurationView() {
        // actions
        Column() {
            // top actions
            Row() {
                AVCastPicker({ normalColor: Color.White, activeColor: Color.White })
                    .width(52)
                    .height(52)
                    .border({ width: 1, radius: 4, color: Color.Transparent })

                Image($r('app.media.av_conference_switch_camera'))
                    .draggable(false)
                    .width(52)
                    .height(52)
                    .colorFilter(WHITE_FILTER)
                    .objectFit(ImageFit.Contain)
                    .padding({ left: 12, right: 12 })
                    .onClick(async () => {
                        if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                            this.callSession?.switchCamera()
                        }
                    })

                Column() {
                    Text(this.callSession?.title)
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
                    .width(52)
                    .height(52)
                    .objectFit(ImageFit.Contain)
                    .padding({ left: 12, right: 12 })
                    .onClick(() => {
                        this.callSession?.hangup()
                    })
                // Image($r('app.media.ic_tab_add'))
                //     .fillColor(Color.Red)
                //     .draggable(false)
                //     .width(52)
                //     .height(52)
                //     .padding(12)
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
            .padding({ left: 12, right: 12 })
            .width('100%')
            .margin({ top: this.statusBarHeight })

            // bottom actions
            if (this.callSession!.status === CallState.STATUS_CONNECTED) {
                Column() {
                    Row() {
                        Column() {
                            Image(this.callSession?.audioMuted ? $r('app.media.av_conference_audio_mute') : $r('app.media.av_conference_audio'))
                                .draggable(false)
                                .width(32)
                                .height(32)
                                .colorFilter(WHITE_FILTER)
                                .onClick(() => {
                                    if (this.callSession?.isScreenSharing() && avengineKit.SCREEN_SHARING_REPLACE_MODE) {
                                        showToast('正在进行屏幕共享，请先结束共享')
                                        return
                                    }
                                    if (!this.conferenceInfo?.allowSwitchMode) {
                                        showToast('主持人不允许主动开启麦克风')
                                        return
                                    }
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
                                .margin({ top: 12 })
                                .fontSize(FontSize.sm)
                                .fontColor(Color.White)
                        }

                        Column() {
                            Image(this.callSession?.videoMuted ? $r('app.media.av_conference_video_mute') : $r('app.media.av_conference_video'))
                                .draggable(false)
                                .width(32)
                                .height(32)
                                .colorFilter(WHITE_FILTER)
                                .hitTestBehavior(HitTestMode.Block)
                                .onClick(() => {
                                    if (!this.conferenceInfo?.allowSwitchMode) {
                                        showToast('主持人不允许主动开启摄像头')
                                        return
                                    }
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
                                .margin({ top: 12 })
                                .fontSize(FontSize.sm)
                                .fontColor(Color.White)
                        }

                        Column() {
                            Image($r('app.media.av_conference_screen_sharing'))
                                .draggable(false)
                                .width(32)
                                .height(32)
                                .colorFilter(WHITE_FILTER)
                                .onClick(() => {
                                    if (this.callSession?.audience) {
                                        showToast('请先切换为互动者')
                                        return
                                    }
                                    if (this.callSession?.isScreenSharing()) {
                                        this.callSession?.stopScreenShare()
                                    } else {
                                        this.callSession?.startScreenShare()
                                        this.minimize()
                                    }
                                })
                            Text('共享屏幕')
                                .margin({ top: 12 })
                                .fontSize(FontSize.sm)
                                .fontColor(Color.White)
                        }

                        Column() {
                            Image($r('app.media.av_conference_members'))
                                .draggable(false)
                                .width(32)
                                .height(32)
                                .colorFilter(WHITE_FILTER)
                                .onClick(() => {
                                    let params = {} as Record<string, Object>
                                    params['callId'] = this.callSession!.callId
                                    params['conferenceInfo'] = this.conferenceInfo!
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConferenceParticipantListPage, params)
                                })
                            Text('管理')
                                .margin({ top: 12 })
                                .fontSize(FontSize.sm)
                                .fontColor(Color.White)
                        }

                        Column() {
                            Image($r('app.media.av_conference_more'))
                                .draggable(false)
                                .width(32)
                                .height(32)
                                .colorFilter(WHITE_FILTER)
                            Text('更多')
                                .margin({ top: 12 })
                                .fontSize(FontSize.sm)
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
                .margin({ bottom: 32 })
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

    onSendMessage = (msg: Message) => {
        this._appendConferenceChatroomMessage([msg])
    }

    onReceiveMessage = (messages: Message[]) => {
        this._appendConferenceChatroomMessage(messages)
    }

    _appendConferenceChatroomMessage(messages: Message[]){
        if (!this.callSession) {
            return
        }
        for (const msg of messages) {
            if (msg.conversation.type === ConversationType.ChatRoom && msg.conversation.target === this.callSession.callId) {
                if (msg.messageContent.type === MessageContentType.Transcription) {
                    this.latest5TranscriptionMessages.push(msg)
                } else {
                    this.latest5ConferenceChatroomMessages.push(msg)
                }
            }
        }
        let len = this.latest5ConferenceChatroomMessages.length
        if (len > 5) {
            this.latest5ConferenceChatroomMessages = this.latest5ConferenceChatroomMessages.slice(len - 5, len)
        }
        let tlen = this.latest5TranscriptionMessages.length
        if (tlen > 5) {
            this.latest5TranscriptionMessages = this.latest5TranscriptionMessages.slice(tlen - 5, tlen)
        }
    }

    @Builder
    transcriptionView() {
        Column() {
            ForEach(this.latest5TranscriptionMessages, (msg: Message, index: number) => {
                Row() {
                    Text(wfc.getUserInfo((msg.messageContent as TranscriptionMessageContent).userId).displayName)
                        .fontSize(FontSize.xs)
                        .fontColor('#FFA500')
                        .margin({ right: 4 })
                    Text((msg.messageContent as TranscriptionMessageContent).content)
                        .fontSize(FontSize.xs)
                        .fontColor(Color.White)
                        .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 2, bottom: 2 })
            }, (msg: Message, index: number) => {
                return msg.messageUid + ''
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('80%')
        .constraintSize({ maxHeight: 120 })
        .padding(8)
        .position({ x: '10%', y: 40 })
    }

    @Builder
    chatroomLatestMessageListView(){
        List() {
            ForEach(this.latest5ConferenceChatroomMessages, (msg: Message, index: number) => {
                ListItem() {
                    Row() {
                        Text(wfc.getUserInfo(msg.from).displayName + ':  ')
                            .fontColor(Color.White)
                            .fontSize(FontSize.xs)
                            .maxLines(1)
                            .constraintSize({ maxWidth: 70 })
                        Text(msg.messageContent.digest(msg))
                            .fontColor(Color.White)
                            .fontSize(FontSize.xs)
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)
                    }
                    .padding({ top: 4, bottom: 4, left: 8, right: 8 })
                    // .backgroundColor('rgba(0,0,0,0.45)')
                    .borderRadius(Radius.md)
                    .margin({ bottom: 4 })
                    .width('100%')
                }
            }, (msg: Message, index: number) => msg.messageId + '')
        }
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: 180 })
        .width('100%')
    }

    // sheet 内容：消息列表 + 输入框，键盘弹出时 sheet 自动上移，不影响主页面
    @Builder
    inputSheetContent() {
        Column() {
            this.chatroomLatestMessageListView()
            Row() {
                TextInput({ placeholder: '说点什么...', text: this.inputText })
                    .fontSize(FontSize.sm)
                    .borderRadius(Radius.full)
                    .backgroundColor('rgba(255,255,255,0.15)')
                    .fontColor(Color.White)
                    .placeholderColor('rgba(255,255,255,0.5)')
                    .layoutWeight(1)
                    .onChange(value => {
                        this.inputText = value
                    })
                    .defaultFocus(true)
                Button('发送')
                    .enabled(!!this.inputText)
                    .type(ButtonType.Normal)
                    .buttonStyle(ButtonStyleMode.TEXTUAL)
                    .fontColor(Color.White)
                    .margin({ left: 8 })
                    .onClick(() => {
                        if (this.inputText) {
                            let textMsgContent = new TextMessageContent(this.inputText)
                            let conversation = new Conversation(ConversationType.ChatRoom, this.callSession!.callId, 0)
                            wfc.sendConversationMessage(conversation, textMsgContent, [], msgId => {
                            }, undefined, undefined, (msgUid, timestamp) => {
                                let len = this.latest5ConferenceChatroomMessages.length
                                if (len > 5) {
                                    this.latest5ConferenceChatroomMessages = this.latest5ConferenceChatroomMessages.slice(len - 5, len)
                                }
                            })
                            this.inputText = ''
                        }
                        // 如果希望点击发送按钮后，不隐藏输入框，将下面这行注释了
                        this.showInputPanel = false
                    })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 12, right: 12 })
            .backgroundColor('rgba(255,255,255,0.1)')
            .borderRadius(Radius.full)
            .margin({ top: 8 })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: this.keyboardHeight > 0 ? this.keyboardHeight + 20 : 20 })
        .width('100%')
    }

    @Builder
    chatroomView() {
        Column() {
            this.chatroomLatestMessageListView()

            // 点击后通过 bindSheet 弹出输入面板；sheet 是系统级浮层，键盘弹出时只有 sheet 上移，视频画面完全不动
            Text('说点什么')
                .fontColor(Color.White)
                .fontSize(FontSize.sm)
                .backgroundColor('rgba(0,0,0,0.45)')
                .borderRadius(Radius.xxl)
                .padding(8)
                .margin({ top: 4 })
                .onClick(() => {
                    this.showInputPanel = true
                })
                .bindSheet(this.showInputPanel, this.inputSheetContent(), {
                    height: SheetSize.FIT_CONTENT,
                    dragBar: false,
                    showClose: false,
                    backgroundColor: '#E61E1E1E',
                    maskColor: Color.Transparent,
                    onDisappear: () => {
                        this.showInputPanel = false
                        this.inputText = ''
                    }
                })
        }
        .alignItems(HorizontalAlign.Start)
        .width('55%')
        .height('100%')
        .padding({ left: 12, top: 12, right: 12, bottom: 100 })
        .justifyContent(FlexAlign.End)
        .hitTestBehavior(HitTestMode.Transparent)
        .visibility(this.showInputPanel ? Visibility.Hidden: Visibility.Visible)
    }

    build() {
        NavDestination() {
            Swiper() {
                LazyForEach(this.swiperParticipantGridItemDataSource, (ps: ParticipantProfile[], participantSwiperItemIndex: number) => {
                    if (participantSwiperItemIndex === 0) {
                        Stack() {
                            // focus
                            if (ps[0]) {
                                ConferenceParticipantView({
                                    p: ps[0],
                                    xcomponentIdPrefix: 'focus-xcp',
                                    swiperIndex: 0,
                                    currentSwiperIndex: this.currentSwiperIndex,
                                    xcomponentController: this.focusXComponentController,
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
                            if (ps[1]) {
                                ConferenceParticipantView({
                                    p: ps[1],
                                    xcomponentIdPrefix: 'preview-xcp',
                                    swiperIndex: 0,
                                    currentSwiperIndex: this.currentSwiperIndex,
                                    xcomponentController: this.previewXComponentController,
                                })
                                    .padding(4)
                                    .margin({ top: this.statusBarHeight + 50 })
                                    .width(120)
                                    .height(160)
                                    .borderRadius(Radius.sm)
                                    .onClick(() => {
                                        if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                            // this.swapVideo(`${p.userId}-${this.callSession.callId}`)
                                        }
                                    })
                            }

                            if (this.showActionAndDurationView) {
                                this.actionAndDurationView()
                            }
                            if(this.callSession?.status === CallState.STATUS_CONNECTED){
                                this.chatroomView()
                            }
                            this.transcriptionView()
                        }
                        .width('100%')
                        .height('100%')
                        .alignContent(Alignment.TopStart)

                    } else {
                        Flex({
                            direction: FlexDirection.Row,
                            justifyContent: FlexAlign.Start,
                            alignContent: FlexAlign.Start,
                            wrap: FlexWrap.Wrap,
                        }) {
                            ForEach(ps, (p: ParticipantProfile, flexIndex) => {
                                ConferenceParticipantView({
                                    p: p,
                                    swiperIndex: participantSwiperItemIndex,
                                    currentSwiperIndex: this.currentSwiperIndex,
                                    xcomponentController: this.participantVideoRenderControllerMap.get(this._participantIdForVideoRenderController(p.userId, p.screenSharing))
                                })
                                    .width('50%')
                                    .height('50%')
                            }, (p: ParticipantProfile, flexIndex) => {
                                return p.userId + '-' + p.screenSharing + '-' + p.audience + '-' + p.videoMuted + '-' + p.audioMuted
                            })
                        }
                        .backgroundColor(Color.Orange)
                        .width('100%')
                        .height('100%')
                    }
                }, (ps: ParticipantProfile[], index: number) => {
                    let id = index + ''
                    for (const p of ps) {
                        if (p) {
                            id += (p.userId + '-' + p.screenSharing + '-' + p.audience + '-' + p.videoMuted + '-' + p.audioMuted) + '|'
                        } else {
                            id += 'u' + '|'
                        }
                    }
                    return id
                })
            }
            .indicator(true)
            .vertical(false)
            .onChange(index => {
                console.log('swiper onChange', this.currentSwiperIndex, index)
                this.currentSwiperIndex = index
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
        .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
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
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ForwardMessagePage,
            {
                'messages': [message]
            } as Record<string, Object>
        )
    }
}

class SwiperParticipantGridItemDataSource extends BasicDataSource<(ParticipantProfile | undefined)[]> {
    selfProfile?: ParticipantProfile
    focusProfile?: ParticipantProfile
    previewProfile?: ParticipantProfile
    participantProfiles: ParticipantProfile[] = []

    setupParticipantProfiles(selfProfile: ParticipantProfile, participantProfiles: ParticipantProfile[]) {
        this.selfProfile = selfProfile;
        this.participantProfiles = participantProfiles;
        this.notifyDataReload();
    }

    setupFocusProfile(focusProfile: ParticipantProfile | undefined, previewProfile?: ParticipantProfile | undefined) {
        this.focusProfile = focusProfile;
        this.previewProfile = previewProfile;
        this.notifyDataChange(0);
    }

    public totalCount(): number {
        // return 1;
        if (this.participantProfiles.length === 0) {
            return 1;
        } else {
            return 1 + Math.ceil((this.participantProfiles.length + 1) / ConferencePage.COUNT_PER_PAGE)
        }
    }

    public getData(index: number): (ParticipantProfile | undefined)[] {
        // 0 主页，focusProfile and previewProfile
        // 1 自己，及（ ConferencePage.COUNT_PER_PAGE - 1）个其他参与者
        // 2... 其他参与者
        if (index === 0) {
            return [this.focusProfile, this.previewProfile]
        } else if (index === 1) {
            return [this.selfProfile!, ...this.participantProfiles.slice(0, ConferencePage.COUNT_PER_PAGE - 1)]
        } else {
            index = index - 1;
            const start = ConferencePage.COUNT_PER_PAGE * index - 1;
            return this.participantProfiles.slice(start, start + ConferencePage.COUNT_PER_PAGE);
        }
    }
}
