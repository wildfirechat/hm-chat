import web_webview from '@ohos.web.webview'
import router from '@ohos.router'
import Config from '../../config'
import { showToast } from '../../common/utils/Toast'
import wfc, { WfcManager } from '../../wfc/client/wfc'
import url from '@ohos.url'
import PickContactPage from '../picker/PickContactPage'
import UserInfo from '../../wfc/model/userInfo'
import DSBridge from './dsBridge'


@Component
export default struct WebViewPage {
    controller?: web_webview.WebviewController
    url: string = ''
    onTitleReceive?: (title?: string) => void
    private dsBridge?: DSBridge
    @State @Watch('onPickUser') pickedUser: SubscribedAbstractProperty<UserInfo[]> = LocalStorage.getShared()
        .link('pickUserResult');

    aboutToAppear() {
        web_webview.WebviewController.setWebDebuggingAccess(true);
    }

    onPageHide(): void {
    }

    onPickUser() {
        console.log('xxxx')
    }

    build() {
        Web({ src: this.url, controller: this.controller })
            .onTitleReceive((event) => {
                console.log('title:' + event!.title)
                this.onTitleReceive && this.onTitleReceive(event?.title)
            })
            .javaScriptAccess(true)
            .javaScriptProxy({
                object: this.dsBridge,
                name: '_dsbridge',
                methodList: ['call'],
                controller: this.controller
            })
            .domStorageAccess(true)
            .onPageEnd(url => {
                console.log('loaded', url)
            })
    }
}

