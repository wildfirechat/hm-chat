import {
    fontSizeManager,
    FONT_SCALE_LEVELS,
    FONT_SCALE_STANDARD_INDEX,
    FontSize,
    Radius
} from '@wfc/uikit/src/main/ets/common/design/Tokens'

/**
 * 「字体大小」设置页（项目风格：系统标题栏 + 主题色滑块 + 右上角「完成」）。
 *
 * - 拖动滑块只改变本页“预览气泡”（通过 min/maxFontScale 锁定为预览倍数），
 *   不影响 App 其它页面；底部滑块区不缩放、高度恒定。
 * - 点击右上角「完成」后，才通过 setFontSizeScale 应用到全 App 并持久化。
 */
@Component
export default struct FontSizeSettingPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    // 草稿档位（未提交）
    @State level: number = FONT_SCALE_STANDARD_INDEX;

    aboutToAppear() {
        this.level = fontSizeManager.getLevel();
    }

    private previewScale(): number {
        return FONT_SCALE_LEVELS[this.level];
    }

    private confirm() {
        // 传 ApplicationContext 仅用于读写 preferences；真正应用缩放用的是
        // 启动时 fontSizeManager.apply() 保存的 ApplicationContext（见 FontScale.ets）。
        fontSizeManager.setLevel(getContext(this).getApplicationContext(), this.level);
        this.mainNavPathStack.pop();
    }

    build() {
        NavDestination() {
            Column() {
                // 预览区（可伸缩，吸收预览气泡的高度变化，不影响底部）
                Column({ space: 16 }) {
                    Row() {
                        this.Avatar()
                        this.Bubble('拖动下面的滑块，可设置字体大小', false)
                        Blank()
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Top)

                    Row() {
                        Blank()
                        this.Bubble('预览字体大小', true)
                        this.Avatar()
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Top)
                }
                .width('100%')
                .padding(16)
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // 滑块区（固定高度，不随字体缩放）
                Column() {
                    Row({ space: 12 }) {
                        Text('A').fontSize(FontSize.sm).visibility(Visibility.Hidden)
                        Row() {
                            Blank().layoutWeight(FONT_SCALE_STANDARD_INDEX)
                            Text('标准')
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_tertiary_text'))
                                .minFontScale(1)
                                .maxFontScale(1)
                            Blank().layoutWeight(FONT_SCALE_LEVELS.length - 1 - FONT_SCALE_STANDARD_INDEX)
                        }
                        .layoutWeight(1)

                        Text('A').fontSize(FontSize.d2).visibility(Visibility.Hidden)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)

                    Row({ space: 12 }) {
                        Text('A')
                            .fontSize(FontSize.sm)
                            .fontColor($r('app.color.wf_primary_text'))
                            .minFontScale(1)
                            .maxFontScale(1)
                        Slider({
                            value: this.level,
                            min: 0,
                            max: FONT_SCALE_LEVELS.length - 1,
                            step: 1,
                            style: SliderStyle.OutSet
                        })
                            .layoutWeight(1)
                            .blockColor($r('app.color.wf_background'))
                            .trackColor($r('app.color.wf_divider'))
                            .selectedColor($r('app.color.wf_primary'))
                            .showSteps(true)
                            .onChange((value: number) => {
                                this.level = Math.round(value);
                            })
                        Text('A')
                            .fontSize(FontSize.d2)
                            .fontColor($r('app.color.wf_primary_text'))
                            .minFontScale(1)
                            .maxFontScale(1)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 12, bottom: 40 })
                .backgroundColor($r('app.color.wf_background'))
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .title('字体大小')
        .menus(this.ConfirmMenu)
        .width('100%')
        .height('100%')
    }

    @Builder
    ConfirmMenu() {
        Row() {
            Button('完成')
                .type(ButtonType.Normal)
                .height(32)
                .margin({ right: 20 })
                .fontSize(FontSize.sm)
                .borderRadius(Radius.sm)// .backgroundColor(Color.Blue)
                .onClick(async () => {
                    this.confirm()
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }

    @Builder
    Avatar() {
        Image($r('app.media.icon'))
            .width(40)
            .height(40)
            .borderRadius(Radius.md)
            .backgroundColor($r('app.color.wf_divider'))
            .margin({ left: 8, right: 8 })
    }

    @Builder
    Bubble(text: string, sent: boolean) {
        Text(text)
            .fontSize(FontSize.md * this.previewScale())
            // 锁定缩放倍数为 1，防止预览字体被全局的 fontScale 叠加缩放
            .minFontScale(1)
            .maxFontScale(1)
            .fontColor($r('app.color.wf_primary_text'))
            .padding(12)
            .constraintSize({ maxWidth: '70%' })
            .backgroundColor(sent ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
            .borderRadius(Radius.sm)
    }
}
