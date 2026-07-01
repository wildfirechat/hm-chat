import { FontSize } from '../common/design/Tokens'

/**
 * 分栏（Pad/宽屏）模式下右侧内容区的空态占位页。
 * 作为各分栏 tab 的右栏基座，未选中任何列表项时展示。
 * 手机单栏模式不会用到此页。
 */
@Component
export default struct WelcomePage {
    build() {
        NavDestination() {
            Column() {
                SymbolGlyph($r('sys.symbol.message'))
                    .fontSize(72)
                    .fontWeight(FontWeight.Lighter)
                    .fontColor([$r('app.color.wf_tertiary_text')])
                Text('从左侧选择一项查看')
                    .fontSize(FontSize.md)
                    .fontColor($r('app.color.wf_secondary_text'))
                    .visibility(Visibility.Hidden)
                    .margin({ top: 16 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
        }
        .hideTitleBar(true)
        .backgroundColor($r('app.color.wf_primary_background_color'))
    }
}
