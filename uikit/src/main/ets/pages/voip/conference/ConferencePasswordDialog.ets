@CustomDialog
export default struct ConferencePasswordDialog {
    controller: CustomDialogController
    onConfirm?: (password: string) => void
    @State password: string = ''

    build() {
        Column() {
            Text('请输入会议密码')
                .fontSize(17)
                .fontColor($r('app.color.wf_primary_text'))
                .padding(20)

            Column() {
                Text('会议密码')
                    .fontSize(15)
                    .fontColor($r('app.color.wf_primary_text'))
                TextInput({ placeholder: '请输入会议密码', text: this.password })
                    .fontSize(14)
                    .borderRadius(4)
                    .type(InputType.Number)
                    .fontColor($r('app.color.wf_primary_text'))
                    .placeholderColor($r('app.color.wf_tertiary_text'))
                    .backgroundColor(Color.Transparent)
                    .maxLines(1)
                    .maxLength(50)
                    .margin({ top: 5 })
                    .onChange(value => {
                        this.password = value
                    })

            }
            .alignItems(HorizontalAlign.Start)

            Row() {
                Button('取消')
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .type(ButtonType.Normal)
                    .buttonStyle(ButtonStyleMode.TEXTUAL)
                    .onClick(() => {
                        this.controller.close()
                    })
                Button('确定')
                    .enabled(!!this.password)
                    .type(ButtonType.Normal)
                    .buttonStyle(ButtonStyleMode.TEXTUAL)
                    .onClick(() => {
                        this.onConfirm?.(this.password);
                        this.controller.close()
                    })
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
            .margin({ top: 20 })
        }
        .padding({ top: 10, bottom: 10 })
        .margin({ left: 40, right: 40 })
    }
}
