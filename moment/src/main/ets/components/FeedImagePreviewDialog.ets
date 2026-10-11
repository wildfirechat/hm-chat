import { FeedEntry } from '../model/MomentModel';
import { curves, display } from '@kit.ArkUI';
import { trustedMediaSrc } from '@wfc/uikit/src/main/ets/util/trustedMedia'

@CustomDialog
export struct FeedImagePreviewDialog {
    controller?: CustomDialogController;
    @Link images: FeedEntry[];
    @Link index: number;

    @State bgColor: string = '#000000';
    @State marginTop: number = 0;
    @State currentScale: number = 1.0;
    // 双指缩放倍率（1~5），与下滑手势的 currentScale 叠加
    @State pinchScale: number = 1.0;
    // 放大后的平移偏移（vp），未放大时恒为 0
    @State translateX: number = 0;
    @State translateY: number = 0;
    // 每张原图的加载完成标记（加载中显示缩略图兜底 + 转圈）
    @State loadedFlags: boolean[] = [];
    private basePinchScale: number = 1.0;
    private lastTranslateX: number = 0;
    private lastTranslateY: number = 0;
    // 放大拖到边缘后超出的水平位移（vp），用于松手判定翻页
    private edgeOverflowX: number = 0;
    private swiperController: SwiperController = new SwiperController();
    private displayHeight: number = 0;
    private displayWidth: number = 0;

    private static readonly MAX_PINCH_SCALE: number = 5;
    // 双击放大的目标倍率
    private static readonly DOUBLE_TAP_SCALE: number = 2.5;
    // 松手时超出边缘超过该位移（vp）则翻到上一张/下一张
    private static readonly EDGE_FLIP_THRESHOLD: number = 50;
    // 超出边缘部分的阻尼系数（橡皮筋效果）
    private static readonly EDGE_DAMPING: number = 0.35;

    aboutToAppear() {
        let _display = display.getDefaultDisplaySync();
        this.displayHeight = _display.height;
        this.displayWidth = _display.width;
        this.loadedFlags = this.images.map(() => false)
    }

    private isZoomed(): boolean {
        return this.pinchScale > 1
    }

    // 放大时把平移限制在图片放大后超出屏幕的范围内
    private clampTranslate(x: number, y: number): number[] {
        let maxX = px2vp((this.pinchScale - 1) * this.displayWidth / 2)
        let maxY = px2vp((this.pinchScale - 1) * this.displayHeight / 2)
        return [Math.max(-maxX, Math.min(maxX, x)), Math.max(-maxY, Math.min(maxY, y))]
    }

    private resetTransform() {
        this.pinchScale = 1.0
        this.basePinchScale = 1.0
        this.translateX = 0
        this.translateY = 0
        this.lastTranslateX = 0
        this.lastTranslateY = 0
    }

    private isLoaded(idx: number): boolean {
        return idx < this.loadedFlags.length && this.loadedFlags[idx]
    }

