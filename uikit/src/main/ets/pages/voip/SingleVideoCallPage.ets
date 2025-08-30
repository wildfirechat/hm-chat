import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import wfc from '@wfc/client'
import { ScalingMode, VideoRenderController } from '@ohos/webrtc'
import { VideoTrack } from '@ohos/webrtc/src/main/libohos_webrtc/webrtc';
import Config from '@wfc/client/src/main/ets/config'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { PiPWindow, router, window } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import AVCastPicker from '@ohos.multimedia.avCastPicker'
import { timestampFormat } from '../../util/helper'
import uikit from '../../uikit'
import { HashMap } from '@kit.ArkTS'
import { navigationDestinations } from '../navigationConfig'
import WFCVideoRenderController from '@wfc/avenginekit/src/main/ets/wfc/av/xcomponent/WFCVideoRenderController'
import VoipPiPNodeController from './VoipPiPNodeController'

@Component
export default struct SingleVideoCallPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State targetUserInfo?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State state: number = 0
    @State callSession?: CallSession = undefined
    @State durationStr: string = ''
    @State showActionAndDurationView: boolean = true
    private lastTriggerToShowActionAndDurationViewTimestamp: number = 0
    private updateActionAndDurationViewInterval = 0
    private statusBarHeight = 0
    private focusUserId: string = ''
    private pipController?: PiPWindow.PiPController;
    private focusXComponentController: WFCVideoRenderController = new WFCVideoRenderController()
    private previewXComponentController: WFCVideoRenderController = new WFCVideoRenderController()
    private isPageShow = false
    private voipPiPNodeController: VoipPiPNodeController = new VoipPiPNodeController('');

    aboutToAppear(): void {
        let callSession = avengineKit.getCurrentSession();

        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            this.mainNavPathStack.pop()
            return
        }
        this.statusBarHeight = px2vp(AppStorage.get<number>('SafeAreaTopHeight')!)

        this.selfUserInfo = wfc.getUserInfo(wfc.getUserId())
        this.targetUserInfo = wfc.getUserInfo(callSession?.getParticipantIds()[0]!)

        // this.state = callSession.status;
        this.callSession = callSession;

        this.focusUserId = this.targetUserInfo.uid

        this.setupSessionCallback()
        console.log('SingleVideoCallPage aboutToAppear')
        let localTrack = this.callSession.getParticipantVideoTrack(this.selfUserInfo.uid)
        if (localTrack) {
            this.previewXComponentController.setVideoTrack(localTrack)
        }
    }

    aboutToDisappear(): void {
        console.log('SingleVideoCallPage aboutToDisappear')
    }

    swapVideo() {
        if (!this.selfUserInfo || !this.targetUserInfo || !this.callSession) {
            return
        }
        let previewUserId = this.focusUserId
        let focusUserId = this.focusUserId === this.selfUserInfo.uid ? this.targetUserInfo.uid : this.selfUserInfo.uid

        this.focusXComponentController.setVideoTrack(this.callSession.getParticipantVideoTrack(focusUserId))
        this.previewXComponentController.setVideoTrack(this.callSession.getParticipantVideoTrack(previewUserId))

        this.focusUserId = focusUserId
    }

    onPageShow(): void {
        this.isPageShow = true
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
                .catch((reason: BusinessError) => {
                    console.log('create pip controller error', reason.message);
                })
        }
    }

    onPageHide(): void {
        this.isPageShow = false
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

    updateActionAndDurationView = () => {
        if (!this.isPageShow) {
            return
        }
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

            let index = this.mainNavPathStack.getIndexByName(navigationDestinations.SingleVideoCallPage)
            if (index.length) {
                this.mainNavPathStack.pop()
            }
        }
        sessionCallback.didCreateLocalVideoTrack = (track: VideoTrack, screenSharing: boolean) => {

            let controller = this.focusUserId === this.selfUserInfo?.uid ? this.focusXComponentController : this.previewXComponentController
            controller.setVideoTrack(track)
            controller.setScalingMode(ScalingMode.AspectFill)
        }
        sessionCallback.didReceiveRemoteVideoTrack = (userId: string, track: VideoTrack, screenSharing: boolean) => {
            this.focusXComponentController.setVideoTrack(track)
            this.focusXComponentController.setScalingMode(ScalingMode.AspectFit)
        }
        this.callSession!.sessionCallback = sessionCallback;
    }

    tip() {
        let desc = ''
        if (this.callSession?.status === CallState.STATUS_OUTGOING) {
            desc = '等待对方接听'
        } else if (this.callSession?.status === CallState.STATUS_INCOMING) {
            desc = `${this.targetUserInfo?.displayName}邀请你通话`
        } else if (this.callSession?.status === CallState.STATUS_CONNECTING) {
            desc = '接听中...'
        } else {
            desc = '通话中'
        }
        return desc;
    }

    async createPipController() {
        this.pipController = await PiPWindow.create({
            context: getContext(this),
            componentController: this.focusXComponentController,
            customUIController: this.voipPiPNodeController,
            navigationId: uikit.bundleName,
            templateType: PiPWindow.PiPTemplateType.VIDEO_MEETING,
            contentWidth: 200,
            contentHeight: 300,
        });
        this.pipController.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
            this.onStateChange(state, reason);
        });
        this.pipController.on('controlPanelActionEvent', (event: PiPWindow.PiPActionEventType, status?: number) => {
            this.onActionEvent(event, status);
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

    onStateChange(state: PiPWindow.PiPState, reason: string) {
        console.log('onStateChange', state, reason)
        if (state === PiPWindow.PiPState.ABOUT_TO_START) {
            this.mainNavPathStack.pop()
        }
        // switch (state) {
        //     case PiPWindow.PiPState.ABOUT_TO_START:
        //         this.curState = 'ABOUT_TO_START';
        //         this.curError = $r('app.string.current_error_hint');
        //         break;
        //     case PiPWindow.PiPState.STARTED:
        //         this.curState = 'STARTED';
        //         this.curError = $r('app.string.current_error_hint');
        //         break;
        //     case PiPWindow.PiPState.ABOUT_TO_STOP:
        //         this.curState = 'ABOUT_TO_STOP';
        //         this.curError = $r('app.string.current_error_hint');
        //         break;
        //     case PiPWindow.PiPState.STOPPED:
        //         this.player?.updatePlayStatus(true);
        //         this.player?.play();
        //         this.curState = 'STOPPED';
        //         this.curError = $r('app.string.current_error_hint');
        //         break;
        //     case PiPWindow.PiPState.ABOUT_TO_RESTORE:
        //         this.curState = 'ABOUT_TO_RESTORE';
        //         this.curError = $r('app.string.current_error_hint');
        //         break;
        //     case PiPWindow.PiPState.ERROR:
        //         this.curState = 'ERROR';
        //         this.curError = reason;
        //         break;
        //     default:
        //         break;
        // }
        // Logger.info(`[${TAG}] onStateChange: ${this.curState}, reason: ${reason}`);
    }

    onActionEvent(event: PiPWindow.PiPActionEventType, status: number | undefined) {
        console.log('onActionEvent', event, status)
        // switch (event) {
        //     case 'playbackStateChanged':
        //         if (status === 0) {
        //             this.player?.updatePlayStatus(false);
        //             this.player?.pause();
        //         } else {
        //             this.player?.updatePlayStatus(true);
        //             this.player?.play();
        //         }
        //         break;
        //     default:
        //         break;
        // }
        // this.buttonAction = event + `-status:${status}`;
        // Logger.info(`[${TAG}] onActionEvent: ${this.buttonAction} status:${status}}`);
    }

    @Builder
    actionAndDurationView() {
        Column() {
            if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                Row() {
                    Image($r('app.media.av_minimize'))
                        .draggable(false)
                        .width(50)
                        .height(50)
                        .padding(10)
                        .onClick(async () => {
                            this.pipController?.startPiP()
                                .catch((reason: BusinessError) => {
                                    console.log('startPiP errr', reason.message)
                                })
                            console.log('stop pip')
                        })

                    Text(this.durationStr)
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Center)
                        .alignSelf(ItemAlign.Center)

                    Image(false ? $r('app.media.av_camera_hover') : $r('app.media.av_camera'))
                        .draggable(false)
                        .width(50)
                        .height(50)
                        .padding(10)
                        .onClick(() => {
                            if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                                this.callSession?.switchCamera()
                            }
                        })
                }
                .margin({ top: this.statusBarHeight })
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
            }

            Blank()

            if (this.callSession!.status === CallState.STATUS_INCOMING || this.callSession!.status === CallState.STATUS_OUTGOING) {
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
                            .visibility(Visibility.Hidden)
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
                                .visibility(Visibility.Hidden)
                                .margin({ top: 10 })
                                .fontSize(13)
                                .fontColor(Color.White)
                        }
                    }
                }
                .width('100%')
                .margin({ bottom: 30 })
                .justifyContent(FlexAlign.SpaceAround)

            } else {
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
                            .visibility(Visibility.Hidden)
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
                            .visibility(Visibility.Hidden)
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
                            .visibility(Visibility.Hidden)
                            .margin({ top: 10 })
                            .fontSize(13)
                            .fontColor(Color.White)
                    }
                    .justifyContent(FlexAlign.Center)
                }
                .margin({ bottom: 30 })
                .width('100%')
                .justifyContent(FlexAlign.SpaceAround)
            }
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)
        .transition(TransitionEffect.OPACITY
            .animation({ duration: 400, curve: Curve.Friction, delay: 0 }))
    }

    build() {
        NavDestination() {
            Stack() {
                // 要包一层，click 才能在 ets 层捕获到 click 事件
                Column() {
                    XComponent({
                        id: this.targetUserInfo?.uid + this.callSession!.callId,
                        type: XComponentType.SURFACE,
                        controller: this.focusXComponentController,
                    })
                    // .onLoad(() => {
                    //     this.focusXComponentController.setVideoTrack(this.localVideoTrack!)
                    // })
                        .enableAnalyzer(false)
                        .width('100%')
                        .height('100%')
                        .backgroundColor('#e0000000')
                }
                .onClick(() => {
                    if (this.callSession?.status !== CallState.STATUS_CONNECTED) {
                        return
                    }
                    this.showActionAndDurationView = !this.showActionAndDurationView
                    this.lastTriggerToShowActionAndDurationViewTimestamp = Date.now()
                })


                Stack() {
                    Column() {

                        Column() {
                            XComponent({
                                id: this.selfUserInfo!.uid + this.callSession?.callId,
                                type: XComponentType.SURFACE,
                                controller: this.previewXComponentController,
                            })
                                .borderRadius(4)
                                .enableAnalyzer(false)
                                .width(this.callSession?.status === CallState.STATUS_CONNECTED ? '120' : '100%')
                                .height(this.callSession?.status === CallState.STATUS_CONNECTED ? '160' : '100%')
                                .margin({
                                    left: this.callSession?.status === CallState.STATUS_CONNECTED ? 10 : 0,
                                    top: this.callSession?.status === CallState.STATUS_CONNECTED ? this.statusBarHeight + 50 : 0
                                })
                        }
                        .onClick(() => {
                            this.swapVideo()
                        })
                    }
                    .width('100%')
                    .height('100%')
                    .justifyContent(FlexAlign.Start)
                    .alignItems(HorizontalAlign.Start)

                    if (this.callSession!.status === CallState.STATUS_OUTGOING
                        || this.callSession!.status === CallState.STATUS_INCOMING
                        || this.callSession!.status === CallState.STATUS_CONNECTING) {
                        Row() {
                            Image(this.targetUserInfo?.portrait || Config.DEFAULT_PORTRAIT_URL)
                                .draggable(false)
                                .width(80)
                                .height(80)
                                .borderRadius(4)
                            Column() {
                                Text(this.targetUserInfo?.displayName)
                                    .fontSize(14)
                                    .fontColor('#848687')
                                Text(this.tip())
                                    .margin({ top: 10 })
                                    .fontSize(13)
                                    .fontColor('#848687')
                            }
                            .height(80)
                            .margin({ left: 10 })
                            .justifyContent(FlexAlign.Center)
                            .alignItems(HorizontalAlign.Start)
                        }
                        .margin({ left: 10, top: 50 + this.statusBarHeight })
                        .width('100%')
                        .height('100%')
                        .justifyContent(FlexAlign.Start)
                        .alignItems(VerticalAlign.Top)
                    }
                }
                .hitTestBehavior(HitTestMode.Transparent)
                .width('100%')
                .height('100%')

                if (this.showActionAndDurationView) {
                    this.actionAndDurationView()
                }
            }
            .width('100%')
            .height('100%')
        }
        .onShown(() => {
            this.onPageShow()
        })
        .onHidden(() => {
            this.onPageHide()
        })
        .onBackPressed(() => {
            return true
        })
        .title('VOIP Single')
        .hideTitleBar(true)
        .backgroundColor('#000000')

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
}
