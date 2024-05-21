import web_webview from '@ohos.web.webview'
import UserInfo from '../../wfc/model/userInfo'
import DSBridge from './dsBridge'


@Component
export default struct WfcWebView {
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

