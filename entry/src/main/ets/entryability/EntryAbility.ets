import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import data_preferences from '@ohos.data.preferences';
import wfc from '../wfc/client/wfc'
import Config from '../config'
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { GlobalContext } from '../globalContext';

import EventType from '../wfc/client/wfcEvent';
import Message from '../wfc/messages/message';
import wfcNotificationManager from '../notification/wfcNotificationManager'

export default class EntryAbility extends UIAbility {
    private windowStage?: window.WindowStage
    private isInBackground: boolean = false

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');

        wfc.init(this.context.getApplicationContext(), this.context.eventHub, this.context.filesDir, Config.getWFCPlatform());
        // wfc.setConnectionStatusListener(async (status) => {
        //     console.log('connectionStatus changed', status);
        //     // TODO 有的状态码时，需要清 session
        //     if (status === -6) {
        //         let preference = await data_preferences.getPreferences(this.context, 'wfcstore')
        //         if (preference) {
        //             preference.clear()
        //             preference.flush()
        //         }
        //         let url = 'pages/Login'
        //         this.loadContent(url)
        //     }
        // })
        this.context.eventHub.on(EventType.ReceiveMessage, (message: Message, hasMore: boolean) => {
            if (this.isInBackground) {
                wfcNotificationManager.onReceiveMessage(message, hasMore);
            }
        })
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

    private loadContent(url: string) {
        // this.windowStage.getMainWindowSync().setWindowBackgroundColor('#EDEDED')
        this.windowStage!.loadContent(url, (err, data) => {
            if (err.code) {
                hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
                return;
            }
            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
    }
}
