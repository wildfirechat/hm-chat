/**
 * 退出登录辅助。
 *
 * 原来设置页「退出」和注销成功后都只做了「清 preferences + clear 导航栈 + wfc.disconnect」，
 * 指望 SDK 断开后再回调 ConnectionStatusLogout、由 EntryAbility 切回登录页；
 * 但手动 disconnect 时 SDK 不一定会再回调，表现为点了退出没有任何反应。
 * 这里改成：断开 IM 后主动跳回登录页，不再依赖连接状态回调。
 */
import common from '@ohos.app.ability.common'
import data_preferences from '@ohos.data.preferences'
import router from '@ohos.router'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { isWideScreen } from '../util/navUtil'
import waterMarkWindow from '../common/watermark/waterMarkWindow'

/**
 * 退出登录：清掉本地保存的账号 token、断开 IM，然后回登录页。
 * @param context 应用上下文（getContext(this).getApplicationContext()）
 */
export function logout(context: common.Context): void {
    try {
        data_preferences.deletePreferences(context, 'wfcstore')
            .catch((e: Error) => {
                console.error('logout: delete login state failed', e)
            })
    } catch (e) {
        console.error('logout: delete login state failed', e)
    }

    try {
        // 断开 IM（内部会阻塞约 1 秒等待与服务器断开）
        wfc.disconnect(true, false)
    } catch (e) {
        console.error('logout: disconnect failed', e)
    }

    // 登录页不需要水印窗口（走 loadContent 时会销毁，这里用 router 跳转，要自己销毁）
    waterMarkWindow.destroy()

    // 主动回登录页：手动断开时 SDK 不一定回调 Logout，不能只等回调
    router.replaceUrl({
        url: isWideScreen() ? 'pages/login/PadLoginPage' : 'pages/login/LoginPage',
        params: {}
    }).catch((e: Error) => {
        console.error('logout: back to login page failed', e)
    })
}
