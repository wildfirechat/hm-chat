import { Core } from "@ohos/hypium"
@Preview
@Component
export default struct ToggleItemView {
    title: string = '测试标题'
    paddingLeft: number = 10
    paddingRight: number = 10
    showDivider: boolean = false
    @Prop isOn: boolean = false
    @Prop enable: boolean = true
    @Prop desc?: string = ''
    onChange?: (isOn: boolean) => void = undefined

    build() {
        Column() {
            Row() {
                Column() {
                    Text(this.title)
                        .fontColor($r('app.color.wf_primary_text'))
                    if (this.desc) {
                        Text(this.desc)
                            .fontColor($r('app.color.wf_tertiary_text'))
                            .fontSize(13)
                            .padding({ top: 5 })
                    }
                }
                .alignItems(HorizontalAlign.Start)
                Toggle({ type: ToggleType.Switch, isOn: this.isOn })
                    .enabled(this.enable)
                    .onChange(this.onChange)
            }
            .padding({ left: this.paddingLeft, right: this.paddingRight })
            .height(56)
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            if (this.showDivider) {
                Divider()
                    .strokeWidth(0.6)
                    .color($r('app.color.wf_divider'))
                    .padding({ left: this.paddingLeft })
            }
        }
        .width('100%')
        .backgroundColor($r('app.color.wf_background'))
    }
}
