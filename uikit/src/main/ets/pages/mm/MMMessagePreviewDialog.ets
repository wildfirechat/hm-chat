import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent';
import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType';
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent';
import { exist } from '../../common/utils/FileUtil';
import { curves, display, matrix4, window } from '@kit.ArkUI';
import { MMMediaEntry } from '../../common/Types';
import { mediaEntry } from '../../helper/messageHelper';
import resourceManager from '@ohos.resourceManager';
import { saveMedia } from '../../helper/mediaHelper';
import { showToast } from '../../common/utils/Toast';
import { stringValue } from '@wfc/client/src/main/ets/wfc/util/longUtil';
import { mediaMessagePositionRegistry, MediaThumbRect } from '../../helper/mediaMessagePositionRegistry';

interface SizeVp {
    cw: number
    ch: number
}

const MAX_ZOOM_SCALE: number = 4
const DOUBLE_TAP_ZOOM_SCALE: number = 2.5

@CustomDialog
export default struct MMMessagePreviewDialog {
    // 预览组合消息里面的媒体消息时，直接设置 mediaEntries，不设置 message
    @State mediaEntries: MMMediaEntry[] = []
    // 预览会话里面的媒体消息时设置
    public message?: Message
    @State index: number = 0
    @State bgColor: string = '#000000'
    // 渲染用的统一变换矩阵：screen(P) = scaleValue * P + (translateX, translateY)（缩放中心为左上角原点）
    @State matrix: matrix4.Matrix4Transit = matrix4.identity().copy()
    // 缩放系数，用 @State 是因为它驱动 Swiper.disableSwipe 与 PanGesture 方向
    @State scaleValue: number = 1.0
    @State isDragging: boolean = false
    @State isClosing: boolean = false
    private translateX: number = 0
    private translateY: number = 0
    // 缩放/拖动交互暂存值
    private lastScale: number = 1.0
    private lastTranslateX: number = 0
    private lastTranslateY: number = 0
    // 捏合开始时位于双指中心下方的内容点（缩放不变的基准点，vp，scale=1 坐标系）
    private pivotX: number = 0
    private pivotY: number = 0
    // 拖拽返回时手指按下的位置（vp，相对屏幕左上角）
    private grabX: number = 0
    private grabY: number = 0
    private dragDownDist: number = 0
    private isLoadingOldMessage: boolean = false
    private isLoadingNewMessage: boolean = false
    private displayHeight: number = 0
    private displayWidth: number = 0
    private screenWvp: number = 0
    private screenHvp: number = 0
    controller: CustomDialogController
    @State showVideoPlayIcon: boolean = false
    // 是否已挂载 Video（点过播放）。未挂载时用缩略图显示，避免 Video 封面的黑色 letterbox
    @State videoMounted: boolean = false
    private isVideoPlaying = false

    async aboutToAppear() {
        if (this.mediaEntries.length === 0) {
            this.mediaEntries = [this.message!].map(msg => mediaEntry(msg))
            let oldMsgs = await this.loadMoreMessages(this.message!, true)
            let newMsgs = await this.loadMoreMessages(this.message!, false)
            this.mediaEntries = oldMsgs.map(msg => mediaEntry(msg))
                .concat(this.mediaEntries, newMsgs.map(msg => mediaEntry(msg)))
            this.index = oldMsgs.length
        }

        let _display = display.getDefaultDisplaySync()
        this.displayHeight = _display.height;
        this.displayWidth = _display.width;
        this.screenWvp = px2vp(this.displayWidth)
        this.screenHvp = px2vp(this.displayHeight)

        let entry = this.mediaEntries[this.index];
        this.showVideoPlayIcon = entry.type === 'video'
    }

    loadMoreMessages(message: Message, before: boolean): Promise<Message[]> {
        return new Promise((resolve, reject) => {
            wfc.getMessagesByTimestampV2(message.conversation, [MessageContentType.Image, MessageContentType.Video], message.timestamp, before, 5, '', (msgs: Message[]) => {
                resolve(msgs)
            }, (err: number) => {
                resolve([])
            })
        })
    }

    onBackPress(): boolean | void {
        return true
    }

