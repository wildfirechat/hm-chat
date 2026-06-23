import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import wfc from '@wfc/client'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import ParticipantProfile from '@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile'
import { AVCastPicker } from '@kit.AVSessionKit'
import PickGroupMemberModal from '../group/PickGroupMemberModal'
import { timestampFormat } from '../../util/helper'
import { PiPWindow } from '@kit.ArkUI'
import VoipPiPNodeController from './VoipPiPNodeController'
import uikit from '../../uikit'
import { BusinessError } from '@kit.BasicServicesKit'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import { FontSize, Radius } from '../../common/design/Tokens'

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
    @State showPickGroupMemberModal: boolean = false
    private updateDurationInterval: number = 0

    private pipController?: PiPWindow.PiPController;
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

            let index = this.mainNavPathStack.getIndexByName(uikitNavigationDestinations.MultiAudioCallPage)
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
            .backgroundColor($r('app.color.wf_background'))
    }

    @Builder
    incomingView() {
        Column() {
            Image(this.invitor!.portrait)
                .width(120)
                .height(120)
                .borderRadius(Radius.lg)
                .margin({ top: 120 })
            Text(this.invitor?.displayName)
                .maxLines(1)
                .fontColor(Color.White)
                .fontSize(FontSize.xl)
                .margin({ top: 20 })

            Text('邀请你加入多人通话')
                .maxLines(1)
                .fontColor('#7E7E7E')
                .fontSize(FontSize.md)
                .margin({ top: 20 })

            Text('参与通话的还有：')
                .maxLines(1)
                .fontColor('#7E7E7E')
                .fontSize(FontSize.sm)
                .margin({ top: 120, bottom: 12 })

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
                        .borderRadius(Radius.sm)
                        .margin(12)
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
                            .margin({ top: 12 })
                            .fontSize(FontSize.sm)
                            .fontColor(Color.White)
                    }
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .layoutWeight(1)

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
                            .margin({ top: 12 })
                            .fontSize(FontSize.sm)
                            .fontColor(Color.White)
                    }
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .layoutWeight(1)
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
                            .width(52)
                            .height(52)
                            .padding(12)
                            .onClick(async () => {
                                this.pipController?.startPiP()
                                    .catch((reason: BusinessError) => {
                                        console.error('startPiP error', reason.code, reason.name, reason.message)
                                    })
                                this.mainNavPathStack.pop()
                            })

                        Image($r('app.media.ic_tab_add'))
                            .fillColor(Color.Red)
                            .draggable(false)
                            .width(52)
                            .height(52)
                            .padding(12)
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
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
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
                                    .borderRadius(Radius.sm)
                                Text(this.participantStatus(userInfo))
                                    .maxLines(1)
                                    .fontColor('#7E7E7E')
                                    .fontSize(FontSize.xs)
                                    .margin({ top: 4 })
                            }

                            Text(userInfo.displayName)
                                .maxLines(1)
                                .fontColor(Color.White)
                                .fontSize(FontSize.sm)
                                .margin({ top: 12 })
                        }
                        .margin(12)
                        .justifyContent(FlexAlign.Center)
                        .alignItems(HorizontalAlign.Center)
                    }, (userInfo: UserInfo) => userInfo.uid + '-' + userInfo.updateDt)

                    if (this.selfUserInfo) {
                        Column() {
                            Stack() {
                                Image(this.selfUserInfo.portrait)
                                    .width(100)
                                    .height(100)
                                    .borderRadius(Radius.sm)
                                Text(this.participantStatus(this.selfUserInfo))
                                    .maxLines(1)
                                    .fontColor('#7E7E7E')
                                    .fontSize(FontSize.xs)
                                    .margin({ top: 4 })
                            }

                            Text(this.selfUserInfo.displayName)
                                .maxLines(1)
                                .fontColor(Color.White)
                                .fontSize(FontSize.sm)
                                .margin({ top: 12 })
                        }
                        .margin(12)
                    }
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
                            .margin({ top: 12 })
                            .fontSize(FontSize.sm)
                            .fontColor(Color.White)
                    }
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .layoutWeight(1)

                    Column() {
                        Image($r('app.media.av_hang_up'))
                            .draggable(false)
                            .width(60)
                            .height(60)
                            .onClick(() => {
                                this.callSession?.hangup()
                            })
                        Text('挂断')
                            .margin({ top: 12 })
                            .fontSize(FontSize.sm)
                            .fontColor(Color.White)
                    }
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .layoutWeight(1)

                    Column() {
                        AVCastPicker({ normalColor: Color.White, activeColor: Color.White })
                            .width(60)
                            .height(60)
                            .border({ width: 1, radius: 30, color: Color.White })

                        Text('扬声器已关')
                            .margin({ top: 12 })
                            .fontSize(FontSize.sm)
                            .fontColor(Color.White)
                    }
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .layoutWeight(1)
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
        this.pipController = await PiPWindow.create({
            context: this.getUIContext().getHostContext(),
            componentController: this.dummyXComponentController,
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