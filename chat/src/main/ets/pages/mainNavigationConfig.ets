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
import BackupAndRestorePage from "./backup/BackupAndRestorePage"
import BackupTargetPage from "./backup/BackupTargetPage"
import ConversationSelectPage from "./backup/ConversationSelectPage"
import BackupOptionsPage from "./backup/BackupOptionsPage"
import BackupProgressPage from "./backup/BackupProgressPage"
import RestoreSourcePage from "./backup/RestoreSourcePage"
import BackupListPage from "./backup/BackupListPage"
import RestoreOptionsPage from "./backup/RestoreOptionsPage"
import RestoreProgressPage from "./backup/RestoreProgressPage"
import PCBackupProgressPage from "./backup/PCBackupProgressPage"
import PCRestoreListPage from "./backup/PCRestoreListPage"
import PCRestoreProgressPage from "./backup/PCRestoreProgressPage"

const APP_NAV_DESTINATION_PREFIX = 'app-'

export class appNavigationDestinations {
    static AboutPage = APP_NAV_DESTINATION_PREFIX + 'aboutPage'
    static AccountPage = APP_NAV_DESTINATION_PREFIX + 'accountPage'
    static ResetPasswordPage = APP_NAV_DESTINATION_PREFIX + 'resetPasswordPage'
    static ChangePasswordPage = APP_NAV_DESTINATION_PREFIX + 'changePasswordPage'
    static SettingPage = APP_NAV_DESTINATION_PREFIX + 'settingPage'
    static DestroyAccountPage = APP_NAV_DESTINATION_PREFIX + 'destroyAccountPage'
    static BackupAndRestorePage = APP_NAV_DESTINATION_PREFIX + 'backupAndRestorePage'
    static BackupTargetPage = APP_NAV_DESTINATION_PREFIX + 'backupTargetPage'
    static ConversationSelectPage = APP_NAV_DESTINATION_PREFIX + 'conversationSelectPage'
    static BackupOptionsPage = APP_NAV_DESTINATION_PREFIX + 'backupOptionsPage'
    static BackupProgressPage = APP_NAV_DESTINATION_PREFIX + 'backupProgressPage'
    static RestoreSourcePage = APP_NAV_DESTINATION_PREFIX + 'restoreSourcePage'
    static BackupListPage = APP_NAV_DESTINATION_PREFIX + 'backupListPage'
    static RestoreOptionsPage = APP_NAV_DESTINATION_PREFIX + 'restoreOptionsPage'
    static RestoreProgressPage = APP_NAV_DESTINATION_PREFIX + 'restoreProgressPage'
    static PCBackupProgressPage = APP_NAV_DESTINATION_PREFIX + 'pcBackupProgressPage'
    static PCRestoreListPage = APP_NAV_DESTINATION_PREFIX + 'pcRestoreListPage'
    static PCRestoreProgressPage = APP_NAV_DESTINATION_PREFIX + 'pcRestoreProgressPage'
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
    } else if (name === appNavigationDestinations.BackupAndRestorePage) {
        BackupAndRestorePage()
    } else if (name === appNavigationDestinations.BackupTargetPage) {
        BackupTargetPage()
    } else if (name === appNavigationDestinations.ConversationSelectPage) {
        ConversationSelectPage()
    } else if (name === appNavigationDestinations.BackupOptionsPage) {
        BackupOptionsPage()
    } else if (name === appNavigationDestinations.BackupProgressPage) {
        BackupProgressPage()
    } else if (name === appNavigationDestinations.RestoreSourcePage) {
        RestoreSourcePage()
    } else if (name === appNavigationDestinations.BackupListPage) {
        BackupListPage()
    } else if (name === appNavigationDestinations.RestoreOptionsPage) {
        RestoreOptionsPage()
    } else if (name === appNavigationDestinations.RestoreProgressPage) {
        RestoreProgressPage()
    } else if (name === appNavigationDestinations.PCBackupProgressPage) {
        PCBackupProgressPage()
    } else if (name === appNavigationDestinations.PCRestoreListPage) {
        PCRestoreListPage()
    } else if (name === appNavigationDestinations.PCRestoreProgressPage) {
        PCRestoreProgressPage()
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
