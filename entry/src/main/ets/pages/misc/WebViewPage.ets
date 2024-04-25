import web_webview from '@ohos.web.webview'
import router from '@ohos.router'
import Config from '../../config'
import { showToast } from '../../common/utils/Toast'
import wfc, { WfcManager } from '../../wfc/client/wfc'
import url from '@ohos.url'
import WfcWebView from '../workspace/WfcWebView'
import PickContactPage from '../picker/PickContactPage'
import UserInfo from '../../wfc/model/userInfo'
import DSBridge from '../workspace/dsBridge'


@Entry
@Component
export default struct WebViewPage {
    webviewController: web_webview.WebviewController = new web_webview.WebviewController()
    url: string = ''
    @State title: string = '加载中'
    isNewPickContact = true;
    dsbridge?: DSBridge

    aboutToAppear() {
        let params = router.getParams() as Record<string, Object>
        this.url = params['url'] as string
        let title = params['title'] as string
        if (title) {
            this.title = title
        }
        this.dsbridge = new DSBridge(this.url, this.webviewController)
    }

    onPageShow(): void {
        let params = router.getParams() as Record<string, Object>
        console.log('main Index Show', params)
        if (params) {
            const tag: string = params['tag'] as string
            if (tag === PickContactPage.TAG) {
                if (this.isNewPickContact) {
                    this.isNewPickContact = false;
                    let pickedUser: UserInfo[] = params['result'] as UserInfo[]
                    this.dsbridge?.onPickContact(pickedUser);
                }
            }
        }
    }

    build() {
        Navigation() {
            WfcWebView({
                url: this.url,
                controller: this.webviewController,
                dsBridge: this.dsbridge,
                onTitleReceive: (title?: string) => {
                    if (title) {
                        this.title = title!;
                    }
                }
            })
        }
        .title(this.title)
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
    }
}
