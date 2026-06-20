import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG: string = 'VoicePlayModeManager'
const PREF_STORE_NAME: string = 'wfcstore'
const PREF_KEY_EARPIECE: string = 'voiceEarpieceMode'

/**
 * 语音消息播放模式（听筒 / 扬声器）的全局开关。
 *
 * - 全局生效：所有会话共用一份设置，持久化在 preferences。
 * - 通过 AppStorage 的 {@link STORAGE_KEY_VOICE_EARPIECE} 暴露给 UI，
 *   会话标题栏用 `@StorageProp` 订阅以决定是否显示「耳朵」图标。
 */

/** AppStorage 中保存当前是否为「听筒播放」的 key（true=听筒，false=扬声器）。 */
export const STORAGE_KEY_VOICE_EARPIECE: string = 'voiceEarpieceMode'

class VoicePlayModeManager {
    private earpiece: boolean = false

    /** 启动早期调用：从 preferences 读取设置，写入 AppStorage。 */
    init(context: common.Context): void {
        try {
            let pref = preferences.getPreferencesSync(context, { name: PREF_STORE_NAME })
            this.earpiece = pref.getSync(PREF_KEY_EARPIECE, false) as boolean
        } catch (e) {
            this.earpiece = false
            hilog.warn(0x0000, TAG, 'read voice earpiece mode failed: %{public}s', JSON.stringify(e))
        }
        AppStorage.setOrCreate<boolean>(STORAGE_KEY_VOICE_EARPIECE, this.earpiece)
    }

    /** 当前是否为听筒播放。 */
    isEarpiece(): boolean {
        return this.earpiece
    }

    /** 设置播放模式：立即全 App 生效并持久化。 */
    setEarpiece(context: common.Context, earpiece: boolean): void {
        this.earpiece = earpiece
        AppStorage.setOrCreate<boolean>(STORAGE_KEY_VOICE_EARPIECE, earpiece)
        try {
            let pref = preferences.getPreferencesSync(context, { name: PREF_STORE_NAME })
            pref.putSync(PREF_KEY_EARPIECE, earpiece)
            pref.flush()
        } catch (e) {
            hilog.warn(0x0000, TAG, 'persist voice earpiece mode failed: %{public}s', JSON.stringify(e))
        }
    }

    /** 切换播放模式，返回切换后的状态（true=听筒）。 */
    toggle(context: common.Context): boolean {
        this.setEarpiece(context, !this.earpiece)
        return this.earpiece
    }
}

export const voicePlayModeManager = new VoicePlayModeManager()
