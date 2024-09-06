@Preview
@Reusable
@Component
export default struct LoadingView {
    text: string = '加载中...'

    build() {
        Column() {
            LoadingProgress().width(20).height(20)
            Text(this.text)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height('100%')
    }
}