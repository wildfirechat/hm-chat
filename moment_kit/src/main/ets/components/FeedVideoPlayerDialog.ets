@CustomDialog
export struct FeedVideoPlayerDialog {
    controller?: CustomDialogController;
    @Link videoUrl: string;
    @Link thumbUrl: string;

    private videoController: VideoController = new VideoController();

    build() {
        Stack({ alignContent: Alignment.TopEnd }) {
            Video({
                src: this.videoUrl,
                previewUri: this.thumbUrl,
                controller: this.videoController
            })
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Contain)
                .autoPlay(true)
                .controls(true)
                .onClick(() => {})

            // 关闭按钮
            Button() {
                SymbolGlyph($r('sys.symbol.xmark'))
                    .fontSize(18)
                    .fontColor([Color.White])
            }
            .width(36)
            .height(36)
            .type(ButtonType.Circle)
            .backgroundColor('rgba(0,0,0,0.45)')
            .margin({ top: 16, right: 16 })
            .onClick(() => {
                this.videoController.stop();
                this.controller?.close();
            })
        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
    }
}
