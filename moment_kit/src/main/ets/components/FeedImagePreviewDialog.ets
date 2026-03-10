import { FeedEntry } from '@wfc/moment_client';
import { curves, display } from '@kit.ArkUI';

@CustomDialog
export struct FeedImagePreviewDialog {
    controller?: CustomDialogController;
    @Link images: FeedEntry[];
    @Link index: number;
    
    @State bgColor: string = '#000000';
    @State marginTop: number = 0;
    @State currentScale: number = 1.0;
    private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Down });
    private displayHeight: number = 0;

    aboutToAppear() {
        let _display = display.getDefaultDisplaySync();
        this.displayHeight = _display.height;
    }

    onActionUpdate(event: GestureEvent) {
        if (event.offsetY > 0) {
            let ratio = vp2px(event.offsetY) / this.displayHeight;
            let alpha = Math.ceil((1 - ratio) * 255);
            this.bgColor = `#${alpha.toString(16).padStart(2, '0')}000000`;
            this.marginTop = event.offsetY;
            this.currentScale = 1 - ratio * 1.2;
        }
    }

    onActionEnd() {
        animateTo({ curve: curves.responsiveSpringMotion() }, () => {
            if (vp2px(this.marginTop) > this.displayHeight * 0.15) {
                this.bgColor = '#00000000';
                this.marginTop = this.displayHeight;
                this.currentScale = 0.2;
                this.controller?.close();
            } else {
                this.bgColor = '#000000';
                this.marginTop = 0;
                this.currentScale = 1.0;
            }
        });
    }

    build() {
        Stack() {
            Swiper() {
                ForEach(this.images, (entry: FeedEntry, idx: number) => {
                    Image(entry.mediaUrl)
                        .alt(entry.thumbUrl)
                        .objectFit(ImageFit.Contain)
                        .margin({ top: this.marginTop })
                        .width('100%')
                        .height('100%')
                        .scale({ x: this.currentScale, y: this.currentScale, centerX: '50%', centerY: '50%' })
                        .draggable(true)
                        .gesture(
                            PanGesture(this.panOption)
                                .onActionStart(() => {})
                                .onActionUpdate((event: GestureEvent) => this.onActionUpdate(event))
                                .onActionEnd(() => this.onActionEnd())
                        )
                }, (entry: FeedEntry, idx: number) => entry.mediaUrl + idx)
            }
            .indicator(false)
            .vertical(false)
            .index(this.index)
            .loop(false)
            .clip(false)
            .onChange((index: number) => {
                this.index = index;
            })
            .onClick(() => {
                this.controller?.close();
            })
        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .height('100%')
        .width('100%')
        .backgroundColor(this.bgColor)
    }
}
