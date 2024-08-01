import web_webview from '@ohos.web.webview'
import { showToast } from '../../common/utils/Toast'
import UserInfo from '../../wfc/model/userInfo'
import DSBridge from './dsBridge'


@Component
export default struct WfcWebView {
    controller?: web_webview.WebviewController
    url: string = ''
    onTitleReceive?: (title?: string) => void
    private dsBridge?: DSBridge
    @State progress: number = 0
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
            Web({ src: this.url, controller: this.controller })
                .onTitleReceive((event) => {
                    console.log('title:' + event!.title)
                    this.onTitleReceive && this.onTitleReceive(event?.title)
                })
                .onProgressChange((data: OnProgressChangeEvent) => {
                    this.progress = data.newProgress
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
}

