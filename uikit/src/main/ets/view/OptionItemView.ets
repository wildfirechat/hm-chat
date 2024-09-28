@Preview
@Component
export default struct OptionItemView {
    // TODO 应该用 @prop，但是不允许可选，故
    private icon: ResourceStr = ''
    private title: string = ''
    @Prop desc: string = ''
    @Prop subTitle: string = ''
    @Prop imgUrl: string = ''
    private showRightArrow: boolean = true
    private paddingLeft: number = 10
    private paddingRight: number = 10
    private showDivider: boolean = true

    build() {
        Column() {
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
                        .constraintSize({ maxWidth: 200 })
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
                    Image($r('app.media.ic_public_arrow_right'))
                        .width(22)
                        .height(22)
                        .fillColor('#B6B6B6')
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

            if (this.showDivider) {
                Divider()
                    .strokeWidth(0.6)
                    .color('#EDEDED')
                    .padding({ left: this.icon ? 30 + this.paddingLeft : this.paddingLeft })
            }
        }
        .width('100%')
    }
}