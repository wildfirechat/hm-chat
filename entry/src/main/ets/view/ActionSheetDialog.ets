@Preview
@CustomDialog
export default struct ActionSheetDialog {
    title: string = ''
    cancel: string = ''
    sheets: SheetInfo[] = []
    // 若尝试在CustomDialog中传入多个其他的Controller，以实现在CustomDialog中打开另一个或另一些CustomDialog，那么此处需要将指向自己的controller放在最后
    controller: CustomDialogController

    build() {
        Column() {
            if (this.title) {
                Column() {
                    Text(this.title)
                        .fontSize(20)
                        .height(50)
                    Divider()
                        .width('90%')
                }
                .justifyContent(FlexAlign.Center)
                .align(Alignment.Center)
                .width('100%')
                .padding({ top: 5 })
            }

            Column() {
                ForEach(this.sheets, (sheet: SheetInfo) => {
                    Row() {
                        if (sheet.icon) {
                            Image(sheet.icon)
                                .width(20)
                                .height(20)
                        }
                        Text(sheet.title)
                            .padding(10)
                            .fontSize(15)
                            .textAlign(TextAlign.Center)
                    }
                    .justifyContent(FlexAlign.Center)
                    .align(Alignment.Center)
                    .height(50)
                    .width('90%')
                    .borderRadius(10)
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
            .padding(10)

            if (this.cancel) {
                Column() {
                    Divider()
                        .width('90%')
                    Text(this.cancel)
                        .fontColor(Color.Red)
                        .fontSize(15)
                        .height(40)
                        .width('90%')
                        .borderRadius(10)
                        .margin({ top: 10, bottom: 10 })
                        .textAlign(TextAlign.Center)
                        .stateStyles({
                            pressed: {
                                .backgroundColor('#E5E5E5')
                            },
                            normal: {
                                .backgroundColor(Color.White)
                            }
                        })
                        .onClick(() => {
                            this.controller.close()
                        })
                }
                .justifyContent(FlexAlign.Center)
                .align(Alignment.Center)
                .width('100%')
            }
        }
        // .padding({ top: 10, bottom: 10 })
        .width('100%')
        .backgroundColor(Color.White)

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

        // dialog默认的borderRadius为24vp，如果需要使用border属性，请和borderRadius属性一起使用。
    }
}
