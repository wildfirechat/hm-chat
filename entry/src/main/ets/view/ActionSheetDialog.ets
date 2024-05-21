@Preview
@CustomDialog
export default struct ActionSheetDialog {
    title: string = ''
    sheets: SheetInfo[] = []
    // 若尝试在CustomDialog中传入多个其他的Controller，以实现在CustomDialog中打开另一个或另一些CustomDialog，那么此处需要将指向自己的controller放在最后
    controller: CustomDialogController

    build() {
        Column() {
            if (this.title) {
                Column() {
                    Text(this.title)
                        .fontSize(20)
                    Divider()
                        .width('100%')
                        .padding({ top: 10 })
                }
                .justifyContent(FlexAlign.Center)
                .align(Alignment.Center)
                .width('100%')
                .padding({ top: 20 })
            }

            ForEach(this.sheets, (sheet: SheetInfo) => {
                Row() {
                    if (sheet.icon) {
                        Image(sheet.icon)
                            .width(20)
                            .height(20)
                    }
                    Text(sheet.title)
                        .padding(10)
                        .fontSize(16)
                        .textAlign(TextAlign.Center)
                }
                .justifyContent(FlexAlign.Center)
                .align(Alignment.Center)
                .height(50)
                .width('100%')
                .stateStyles({
                    pressed: {
                        .backgroundColor('#E5E5E5')
                    },
                    normal: {
                        .backgroundColor(Color.White)
                    }
                })
                .onClick(() => {
                    sheet.action()
                    this.controller.close()
                })
            }, (sheet: SheetInfo, index: number) => index + '')

        }
        // .padding({ top: 10, bottom: 10 })
        .width('100%')
        .backgroundColor(Color.White)

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

        // dialog默认的borderRadius为24vp，如果需要使用border属性，请和borderRadius属性一起使用。
    }
}
