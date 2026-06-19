import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG: string = 'FontScale'

/**
 * 用户「字体大小」缩放。
 *
 * 采用系统级方案：ApplicationContext.setFontSizeScale(scale)（API 13+）。
 * 设置后，整个 App 中所有以 fp 为单位的文字（含未显式设置字号的文字）都会
 * 按比例缩放，且实时生效、自动撑高容器，无需逐组件订阅。
 *
 * 不希望跟随缩放的文字（底部 Tab、标题栏），在对应 Text 上设置
 * `.minFontScale(1).maxFontScale(1)` 即可固定为 1 倍。
 */

/** 可选的缩放档位（由小到大），与「设置字体大小」滑块一致。 */
export const FONT_SCALE_LEVELS: number[] = [0.85, 1.0, 1.15, 1.30, 1.45, 1.60, 1.75]

/** “标准”档位在 FONT_SCALE_LEVELS 中的下标（默认值）。 */
export const FONT_SCALE_STANDARD_INDEX: number = 1

const PREF_STORE_NAME: string = 'wfcstore'
const PREF_KEY_FONT_LEVEL: string = 'fontSizeLevel'

class FontSizeManager {
    private level: number = FONT_SCALE_STANDARD_INDEX
    private appContext?: common.ApplicationContext

    /** 启动早期调用：从 preferences 读取档位（不依赖窗口）。 */
    init(context: common.Context): void {
        try {
            let pref = preferences.getPreferencesSync(context, { name: PREF_STORE_NAME })
            this.level = this.clampLevel(pref.getSync(PREF_KEY_FONT_LEVEL, FONT_SCALE_STANDARD_INDEX) as number)
        } catch (e) {
            this.level = FONT_SCALE_STANDARD_INDEX
            hilog.warn(0x0000, TAG, 'read font level failed, fallback to standard: %{public}s', JSON.stringify(e))
        }
        AppStorage.setOrCreate<number>('fontScale', this.getScale())
    }

    /** 窗口创建后调用：把当前档位应用 to 全 App。 */
    apply(appContext: common.ApplicationContext): void {
        this.appContext = appContext
        let scale = this.scaleOf(this.level)
        this.applyScale(scale)
        AppStorage.setOrCreate<number>('fontScale', scale)
    }

    /** 当前选中的档位下标。 */
    getLevel(): number {
        return this.level
    }

    /** 当前缩放比例。 */
    getScale(): number {
        return this.scaleOf(this.level)
    }


    /** 指定档位对应的缩放比例。 */
    scaleOf(level: number): number {
        return FONT_SCALE_LEVELS[this.clampLevel(level)]
    }

    /** 设置档位：立即全 App 生效并持久化。 */
    setLevel(context: common.Context, level: number): void {
        let target = this.clampLevel(level)
        this.level = target
        let scale = this.scaleOf(target)
        this.applyScale(scale)
        AppStorage.setOrCreate<number>('fontScale', scale)
        try {
            let pref = preferences.getPreferencesSync(context, { name: PREF_STORE_NAME })
            pref.putSync(PREF_KEY_FONT_LEVEL, target)
            pref.flush()
        } catch (e) {
            hilog.warn(0x0000, TAG, 'persist font level failed: %{public}s', JSON.stringify(e))
        }
    }

    private applyScale(scale: number): void {
        let ctx = this.appContext
        if (!ctx) {
            return
        }
        try {
            // setFontSizeScale 自 API 13 起提供；低版本设备静默忽略
            ctx.setFontSizeScale(scale)
        } catch (e) {
            hilog.warn(0x0000, TAG, 'setFontSizeScale unavailable (API < 13?): %{public}s', JSON.stringify(e))
        }
    }

    private clampLevel(level: number): number {
        if (level < 0) {
            return 0
        }
        if (level > FONT_SCALE_LEVELS.length - 1) {
            return FONT_SCALE_LEVELS.length - 1
        }
        return Math.round(level)
    }
}

export const fontSizeManager = new FontSizeManager()