    isImageMessageContent(message: Message) {
        return message.messageContent.type === MessageContentType.Image
    }

    isZoomed(): boolean {
        return this.scaleValue > 1.001
    }

    // 根据当前的 scaleValue / translateX / translateY 重建渲染矩阵
    // matrix4 链式调用是前乘：先 scale 再 translate 才能得到 screen = s*P + t
    // 注意：matrix4.translate 单位是 px，内部计算用 vp，这里转换
    applyMatrix(): void {
        this.matrix = matrix4.identity()
            .scale({ x: this.scaleValue, y: this.scaleValue, centerX: 0, centerY: 0 })
            .translate({ x: vp2px(this.translateX), y: vp2px(this.translateY) })
            .copy()
    }

    // 切换图片或回弹时重置所有变换
    resetTransform(): void {
        this.scaleValue = 1.0
        this.lastScale = 1.0
        this.translateX = 0
        this.translateY = 0
        this.lastTranslateX = 0
        this.lastTranslateY = 0
        this.bgColor = '#000000'
        this.applyMatrix()
    }

    // 当前图片按 Contain 显示后的内容区尺寸（vp）
    contentSize(): SizeVp {
        let entry = this.mediaEntries[this.index]
        let rect = entry ? mediaMessagePositionRegistry.get(stringValue(entry.message.messageUid)) : undefined
        let aspect = rect && rect.height > 0 ? rect.width / rect.height : this.screenWvp / this.screenHvp
        let cw = this.screenWvp
        let ch = this.screenHvp
        if (aspect > this.screenWvp / this.screenHvp) {
            cw = this.screenWvp
            ch = this.screenWvp / aspect
        } else {
            ch = this.screenHvp
            cw = this.screenHvp * aspect
        }
        return { cw: cw, ch: ch }
    }

    fingerPos(event: GestureEvent): number[] {
        if (event.fingerList && event.fingerList.length > 0 && event.fingerList[0]) {
            return [event.fingerList[0].localX, event.fingerList[0].localY]
        }
        return [this.grabX + event.offsetX, this.grabY + event.offsetY]
    }

    // ============ 拖拽返回（默认大小下） ============

    handleDragStart(event: GestureEvent) {
        this.isDragging = true
        let p = this.fingerPos(event)
        this.grabX = p[0]
        this.grabY = p[1]
        this.dragDownDist = 0
    }

    handleDragUpdate(event: GestureEvent) {
        let p = this.fingerPos(event)
        let fx = p[0]
        let fy = p[1]
        this.dragDownDist = fy - this.grabY
        if (this.dragDownDist < 0) {
            this.dragDownDist = 0
        }
        let ratio = this.dragDownDist / this.screenHvp
        let alpha = Math.max(0, Math.ceil((1 - ratio) * 255))
        this.bgColor = `#${alpha.toString(16).padStart(2, '0')}000000`
        // 把手指按下处的内容点钉在当前手指位置，图片朝手指方向缩小
        this.scaleValue = Math.max(0.3, 1 - ratio)
        this.translateX = fx - this.scaleValue * this.grabX
        this.translateY = fy - this.scaleValue * this.grabY
        this.applyMatrix()
    }

    handleDragEnd() {
        this.isDragging = false
        if (this.dragDownDist > this.screenHvp * 0.15) {
            this.dismissToThumbnail()
        } else {
            animateTo({ curve: curves.responsiveSpringMotion() }, () => {
                this.resetTransform()
            })
        }
    }

