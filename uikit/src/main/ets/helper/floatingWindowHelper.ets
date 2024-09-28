import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalContext } from '../globalContext';

// 悬浮窗需要特殊权限，请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/application-window-stage-0000001820999885-V5#ZH-CN_TOPIC_0000001881257813__设置悬浮窗
export function showVoipFloatingWindow(context: Context, name: string, contentPagePath: string, width: number, height: number, x: number, y: number): Promise<window.Window> {
    // 1.创建悬浮窗。
    let _newWindow: window.Window | null = null;
    let config: window.Configuration = {
        name: name, windowType: window.WindowType.TYPE_FLOAT, ctx: context
    };
    return new Promise((resolve, reject) => {
        window.createWindow(config, (err: BusinessError, data) => {
            let errCode: number = err.code;
            if (errCode) {
                console.error('Failed to create the floatWindow. Cause: ' + JSON.stringify(err));
                reject(err)
                return;
            }
            console.info('Succeeded in creating the floatWindow. Data: ' + JSON.stringify(data));
            _newWindow = data;
            // 2.悬浮窗窗口创建成功后，设置悬浮窗的位置、大小及相关属性等。
            _newWindow.moveWindowTo(x, y, (err: BusinessError) => {
                let errCode: number = err.code;
                if (errCode) {
                    console.error('Failed to move the window. Cause:' + JSON.stringify(err));
                    reject(err)
                    return;
                }
                console.info('Succeeded in moving the window.');
            });
            _newWindow.resize(width, height, (err: BusinessError) => {
                let errCode: number = err.code;
                if (errCode) {
                    console.error('Failed to change the window size. Cause:' + JSON.stringify(err));
                    reject(err)
                    return;
                }
                console.info('Succeeded in changing the window size.');
            });
            _newWindow.setWindowTouchable(true)
            // 3.为悬浮窗加载对应的目标页面。
            _newWindow.setUIContent(contentPagePath, (err: BusinessError) => {
                let errCode: number = err.code;
                if (errCode) {
                    console.error('Failed to load the content. Cause:' + JSON.stringify(err));
                    reject(err)
                    return;
                }
                console.info('Succeeded in loading the content.');
                // 3.显示悬浮窗。
                (_newWindow as window.Window).showWindow((err: BusinessError) => {
                    let errCode: number = err.code;
                    if (errCode) {
                        console.error('Failed to show the window. Cause: ' + JSON.stringify(err));
                        reject(err)
                        return;
                    }
                    console.info('Succeeded in showing the window.');

                    resolve(_newWindow!)
                });
            });
        })
    })
}
