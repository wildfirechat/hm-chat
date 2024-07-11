import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import data_preferences from '@ohos.data.preferences';
import wfc from '../wfc/client/wfc'
import Config from '../config'
import { AbilityConstant, Context, Want } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { GlobalContext } from '../globalContext';
import { pushService } from '@kit.PushKit';

import EventType from '../wfc/client/wfcEvent';
import Message from '../wfc/messages/message';
import wfcNotificationManager from '../notification/wfcNotificationManager'
import { BusinessError } from '@ohos.base';
import Conversation from '../wfc/model/conversation';
import ConnectionStatus from '../wfc/client/connectionStatus';
import CustomMessageConfig from '../wfc_custom_message/customMessageConfig';


export default class EntryAbility extends UIAbility {
    private windowStage?: window.WindowStage
    private isMaiPageLoaded: boolean = false
    private isInBackground: boolean = false
    private launchParams: Record<string, Object> = {
        'targetConversation': new Conversation(0, '', 0)
    };
    private storage: LocalStorage = new LocalStorage(this.launchParams);

    async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
        GlobalContext.getContext().setObject('context', this.context);

        wfc.init(this.context.getApplicationContext(), this.context.eventHub, this.context.filesDir, Config.getWFCPlatform());
        CustomMessageConfig.registerCustomMessages();
        wfc.eventEmitter!.on(EventType.ConnectionStatusChanged, async (status: number) => {
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
                let preference = await data_preferences.getPreferences(this.context, 'wfcstore')
                if (preference) {
                    preference.clear()
                    preference.flush()
                }
                let url = 'pages/LoginPage'
                this.loadContent(url)
            }
        })

        wfc.eventEmitter!.on(EventType.ReceiveMessage, (message: Message, hasMore: boolean) => {
            if (this.isInBackground) {
                wfcNotificationManager.onReceiveMessage(message, hasMore);
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
        GlobalContext.getContext().setObject('windowStage', windowStage);

        let url = 'pages/LoginPage';
        data_preferences.getPreferences(this.context, 'wfcstore', async (err, val) => {
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
        let windowClass: window.Window = windowStage.getMainWindowSync();
        // 获取状态栏高度
        let statusArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        AppStorage.setOrCreate('SafeAreaTopHeight', statusArea.topRect.height);
        // 获取导航栏高度
        let navigationArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        AppStorage.setOrCreate('SafeAreaBottomHeight', navigationArea.bottomRect.height);
        // 获取软键盘高度，但这儿获取到的软键盘高度无效，后续也没有使用
        let keyboardArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
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
    }

    onBackground() {
        // Ability has back to background
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
        this.isInBackground = true;
    }

    onBackPressed(): boolean {
        return true;
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

            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
    }

    private parseLaunchParamsAndThen(want: Want) {
        let conversation = want.parameters?.conversation as Conversation
        if (conversation) {
            this.storage.setOrCreate<Conversation>('targetConversation', conversation);
        }
        // TODO more，比如跳转到加好友、voip 相关页面
    }
}
