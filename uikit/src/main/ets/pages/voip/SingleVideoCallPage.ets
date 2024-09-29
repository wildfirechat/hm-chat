import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import wfc from '@wfc/client'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { router, window } from '@kit.ArkUI'
import { common, Permissions, Want, WantAgent, wantAgent } from '@kit.AbilityKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { showVoipFloatingWindow } from '../../helper/floatingWindowHelper'
import { checkPermissions, requestPermissions } from '../../helper/permissionHelper'
import AVCastPicker from '@ohos.multimedia.avCastPicker'
import { camera } from '@kit.CameraKit'
import { showToast } from '../../common/utils/Toast'
import { timestampFormat } from '../../util/helper'
import { GlobalContext } from '../../globalContext'
import uikit from '../../uikit'

@Entry({ routeName: 'singleVideoCallPage' })
@Component
export default struct SingleVideoCallPage {
    @State targetUserInfo?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State state: number = 0
    @State callSession?: CallSession = undefined
    xComponentController: XComponentController = new XComponentController()
    private remoteSurfaceId: string = ''
    private localSurfaceId: string = ''
    @State durationStr: string = ''
    private durationInternal = 0
    private connectedTime = 0
    private statusBarHeight = 0

    aboutToAppear(): void {
        let callSession = avengineKit.getCurrentSession();

        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            router.back()
            return
        }
        this.statusBarHeight = px2vp(AppStorage.get<number>('SafeAreaTopHeight')!)

        this.selfUserInfo = wfc.getUserInfo(wfc.getUserId())
        this.targetUserInfo = wfc.getUserInfo(callSession?.getParticipantIds()[0]!)

        // this.state = callSession.status;
        this.callSession = callSession;

        callSession.setUserXComponentId(this.selfUserInfo.uid, 'localXComponent')
        callSession.setUserXComponentId(this.targetUserInfo.uid, this.targetUserInfo.uid)

        this.setupSessionCallback()
        console.log('SingleVideoCallPage aboutToAppear')
    }

    aboutToDisappear(): void {
        let win = GlobalContext.getContext().getObject<window.Window>('window')
        win?.setWindowLayoutFullScreen(false)
    }

    onPageShow(): void {
        let win = GlobalContext.getContext().getObject<window.Window>('window')
        win?.setWindowLayoutFullScreen(true)
    }

    // router 路由才生效
    onBackPress(): boolean | void {
        return true
    }

    updateDuration = () => {
        let millis = new Date().getTime() - this.connectedTime
        this.durationStr = timestampFormat(millis)
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
                this.connectedTime = new Date().getTime()
                this.durationInternal = setInterval(this.updateDuration, 1000)
            }
        }
        sessionCallback.didCallEndWithReason = reason => {
            if (this.durationInternal) {
                clearInterval(this.durationInternal)
            }
            router.back()
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

    startContinuousTask(context: Context) {
        let wantAgentInfo: wantAgent.WantAgentInfo = {
            // 点击通知后，将要执行的动作列表
            // 添加需要被拉起应用的bundleName和abilityName
            wants: [
                {
                    bundleName: uikit.bundleName,
                    abilityName: uikit.entryAbilityName
                }
            ],
            // 指定点击通知栏消息后的动作是拉起ability
            actionType: wantAgent.OperationType.START_ABILITY,
            // 使用者自定义的一个私有值
            requestCode: 0,
            // 点击通知后，动作执行属性
            wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
        };

        // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
        wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
            backgroundTaskManager.startBackgroundRunning(context,
                backgroundTaskManager.BackgroundMode.AUDIO_RECORDING, wantAgentObj).then(() => {
                console.info(`Succeeded in operationing startBackgroundRunning.`);
            }).catch((err: BusinessError) => {
                console.error(`Failed to operation startBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
            });
        });
    }

    stopContinuousTask(context: Context) {
        backgroundTaskManager.stopBackgroundRunning(context).then(() => {
            console.info(`Succeeded in operationing stopBackgroundRunning.`);
        }).catch((err: BusinessError) => {
            console.error(`Failed to operation stopBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
        });
    }

    previewXComponentWidth(): SizeT<string> {
        let previewSize = this.callSession!.previewProfile?.size
        if (!previewSize) {
            return {
                width: '100%',
                height: '100%'
            }
        }
        if (previewSize.width > previewSize.height) {
            return {
                width: `${previewSize.width / previewSize.height * 100}%`,
                height: '100%'
            }
        } else {
            return {
                width: '100%',
                height: `${previewSize.height / previewSize.width * 100}%`
            }
        }
    }

    build() {
        Navigation() {
            Stack() {
                XComponent({
                    id: this.targetUserInfo?.uid,
                    type: XComponentType.SURFACE,
                    libraryname: 'wfrtc'
                })
                    .onLoad((xComponentContext?: object | Record<string, () => void>) => {
                        if (xComponentContext) {

                        }
                    })
                    .enableAnalyzer(false)
                    .width('100%')
                    .height('100%')
                    .backgroundColor('#e0000000')


                Stack() {
                    Column() {
                        XComponent({
                            id: 'localXComponent',
                            type: XComponentType.SURFACE,
                            libraryname: 'wfrtc',
                            controller: this.xComponentController
                        })
                            .onClick(() => {
                                showToast("hello")
                            })
                            .onLoad((xComponentContext?: object | Record<string, () => void>) => {
                                this.localSurfaceId = this.xComponentController.getXComponentSurfaceId()
                            })
                            .enableAnalyzer(false)
                            .width(this.callSession?.status === CallState.STATUS_CONNECTED ? '120' : this.previewXComponentWidth().width)
                            .height(this.callSession?.status === CallState.STATUS_CONNECTED ? '160' : this.previewXComponentWidth().height)
                            .margin({
                                left: this.callSession?.status === CallState.STATUS_CONNECTED ? 10 : 0,
                                top: this.callSession?.status === CallState.STATUS_CONNECTED ? this.statusBarHeight + 50 : 0
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
                            Image(this.targetUserInfo?.portrait)
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
                .width('100%')
                .height('100%')

                Column() {
                    Stack() {
                        Text(this.durationStr)
                            .width('100%')
                            .fontColor(Color.White)
                            .textAlign(TextAlign.Center)
                            .alignSelf(ItemAlign.Center)

                        if (this.callSession?.status === CallState.STATUS_CONNECTED) {
                            Row() {
                                Image($r('app.media.av_minimize'))
                                    .draggable(false)
                                    .width(50)
                                    .height(50)
                                    .padding(10)
                                    .onClick(async () => {
                                        // this.startContinuousTask(getContext(this))
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
                                Image(false ? $r('app.media.av_camera_hover') : $r('app.media.av_camera'))
                                    .draggable(false)
                                    .width(60)
                                    .height(60)
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
                    }
                    .width('100%')

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
            }
        }
        .title('Voip Test')
        .hideTitleBar(true)
        .backgroundColor('#000000')

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
}