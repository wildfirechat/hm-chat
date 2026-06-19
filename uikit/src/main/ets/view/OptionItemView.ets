import { FontSize, Radius, scaledSize, LayoutScale } from '../common/design/Tokens'
@Preview
@Component
export default struct OptionItemView {
    @StorageProp('fontScale') fontScale: number = 1.0;
    // TODO 应该用 @prop，但是不允许可选，故
    icon: ResourceStr = ''
    title: string = ''
    @Prop desc: string = ''
    @Prop subTitle: string = ''
    @Prop imgUrl: string = ''
    showRightArrow: boolean = true
    showBadge: boolean = false
    paddingLeft: number = 16
    paddingRight: number = 8
    showDivider: boolean = true

    build() {
        Column() {
            Row() {
                if (this.icon) {
                    Image(this.icon)
                        .width(20)
                        .height(20)
                        .margin({ right: this.paddingLeft })
                }
                Column() {
                    Row() {
                        Text(this.title)
                            .fontSize(FontSize.md)
                            .fontColor($r('app.color.wf_primary_text'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        if (this.showBadge) {
                            Text('')
                                .width(8)
                                .height(8)
                                .backgroundColor('#FF0000')
                                .borderRadius(Radius.sm)
                                .margin({ left: 8 })
                        }
                    }
                    .justifyContent(FlexAlign.Start)
                    .alignItems(VerticalAlign.Center)
                    if (this.subTitle) {
                        Text(this.subTitle)
                            .padding({ top: 2 })
                            .fontSize(FontSize.sm)
                            .fontColor($r('app.color.wf_tertiary_text'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                if (this.desc) {
                    Text(this.desc)
                        .padding({ left: 12, right: 12 })
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.wf_tertiary_text'))
                        .maxLines(1)
                        .constraintSize({ maxWidth: 200 })
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                if (this.imgUrl) {
                    Image(this.imgUrl)
                        .width(20)
                        .height(20)
                        .borderRadius(Radius.sm)
                        .margin({ right: 12 })
                }
                if (this.showRightArrow) {
                    Image($r('app.media.ic_public_arrow_right'))
                        .width(24)
                        .height(24)
                        .fillColor($r('app.color.c_gray'))
                }
            }
            .width('100%')
            .constraintSize({ minHeight: scaledSize(56, this.fontScale, LayoutScale.row)})
            .padding({ left: this.paddingLeft, right: this.paddingRight })
            .justifyContent(FlexAlign.SpaceBetween)
            .stateStyles({
                pressed: {
                    .backgroundColor($r('app.color.wf_item_pressed'))
                },
                normal: {
                    .backgroundColor($r('app.color.wf_background'))
                }
            })

            if (this.showDivider) {
                Divider()
                    .strokeWidth(0.4)
                    .color($r('app.color.wf_divider'))
                    .padding({ left: this.icon ? 20 + 2 * this.paddingLeft : this.paddingLeft })
            }
        }
        .width('100%')
    }
}
