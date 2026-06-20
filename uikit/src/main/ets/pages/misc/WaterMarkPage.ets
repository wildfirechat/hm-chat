import { WaterMark } from '../../common/watermark/WaterMark'

/**
 * 水印子窗口的内容页。该页面被加载到一个透明、整窗不可触摸、始终置顶的子窗口里
 * （见 waterMarkWindow.ets），因此能盖在所有页面、弹窗（Dialog/Sheet/Menu/Toast）之上，
 * 实现真正全局的水印。背景必须透明，否则会遮挡主窗口内容。
 *
 * 本页位于 uikit（HAR）模块，无法通过 `pages/...` 路径被 HAP 的 setUIContent 直接加载，
 * 必须用「命名路由」：声明 @Entry({ routeName })，由窗口侧 loadContentByName(entryName) 加载。
 */
export const entryName: string = 'wfc_watermark_page'

@Entry({ routeName: entryName })
@Component
struct WaterMarkPage {
    build() {
        Stack() {
            WaterMark()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
    }
}
