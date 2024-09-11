import web_webview from '@ohos.web.webview'
import WfcWebView from '../workspace/WfcWebView'
import UserInfo from '../../wfc/model/userInfo'
import DSBridge from '../workspace/dsBridge'
import PickContactModal from '../picker/PickContactModal'
import { router } from '@kit.ArkUI'


@Entry
@Component
export default struct WebViewPage {
    webviewController: web_webview.WebviewController = new web_webview.WebviewController()
    url: string = ''
    @State title: string = '加载中'

    aboutToAppear() {
        let params = router.getParams() as Record<string, Object>;
        this.url = params['url'] as string
        let title = params['title'] as string
        if (title) {
            this.title = title
        }
    }

    onPageShow(): void {
        // DO NOTHING
    }

    build() {
        Navigation() {
            WfcWebView({
                url: this.url,
                controller: this.webviewController,
                onTitleReceive: (title?: string) => {
                    if (title) {
                        this.title = title!;
                    }
                }
            })
                .width('100%')
                .height('100%')
        }
        .title(this.title)
        .titleMode(NavigationTitleMode.Mini)
        .navBarPosition(NavBarPosition.Start)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
    }
}
