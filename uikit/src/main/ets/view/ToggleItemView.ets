import { Core } from "@ohos/hypium"

@Preview
@Component
export default struct ToggleItemView {
    title: string = '测试标题'
    paddingLeft: number = 10
    paddingRight: number = 10
    showDivider: boolean = false
    @Prop isOn: boolean = false
    @Prop desc?: string = ''
    onChange?: (isOn: boolean) => void = undefined

    build() {
        Column() {
            Row() {
                Column() {
                    Text(this.title)
                    if (this.desc) {
                        Text(this.desc)
                            .fontColor(Color.Gray)
                            .fontSize(13)
                            .padding({ top: 5 })
                    }
                }
                .alignItems(HorizontalAlign.Start)

                Toggle({ type: ToggleType.Switch, isOn: this.isOn })
                    .onChange(this.onChange)
            }
            .padding({ left: this.paddingLeft, right: this.paddingRight })
            .height(56)
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            if (this.showDivider) {
                Divider()
                    .strokeWidth(0.6)
                    .color('#EDEDED')
                    .padding({ left: this.paddingLeft })
            }
        }
        .width('100%')
    }
}