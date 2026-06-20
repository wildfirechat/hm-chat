import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import data_preferences from '@ohos.data.preferences';
import wfc from '@wfc/client'
import Config from '@wfc/client/src/main/ets/config'
import { AbilityConstant, common, ConfigurationConstant, Configuration, Context, Want } from '@kit.AbilityKit';
import { pushCommon, pushService } from '@kit.PushKit';

import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent';
import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import wfcNotificationManager from '@wfc/uikit/src/main/ets/notification/wfcNotificationManager'
import { BusinessError } from '@ohos.base';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConnectionStatus from '@wfc/client/src/main/ets/wfc/client/connectionStatus';
import CustomMessageConfig from '@wfc/client/src/main/ets/wfc_custom_message/customMessageConfig';
import uikit from '@wfc/uikit'
import { fontSizeManager } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import { LAST_LOGIN_MOBILE_KEY } from '../pages/login/LoginPage';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { systemShare } from '@kit.ShareKit';
import { copyFileUri, fileNameFromFileUri, fileSize } from '@wfc/uikit/src/main/ets/common/utils/FileUtil';
import { isImage, isVideo } from '@wfc/uikit/src/main/ets/util/helper';
import { ShareItem } from '@wfc/uikit/src/main/ets/common/Types';
import waterMarkWindow from '@wfc/uikit/src/main/ets/common/watermark/waterMarkWindow';

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
        AppStorage.setOrCreate<ConfigurationConstant.ColorMode>('currentColorMode', this.context.config.colorMode);
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

        this.dispatchWant(want);
    }

    onConfigurationUpdate(newConfig: Configuration): void {
        const currentColorMode: ConfigurationConstant.ColorMode | undefined = AppStorage.get('currentColorMode');
        if (currentColorMode !== newConfig.colorMode) {
            AppStorage.setOrCreate<ConfigurationConstant.ColorMode>('currentColorMode', newConfig.colorMode);
        }
    }

    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        console.log('testTag, newWant',)
        this.dispatchWant(want);
    }

    private dispatchWant(want: Want) {
        if (want.action === 'ohos.want.action.sendData') {
            this.handleShare(want);
        } else {
            this.parseLaunchParamsAndThen(want);
        }
    }

    onDestroy() {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage: window.WindowStage) {
        // Main window is created, set main page for this ability
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
        this.windowStage = windowStage;
        AppStorage.setOrCreate('windowStage', windowStage);

        // 应用用户「字体大小」设置（全 App 生效）
        if (this.applicationContext) {
            fontSizeManager.apply(this.applicationContext);
        }

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
                // 登录进入主页面后，创建全局水印子窗口（覆盖所有页面及弹窗）
                waterMarkWindow.create(this.windowStage!);
            } else {
                // 退出登录回到登录页时，销毁水印子窗口
                waterMarkWindow.destroy();
            }

            PersistentStorage.persistProp(LAST_LOGIN_MOBILE_KEY, '');
            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
    }

    // 接收其他应用通过系统分享发来的内容。共享文件的 uri 只有临时读取授权，
    // 必须在此处立即拷贝进本应用沙箱（cacheDir），再把可序列化的 ShareItem[]
    // 交给 MainPage 去选择会话并发送。
    private async handleShare(want: Want) {
        try {
            let data = await systemShare.getSharedData(want);
            let items: ShareItem[] = [];
            let records = data.getRecords();
            for (let record of records) {
                try {
                    // 只有 file:// 的 uri 才是需要拷贝的本地文件；网页链接（general.hyperlink）
                    // 等内容类数据的 URL 在 record.content 里，也可能以 http(s) 形式出现在
                    // record.uri 里，这些都按文本/链接消息发送，不能当作文件拷贝。
                    if (record.uri && record.uri.startsWith('file://')) {
                        let name = fileNameFromFileUri(record.uri);
                        let dstPath = this.context.getApplicationContext().cacheDir + '/' + new Date().getTime() + '-' + name;
                        copyFileUri(record.uri, dstPath);
                        let ext = name.substring(name.lastIndexOf('.') + 1).toLowerCase();
                        let type: 'image' | 'video' | 'file' = isImage(ext) ? 'image' : (isVideo(ext) ? 'video' : 'file');
                        items.push({
                            type: type,
                            filePath: dstPath,
                            name: name,
                            size: fileSize(dstPath)
                        });
                    } else {
                        let url = record.content ? record.content : record.uri;
                        let isHyperlink = (record.utd && record.utd.indexOf('hyperlink') >= 0)
                            || (!!url && (url.startsWith('http://') || url.startsWith('https://')));
                        if (isHyperlink && url) {
                            // 网页分享：连同分享方携带的 title/description/缩略图一起做成链接消息。
                            items.push({
                                type: 'link',
                                url: url,
                                title: record.title ? record.title : '',
                                description: record.description ? record.description : '',
                                thumbnail: this.shareThumbnail(record)
                            });
                        } else if (url) {
                            items.push({
                                type: 'text',
                                text: url
                            });
                        }
                    }
                } catch (e) {
                    hilog.error(0x0000, 'testTag', 'handle share record failed: %{public}s', JSON.stringify(e) ?? '');
                }
            }
            if (items.length > 0) {
                this.storage.setOrCreate<ShareItem[]>('shareParams', items);
            }
        } catch (e) {
            hilog.error(0x0000, 'testTag', 'getSharedData failed: %{public}s', JSON.stringify(e) ?? '');
        }
    }

    // 取分享记录的缩略图，转成 Image 可直接加载的字符串：
    // 优先用 http(s) 封面地址；否则把缩略图字节转成 base64 data uri（避免依赖
    // 临时授权的 file:// thumbnailUri，发送后仍可显示）。
    private shareThumbnail(record: systemShare.SharedRecord): string {
        try {
            if (record.thumbnailUri && record.thumbnailUri.startsWith('http')) {
                return record.thumbnailUri;
            }
            if (record.thumbnail && record.thumbnail.byteLength > 0) {
                return 'data:image/png;base64,' + wfc.arrayBuffer_to_b64(record.thumbnail.buffer as ArrayBuffer);
            }
        } catch (e) {
            hilog.error(0x0000, 'testTag', 'share thumbnail failed: %{public}s', JSON.stringify(e) ?? '');
        }
        return '';
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
