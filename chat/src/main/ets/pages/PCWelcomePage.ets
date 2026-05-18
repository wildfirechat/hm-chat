@Component
export default struct PCWelcomePage {
    build() {
        Column() {
            Image($r('app.media.app_icon'))
                .width(80)
                .height(80)
                .borderRadius(16)
                .margin({ bottom: 24 })
            Text('野火 IM')
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.wf_primary_text'))
                .margin({ bottom: 12 })
            Text('选择一个会话，开始聊天')
                .fontSize(14)
                .fontColor($r('app.color.wf_secondary_text'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.wf_background'))
    }
}
