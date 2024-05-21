import web_webview from '@ohos.web.webview'
import WfcWebView from '../workspace/WfcWebView'
import UserInfo from '../../wfc/model/userInfo'
import DSBridge from '../workspace/dsBridge'
import PickContactModal from '../picker/PickContactModal'


@Entry
@Component
export default struct WebViewPage {
    webviewController: web_webview.WebviewController = new web_webview.WebviewController()
    url: string = ''
    @State title: string = '加载中'
    isNewPickContact = true;
    dsbridge?: DSBridge
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

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
        let pickedUsers = localStorage.get<UserInfo[]>(PickContactModal.PICK_RESULT);
        if (pickedUsers) {
            this.dsbridge?.onPickContact(pickedUsers);
            localStorage.delete(PickContactModal.PICK_RESULT)
        }
    }

    build() {
        NavDestination() {
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
                .width('100%')
                .height('100%')
        }
        .title(this.title)
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
