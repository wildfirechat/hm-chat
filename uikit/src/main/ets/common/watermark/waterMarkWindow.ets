import window from '@ohos.window'
import { BusinessError } from '@ohos.base'
import Config from '@wfc/client/src/main/ets/config'
// 以命名路由方式加载 HAR 内的水印页面，import * 既拿到 entryName 也确保该页被打包/注册
import * as WaterMarkPage from '../../pages/misc/WaterMarkPage'

/**
 * 全局水印子窗口。
 *
 * 鸿蒙的弹窗（Dialog/Sheet/Menu/Popup/Toast）以及 OverlayManager 浮层都渲染在「页面层」之上，
 * 因此无论把水印放进页面树还是 OverlayManager，都盖不住弹窗。要做到真正全局（含弹窗），
 * 必须把水印放进一个独立的、置顶的子窗口里。
 *
 * 这里创建一个：
 * - 透明背景（setWindowBackgroundColor #00000000）；
 * - 整窗不可触摸（setWindowTouchable(false)），所有手势透传到主窗口；
 * - 全屏铺满（沉浸式 + resize 到屏幕尺寸）
 * 的子窗口，内容是命名路由页 WaterMarkPage（渲染 WaterMark 组件）。
 *
 * 子窗口是主窗口的子级，层级在主窗口（及其弹窗）之上，从而覆盖一切。
 * 登录进入主页面时创建，退出登录时销毁。开关见 Config.ENABLE_WATER_MARK。
 */
const TAG: string = 'WaterMarkWindow'
const WINDOW_NAME: string = 'wfc_watermark'

class WaterMarkWindowManager {
    private subWindow?: window.Window
    private mainWindow?: window.Window
    private onSizeChange?: (size: window.Size) => void

    /** 创建并显示水印子窗口（已存在或未开启时直接返回）。 */
    async create(windowStage: window.WindowStage): Promise<void> {
        if (!Config.ENABLE_WATER_MARK || this.subWindow) {
            return
        }
        try {
            const sub = await windowStage.createSubWindow(WINDOW_NAME)
            this.subWindow = sub

            await sub.loadContentByName(WaterMarkPage.entryName)
            // 透明背景，避免遮挡主窗口
            await sub.setWindowBackgroundColor('#00000000')
            // 沉浸式，铺到状态栏/导航栏区域
            await sub.setWindowLayoutFullScreen(true)
            // 整窗不可触摸，事件全部透传到主窗口
            await sub.setWindowTouchable(false)
            // 设为不可聚焦，防止水印窗口抢夺焦点拦截系统返回键/侧滑手势
            await sub.setWindowFocusable(false)

            this.mainWindow = windowStage.getMainWindowSync()
            this.resizeToFullScreen()
            await sub.showWindow()

            // 跟随主窗口尺寸变化（旋转/折叠/分屏）调整水印窗口大小
            this.onSizeChange = (size: window.Size) => {
                this.subWindow?.moveWindowTo(0, 0)
                this.subWindow?.resize(size.width, size.height)
            }
            this.mainWindow.on('windowSizeChange', this.onSizeChange)
        } catch (e) {
            const err = e as BusinessError
            console.error(TAG, `create watermark window failed: ${err.code} ${err.message}`)
            this.subWindow = undefined
        }
    }

    /** 销毁水印子窗口。 */
    async destroy(): Promise<void> {
        if (this.mainWindow && this.onSizeChange) {
            try {
                this.mainWindow.off('windowSizeChange', this.onSizeChange)
            } catch (e) {
            }
        }
        this.mainWindow = undefined
        this.onSizeChange = undefined
        if (this.subWindow) {
            const w = this.subWindow
            this.subWindow = undefined
            try {
                await w.destroyWindow()
            } catch (e) {
                const err = e as BusinessError
                console.error(TAG, `destroy watermark window failed: ${err.code} ${err.message}`)
            }
        }
    }

    private resizeToFullScreen(): void {
        if (!this.subWindow || !this.mainWindow) {
            return
        }
        try {
            const rect = this.mainWindow.getWindowProperties().windowRect
            this.subWindow.moveWindowTo(0, 0)
            this.subWindow.resize(rect.width, rect.height)
        } catch (e) {
            const err = e as BusinessError
            console.error(TAG, `resize watermark window failed: ${err.code} ${err.message}`)
        }
    }
}

const waterMarkWindow: WaterMarkWindowManager = new WaterMarkWindowManager()
export default waterMarkWindow
