import { FontSize, Radius } from '../../../common/design/Tokens'
@CustomDialog
export default struct ConferencePasswordDialog {
    controller: CustomDialogController
    onConfirm?: (password: string) => void
    @State password: string = ''

    build() {
        Column() {
            Text('请输入会议密码')
                .fontSize(FontSize.md)
                .fontColor($r('app.color.wf_primary_text'))
                .padding(20)

            Column() {
                Text('会议密码')
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_primary_text'))
                TextInput({ placeholder: '请输入会议密码', text: this.password })
                    .fontSize(FontSize.sm)
                    .borderRadius(Radius.sm)
                    .type(InputType.Number)
                    .fontColor($r('app.color.wf_primary_text'))
                    .placeholderColor($r('app.color.wf_tertiary_text'))
                    .backgroundColor(Color.Transparent)
                    .maxLines(1)
                    .maxLength(50)
                    .margin({ top: 4 })
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
        .padding({ top: 12, bottom: 12 })
        .margin({ left: 40, right: 40 })
    }
}