    dismissToThumbnail() {
        this.isClosing = true
        let entry = this.mediaEntries[this.index]
        let rect = entry ? mediaMessagePositionRegistry.get(stringValue(entry.message.messageUid)) : undefined
        if (rect && rect.width > 0) {
            // 缩放并消失到当前图片对应的缩略图位置
            let size = this.contentSize()
            let targetScale = size.cw > 0 ? rect.width / size.cw : 0.2
            let thumbCenterX = rect.x + rect.width / 2
            let thumbCenterY = rect.y + rect.height / 2
            // 内容中心即屏幕中心，令其落在缩略图中心：s * C + t = thumbCenter
            this.scaleValue = targetScale
            this.translateX = thumbCenterX - targetScale * (this.screenWvp / 2)
            this.translateY = thumbCenterY - targetScale * (this.screenHvp / 2)
            animateTo({
                duration: 250,
                curve: Curve.EaseOut,
                onFinish: () => {
                    this.controller.close()
                }
            }, () => {
                this.bgColor = '#00000000'
                this.applyMatrix()
            })
        } else {
            // 找不到缩略图位置（已滚出屏幕）时，回退为向下滑出关闭
            this.scaleValue = 0.3
            this.translateX = (this.screenWvp / 2) * (1 - 0.3)
            this.translateY = this.screenHvp
            animateTo({
                curve: curves.responsiveSpringMotion(),
                onFinish: () => {
                    this.controller.close()
                }
            }, () => {
                this.bgColor = '#00000000'
                this.applyMatrix()
            })
        }
    }

    // ============ 缩放 zoom-in/zoom-out ============

    zoomAboutCenter(scale: number) {
        // 绕屏幕中心缩放：s * C + t = C  =>  t = C * (1 - s)
        this.scaleValue = scale
        this.translateX = (this.screenWvp / 2) * (1 - scale)
        this.translateY = (this.screenHvp / 2) * (1 - scale)
    }

    onPinchStart(event: GestureEvent) {
        this.lastScale = this.scaleValue
        // 反解出当前位于双指中心下方的内容点：screen = s*P + t  =>  P = (center - t) / s
        this.pivotX = (event.pinchCenterX - this.translateX) / this.scaleValue
        this.pivotY = (event.pinchCenterY - this.translateY) / this.scaleValue
    }

    onPinchUpdate(event: GestureEvent) {
        let s = this.lastScale * event.scale
        s = Math.min(Math.max(s, 0.5), MAX_ZOOM_SCALE)
        // 以双指中心为基准缩放：保持 pivot 点始终落在当前双指中心下方
        // screen = s*pivot + t = center  =>  t = center - s*pivot
        this.scaleValue = s
        this.translateX = event.pinchCenterX - s * this.pivotX
        this.translateY = event.pinchCenterY - s * this.pivotY
        this.applyMatrix()
    }

    onPinchEnd() {
        if (this.scaleValue < 1) {
            animateTo({ curve: curves.responsiveSpringMotion() }, () => {
                this.resetTransform()
            })
        } else {
            // 缩放结束后把位移收回边界内，避免出现黑边
            animateTo({ curve: curves.responsiveSpringMotion() }, () => {
                this.clampToBounds()
                this.applyMatrix()
            })
        }
        this.lastScale = this.scaleValue
        this.lastTranslateX = this.translateX
        this.lastTranslateY = this.translateY
    }

    onDoubleTap() {
        animateTo({ curve: curves.responsiveSpringMotion() }, () => {
            if (this.isZoomed()) {
                this.resetTransform()
            } else {
                this.zoomAboutCenter(DOUBLE_TAP_ZOOM_SCALE)
                this.lastScale = this.scaleValue
                this.lastTranslateX = this.translateX
                this.lastTranslateY = this.translateY
                this.applyMatrix()
            }
        })
    }

    // ============ 放大状态下拖动图片 ============

    onMoveUpdate(event: GestureEvent) {
        // 手势偏移量是组件缩放(transform)前的局部坐标，被缩放比 s 缩小了 s 倍；
        // 这里乘回 scaleValue 换算成屏幕位移，保证拖动 1:1 跟手（否则放大后拖动很慢）
        this.translateX = this.lastTranslateX + event.offsetX * this.scaleValue
        this.translateY = this.lastTranslateY + event.offsetY * this.scaleValue
        this.applyMatrix()
    }

    // 把当前位移限制在边界内，保证缩放后内容区不出现黑边
    clampToBounds() {
        let size = this.contentSize()
        let s = this.scaleValue
        let lowerX = this.screenWvp - s * (this.screenWvp + size.cw) / 2
        let upperX = -s * (this.screenWvp - size.cw) / 2
        let lowerY = this.screenHvp - s * (this.screenHvp + size.ch) / 2
        let upperY = -s * (this.screenHvp - size.ch) / 2
        this.translateX = this.clamp(this.translateX, lowerX, upperX)
        this.translateY = this.clamp(this.translateY, lowerY, upperY)
    }

