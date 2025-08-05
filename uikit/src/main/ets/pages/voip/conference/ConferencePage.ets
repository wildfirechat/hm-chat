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
import { window } from '@kit.ArkUI'
import ConferenceInfo from '@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo'
import { showToast } from '../../../common/utils/Toast'
import { WHITE_FILTER } from '../../../api/Util'
import ConferenceParticipantView from './ConferenceParticipantView'
import ConferenceMoreActionView from './ConferenceMoreActionView'

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
    static COUNT_PER_PAGE = 4;
    private focusXComponentIdPrefix: string = 'focus-xcp'
    private focusXComponentId: string = this.focusXComponentIdPrefix + new Date().getTime()
    private previewXComponentIdPrefix: string = 'preview-xcp'
    private previewXComponentId: string = this.previewXComponentIdPrefix + new Date().getTime()

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

        this.selfProfile = callSession.getSelfProfile()

        this.updateFocusAndPreviewProfile()
        this.setupSessionCallback()
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

    setupFocusAndPreviewXComponentId() {
        this.callSession?.setUserXComponentId(this.focusProfile?.xcomponentUserId()!, this.focusXComponentId)
        if (this.previewProfile) {
            this.callSession?.setUserXComponentId(this.previewProfile.xcomponentUserId(), this.previewXComponentId)
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
            this.setupFocusAndPreviewXComponentId()
        }
    }

    // 支持 unset
    setupParticipantFlexXComponentIds(swiperIndex: number, unset: boolean) {
        // 0 is focus/preview view
        if (swiperIndex === 0) {
            this.setupFocusAndPreviewXComponentId()
        } else if (swiperIndex == 1) {
            let selfProfile = this.callSession?.getSelfProfile()!
            this.callSession?.setUserXComponentId(selfProfile?.xcomponentUserId(), unset ? '' : selfProfile?.xcomponentId())
            for (let i = 0; i < ConferencePage.COUNT_PER_PAGE - 1; i++) {
                let index = (swiperIndex - 1) * ConferencePage.COUNT_PER_PAGE + i
                if (index < this.participantProfiles!.length) {
                    let p = this.participantProfiles![index]
                    this.callSession?.setUserXComponentId(p.xcomponentUserId(), unset ? '' : p.xcomponentId())
                }
            }
        } else if (swiperIndex > 1) {
            for (let i = 0; i < ConferencePage.COUNT_PER_PAGE; i++) {
                let index = (swiperIndex - 1) * ConferencePage.COUNT_PER_PAGE + i
                if (index < this.participantProfiles!.length) {
                    let p = this.participantProfiles![index]
                    this.callSession?.setUserXComponentId(p.xcomponentUserId(), unset ? '' : p.xcomponentId())
                }
            }
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
            this.mainNavPathStack.pop()
        }
        sessionCallback.didParticipantJoined = (userId: string, isScreenSharing?: boolean) => {

            this.targetUserInfos = wfc.getUserInfos(this.callSession!.getParticipantIds()!)
            this.participantProfiles = this.callSession?.getParticipantProfiles();

            // 主页只显示两个
            if (this.participantProfiles?.length === 1) {
                this.previewProfile = this.focusProfile;
                this.focusProfile = this.participantProfiles[0]
            }
            this.updateFocusAndPreviewView()
        }
        sessionCallback.didParticipantLeft = (userId: string, callEndReason: number, screenSharing = false) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.participantProfiles = this.callSession?.getParticipantProfiles();

            this.updateFocusAndPreviewView();

        }
        sessionCallback.didChangeType = (userId: string, audience: boolean, screenSharing?: boolean) => {
            this.participantProfiles = this.callSession?.getParticipantProfiles();
            this.selfProfile = this.callSession?.getSelfProfile()!;
            this.updateFocusAndPreviewView()
        }

        sessionCallback.didParticipantConnected = (userId: string, isScreenSharing?: boolean) => {
            this.targetUserInfos = wfc.getUserInfos(this.callSession?.getParticipantIds()!)
            this.participantProfiles = this.callSession?.getParticipantProfiles();
            console.log('didParticipantConnected', userId, isScreenSharing)
        }
        sessionCallback.didChangeMode = state => {

        }
        sessionCallback.didMuteStateChanged = participants => {
            if (participants.indexOf(wfc.getUserId()) >= 0) {
                this.selfProfile = this.callSession?.getSelfProfile()!
            }
            this.participantProfiles = this.callSession?.getParticipantProfiles();
            this.updateFocusAndPreviewView()
        }

        // end
        this.callSession!.sessionCallback = sessionCallback;
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
        ConferenceMoreActionView()
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
                    .border({ width: 1, radius: 4, color: Color.Transparent})

                Image($r('app.media.av_conference_switch_camera'))
                    .draggable(false)
                    .width(50)
                    .height(50)
                    .colorFilter(WHITE_FILTER)
                    .objectFit(ImageFit.Contain)
                    .padding({ left: 10, right: 10 })
                    .onClick(async () => {
                        this.callSession?.switchCamera()
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
                                    showToast('TODO')
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
                                    showToast('TODO')
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
                            callSession: this.callSession,
                            p: this.focusProfile,
                            xcomponentId: this.focusXComponentId,
                            swiperIndex: 0,
                            currentSwiperIndex: this.currentSwiperIndex,
                            onXComponentLoadCallback: () => {
                                this.setupFocusAndPreviewXComponentId()
                            }

                        })
                            .onClick(() => {
                                if (this.callSession?.status !== CallState.STATUS_CONNECTED) {
                                    return
                                }
                                this.showActionAndDurationView = !this.showActionAndDurationView
                                this.lastTriggerToShowActionAndDurationViewTimestamp = Date.now()
                            })
                            .onDisAppear(() => {
                                this.focusXComponentId = this.focusXComponentIdPrefix + new Date().getTime()
                            })
                    }

                    // preview
                    if (this.previewProfile) {
                        ConferenceParticipantView({
                            callSession: this.callSession,
                            p: this.previewProfile,
                            xcomponentId: this.previewXComponentId,
                            swiperIndex: 0,
                            currentSwiperIndex: this.currentSwiperIndex,
                            onXComponentLoadCallback: () => {
                                this.setupFocusAndPreviewXComponentId()
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
                            .onDisAppear(() => {
                                this.previewXComponentId = this.previewXComponentIdPrefix + new Date().getTime()
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
                                    p: this.callSession!.getSelfProfile()!,
                                    callSession: this.callSession,
                                    swiperIndex: participantFlexIndex + 1,
                                    currentSwiperIndex: this.currentSwiperIndex
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
                                        callSession: this.callSession,
                                        swiperIndex: participantFlexIndex + 1,
                                        currentSwiperIndex: this.currentSwiperIndex
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
}
