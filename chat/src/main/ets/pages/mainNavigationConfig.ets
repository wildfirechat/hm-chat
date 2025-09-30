import { UIKitPageMap, UIKIT_NAV_DESTINATION_PREFIX } from "@wfc/uikit/src/main/ets/pages/uikitNavigationConfig"
// 如果需要支持朋友圈时，请取消注释
import { MomentPageMap, MOMENT_NAV_DESTINATION_PREFIX } from "@wfc/momentkit"
import AboutPage from "./me/AboutPage"
import AccountPage from "./me/AccountPage"
import ChangePasswordPage from "./me/ChangePasswordPage"
import DestroyAccountPage from "./me/DestroyAccountPage"
import ResetPasswordPage from "./me/ResetPasswordPage"
import SettingPage from "./me/SettingPage"
import TestPage from "./test/TestPage"

const APP_NAV_DESTINATION_PREFIX = 'app-'

export class appNavigationDestinations {
    static AboutPage = APP_NAV_DESTINATION_PREFIX + 'aboutPage'
    static AccountPage = APP_NAV_DESTINATION_PREFIX + 'accountPage'
    static ResetPasswordPage = APP_NAV_DESTINATION_PREFIX + 'resetPasswordPage'
    static ChangePasswordPage = APP_NAV_DESTINATION_PREFIX + 'changePasswordPage'
    static SettingPage = APP_NAV_DESTINATION_PREFIX + 'settingPage'
    static DestroyAccountPage = APP_NAV_DESTINATION_PREFIX + 'destroyAccountPage'
}

@Builder
export function AppPageMap(name: string) {
    if (name === appNavigationDestinations.AboutPage) {
        AboutPage()
    } else if (name === appNavigationDestinations.AccountPage) {
        AccountPage()
    } else if (name === appNavigationDestinations.ResetPasswordPage) {
        ResetPasswordPage()
    } else if (name === appNavigationDestinations.ChangePasswordPage) {
        ChangePasswordPage()
    } else if (name === appNavigationDestinations.SettingPage) {
        SettingPage()
    } else if (name === 'testPage') {
        TestPage()
    } else if (name === appNavigationDestinations.DestroyAccountPage) {
        DestroyAccountPage()
    }
}

@Builder
export function MainPageMap(name: string) {
    if (name.startsWith(APP_NAV_DESTINATION_PREFIX)) {
        AppPageMap(name)
    } else if (name.startsWith(UIKIT_NAV_DESTINATION_PREFIX)) {
        UIKitPageMap(name)
        // 如果需要支持朋友圈时，请取消注释
    } else if (name.startsWith(MOMENT_NAV_DESTINATION_PREFIX)) {
        MomentPageMap(name);
    } else {
        NavDestination() {
            Column() {
                Text('Nav destination not found')
            }
            .width('100%')
            .height('100%')
        }
    }
}
