import AbilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl'
import { bundleManager, common } from '@kit.AbilityKit';
import Logger from '../common/utils/Logger';

const atManager = AbilityAccessCtrl.createAtManager();

async function checkAccessToken(permission: Permissions) {
    let grantStatus: AbilityAccessCtrl.GrantStatus;
    let tokenID: number;
    try {
        let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
        tokenID = appInfo.accessTokenId;
    } catch (err) {
        console.error(`getBundleInfoForSelf failed, error: ${err}`);
    }

    try {
        grantStatus = await atManager.checkAccessToken(tokenID!, permission);
    } catch (err) {
        console.error(`checkAccessToken failed, error: ${err}`);
    }
    return grantStatus!;
}

/**
 * 检查是否授权
 * @param context
 * @param permissions
 * @returns 未授权的权限列表
 */
export async function checkPermissions(context: Context, permissions: Permissions[]): Promise<Permissions[]> {
    let ungrantedPermissions: Permissions[] = [];
    for (let i = 0; i < permissions.length; i++) {
        let grantStatus: AbilityAccessCtrl.GrantStatus = await checkAccessToken(permissions[i]);
        if (grantStatus !== AbilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
            ungrantedPermissions.push(permissions[i])
        }
    }
    return ungrantedPermissions
}

/**
 * 请求授权
 * @param context
 * @param permissions
 * @returns 未授权的权限列表
 */
export async function requestPermissions(context: Context, permissions: Permissions[]): Promise<PermissionRequestResult> {
    return await atManager.requestPermissionsFromUser(context, permissions)
}

/**
 * 检查并请求权限
 * @param context
 * @param permissions 如果需要权限被用户拒绝过，需要弹出设置页申请，需要保证相关权限是一个权限组，否则失败 https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/app-permission-group-list-V5
 * @returns
 */
export async function checkAndRequestPermissions(context: Context, permissions: Permissions[]): Promise<boolean> {
    let ungrantedPermissions = await checkPermissions(context, permissions)
    if (ungrantedPermissions.length > 0) {
        let result = await requestPermissions(context, ungrantedPermissions)
        let deniedPermissions: Permissions[] = []
        let notShowDialogCount = 0
        for (let i = 0; i < permissions.length; i++) {
            if (result.authResults[i] === AbilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
                deniedPermissions.push(permissions[i])
                // if (result.dialogShownResults && result.dialogShownResults[i] === false) {
                //     notShowDialogCount++
                // }
            }
        }
        if (deniedPermissions.length) {
            // 请求未授权权限时，所有未授权权限，都没有弹出授权框
            if (deniedPermissions.length === notShowDialogCount) {
                try {

                    // let grantStatusList = await atManager.requestPermissionOnSetting(context, deniedPermissions)
                    // let allGranted = true
                    // for (const grantStatus of grantStatusList) {
                    //     if (grantStatus === -1) {
                    //         allGranted = false
                    //         break
                    //     }
                    // }
                    return false
                } catch (e) {
                    console.error('requestPermissionOnSetting', deniedPermissions, e)
                    return false
                }
                // 请求未授权权限时，部分未授权权限，用户主动拒绝
            } else {
                return false
            }
        } else {
            return true
        }
    }
    return true
}

// why ？
// camera 权限和麦克风权限不是同一个权限组，当用户都拒绝之后，requestPermissionOnSetting 不支持申请不同权限组的权限
export async function checkAndRequestPermission(context: Context, permission: Permissions): Promise<boolean> {
    return checkAndRequestPermissions(context, [permission])
}
