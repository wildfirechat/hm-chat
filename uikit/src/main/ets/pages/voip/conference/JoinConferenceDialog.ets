@CustomDialog
export default struct JoinConferenceDialog {
    controller: CustomDialogController
    onConfirm?: (conferenceId: string, password: string) => void
    @State conferenceId: string = ''
    @State password: string = ''

    build() {
        Column() {
            Text('请输入会议号及密码')
                .fontSize(17)
                .padding(20)

            Column() {
                Text('会议号')
                    .fontSize(15)
                TextInput({ placeholder: '请输入会议号', text: this.conferenceId })
                    .fontSize(14)
                    .borderRadius(4)
                    .type(InputType.Number)
                    .maxLines(1)
                    .maxLength(50)
                    .margin({ top: 5 })
                    .onChange((value) => {
                        this.conferenceId = value;
                    })

            }
            .alignItems(HorizontalAlign.Start)

            Column() {
                Text('会议密码')
                    .fontSize(15)
                TextInput({ placeholder: '如果没有，请忽略', text: this.password })
                    .fontSize(14)
                    .borderRadius(4)
                    .maxLines(1)
                    .maxLength(50)
                    .margin({ top: 5 })
                    .onChange((value) => {
                        this.password = value;
                    })

            }
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 20 })

            Row() {
                Button('取消')
                    .fontColor(Color.Gray)
                    .type(ButtonType.Normal)
                    .buttonStyle(ButtonStyleMode.TEXTUAL)
                    .onClick(() => {
                        this.controller.close()
                    })
                Button('确定')
                    .enabled(this.conferenceId.trim().length > 0)
                    .type(ButtonType.Normal)
                    .buttonStyle(ButtonStyleMode.TEXTUAL)
                    .onClick(() => {
                        this.onConfirm?.(this.conferenceId, this.password)
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
