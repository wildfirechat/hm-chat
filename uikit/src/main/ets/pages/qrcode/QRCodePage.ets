import { FontSize, Radius } from '../../common/design/Tokens'
@Component
export default struct QRCodePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State private title: string = ''
    @State private portraitUrl: string = ''
    @State private name: string = ''
    @State private qrCodeValue: string = ''
    @State private hint: string = ''

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.title = params['title'] as string ?? ''
        this.portraitUrl = params['portraitUrl'] as string ?? ''
        this.name = params['name'] as string ?? ''
        this.qrCodeValue = params['qrCodeValue'] as string ?? ''
        this.hint = params['hint'] as string ?? ''
    }

    build() {
        NavDestination() {
            Column() {
                if (this.portraitUrl) {
                    Image(this.portraitUrl)
                        .width(80)
                        .height(80)
                        .borderRadius(Radius.sm)
                        .margin({ top: 40 })
                }
                if (this.name) {
                    Text(this.name)
                        .fontSize(FontSize.lg)
                        .fontColor($r('app.color.wf_primary_text'))
                        .margin({ top: 16 })
                }
                Stack() {
                    QRCode(this.qrCodeValue)
                        .width(220)
                        .height(220)
                        .color(0xFF000000)
                        .backgroundColor(Color.White)
                }
                .padding(12)
                .margin({ top: 32 })
                .backgroundColor(Color.White)
                .borderRadius(Radius.lg)
                if (this.hint) {
                    Text(this.hint)
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.wf_secondary_text'))
                        .margin({ top: 20 })
                }
            }
            .width('100%')
            .height('100%')
            .alignItems(HorizontalAlign.Center)
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .title(this.title)
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.wf_primary_background_color'))
    }
}
