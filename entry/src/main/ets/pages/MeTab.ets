import UserInfo from '../wfc/model/userInfo'
import wfc from '../wfc/client/wfc'
import router from '@ohos.router'
import data_preferences from '@ohos.data.preferences'
import EventType from '../wfc/client/wfcEvent'
import ConnectionStatus from '../wfc/client/connectionStatus'
import OptionItemView from '../view/OptionItemView'
import { GlobalContext } from '../globalContext'
import EntryAbility from '../entryability/EntryAbility'
import { common, Want, WantAgent, wantAgent } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { AVCastPicker } from '@kit.AVSessionKit'

@Component
export default struct MeTab {
    @State message: string = 'Hello Me'
    @State userInfo?: UserInfo = undefined
    private userId: string = ''
    @Link meTabUnreadCount: number
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private context: Context = getContext(this);

    startContinuousTask() {
        let wantAgentInfo: wantAgent.WantAgentInfo = {
            // 点击通知后，将要执行的动作列表
            // 添加需要被拉起应用的bundleName和abilityName
            wants: [
                {
                    bundleName: 'cn.wildfirechat.messenger',
                    abilityName: 'EntryAbility',
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
            backgroundTaskManager.startBackgroundRunning(this.context,
                backgroundTaskManager.BackgroundMode.AUDIO_RECORDING, wantAgentObj).then(() => {
                console.info(`Succeeded in operationing startBackgroundRunning.`);
            }).catch((err: BusinessError) => {
                console.error(`Failed to operation startBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
            });
        });
    }

    stopContinuousTask() {
        backgroundTaskManager.stopBackgroundRunning(this.context).then(() => {
            console.info(`Succeeded in operationing stopBackgroundRunning.`);
        }).catch((err: BusinessError) => {
            console.error(`Failed to operation stopBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
        });
    }

    aboutToAppear() {
        this.loadSelfUserInfo()
        wfc.eventEmitter!.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        wfc.eventEmitter!.on(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
    }

    onUserInfosUpdate = (usersInfos: UserInfo[]) => {
        for (const userinfo of usersInfos) {
            if (userinfo.uid === this.userId)
                this.userInfo = userinfo
        }
    }
    onConnectionStatusChange = (status: number) => {
        if (status === ConnectionStatus.ConnectionStatusConnected) {
            this.loadSelfUserInfo()
        }
    }

    loadSelfUserInfo() {
        this.userId = wfc.getUserId()
        this.userInfo = wfc.getUserInfo(this.userId)
    }

    aboutToDisappear() {
        wfc.eventEmitter!.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        wfc.eventEmitter!.off(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
    }

    build() {
        Column() {
            Row() {
                Image(this.userInfo!.portrait)
                    .width(60)
                    .height(60)
                    .borderRadius(4)
                Column() {
                    Text(this.userInfo!.displayName)
                        .fontSize(20)
                        .maxLines(1)
                    Text(`野火号:${this.userInfo!.name}`)
                        .maxLines(1)
                        .fontSize(14)
                        .fontColor(Color.Gray)
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.SpaceBetween)
                .layoutWeight(1)
                .height(60)
                .padding({ top: 5, bottom: 5 })
                .margin({ left: 10 })

                Image($r('app.media.ic_right'))
                    .width(12)
                    .height(12)
            }
            .width('100%')
            .height(100)
            .padding(10)
            .alignItems(VerticalAlign.Center)
            .backgroundColor(Color.White)

            OptionItemView({ icon: $r('app.media.ic_account'), title: '账号与安全' })
                .margin({ top: 10, bottom: 10 })

            OptionItemView({ icon: $r('app.media.ic_notification'), title: '消息与通知' })
                .margin({ top: 10, bottom: 10 })

            Column() {
                OptionItemView({ icon: $r('app.media.ic_settings_file'), title: '文件' })
                Divider()
                    .margin({ left: 40 })
                    .color('#F7F7F7')
                OptionItemView({ icon: $r('app.media.ic_star'), title: '收藏' })
            }
            .margin({ top: 10, bottom: 10 })
            .backgroundColor(Color.White)

            Column() {
                OptionItemView({ icon: $r('app.media.ic_theme'), title: '主题' })
                Divider()
                    .margin({ left: 40 })
                    .color('#F7F7F7')
                OptionItemView({ icon: $r('app.media.ic_setting'), title: '设置' })
            }
            .margin({ top: 10, bottom: 10 })
            .backgroundColor(Color.White)

            Column() {
                Stack() {
                    Text('点击 显示 AVCastPicker')
                    AVCastPicker()
                        .size({ height: '100%', width: '100%' })
                }
            }
            .width('100%')
            .height(50)

            OptionItemView({ title: 'API测试页' })
                .onClick(() => {
                    // //this.mainNavPathStack.pushPathByName('singleAudioCallPage', {} as Record<string, Object>)
                    // // (GlobalContext.getContext().getObject('entry') as EntryAbility).showSubWindow()
                    //
                    // // this.mainNavPathStack.pushPathByName('singleAudioCallPage', {} as Record<string, Object>)
                    // //router.pushUrl({url: 'pages/voip/SingleAudioCallPage'})
                    // router.pushUrl({ url: 'pages/TestPage' })
                    // // this.showVoipFloatingWindow()

                    this.startContinuousTask();
                })

            Button('退出')
                .width(100)
                .type(ButtonType.Normal)
                .borderRadius(4)
                .margin({ top: 30 })
                .onClick(() => {
                    data_preferences.deletePreferences(getContext(this), 'wfcstore')
                    wfc.disconnect(true, false)
                    router.replaceUrl({ url: 'pages/LoginPage' }, router.RouterMode.Standard)
                })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#EDEDED')
    }

    showVoipFloatingWindow() {
        let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext; // UIAbilityContext

        let want: Want = {
            deviceId: '', // deviceId为空表示本设备
            bundleName: 'cn.wildfirechat.messenger',
            abilityName: 'VoipFloatingEntryAbility',
            action: '',
            entities: [],
            uri: '',
            parameters: {
                // 自定义信息
                info: '来自EntryAbility UIAbilityComponentsInteractive页面'
            }
        };
        context.startAbilityForResult(want).then((data) => {
            // ...
            console.log('xxxxxxxx', data)
        }).catch((err: BusinessError) => {
            hilog.error(0, "xxx", `Failed to start ability for result. Code is ${err.code}, message is ${err.message}`);
        });
    }
}