import { LengthUnit } from "@kit.ArkUI"
import { flexButtonSpace } from "../../common/Styles"

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
                .fontSize(16)
                .margin({ top: 10, bottom: 10 })
                .width('100%')

            TextInput({ placeholder: '请输入理由' })
                .height(40)
                .width('100%')
                .margin({ top: 10 })
                .borderRadius(4)
                .onChange((value: string) => {
                    this.textValue = value
                })
            Flex({ justifyContent: FlexAlign.End, space: flexButtonSpace }) {
                Button('取消')
                    .onClick(() => {
                        this.controller.close()
                        this.cancel()
                    }).backgroundColor(0xffffff).fontColor(Color.Black)
                Button('确定')
                    .onClick(() => {
                        this.controller.close()
                        this.confirm(this.textValue)
                    }).backgroundColor(0xffffff).fontColor(Color.Red)
            }
            .margin({ top: 10 })
        }
        .padding(20)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
    }
}
