import { ComponentContent, UIContext } from '@kit.ArkUI'

/**
 * 带图标的居中提示（仿微信「听筒播放，请贴近手机聆听」那种）。
 *
 * 系统的 {@link showToast} 只能显示纯文本；需要图标时这里用 OverlayManager 绘制一个浮层节点：
 * - 浮层节点默认页面居中，且没有弹窗的背板/蒙层/毛玻璃，所以不会出现盖住下层内容的白色边条；
 * - 内容用全局 @Builder + wrapBuilder 渲染（这是在非组件代码里渲染 @Builder 的官方方式，
 *   不会像把全局 @Builder 直接交给 openCustomDialog 那样崩溃）。
 *
 * 用法（无需自己写 @Builder）：
 * ```
 * showTipToast(this.getUIContext(), '听筒播放，请贴近手机聆听', $r('app.media.ic_voice_earpiece'))
 * showTipToast(this.getUIContext(), '已复制') // 纯文本
 * ```
 */

const DEFAULT_DURATION_MS: number = 2000

class TipToastParams {
    message: string
    icon?: ResourceStr

    constructor(message: string, icon?: ResourceStr) {
        this.message = message
        this.icon = icon
    }
}

@Builder
function tipToastBuilder(params: TipToastParams) {
    Column() {
        if (params.icon) {
            Image(params.icon)
                .width(44)
                .height(44)
                .margin({ bottom: 14 })
        }
        Text(params.message)
            .fontSize(15)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
    }
    .constraintSize({ maxWidth: '70%' })
    .padding({ left: 30, right: 30, top: 22, bottom: 22 })
    .backgroundColor('rgba(0,0,0,0.82)')
    .borderRadius(14)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
}

// 同一时刻只展示一个提示，状态为模块级单例，跨组件共享。
let tipContent: ComponentContent<TipToastParams> | undefined = undefined
let tipTimer: number = -1

export function showTipToast(ui: UIContext, message: string, icon?: ResourceStr, durationMs: number = DEFAULT_DURATION_MS): void {
    const overlay = ui.getOverlayManager()
    const dismiss = () => {
        tipTimer = -1
        if (tipContent) {
            const c = tipContent
            tipContent = undefined
            try {
                overlay.removeComponentContent(c)
                c.dispose()
            } catch (e) {
            }
        }
    }
    // 已在显示：更新文案/图标并重置消失计时，避免重复弹出
    if (tipContent) {
        if (tipTimer >= 0) {
            clearTimeout(tipTimer)
        }
        tipContent.update(new TipToastParams(message, icon))
        tipTimer = setTimeout(dismiss, durationMs)
        return
    }
    const content = new ComponentContent(ui, wrapBuilder<[TipToastParams]>(tipToastBuilder), new TipToastParams(message, icon))
    tipContent = content
    overlay.addComponentContent(content)
    tipTimer = setTimeout(dismiss, durationMs)
}

/** 立即关闭当前提示（如有）。 */
export function dismissTipToast(ui: UIContext): void {
    if (tipTimer >= 0) {
        clearTimeout(tipTimer)
        tipTimer = -1
    }
    if (tipContent) {
        const c = tipContent
        tipContent = undefined
        try {
            ui.getOverlayManager().removeComponentContent(c)
            c.dispose()
        } catch (e) {
        }
    }
}
