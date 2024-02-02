@Component
export default struct PutDownRefresh {
    @Link refreshText: Resource;

    build() {
        Row() {
            Image($r('app.media.refreshing'))
                .width(40)
                .height(40)
            Text(this.refreshText).fontSize(16)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(100)
    }
}