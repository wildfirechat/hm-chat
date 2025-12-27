import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import data_preferences from '@ohos.data.preferences';
import wfc from '@wfc/client'
import Config from '@wfc/client/src/main/ets/config'
import { AbilityConstant, common, Context, Want } from '@kit.AbilityKit';
import { pushCommon, pushService } from '@kit.PushKit';

import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent';
import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import wfcNotificationManager from '@wfc/uikit/src/main/ets/notification/wfcNotificationManager'
import { BusinessError } from '@ohos.base';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConnectionStatus from '@wfc/client/src/main/ets/wfc/client/connectionStatus';
import CustomMessageConfig from '@wfc/client/src/main/ets/wfc_custom_message/customMessageConfig';
import uikit from '@wfc/uikit'
import { LAST_LOGIN_MOBILE_KEY } from '../pages/login/LoginPage';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { deviceInfo } from '@kit.BasicServicesKit';


export default class EntryAbility extends UIAbility {
    private windowStage?: window.WindowStage
    private isMaiPageLoaded: boolean = false
    private isInBackground: boolean = false
    private launchParams: Record<string, Object> = {
        'targetConversation': new Conversation(0, '', 0)
    };
    private storage: LocalStorage = new LocalStorage(this.launchParams);
    private applicationContext?: common.ApplicationContext
    private connectionStatus: number = -1;
    // 申请短时任务ID
    private suspendDelayId: number = 0;
    private cancelIMShortTaskTimerID: number = 0

    async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
        AppStorage.setOrCreate('context', this.context);
        this.applicationContext = this.context.getApplicationContext()

        wfc.init(this.applicationContext, this.context.eventHub, this.applicationContext.filesDir, Config.getWFCPlatform());
        CustomMessageConfig.registerCustomMessages();
        uikit.init(this.context)

        wfc.eventEmitter!.on(EventType.ConnectionStatusChanged, async (status: number) => {
            this.connectionStatus = status;
            if (status === ConnectionStatus.ConnectionStatusConnected) {
                try {
                    const pushToken: string = await pushService.getToken();
                    // huawei harmony
                    wfc.setDeviceToken(8, pushToken);
                    hilog.info(0x0000, 'testTag', 'Get push token successfully: %{public}s', pushToken);
                } catch (err) {
                    let e: BusinessError = err as BusinessError;
                    hilog.error(0x0000, 'testTag', 'Get push token catch error: %{public}d %{public}s', e.code, e.message);
                }

            } else if ([
                ConnectionStatus.ConnectionStatusTokenIncorrect,
                ConnectionStatus.ConnectionStatusSecretKeyMismatch,
                ConnectionStatus.ConnectionStatusRejected,
                ConnectionStatus.ConnectionStatusLogout,
                ConnectionStatus.ConnectionStatusKickedOff
            ].indexOf(status) >= 0) {
                let preference = await data_preferences.getPreferences(this.applicationContext!, 'wfcstore')
                if (preference) {
                    preference.clear()
                    preference.flush()
                }
                let url = 'pages/login/LoginPage'
                this.loadContent(url)
            }
        })

        // TODO
        // FIXME
        // 这儿可能永远不会触发，切到后台时，都会走推送
        wfc.eventEmitter!.on(EventType.ReceiveMessage, (messages: Message[], hasMore: boolean) => {
            if (this.isInBackground) {
                console.log('receive message in background')
                for (const message of messages) {
                    wfcNotificationManager.onReceiveMessage(message, hasMore);
                }
            }
        })

