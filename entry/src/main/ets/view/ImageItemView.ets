/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { image } from '@kit.ImageKit';
import { matrix4, window } from '@kit.ArkUI';
import { windowSizeManager } from '../util/windowSizeManager';
import { BusinessError } from '@kit.BasicServicesKit';

// TODO：知识点：组件复用
@Reusable
@Component
export struct ImageItemView {
    // @Consume private bgc: Color;
    @Link isEnableSwipe: boolean; // TODO：需求：多图切换
    @State isEnableOffset: boolean = false;
    @State imageScaleInfo: ScaleModel = new ScaleModel(1.0, 1.0, 1.5, 0.3);
    @State imageOffsetInfo: OffsetModel = new OffsetModel(0, 0);
    @State matrix: matrix4.Matrix4Transit = matrix4.identity().copy();
    @State imagePixelMap: image.PixelMap | null = null; // 当前图片pixelMap，用于Image组件显示
    @State fitWH: "width" | "height" | undefined = undefined; // 表示当前图片是根据宽度适配还是高度适配
    @State imageDefaultSize: image.Size = { width: 0, height: 0 }; // 图片默认大小，即，与屏幕大小最适配的显示大小
    imageUri: string = ""; // 当前图片uri
    imageWHRatio: number = 0; // 图片原始宽高比
    swiperController?: SwiperController

    aboutToAppear(): void {
        this.isEnableSwipe = true;
        this.initCurrentImageInfo();
    }

    /**
     * 根据图片宽高比及窗口大小计算图片的默认宽高，即，图片最适配屏幕的大小
     * @param imageWHRatio：图片原始宽高比
     * @param size：窗口大小{with:number,height:number}
     * @returns image.Size
     */
    calcImageDefaultSize(imageWHRatio: number, size: window.Size): image.Size {
        let width = 0
        let height = 0;
        if (imageWHRatio > size.width / size.height) {
            // 图片宽高比大于屏幕宽高比，图片默认以屏幕宽度进行显示
            width = size.width;
            height = size.width / imageWHRatio;
        } else {
            height = size.height;
            width = size.height * imageWHRatio;
        }
        return { width: width, height: height };
    }

    /**
     * TODO：知识点：根据图片大小（宽高<=屏幕宽高）和屏幕大小计算图片放大适配屏幕进行显示的缩放倍率
     * @param imageSize：图片当前大小
     * @param windowSize：窗口大小
     * @returns：缩放倍率
     */
    calcFitScaleRatio(imageSize: image.Size, windowSize: window.Size): number {
        let ratio: number = 1.0;
        if (windowSize.width > imageSize.width) {
            ratio = windowSize.width / imageSize.width;
        } else {
            ratio = windowSize.height / imageSize.height;
        }
        return ratio;
    }

    /**
     * 设置当前图片的相关信息：uri、whRatio、pixelMap、fitWH、defaultSize、maxScaleValue
     * TODO：知识点：提前获取图片的信息，以进行Image组件的尺寸设置及后续的相关计算
     */
    initCurrentImageInfo(): void {
        this.matrix = matrix4.identity().copy();
        const imageSource: image.ImageSource = image.createImageSource(this.imageUri);
        imageSource.getImageInfo(0).then((data: image.ImageInfo) => {
            this.imageWHRatio = data.size.width / data.size.height;
            this.imageDefaultSize = this.calcImageDefaultSize(this.imageWHRatio, windowSizeManager.get());
            if (this.imageDefaultSize.width === windowSizeManager.get().width) {
                this.fitWH = "width";
            } else {
                this.fitWH = "height";
            }
            this.imageScaleInfo.maxScaleValue += this.fitWH === "width" ?
                (windowSizeManager.get().height / this.imageDefaultSize.height) :
                (windowSizeManager.get().width / this.imageDefaultSize.width);
        }).catch((err: BusinessError) => {
            console.error(`[error][getImageInfo]${err.message}`);
        });
        imageSource.createPixelMap().then((data: image.PixelMap) => {
            this.imagePixelMap = data;
        }).catch((err: BusinessError) => {
            console.error(`[error][createPixelMap]${err.message}`);
        });
        this.isEnableOffset = false;
        this.imageScaleInfo.reset();
        this.imageOffsetInfo.reset();
    }

