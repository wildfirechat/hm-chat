import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import pttClient, { PttClient } from '@wfc/ptt'

const TAG: string = 'PttManager'
const PREF_STORE_NAME: string = 'wfcstore'
const PREF_KEY_PTT_ENABLED: string = 'pttEnabled'

/**
 * 对讲功能的全局开关，对应 android 端 SharedPreferences 里的 pttEnabled。
 *
 * - 开关打开时初始化对讲 SDK：不管在哪个界面，都能收到并播放别人的对讲；
 *   会话输入栏上的「对讲」按钮也只有开关打开时才显示。
 * - 关闭时反初始化，麦克风、播放器、消息监听全部释放。
 *
 * 通过 AppStorage 的 {@link STORAGE_KEY_PTT_ENABLED} 暴露给 UI，输入栏用 `@StorageProp` 订阅。
 */

/** AppStorage 中保存对讲开关的 key。 */
export const STORAGE_KEY_PTT_ENABLED: string = 'pttEnabled'

class PttManager {
    private abilityContext?: common.UIAbilityContext
    private enabled: boolean = true

    /** 启动时调用：读取开关，打开时初始化对讲 SDK。需要在 wfc.init 之后。 */
    init(context: common.UIAbilityContext): void {
        this.abilityContext = context
        try {
            let pref = preferences.getPreferencesSync(context.getApplicationContext(), { name: PREF_STORE_NAME })
            this.enabled = pref.getSync(PREF_KEY_PTT_ENABLED, true) as boolean
        } catch (e) {
            this.enabled = true
            hilog.warn(0x0000, TAG, 'read ptt enabled failed: %{public}s', JSON.stringify(e))
        }
        AppStorage.setOrCreate<boolean>(STORAGE_KEY_PTT_ENABLED, this.enabled)
        // 不管开关是否打开都要注册对讲消息类型，否则关掉对讲之后，会话里的对讲留底语音消息
        // 会被解析成未知消息，展示不出来
        PttClient.registerMessageContents()
        if (this.enabled) {
            this.startClient()
        }
    }

    isEnabled(): boolean {
        return this.enabled
    }

    /** 设置对讲开关：立即生效并持久化，不需要重启应用。 */
    setEnabled(enabled: boolean): void {
        if (this.enabled === enabled) {
            return
        }
        this.enabled = enabled
        AppStorage.setOrCreate<boolean>(STORAGE_KEY_PTT_ENABLED, enabled)
        try {
            let context = this.abilityContext ? this.abilityContext.getApplicationContext() : undefined
            if (context) {
                let pref = preferences.getPreferencesSync(context, { name: PREF_STORE_NAME })
                pref.putSync(PREF_KEY_PTT_ENABLED, enabled)
                pref.flush()
            }
        } catch (e) {
            hilog.warn(0x0000, TAG, 'persist ptt enabled failed: %{public}s', JSON.stringify(e))
        }
        if (enabled) {
            this.startClient()
        } else {
            pttClient.uninit()
        }
    }

    /** 退出登录时调用，释放对讲 SDK。 */
    uninit(): void {
        pttClient.uninit()
    }

    private startClient(): void {
        if (!this.abilityContext) {
            hilog.warn(0x0000, TAG, 'can not start ptt client, not init yet')
            return
        }
        // 事件走 UIAbility 的 eventHub，和 wfc 保持一致，界面上直接 pttClient.eventEmitter.on(...) 订阅
        pttClient.init(this.abilityContext.getApplicationContext(), this.abilityContext.eventHub)
    }
}

export const pttManager = new PttManager()
