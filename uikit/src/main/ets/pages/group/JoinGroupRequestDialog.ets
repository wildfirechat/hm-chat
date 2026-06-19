import { LengthUnit } from "@kit.ArkUI"
import { flexButtonSpace } from "../../common/Styles"
import { FontSize, Radius } from '../../common/design/Tokens'

@CustomDialog
export default struct JoinGroupRequestDialog {
    textValue: string = ''
    controller: CustomDialogController
    cancel: () => void = () => {
    }
    confirm: (text: string) => void = str => {
    }

    build() {
        Column() {
            Text('已开启入群验证，请输入理由，等待群主或管理员审批')
                .fontSize(FontSize.md)
                .margin({ top: 12, bottom: 12 })
                .width('100%')
                .fontColor($r('app.color.wf_primary_text'))

            TextInput({ placeholder: '请输入理由' })
                .height(40)
                .width('100%')
                .margin({ top: 12 })
                .borderRadius(Radius.sm)
                .fontColor($r('app.color.wf_primary_text'))
                .onChange((value: string) => {
                    this.textValue = value
                })
            Flex({ justifyContent: FlexAlign.End, space: flexButtonSpace }) {
                Button('取消')
                    .onClick(() => {
                        this.controller.close()
                        this.cancel()
                    })
                Button('确定')
                    .onClick(() => {
                        this.controller.close()
                        this.confirm(this.textValue)
                    })
                    .fontColor(Color.Red)
            }
            .margin({ top: 12 })
        }
        .padding(20)
        .backgroundColor($r('app.color.wf_background'))
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
    }
}
