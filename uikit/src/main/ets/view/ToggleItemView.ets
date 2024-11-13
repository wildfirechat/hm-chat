@Preview
@Component
export default struct ToggleItemView {
    title: string = '测试标题'
    paddingLeft: number = 10
    paddingRight: number = 10
    showDivider: boolean = false
    @Prop isOn: boolean = false
    onChange?: (isOn: boolean) => void = undefined

    build() {
        Column() {
            Row() {
                Text(this.title)
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