    onMoveEnd() {
        animateTo({ curve: curves.responsiveSpringMotion() }, () => {
            this.clampToBounds()
            this.applyMatrix()
        })
        this.lastTranslateX = this.translateX
        this.lastTranslateY = this.translateY
    }

    clamp(v: number, lower: number, upper: number): number {
        if (lower > upper) {
            return (lower + upper) / 2
        }
        if (v < lower) {
            return lower
        }
        if (v > upper) {
            return upper
        }
        return v
    }

    build() {
        Stack() {
            Swiper() {
                ForEach(this.mediaEntries, (entry: MMMediaEntry, index: number) => {
                    if (entry.type === 'image') {
                        Image(entry.url)
                            .alt(entry.thumbnail)
                            .objectFit(ImageFit.Contain)
                            .width('100%')
                            .height('100%')
                            // 让 transform 矩阵以组件左上角为变换原点（与矩阵计算保持一致）
                            .scale({ centerX: 0, centerY: 0, x: 1 })
                            .transform(this.matrix)
                            .draggable(false)
                            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                            .gesture(
                                GestureGroup(GestureMode.Exclusive,
                                    TapGesture({ count: 2 })
                                        .onAction(() => {
                                            this.onDoubleTap()
                                        }),
                                    PinchGesture({ fingers: 2, distance: 1 })
                                        .onActionStart((event: GestureEvent) => {
                                            this.onPinchStart(event)
                                        })
                                        .onActionUpdate((event: GestureEvent) => {
                                            this.onPinchUpdate(event)
                                        })
                                        .onActionEnd(() => {
                                            this.onPinchEnd()
                                        }),
                                    // 放大时全方向拖动图片；默认大小时仅向下拖动触发返回，水平方向交给 Swiper 翻页
                                    PanGesture({ fingers: 1, direction: this.isZoomed() ? PanDirection.All : PanDirection.Down })
                                        .onActionStart((event: GestureEvent) => {
                                            if (!this.isZoomed()) {
                                                this.handleDragStart(event)
                                            }
                                        })
                                        .onActionUpdate((event: GestureEvent) => {
                                            if (this.isZoomed()) {
                                                this.onMoveUpdate(event)
                                            } else {
                                                this.handleDragUpdate(event)
                                            }
                                        })
                                        .onActionEnd(() => {
                                            if (this.isZoomed()) {
                                                this.onMoveEnd()
                                            } else {
                                                this.handleDragEnd()
                                            }
                                        })
                                )
                            )
                    } else {
                        // 把矩阵变换加在包裹容器上（整层一起合成，视频 surface 跟随缩放），
                        // Video 背景设为透明，避免黑色背板不跟随缩小变淡；拖拽过程中视频继续播放
                        Stack() {
                            if (this.videoMounted && index === this.index) {
                                Video({
                                    previewUri: entry.thumbnail,
                                    src: entry.url,
                                    controller: entry.videoController
                                })
                                    .autoPlay(true)
                                    .controls(false)
                                    .objectFit(ImageFit.Contain)
                                    .width('100%')
                                    .height('100%')
                                    .backgroundColor(Color.Transparent)
                                    .draggable(false)
                                    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                                    .onFinish(() => {
                                        this.showVideoPlayIcon = true
                                        this.isVideoPlaying = false
                                    })
                                    .onStart(() => {
                                        this.showVideoPlayIcon = false
                                    })
                                    .onPause(() => {
                                        this.showVideoPlayIcon = true
                                        this.isVideoPlaying = false
                                    })
                                    .onClick(() => {
                                        if (!this.showVideoPlayIcon) {
                                            entry.videoController?.pause()
                                        }
                                    })
                            } else {
                                // 未播放时用缩略图（透明 letterbox），拖拽缩小无黑边
                                Image(entry.thumbnail)
                                    .objectFit(ImageFit.Contain)
                                    .width('100%')
                                    .height('100%')
                                    .draggable(false)
                                    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                            }
                        }
                        .width('100%')
                        .height('100%')
                        .scale({ centerX: 0, centerY: 0, x: 1 })
                        .transform(this.matrix)
                        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                        .gesture(
                            PanGesture({ fingers: 1, direction: PanDirection.Down })
                                .onActionStart((event: GestureEvent) => {
                                    this.handleDragStart(event)
                                })
                                .onActionUpdate((event: GestureEvent) => {
                                    this.handleDragUpdate(event)
                                })
                                .onActionEnd(() => {
                                    this.handleDragEnd()
                                })
                        )
                    }
                }, (entry: MMMediaEntry) => entry.message.messageId + '')
            }
            .indicator(false)
            .vertical(false)
            .index(this.index)
            .loop(false)
            // 放大状态下禁止 Swiper 翻页，把拖动交给图片移动
            .disableSwipe(this.isZoomed())
            // 关闭Swiper组件默认的裁切效果以便子节点可以绘制在Swiper外。
            .clip(false)
            .cachedCount(3)
            .onChange((index: number) => {
                let entry = this.mediaEntries[this.index];
                if (entry.type === 'video') {
                    entry.videoController?.stop()
                    entry.videoController?.reset()
                    this.isVideoPlaying = false
                }
                // 离开当前页时卸载 Video，回到缩略图状态
                this.videoMounted = false
                this.index = index
                // 切换图片时重置缩放/位移
                this.resetTransform()
                entry = this.mediaEntries[index];
                if (entry.type === 'video') {
                    this.showVideoPlayIcon = true;
                } else {
                    this.showVideoPlayIcon = false
                }
                if (this.message) {
                    if (index < 3) {
                        if (this.isLoadingOldMessage) {
                            return
                        }
                        this.isLoadingOldMessage = true
                        this.loadMoreMessages(this.mediaEntries[0].message, true)
                            .then((msgs: Message[]) => {
                                this.index = msgs.length + this.index
                                this.mediaEntries = msgs.map(msg => mediaEntry(msg)).concat(this.mediaEntries)
                                this.isLoadingOldMessage = false
                            })
                    } else if (index > this.mediaEntries.length - 3) {
                        if (this.isLoadingNewMessage) {
                            return
                        }
                        this.isLoadingNewMessage = true
                        this.loadMoreMessages(this.mediaEntries[this.mediaEntries.length - 1].message, false)
                            .then((msgs: Message[]) => {
                                this.mediaEntries = this.mediaEntries.concat(msgs.map(msg => mediaEntry(msg)))
                                this.isLoadingNewMessage = false
                            })

                    }
                }
            })
            .onGestureSwipe(index => {
                this.showVideoPlayIcon = false
            })
            .onAnimationEnd(index => {
                let entry = this.mediaEntries[index];
                if (!this.isVideoPlaying && entry.type === 'video') {
                    this.showVideoPlayIcon = true
                }
            })

            if (this.showVideoPlayIcon && !this.isDragging && !this.isClosing) {
                Column() {
                    Image($r('app.media.img_video_play_session'))
                        .width(40)
                        .height(40)
                        .onClick(() => {
                            let entry = this.mediaEntries[this.index];
                            if (this.videoMounted) {
                                // 已挂载（暂停态）直接恢复播放
                                entry.videoController?.start()
                            } else {
                                // 首次播放：挂载 Video，autoPlay 自动开始
                                this.videoMounted = true
                            }
                            this.showVideoPlayIcon = false
                            this.isVideoPlaying = true
                        })
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .width('100%')
                .height('100%')
                .hitTestBehavior(HitTestMode.Transparent)
                .scale({ centerX: 0, centerY: 0, x: 1 })
                .transform(this.matrix)
            }

            // 拖拽/关闭过程中隐藏下载按钮
            if (!this.isDragging && !this.isClosing) {
                Column() {
                    SaveButton()
                        .onClick(() => {
                            showToast('正在保存...')
                            let entry = this.mediaEntries[this.index];
                            saveMedia(getContext(this), entry.message.messageUid, entry.url, entry.type)
                        })
                }
                .hitTestBehavior(HitTestMode.Transparent)
                .justifyContent(FlexAlign.End)
                .alignItems(HorizontalAlign.End)
                .width('100%')
                .height('100%')
                .padding(12)
            }

        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .height('100%')
        .width('100%')
        .backgroundColor(this.bgColor)
    }
}
