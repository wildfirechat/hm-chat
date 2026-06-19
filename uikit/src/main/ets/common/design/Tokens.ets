/**
 * 设计令牌（Design Tokens）——字号 / 圆角 / 布局缩放规范。
 *
 * 只保留“有意义”的令牌：
 *   - FontSize：字号的类型阶（type ramp），语义清晰、便于统一；
 *   - Radius：圆角实际只有少数几档（默认/卡片/圆形），天然语义化；
 *   - LayoutScale：非文字元素（图标/头像/行高）随字号放大的“封顶比例”。
 * 间距（padding/margin/gap）不做令牌：其取值是连续的、与具体布局强相关，
 *   t-shirt 数值阶并不能语义化，反而增加无谓改动，故直接用数值字面量；
 *   但需遵循约定的间距栅格，见 design/SPACING.md。
 * 颜色继续使用 `$r('app.color.wf_*')` 资源（保证暗色模式），见 design/COLORS.md。
 *
 * 用法：
 *   import { FontSize, Radius } from '../../common/design/Tokens'
 *   Text(x).fontSize(FontSize.md).borderRadius(Radius.sm)
 *
 * 字号缩放是全局的（见 FontScale.ets，ApplicationContext.setFontSizeScale），
 * 所有 fp 文字自动跟随；不跟随的（底部 Tab、标题栏）在该 Text 上加
 *   .minFontScale(1).maxFontScale(1)
 *
 * 非文字元素（头像、图标、固定/最小行高、徽标）不会被 setFontSizeScale 影响，
 * 需要手动随字号放大时用 scaledSize()，并按 LayoutScale 封顶，避免被超大字号撑爆：
 *   .height(scaledSize(64, this.fontScale))                       // 图标/固定高，cap 1.2
 *   .constraintSize({ minHeight: scaledSize(72, this.fontScale, LayoutScale.row) }) // 行高可放宽到 1.5
 * 其中 this.fontScale 由 `@StorageProp('fontScale') fontScale: number = 1.0` 提供。
 */

export { fontSizeManager, FONT_SCALE_LEVELS, FONT_SCALE_STANDARD_INDEX } from './FontScale'

/** 字号（fp）。通用 UI 直接用本阶；聊天/朋友圈领域语义见 TextStyleToken。 */
export class FontSize {
    static readonly xs: number = 12      // 最小辅助字：时间戳、未读气泡计数等
    static readonly sm: number = 14      // 次要文本字：如副标题、群成员名字等
    static readonly md: number = 16      // 正文默认：聊天正文、列表标题、输入文字等
    static readonly lg: number = 18      // 突出文本字：弹窗标题、设置大项等
    static readonly xl: number = 20      // 页面标题字：TitleBar 的标题等
    static readonly xxl: number = 24     // 特大字：如验证码输入、欢迎大标题
    static readonly d1: number = 28      // display 大字
    static readonly d2: number = 32
    static readonly d3: number = 36
    static readonly huge: number = 64    // emoji / 启动页超大字
}

/**
 * 聊天 / 朋友圈领域的语义字号别名（指向上面的字号阶）。
 * 边界：聊天/消息相关文字用本类（messageText 等），其余通用 UI 直接用 FontSize。
 */
export class TextStyleToken {
    // 聊天相关
    static readonly messageText: number = FontSize.md      // 消息正文
    static readonly messageQuote: number = FontSize.sm     // 引用摘要
    static readonly messagePreview: number = FontSize.xl   // 全屏预览
    static readonly messageTime: number = FontSize.xs      // 消息时间
    static readonly messageSender: number = FontSize.sm    // 发送者名字

    // 输入相关
    static readonly inputText: number = FontSize.md        // 输入框文字

    // 通用列表与页面
    static readonly listTitle: number = FontSize.md        // 列表标题
    static readonly listSubtitle: number = FontSize.sm     // 列表副标题
    static readonly navigationTitle: number = FontSize.xl  // 导航标题
}

/** 圆角（vp）。 */
export class Radius {
    static readonly none: number = 0
    static readonly xs: number = 2
    static readonly sm: number = 4     // 最高频默认
    static readonly md: number = 6     // 头像 / 卡片
    static readonly lg: number = 8
    static readonly xl: number = 12
    static readonly xxl: number = 16
    static readonly full: number = 999 // 头像等圆形 / 胶囊
}

/**
 * 非文字元素随字号放大的“封顶比例”。
 * 文字本身由全局 fontScale 自由缩放，但图标/行高若 1:1 跟随会被超大字号撑爆，
 * 故统一封顶：图标/头像/固定尺寸到 cap，可撑高的行（minHeight）放宽到 row。
 */
export class LayoutScale {
    static readonly cap: number = 1.2  // 图标 / 头像 / 徽标 / 固定高度 / startMargin
    static readonly row: number = 1.5  // 列表行 minHeight（能被内容撑高，可放宽）
}

/**
 * 按字号缩放一个布局尺寸并封顶。
 *   scaledSize(64, this.fontScale)                  => 64 * min(fontScale, 1.2)
 *   scaledSize(72, this.fontScale, LayoutScale.row) => 72 * min(fontScale, 1.5)
 */
export function scaledSize(base: number, fontScale: number, cap: number = LayoutScale.cap): number {
    return base * Math.min(fontScale, cap)
}