    /**
     * 在图片消失时，将当前图片的信息设置为默认值
     */
    resetCurrentImageInfo(): void {
        console.log('xxxxxxxxx reset')
        this.imageScaleInfo.reset();
        this.imageOffsetInfo.reset();
        this.matrix = matrix4.identity().copy();
    }

    /**
     * TODO：需求：在偏移时评估是否到达边界，以便进行位移限制与图片的切换
     * @returns：长度为4的boolean数组，表示上下左右是否到达边界
     */
    evaluateBound(): boolean[] {
        return [false, false, false, false];
    }

    aboutToDisappear(): void {
        this.resetCurrentImageInfo()
    }

    build() {
        Stack() {
            Image(this.imagePixelMap)// TODO：知识点：宽高只根据其尺寸设置一个，通过保持宽高比来设置另一个属性
                .width(this.fitWH === "width" ? '100%' : undefined)
                .height(this.fitWH === "height" ? '100%' : undefined)
                .aspectRatio(this.imageWHRatio)
                .objectFit(ImageFit.Cover)// TODO：知识点：保持宽高比进行缩放，可以超出父组件，以便实现多图切换的增强功能
                .autoResize(false)
                .transform(this.matrix)// TODO：知识点：通过matrix控制图片的缩放
                .defaultFocus(true)
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                .offset({
                    // TODO：知识点：通过offset控制图片的偏移
                    x: this.imageOffsetInfo.currentX,
                    y: this.imageOffsetInfo.currentY
                })
                .onTouch(() => {
                    console.log('xxxx image on touch')
                })
            // .hitTestBehavior(this.isEnableSwipe ? HitTestMode.Transparent: HitTestMode.Default)
        }
        .focusable(true)
        .onBlur(() => {
            this.resetCurrentImageInfo();
        })
        .onTouch(event => {
            console.log('xxxx stack on touch')
        })
        .hitTestBehavior(this.isEnableSwipe ? HitTestMode.Transparent : HitTestMode.Default)

        .gesture(
            GestureGroup(
                GestureMode.Exclusive,
                // TODO：知识点：双击切换图片大小
                TapGesture({ count: 2 })
                    .onAction(() => {
                        let fn: Function;
                        // 已经是放大状态下，双击缩小
                        if (this.imageScaleInfo.scaleValue > this.imageScaleInfo.defaultScaleValue) {
                            fn = () => {
                                this.isEnableSwipe = true;
                                this.imageScaleInfo.reset();
                                this.imageOffsetInfo.reset();
                                this.matrix = matrix4.identity().copy();
                            };
                        } else {
                            // 已经是缩小状态，双击放大
                            fn = () => {
                                this.isEnableSwipe = false;
                                let ratio: number = this.calcFitScaleRatio(this.imageDefaultSize, windowSizeManager.get());
                                ratio = ratio <= 1 ? 2 : ratio
                                this.imageScaleInfo.scaleValue = ratio;
                                this.imageOffsetInfo.reset();
                                this.matrix = matrix4.identity().scale({
                                    x: ratio,
                                    y: ratio,
                                }).copy();
                                this.imageScaleInfo.stash();
                            }
                        }
                        runWithAnimation(fn);
                    }),
                // 单击切换背景色
                // TapGesture({ count: 1 }).onAction(() => {
                //     runWithAnimation(() => {
                //         this.bgc = this.bgc === Color.White ? Color.Black : Color.White;
                //     });
                // }),
                // TODO：知识点：双指捏合缩放图片
                PinchGesture({ fingers: 2, distance: 1 })
                    .onActionUpdate((event: GestureEvent) => {
                        this.imageScaleInfo.scaleValue = this.imageScaleInfo.lastValue * event.scale;
                        // TODO：知识点：缩放时不允许大于最大缩放因子+额外缩放因子，不允许小于默认大小-额外缩放因子，额外缩放因子用于提升用户体验
                        if (this.imageScaleInfo.scaleValue > this.imageScaleInfo.maxScaleValue *
                            (1 + this.imageScaleInfo.extraScaleValue)
                        ) {
                            this.imageScaleInfo.scaleValue = this.imageScaleInfo.maxScaleValue *
                                (1 + this.imageScaleInfo.extraScaleValue);
                        }
                        if (this.imageScaleInfo.scaleValue < this.imageScaleInfo.defaultScaleValue *
                            (1 - this.imageScaleInfo.extraScaleValue)) {
                            this.imageScaleInfo.scaleValue = this.imageScaleInfo.defaultScaleValue *
                                (1 - this.imageScaleInfo.extraScaleValue);
                        }
                        // TODO：知识点：matrix默认缩放中心为组件中心
                        // if (this.imageScaleInfo.scaleValue > this.imageScaleInfo.lastValue) {
                        this.matrix = matrix4.identity().scale({
                            x: this.imageScaleInfo.scaleValue,
                            y: this.imageScaleInfo.scaleValue,
                        }).copy();
                        // } else {
                        //     console.log('xxxxxxxx pinch', this.imageScaleInfo.scaleValue, this.imageOffsetInfo.currentX, this.imageOffsetInfo.currentY, -(this.imageOffsetInfo.currentX - this.imageOffsetInfo.currentX * this.imageScaleInfo.scaleValue), -(this.imageOffsetInfo.currentY - this.imageOffsetInfo.currentY * this.imageScaleInfo.scaleValue))
                        //     let scaleX = this.imageOffsetInfo.currentX * (this.imageScaleInfo.lastValue - this.imageScaleInfo.scaleValue);
                        //     let translateX = scaleX < this.imageOffsetInfo.minX ? this.imageOffsetInfo.minX : scaleX;
                        //     translateX = scaleX > this.imageOffsetInfo.maxX ? this.imageOffsetInfo.maxX : scaleX;
                        //     let scaleY = this.imageOffsetInfo.currentY * (this.imageScaleInfo.lastValue - this.imageScaleInfo.scaleValue);
                        //     let translateY = scaleX < this.imageOffsetInfo.minY ? this.imageOffsetInfo.minY : scaleY;
                        //     translateY = scaleX > this.imageOffsetInfo.maxX ? this.imageOffsetInfo.maxY : scaleY;
                        //     this.matrix = matrix4.identity()
                        //         .scale({
                        //             x: this.imageScaleInfo.scaleValue,
                        //             y: this.imageScaleInfo.scaleValue,
                        //         })
                        //         .translate({
                        //             x: 100,
                        //             y: -300,
                        //
                        //         })
                        //         .copy();
                        // }
                        console.debug(this.imageScaleInfo.toString());
                    })
                    .onActionEnd((event: GestureEvent) => {
                        /**
                         * TODO：知识点：当小于默认大小时，恢复为默认大小
                         */
                        if (this.imageScaleInfo.scaleValue < this.imageScaleInfo.defaultScaleValue) {
                            runWithAnimation(() => {
                                this.imageScaleInfo.reset();
                                this.imageOffsetInfo.reset();
                                this.matrix = matrix4.identity().copy();
                            })
                        }
                        // TODO：知识点：当大于最大缩放因子时，恢复到最大
                        if (this.imageScaleInfo.scaleValue > this.imageScaleInfo.maxScaleValue) {
                            runWithAnimation(() => {
                                this.imageScaleInfo.scaleValue = this.imageScaleInfo.maxScaleValue;
                                this.matrix = matrix4.identity()
                                    .scale({
                                        x: this.imageScaleInfo.maxScaleValue,
                                        y: this.imageScaleInfo.maxScaleValue
                                    });
                            })
                        }
                        this.imageScaleInfo.stash();
                    }),
                // TODO：知识点：滑动图片
                PanGesture({ fingers: 1 })// TODO：需求：默认大小下左右滑动应当是切换图片
                    .onActionStart((event: GestureEvent) => {
                        if (this.imageScaleInfo.scaleValue === this.imageScaleInfo.defaultScaleValue) {
                            // 默认大小下不允许移动
                            this.isEnableSwipe = true;
                            return;
                        }

                        let iw = this.imageDefaultSize.width * this.imageScaleInfo.scaleValue
                        let ih = this.imageDefaultSize.height * this.imageScaleInfo.scaleValue;

                        let displaySize = windowSizeManager.get();
                        this.imageOffsetInfo.minX = displaySize.width / 2 - iw / 2
                        this.imageOffsetInfo.maxX = iw / 2 - displaySize.width / 2

                        this.imageOffsetInfo.minY = displaySize.height / 2 - ih / 2
                        this.imageOffsetInfo.maxY = ih / 2 - displaySize.height / 2

                    })
                    .onActionUpdate((event: GestureEvent) => {
                        if (this.imageScaleInfo.scaleValue === this.imageScaleInfo.defaultScaleValue) {
                            // 默认大小下不允许移动
                            return;
                        }
                        this.imageOffsetInfo.currentX = this.imageOffsetInfo.lastX + event.offsetX;
                        this.imageOffsetInfo.currentY = this.imageOffsetInfo.lastY + event.offsetY;
                    })
                    .onActionEnd((event: GestureEvent) => {
                        if (this.imageScaleInfo.scaleValue === this.imageScaleInfo.defaultScaleValue) {
                            // 默认大小下不允许移动
                            return;
                        }
                        runWithAnimation(() => {
                            if (this.imageOffsetInfo.currentX < this.imageOffsetInfo.minX) {
                                this.imageOffsetInfo.currentX = this.imageOffsetInfo.minX
                            } else if (this.imageOffsetInfo.currentX > this.imageOffsetInfo.maxX) {
                                this.imageOffsetInfo.currentX = this.imageOffsetInfo.maxX
                            }
                            if (this.imageOffsetInfo.currentY < this.imageOffsetInfo.minY) {
                                this.imageOffsetInfo.currentY = this.imageOffsetInfo.minY
                            } else if (this.imageOffsetInfo.currentY > this.imageOffsetInfo.maxY) {
                                this.imageOffsetInfo.currentY = this.imageOffsetInfo.maxY
                            }
                            this.imageOffsetInfo.stash();
                        });
                    })
            )
        )

        // .backgroundColor(this.bgc)
        .alignContent(Alignment.Center)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .width('100%')
        .height('100%')
    }
}

