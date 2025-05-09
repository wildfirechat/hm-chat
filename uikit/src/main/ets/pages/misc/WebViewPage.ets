import web_webview from '@ohos.web.webview'
import WfcWebView from '../workspace/WfcWebView'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import DSBridge from '../workspace/dsBridge'
import PickMultiContactModal from '../picker/PickMultiContactModal'


@Entry
@Component
export default struct WebViewPage {
    webviewController: web_webview.WebviewController = new web_webview.WebviewController()
    url: string = ''
    @State title: string = ''
    isNewPickContact = true;
    dsbridge?: DSBridge
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private defaultTitle: string = '加载中'

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.url = params['url'] as string
        let title = params['title'] as string
        if (title) {
            this.title = title
        }
        this.dsbridge = new DSBridge(this.url, this.webviewController, this.mainNavPathStack)
    }

    onPageShow(): void {
        let localStorage = LocalStorage.getShared();
        let pickedUsers = localStorage.get<UserInfo[]>(PickMultiContactModal.PICK_RESULT);
        if (pickedUsers) {
            this.dsbridge?.onPickContact(pickedUsers);
            localStorage.delete(PickMultiContactModal.PICK_RESULT)
        }
    }

    build() {
        NavDestination() {
            WfcWebView({
                url: this.url,
                controller: this.webviewController,
                dsBridge: this.dsbridge,
                onTitleReceive: (title?: string) => {
                    if (!this.title && title) {
                        this.title = title!;
                    }
                }
            })
                .width('100%')
                .height('100%')
        }
        .title(this.title ? this.title : this.defaultTitle)
        .height('100%')
        .width('100%')
        .onShown(() => {
            this.onPageShow()
        })
    }

    uiMethodConfig(): Record<string, Function> {
        let record: Record<string, Function> = {
            'chooseContact': this.chooseContact
        }

        return record;
    }

    chooseContact() {
        // TODO
    }
}
