import web_webview from '@ohos.web.webview'
import Config from '@wfc/client/src/main/ets/config'
import WfcWebView from './workspace/WfcWebView'
import DSBridge from './workspace/dsBridge'
import { WidthBreakpoint } from '../util/windowSizeManager'

@Component
export default struct WorkSpaceTab {
    webviewController: web_webview.WebviewController = new web_webview.WebviewController()
    url: string = Config.getWorkspaceUrl() || '';
    @State title: string = '加载中'
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @StorageProp('widthBreakpoint') @Watch('onWidthBreakpointChange') widthBreakpoint: WidthBreakpoint = 'sm'

    onWidthBreakpointChange() {
        try {
            this.webviewController.refresh()
        } catch (error) {
        }
    }

    aboutToAppear(): void {
        try {
            this.webviewController.setCustomUserAgent(Config.CUSTOM_USER_AGENT)
        } catch (error) {
        }
    }

    build() {
        Column() {
            WfcWebView({
                url: this.url,
                controller: this.webviewController,
                dsBridge: new DSBridge(this.url, this.webviewController, this.mainNavPathStack)
            })
        }
        .height('100%')
        .width('100%')
    }
}
