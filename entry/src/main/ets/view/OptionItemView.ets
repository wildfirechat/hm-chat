@Preview
@Component
export default struct OptionItemView {
    // TODO 应该用 @prop，但是不允许可选，故
    private icon: ResourceStr
    private title: string
    private desc: string = ''
    private subTitle: string
    private imgUrl: string
    private showRightArrow: boolean = true
    private paddingLeft: number = 10
    private paddingRight: number = 10

    build() {
        Row() {
            if (this.icon) {
                Image(this.icon)
                    .width(20)
                    .height(20)
                    .margin({ right: 10 })
            }
            Column() {
                Text(this.title)
                    .fontSize(16)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                if (this.subTitle) {

                    Text(this.subTitle)
                        .padding({ top: 2 })
                        .fontSize(13)
                        .fontColor('#747474')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            if (this.desc) {
                Text(this.desc)
                    .padding({ left: 10, right: 10 })
                    .fontSize(13)
                    .fontColor('#747474')
                    .maxLines(1)
                    .constraintSize({ maxWidth: 100 })
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            if (this.imgUrl) {
                Image(this.imgUrl)
                    .width(20)
                    .height(20)
                    .borderRadius(4)
                    .margin({ right: 10 })
            }
            if (this.showRightArrow) {
                Image($r('app.media.ic_right'))
                    .width(12)
                    .height(12)
            }
        }
        .width('100%')
        .height(56)
        .padding({ left: this.paddingLeft, right: this.paddingRight })
        .justifyContent(FlexAlign.SpaceBetween)
        .stateStyles({
            pressed: {
                .backgroundColor('#E5E5E5')
            },
            normal: {
                .backgroundColor(Color.White)
            }
        })
    }
}