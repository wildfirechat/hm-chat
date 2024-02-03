import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import data_preferences from '@ohos.data.preferences';
import wfc from '../wfc/client/wfc'

export default class EntryAbility extends UIAbility {
    private windowStage: window.WindowStage

    onCreate(want, launchParam) {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');

        wfc.init(this.context.getApplicationContext(), this.context.eventHub, this.context.filesDir);
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
    }

    onDestroy() {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage: window.WindowStage) {
        // Main window is created, set main page for this ability
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
        this.windowStage = windowStage;

        let url = 'pages/LoginPage';
        data_preferences.getPreferences(this.context, 'wfcstore', async (err, val) => {
            if (err) {
                console.error("Failed to get preferences. code =" + err.code + ", message =" + err.message);
            } else {
                let preferences = val;
                try {
                    let userId = await preferences.get('userId', null) as string
                    let token = await preferences.get('token', null) as string
                    if (userId && token) {
                        url = 'pages/MainPage'
                        wfc.connect(userId, token);
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
    }

    onBackground() {
        // Ability has back to background
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
    }

    private loadContent(url: string) {
        // this.windowStage.getMainWindowSync().setWindowBackgroundColor('#EDEDED')
        this.windowStage.loadContent(url, (err, data) => {
            if (err.code) {
                hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
                return;
            }
            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
    }
}