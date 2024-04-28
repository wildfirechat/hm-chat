import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';

export default class VoipFloatingEntryAbility extends UIAbility {
    onWindowStageCreate(windowStage: window.WindowStage) {
        // 1.创建悬浮窗。
        let windowClass: window.Window | null = null;
        let config: window.Configuration = {
            name: "floatWindow", windowType: window.WindowType.TYPE_FLOAT, ctx: this.context
        };
        window.createWindow(config, (err: BusinessError, data) => {
            let errCode: number = err.code;
            if (errCode) {
                console.error('Failed to create the floatWindow. Cause: ' + JSON.stringify(err));
                return;
            }
            console.info('Succeeded in creating the floatWindow. Data: ' + JSON.stringify(data));
            windowClass = data;
            // 2.悬浮窗窗口创建成功后，设置悬浮窗的位置、大小及相关属性等。
            windowClass.moveWindowTo(300, 300, (err: BusinessError) => {
                let errCode: number = err.code;
                if (errCode) {
                    console.error('Failed to move the window. Cause:' + JSON.stringify(err));
                    return;
                }
                console.info('Succeeded in moving the window.');
            });
            windowClass.resize(500, 500, (err: BusinessError) => {
                let errCode: number = err.code;
                if (errCode) {
                    console.error('Failed to change the window size. Cause:' + JSON.stringify(err));
                    return;
                }
                console.info('Succeeded in changing the window size.');
            });
            // 3.为悬浮窗加载对应的目标页面。
            windowClass.setUIContent("pages/voip/VoipFloatingPage", (err: BusinessError) => {
                let errCode: number = err.code;
                if (errCode) {
                    console.error('Failed to load the content. Cause:' + JSON.stringify(err));
                    return;
                }
                console.info('Succeeded in loading the content.');
                // 3.显示悬浮窗。
                (windowClass as window.Window).showWindow((err: BusinessError) => {
                    let errCode: number = err.code;
                    if (errCode) {
                        console.error('Failed to show the window. Cause: ' + JSON.stringify(err));
                        return;
                    }
                    console.info('Succeeded in showing the window.');
                });
            });
            // 4.销毁悬浮窗。当不再需要悬浮窗时，可根据具体实现逻辑，使用destroy对其进行销毁。
            windowClass.destroyWindow((err: BusinessError) => {
                let errCode: number = err.code;
                if (errCode) {
                    console.error('Failed to destroy the window. Cause: ' + JSON.stringify(err));
                    return;
                }
                console.info('Succeeded in destroying the window.');
            });
        });
    }
};