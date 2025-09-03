import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import CallSessionCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSessionCallback'
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import avengineKit from '@wfc/avenginekit'
import wfc from '@wfc/client'
import Config from '@wfc/client/src/main/ets/config'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { BusinessError } from '@kit.BasicServicesKit'
import AVCastPicker from '@ohos.multimedia.avCastPicker'
import { timestampFormat } from '../../util/helper'
import { PiPWindow } from '@kit.ArkUI'
import pipHelper from './pipHelper'
import VoipPiPNodeController from './VoipPiPNodeController'
import { navigationDestinations } from '../navigationConfig'

@Component
export default struct SingleAudioCallPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State targetUserInfo?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State state: number = 0
    @State callSession?: CallSession = undefined
    @State durationStr: string = ''
    private durationInterval = 0

    private voipPiPNodeController: VoipPiPNodeController = new VoipPiPNodeController('');
    private dummyXComponentController: XComponentController = new XComponentController()

    aboutToAppear(): void {
        let callSession = avengineKit.getCurrentSession();

        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            this.mainNavPathStack.pop()
            return
        }
        this.selfUserInfo = wfc.getUserInfo(wfc.getUserId())
        this.targetUserInfo = wfc.getUserInfo(callSession?.getParticipantIds()[0]!)

        // this.state = callSession.status;
        this.callSession = callSession;
        this.setupSessionCallback()
    }

    onPageShown(): void {
            this.createPipController()
                .then(() => {
                    console.log('xxxxxxx create pip success')
                })
                .catch((reason: BusinessError) => {
                    console.log('xxxxxxxx create pip controller error', reason.message);
                })
    }

    onPageHidde(): void {
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
                this.durationInterval = setInterval(this.updateDuration, 1000)
            }
        }
        sessionCallback.didCallEndWithReason = reason => {
            if (this.durationInterval) {
                clearInterval(this.durationInterval)
            }

            this.destroyPipController()

            let index = this.mainNavPathStack.getIndexByName(navigationDestinations.SingleAudioCallPage)
            if (index.length) {
                this.mainNavPathStack.pop()
            }
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
        pipHelper.createPipController(this.getUIContext(), this.dummyXComponentController, this.voipPiPNodeController, this.mainNavPathStack, navigationDestinations.SingleAudioCallPage)
    }

    destroyPipController() {
        pipHelper.destroyPipController()
    }

    build() {
        NavDestination() {
            Stack() {
                // 仅仅用来实现pip
                XComponent({
                    id: this.targetUserInfo?.uid + this.callSession!.callId,
                    type: XComponentType.SURFACE,
                    controller: this.dummyXComponentController,
                })
                    .enableAnalyzer(false)
                    .width(200)
                    .height(300)
                    .backgroundColor('#e0000000')
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
                                    pipHelper.startPiP()
                                    this.mainNavPathStack.pop()
                                })
                        }
                        .width('100%')
                    }
                    .width('100%')
                    .padding(20)

                    if (this.callSession!.status === CallState.STATUS_INCOMING || this.callSession!.status === CallState.STATUS_OUTGOING) {
                        Column() {
                            Image(this.targetUserInfo?.portrait|| Config.DEFAULT_PORTRAIT_URL)
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
                            Image(this.targetUserInfo?.portrait || Config.DEFAULT_PORTRAIT_URL)
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
        .onShown(() => {
            this.onPageShown()
        })
        .onHidden(() => {
            this.onPageHidde()
        })
        .onBackPressed(() => true)
        .backgroundColor('#000000')

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
}