/**
 * 给函数的执行加上动画
 * @param fn：要在动画内执行的回调函数，通常fn里面会改变状态变量
 * @param duration：动画持续时长
 * @param curve：动画区线
 */
function runWithAnimation(
    fn: Function,
    duration: number = 300,
    curve: Curve = Curve.Smooth): void {
    animateTo({ duration: duration, curve: curve }, () => {
        fn();
    })
}

@Observed
class OffsetModel {
    public currentX: number;
    public currentY: number;
    public lastX: number = 0;
    public lastY: number = 0;
    public minX: number = 0
    public maxX: number = 0
    public minY: number = 0
    public maxY: number = 0

    constructor(currentX: number = 0, currentY: number = 0) {
        this.currentX = currentX;
        this.currentY = currentY;
    }

    reset(): void {
        this.currentX = 0;
        this.currentY = 0;
        this.lastX = 0;
        this.lastY = 0;
    }

    stash(): void {
        this.lastX = this.currentX;
        this.lastY = this.currentY;
    }

    toString(): string {
        return `[currentX: ${this.currentX} currentY: ${this.currentY} lastX: ${this.lastX} lastY: ${this.lastY}]`;
    }
}

@Observed
class ScaleModel {
    /**
     * scaleValue: 本次缩放因子，用于控制图片的大小显示
     * lastValue：记录上次缩放完后的缩放因子
     * defaultMaxScaleValue：默认的最大放大值
     * defaultScaleValue：默认缩放值，1
     */
    public scaleValue: number;
    public lastValue: number;
    public maxScaleValue: number;
    public extraScaleValue: number;
    public readonly defaultScaleValue: number = 1;

    constructor(scaleValue: number = 1.0, lastValue: number = 1.0,
                maxScaleValue: number = 1.5, extraScaleValue: number = 0.2) {
        this.scaleValue = scaleValue;
        this.lastValue = lastValue;
        this.maxScaleValue = maxScaleValue;
        this.extraScaleValue = extraScaleValue;
    }

    reset(): void {
        this.scaleValue = this.defaultScaleValue;
        this.lastValue = this.scaleValue;
    }

    stash(): void {
        this.lastValue = this.scaleValue;
    }

    toString(): string {
        return `[scaleValue: ${this.scaleValue} lastValue: ${this.lastValue}]`;
    }
}
