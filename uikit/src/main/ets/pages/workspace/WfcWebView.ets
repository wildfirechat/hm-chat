import web_webview from '@ohos.web.webview'
import { showToast } from '../../common/utils/Toast'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import DSBridge from './dsBridge'
import Config from '@wfc/client/src/main/ets/config'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import data_preferences from '@ohos.data.preferences';

@Component
export default struct WfcWebView {
    @StorageProp('fontScale') fontScale: number = 1.0;
    controller?: web_webview.WebviewController
    url: string = ''
    onTitleReceive?: (title?: string) => void
    dsBridge?: DSBridge
    @State progress: number = 0
    @State darkMode: WebDarkMode = WebDarkMode.Auto;
    @State @Watch('onPickUser') pickedUser: SubscribedAbstractProperty<UserInfo[]> = LocalStorage.getShared()
        .link('pickUserResult');

    aboutToAppear() {
        web_webview.WebviewController.setWebDebuggingAccess(true);
    }

    onPageHide(): void {
    }

    onPickUser() {
        showToast('TODO Pick user')
    }

    build() {
        Column() {
            if (this.progress < 100) {
                Progress({
                    type: ProgressType.Linear,
                    value: this.progress,
                    total: 100
                })
                    .width('100%')
                    .height(4)
            }
            Web({ src: this.url, controller: this.controller! })
                .onTitleReceive((event) => {
                    console.log('title:' + event!.title)
                    this.onTitleReceive && this.onTitleReceive(event?.title)
                })
                .onProgressChange((data: OnProgressChangeEvent) => {
                    this.progress = data.newProgress
                })
                .darkMode(this.darkMode)
                .forceDarkAccess(true)
                .javaScriptAccess(true)
                // 必须在 onControllerAttached 里设置 UA，此时 controller 才与 Web 组件绑定，
                // 且早于首次加载；在 aboutToAppear 里调用会抛 17100001。
                .onControllerAttached(() => {
                    let controller = this.controller
                    if (!controller) {
                        return
                    }
                    try {
                        controller.setCustomUserAgent(Config.buildWebUserAgent(controller.getUserAgent()))
                    } catch (e) {
                        console.log('setCustomUserAgent error', e)
                    }
                })
                // UA 不含 "Mobile" 时 ArkWeb 默认不解析 <meta name="viewport">，页面会按桌面宽度布局，
                // 这里显式打开，保证平板等设备上响应式页面也按 viewport 布局。
                .metaViewport(true)
                .textZoomRatio(this.fontScale * 100)
                .javaScriptProxy({
                    object: this.dsBridge,
                    name: '_dsbridge',
                    methodList: ['call'],
                    controller: this.controller
                })
                .onPageBegin(async (evt) => {
                    if (evt.url === Config.getWorkspaceUrl()) {
                        let userId = wfc.getUserId()
                        let p = await data_preferences.getPreferences(getContext(this).getApplicationContext(), 'wfcstore')
                        let openUserId = p.getSync('workspace-userId', '')
                        if (userId !== openUserId) {
                            try {
                                await this.controller?.runJavaScript('localStorage.clear()')
                            } catch (e) {
                                console.log('clear localStorage error', e)
                            }

                        }
                    }
                })
                .domStorageAccess(true)
                .onPageEnd(url => {
                    console.log('loaded', url)
                })
        }
    }
}