        this.parseLaunchParamsAndThen(want);
    }

    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        console.log('testTag, newWant',)
        this.parseLaunchParamsAndThen(want);
    }

    onDestroy() {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage: window.WindowStage) {
        // Main window is created, set main page for this ability
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
        this.windowStage = windowStage;
        AppStorage.setOrCreate('windowStage', windowStage);

        let url = 'pages/login/LoginPage';
        data_preferences.getPreferences(this.applicationContext, 'wfcstore', async (err, val) => {
            if (err) {
                console.error("Failed to get preferences. code =" + err.code + ", message =" + err.message);
            } else {
                let preferences = val;
                try {

                    let userId = await preferences.get('userId', null);
                    let token = await preferences.get('token', null);
                    if (userId && token) {
                        url = 'pages/MainPage'
                        wfc.connect(userId as string, token as string);
                    }
                } catch (e) {

                }
            }
            this.loadContent(url);
        })

        // 获取应用主窗口
        let mainWin: window.Window = windowStage.getMainWindowSync();
        AppStorage.setOrCreate('window', mainWin)
        // 获取状态栏高度
        let statusArea = mainWin.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        AppStorage.setOrCreate('SafeAreaTopHeight', statusArea.topRect.height);
        // 获取导航栏高度
        let navigationArea = mainWin.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        AppStorage.setOrCreate('SafeAreaBottomHeight', navigationArea.bottomRect.height);
        // 获取软键盘高度，但这儿获取到的软键盘高度无效，后续也没有使用
        let keyboardArea = mainWin.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
        AppStorage.setOrCreate('SafeAreaKeyboardHeight', keyboardArea.bottomRect.height);

        // setConnectionStatusListener((value) => {
        //   hilog.info(0x0000, 'testTag', 'connection status changed: %{public}d', value);
        // });
    }

    onWindowStageDestroy() {
        // Main window is destroyed, release UI related resources
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    }

    onForeground() {
        // Ability has brought to foreground
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
        this.isInBackground = false;
        AppStorage.setOrCreate('isInBackground', false);
        this.cancelIMShortTask()
    }

    async onBackground() {
        // Ability has back to background
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
        this.isInBackground = true;
        AppStorage.setOrCreate('isInBackground', true);
        // wfc.disconnect(false, false)
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground, to disconnected');
        if ([ConnectionStatus.ConnectionStatusConnected, ConnectionStatus.ConnectionStatusReceiveing].indexOf(this.connectionStatus) === -1) {
            return
        }
        this.startIMShortTask();

    }

    onBackPressed(): boolean {
        return true;
    }

    private async startIMShortTask() {
        try {
            if (deviceInfo.sdkApiVersion >= 20) {
                let transientTaskInfo = await backgroundTaskManager.getTransientTaskInfo()
                if (transientTaskInfo.remainingQuota < 10 * 1000) {
                    // TODO
                    // force close tcp
                    return;
                }
            }

            let delayInfo = backgroundTaskManager.requestSuspendDelay('im', () => {
                // 回调函数。应用申请的短时任务即将超时，通过此函数回调应用，执行一些清理和标注工作，并取消短时任务
                console.info('suspend delay task will timeout');
                this.cancelIMShortTask()
            })
            this.suspendDelayId = delayInfo.requestId;
            this.cancelIMShortTaskTimerID = setTimeout(() => {
                this.cancelIMShortTask()
                this.cancelIMShortTaskTimerID = 0;
            }, 15 * 1000)
            console.log('requestSuspendDelay success', delayInfo.requestId, delayInfo.actualDelayTime)
        } catch (error) {
            console.error(`Operation requestSuspendDelay failed. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
        }
    }

    private cancelIMShortTask() {
        if (this.suspendDelayId > 0) {
            try {
                backgroundTaskManager.cancelSuspendDelay(this.suspendDelayId);
                console.log('cancelSuspendDelay success', this.suspendDelayId)
                this.suspendDelayId = 0
            } catch (error) {
                console.error(`Operation cancelSuspendDelay failed. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
            }
        }
        if (this.cancelIMShortTaskTimerID > 0) {
            clearTimeout(this.cancelIMShortTaskTimerID)
            this.cancelIMShortTaskTimerID = 0;
        }
    }

    private loadContent(url: string) {
        // this.windowStage.getMainWindowSync().setWindowBackgroundColor('#EDEDED')
        console.log('testTag, loadUrl', url)
        this.windowStage!.loadContent(url, this.storage, (err, data) => {
            if (err.code) {
                hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
                return;
            }
            if (url === 'pages/MainPage') {
                this.isMaiPageLoaded = true;
            }

            PersistentStorage.persistProp(LAST_LOGIN_MOBILE_KEY, '');
            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
    }

    private parseLaunchParamsAndThen(want: Want) {
        // let conversation = want.parameters?.conversation as Conversation
        // let params: Record<string, Object> = {}
        // if (conversation) {
        this.storage.setOrCreate<Record<string, Object>>('wantParams', want.parameters);
        // }
        // TODO more，比如跳转到加好友、voip 相关页面
    }
}
