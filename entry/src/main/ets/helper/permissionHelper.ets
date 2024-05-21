import AbilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { bundleManager, common } from '@kit.AbilityKit';
import Logger from '../common/utils/Logger';

async function checkAccessToken(permission: Permissions) {
    let atManager = AbilityAccessCtrl.createAtManager();
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
 *
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

export async function checkPermission(context: Context, permission: Permissions): Promise<boolean> {
    let grantStatus: AbilityAccessCtrl.GrantStatus = await checkAccessToken(permission);
    if (grantStatus !== AbilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return false
    }
    return true
}

export async function requestPermissions(context: Context, permissions: Permissions[]): Promise<void> {
    let atManager = AbilityAccessCtrl.createAtManager();
    await atManager.requestPermissionsFromUser(context, permissions).then((data) => {
        console.info(`Request permissions succeed, data is: ${data}`);
    }).catch((error: Error) => {
        console.error(`Request permissions failed, error is: ${error}`);
    });

}
