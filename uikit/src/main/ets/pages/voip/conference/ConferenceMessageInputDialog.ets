@CustomDialog
export default struct ConferenceMessageInputDialog {
    controller: CustomDialogController
    onConfirm?: (text: string) => void
    @State text: string = ''

    build() {
        Column() {
            Row() {
                TextInput({ placeholder: '请输入消息', text: this.text })
                    .fontSize(14)
                    .borderRadius(4)
                    .type(InputType.Normal)
                    .maxLines(1)
                    .maxLength(50)
                    .onChange(value => {
                        this.text = value
                    })
                    .layoutWeight(1)

                Button('发送')
                    .enabled(!!this.text)
                    .type(ButtonType.Normal)
                    .buttonStyle(ButtonStyleMode.TEXTUAL)
                    .onClick(() => {
                        this.onConfirm?.(this.text);
                        this.controller.close()
                    })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
        }
        .padding({ top: 10, bottom: 10 })
        .margin({ left: 10, right: 10 })
    }
}
