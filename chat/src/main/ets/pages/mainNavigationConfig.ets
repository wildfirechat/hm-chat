import { UIKitPageMap } from "@wfc/uikit/src/main/ets/pages/navigationConfig"
import AboutPage from "./me/AboutPage"
import AccountPage from "./me/AccountPage"
import ChangePasswordPage from "./me/ChangePasswordPage"
import ResetPasswordPage from "./me/ResetPasswordPage"
import SettingPage from "./me/SettingPage"
import TestPage from "./test/TestPage"

export class mainNavigationDestinations {
    static AboutPage = 'aboutPage'
    static AccountPage = 'accountPage'
    static ResetPasswordPage = 'resetPasswordPage'
    static ChangePasswordPage = 'changePasswordPage'
    static SettingPage = 'settingPage'
}

@Builder
export function MainPageMap(name: string) {
    if (name === mainNavigationDestinations.AboutPage) {
        AboutPage()
    } else if (name === mainNavigationDestinations.AccountPage) {
        AccountPage()
    } else if (name === mainNavigationDestinations.ResetPasswordPage) {
        ResetPasswordPage()
    } else if (name === mainNavigationDestinations.ChangePasswordPage) {
        ChangePasswordPage()
    } else if (name === mainNavigationDestinations.SettingPage) {
        SettingPage()
    } else if (name === 'testPage') {
        TestPage()
    } else {
        UIKitPageMap(name)
    }
}
