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
import { showToast } from '../../common/utils/Toast'
import { timeFormat, timestampFormat } from '../../util/helper'
import uikit from '../../uikit'

@Entry({ routeName: 'singleAudioCallPage' })
@Component
export default struct SingleAudioCallPage {
    @State targetUserInfo?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State state: number = 0
    @State callSession?: CallSession = undefined
    @State durationStr: string = ''
    private durationInternal = 0

    aboutToAppear(): void {
        let callSession = avengineKit.getCurrentSession();

        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            router.back()
            return
        }
        this.selfUserInfo = wfc.getUserInfo(wfc.getUserId())
        this.targetUserInfo = wfc.getUserInfo(callSession?.getParticipantIds()[0]!)

        // this.state = callSession.status;
        this.callSession = callSession;
        this.setupSessionCallback()
    }

    aboutToDisappear(): void {
    }

    onPageShow(): void {
    }

    // router 路由才生效
    onBackPress(): boolean | void {
        return true
    }

    updateDuration = () => {
        let millis = new Date().getTime() - this.callSession!.connectedTime
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

    build() {
        Navigation() {
            Stack() {
                Image(this.targetUserInfo?.portrait)
                    .draggable(false)
                    .width('100%')
                    .height('100%')
                Column() {
                    Stack() {
                        Text(this.durationStr)
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
                        }
                        .width('100%')
                    }
                    .width('100%')
                    .padding(20)

                    if (this.callSession!.status === CallState.STATUS_INCOMING || this.callSession!.status === CallState.STATUS_OUTGOING) {
                        Column() {
                            Image(this.targetUserInfo?.portrait)
                                .draggable(false)
                                .borderRadius(6)
                                .width(100)
                                .height(100)
                                .margin({ top: 60 })
                            Text(this.targetUserInfo?.displayName)
                                .margin({ top: 10 })
                                .fontSize(14)
                                .fontColor(Color.White)

                            Blank()

                            Text(this.tip())
                                .margin({ bottom: 10 })
                                .fontSize(14)
                                .fontColor('#848687')

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
                            .padding({ top: 40, bottom: 50 })
                            .width('100%')
                            .justifyContent(FlexAlign.SpaceAround)

                        }
                        .width('100%')
                        .flexGrow(1)
                        .justifyContent(FlexAlign.SpaceAround)
                    } else {
                        Column() {
                            Image(this.targetUserInfo?.portrait)
                                .draggable(false)
                                .borderRadius(6)
                                .width(100)
                                .height(100)
                                .margin({ top: 60 })
                            Text(this.targetUserInfo?.displayName)
                                .margin({ top: 10 })
                                .fontSize(14)
                                .fontColor(Color.White)

                            Blank()

                            Text(this.tip())
                                .margin({ bottom: 10 })
                                .fontSize(14)
                                .fontColor('#848687')

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
                            .padding({ top: 40, bottom: 50 })
                            .width('100%')
                            .justifyContent(FlexAlign.SpaceAround)

                        }
                        .width('100%')
                        .flexGrow(1)
                        .justifyContent(FlexAlign.SpaceAround)
                    }
                }
                .justifyContent(FlexAlign.Start)
                .width('100%')
                .height('100%')
                .backgroundColor('#e0000000')
            }
        }
        .title('Voip Test')
        .hideTitleBar(true)
        .backgroundColor('#000000')

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
}