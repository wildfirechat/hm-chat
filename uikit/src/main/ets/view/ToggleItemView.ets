@Preview
@Component
export default struct ToggleItemView {
    private title: string = '测试标题'
    private paddingLeft: number = 10
    private paddingRight: number = 10
    private showDivider: boolean = false
    @Prop isOn: boolean = false
    private onChange?: (isOn: boolean) => void = undefined

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