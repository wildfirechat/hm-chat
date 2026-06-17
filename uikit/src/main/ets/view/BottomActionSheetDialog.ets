@Preview
@CustomDialog
export default struct BottomActionSheetDialog {
    // 标题，可选。为空字符串时不显示标题
    title: string = ''
    sheets: SheetInfo[] = []
    // 取消项，可选。不传时使用默认的“取消”，点击仅关闭弹窗
    cancel?: SheetInfo
    // 关闭弹窗的回调，使用方传入 () => { xxxController.close() }
    dismiss?: () => void
    // @CustomDialog 要求必须包含一个 CustomDialogController 类型的属性，这里仅用于满足该约束
    controller?: CustomDialogController
    // 底部安全区高度 + 间距
    private bottomInset: number = 8
    // 默认取消项
    private fallbackCancel: SheetInfo = {
        title: '取消', action: () => {
        }
    }

    aboutToAppear(): void {
        let safeBottom = AppStorage.get<number>('SafeAreaBottomHeight') ?? 0
        this.bottomInset = px2vp(safeBottom) + 8
    }

    @Builder
    itemRow(item: SheetInfo, onClick: () => void) {
        Row() {
            if (item.icon) {
                Image(item.icon)
                    .width(22)
                    .height(22)
                    .objectFit(ImageFit.Contain)
                    .margin({ right: 8 })
            }
            Text(item.title)
                .fontSize(16)
                .fontColor($r('app.color.wf_primary_text'))
                .textAlign(TextAlign.Center)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(54)
        .stateStyles({
            pressed: {
                .backgroundColor($r('app.color.wf_item_pressed'))
            },
            normal: {
                .backgroundColor($r('app.color.wf_background'))
            }
        })
        .onClick(onClick)
    }

    build() {
        Column() {
            // 标题 + 选项列表
            Column() {
                if (this.title) {
                    Text(this.title)
                        .fontSize(13)
                        .fontColor($r('app.color.wf_secondary_text'))
                        .textAlign(TextAlign.Center)
                        .width('100%')
                        .padding({
                            top: 18,
                            bottom: 18,
                            left: 16,
                            right: 16
                        })
                    Divider()
                        .color($r('app.color.wf_divider'))
                        .width('100%')
                }

                ForEach(this.sheets, (sheet: SheetInfo, index: number) => {
                    this.itemRow(sheet, () => {
                        this.dismiss?.()
                        sheet.action()
                    })
                    if (index < this.sheets.length - 1) {
                        Divider()
                            .color($r('app.color.wf_divider'))
                            .width('100%')
                    }
                }, (sheet: SheetInfo, index: number) => index + '')
            }
            .width('100%')
            .backgroundColor($r('app.color.wf_background'))

            Row()
                .width('100%')
                .backgroundColor($r('app.color.wf_secondary_background'))
                .height(8)

            // 取消项（默认显示，位于最下方，与上面分隔）
            Column() {
                Text('取消')
                    .fontSize(16)
                    .height(54)
                    .fontColor($r('app.color.wf_primary_text'))
                    .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ bottom: 32 })
            .stateStyles({
                pressed: {
                    .backgroundColor($r('app.color.wf_item_pressed'))
                },
                normal: {
                    .backgroundColor($r('app.color.wf_background'))
                }
            })
            .onClick(() => {
                this.dismiss?.()
                this.cancel?.action()
            })
        }
        .width('100%')
        .clip(true)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM)
            .animation({ duration: 250, curve: Curve.Friction }))
    }
}