    private markLoaded(idx: number) {
        if (idx < this.loadedFlags.length && !this.loadedFlags[idx]) {
            let flags = this.loadedFlags.slice()
            flags[idx] = true
            this.loadedFlags = flags
        }
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

    // 放大状态下的拖动：范围内平移图片；超出边缘的部分加阻尼（橡皮筋），
    // 记录超出量供松手时判定是否翻页
    onZoomedPanUpdate(event: GestureEvent) {
        let rawX = this.lastTranslateX + event.offsetX
        let rawY = this.lastTranslateY + event.offsetY
        let r = this.clampTranslate(rawX, rawY)
        let overflowX = rawX - r[0]
        this.edgeOverflowX = overflowX
        this.translateX = r[0] + overflowX * FeedImagePreviewDialog.EDGE_DAMPING
        this.translateY = r[1]
    }

    // 放大状态松手：超出边缘超过阈值且该方向还有图，则翻页；否则回弹到边缘
    onZoomedPanEnd() {
        let over = this.edgeOverflowX
        this.edgeOverflowX = 0
        if (over < -FeedImagePreviewDialog.EDGE_FLIP_THRESHOLD && this.index < this.images.length - 1) {
            this.resetTransform()
            this.swiperController.showNext()
            return
        }
        if (over > FeedImagePreviewDialog.EDGE_FLIP_THRESHOLD && this.index > 0) {
            this.resetTransform()
            this.swiperController.showPrevious()
            return
        }
        let r = this.clampTranslate(this.translateX, this.translateY)
        animateTo({ curve: curves.responsiveSpringMotion() }, () => {
            this.translateX = r[0]
            this.translateY = r[1]
        })
        this.lastTranslateX = r[0]
        this.lastTranslateY = r[1]
    }

    build() {
        Stack() {
            Swiper(this.swiperController) {
                ForEach(this.images, (entry: FeedEntry, idx: number) => {
                    Stack() {
                        // 缩略图兜底：原图未加载完成时先显示九宫格里的缩略图
                        if (entry.thumbUrl) {
                            Image(trustedMediaSrc(entry.thumbUrl))
                                .objectFit(ImageFit.Contain)
                                .width('100%')
                                .height('100%')
                                .draggable(false)
                        }
                        // 原图加载完成前透明，完成后淡入
                        Image(trustedMediaSrc(entry.mediaUrl))
                            .objectFit(ImageFit.Contain)
                            .width('100%')
                            .height('100%')
                            .opacity(this.isLoaded(idx) ? 1 : 0)
                            .animation({ duration: 200, curve: Curve.EaseOut })
                            .onComplete(() => this.markLoaded(idx))
                            .onError(() => this.markLoaded(idx))
                            .draggable(false)
                        // 加载进度指示
                        if (!this.isLoaded(idx)) {
                            LoadingProgress()
                                .width(48)
                                .height(48)
                                .color(Color.White)
                        }
                    }
                    .margin({ top: this.marginTop })
                    .width('100%')
                    .height('100%')
                    .scale({
                        x: this.currentScale * this.pinchScale,
                        y: this.currentScale * this.pinchScale,
                        centerX: '50%',
                        centerY: '50%'
                    })
                    .translate({ x: this.translateX, y: this.translateY })
                    // 所有手势收进一个 Exclusive 组，与消息图片预览（MMMessagePreviewDialog）同款：
                    // 双击复位 / 单击关闭 / 双指缩放 / 下滑关闭；水平滑动留给 Swiper 翻页；
                    // 放大后单指全方向拖动查看图片内容
                    .gesture(
                        GestureGroup(GestureMode.Exclusive,
                            TapGesture({ count: 2 })
                                .onAction(() => {
                                    animateTo({ curve: Curve.EaseOut, duration: 200 }, () => {
                                        if (this.isZoomed()) {
                                            this.resetTransform()
                                        } else {
                                            this.pinchScale = FeedImagePreviewDialog.DOUBLE_TAP_SCALE
                                            this.basePinchScale = this.pinchScale
                                        }
                                    });
                                }),
                            TapGesture({ count: 1 })
                                .onAction(() => {
                                    this.controller?.close();
                                }),
                            PinchGesture()
                                .onActionStart(() => {
                                    this.basePinchScale = this.pinchScale;
                                })
                                .onActionUpdate((event: GestureEvent) => {
                                    let scale = this.basePinchScale * event.scale;
                                    this.pinchScale = Math.max(1, Math.min(FeedImagePreviewDialog.MAX_PINCH_SCALE, scale));
                                })
                                .onActionEnd(() => {
                                    this.basePinchScale = this.pinchScale;
                                    if (!this.isZoomed()) {
                                        this.translateX = 0
                                        this.translateY = 0
                                        this.lastTranslateX = 0
                                        this.lastTranslateY = 0
                                    }
                                }),
                            PanGesture({ direction: this.isZoomed() ? PanDirection.All : PanDirection.Down })
                                .onActionStart(() => {})
                                .onActionUpdate((event: GestureEvent) => {
                                    if (this.isZoomed()) {
                                        this.onZoomedPanUpdate(event)
                                    } else {
                                        this.onActionUpdate(event)
                                    }
                                })
                                .onActionEnd(() => {
                                    if (this.isZoomed()) {
                                        this.onZoomedPanEnd()
                                    } else {
                                        this.onActionEnd()
                                    }
                                })
                        )
                    )
                }, (entry: FeedEntry, idx: number) => entry.mediaUrl + idx)
            }
            .indicator(false)
            .vertical(false)
            .index(this.index)
            .loop(false)
            // 放大状态下禁止 Swiper 翻页，避免缩放后误触翻页
            .disableSwipe(this.pinchScale > 1)
            .clip(false)
            .onChange((index: number) => {
                this.index = index;
                this.resetTransform()
            })
        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .height('100%')
        .width('100%')
        .backgroundColor(this.bgColor)
    }
}
