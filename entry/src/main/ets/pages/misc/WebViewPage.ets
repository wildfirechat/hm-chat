import web_webview from '@ohos.web.webview'
import router from '@ohos.router'


@Entry
@Component
export default struct WebViewPage {
    controller: web_webview.WebviewController = new web_webview.WebviewController()
    url: string
    @State title: string = '加载中'

    aboutToAppear() {
        this.url = router.getParams()['url']
        let title = router.getParams()['title']
        if (title) {
            this.title = title
        }
    }

    build() {
        Navigation() {
            Web({ src: this.url, controller: this.controller })
                .onTitleReceive((event) => {
                    console.log('title:' + event.title)
                    this.title = event.title
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
