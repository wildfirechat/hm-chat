import web_webview from '@ohos.web.webview'
import router from '@ohos.router'
import Config from '../config'
import WfcWebView from './workspace/WfcWebView'
import DSBridge from './workspace/dsBridge'


@Component
export default struct WorkSpaceTab {
    webviewController: web_webview.WebviewController = new web_webview.WebviewController()
    url: string = Config.OPEN_PLATFORM_WORK_SPACE_URL;
    @State title: string = '加载中'

    build() {
        Column() {
            WfcWebView({
                url: this.url,
                controller: this.webviewController,
                dsBridge: new DSBridge(this.url, this.webviewController)
            })
        }
        .height('100%')
        .width('100%')
    }
}
