import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import data_preferences from '@ohos.data.preferences'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { uikitNavigationDestinations } from '@wfc/uikit/src/main/ets/pages/uikitNavigationConfig';
import { appNavigationDestinations } from '../mainNavigationConfig';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import BuildProfile from 'BuildProfile';
import appServer from '@wfc/uikit/src/main/ets/api/appServer';
import { bundleManager } from '@kit.AbilityKit';

@Preview
@Component
export default struct SettingPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State versionNeedUpdate: boolean = false;

    aboutToAppear() {
        this.loadVersionInfo();
        this.refreshVersionInfo();
    }

    loadVersionInfo() {
        let versionInfo = AppStorage.get<Record<string, Object> | null>('versionInfo')
        this.versionNeedUpdate = versionInfo ? (versionInfo['needUpdate'] as boolean) : false
    }

    async refreshVersionInfo() {
        try {
            let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
            let currentVersion = bundleInfo.versionName || ''
            let buildNumber = bundleInfo.versionCode || 0
            let versionInfo = await appServer.checkVersion(currentVersion, buildNumber)
            AppStorage.setOrCreate<Record<string, Object> | null>('versionInfo', versionInfo)
            if (versionInfo) {
                this.versionNeedUpdate = versionInfo['needUpdate'] as boolean
            }
        } catch (e) {
            console.error('SettingPage refreshVersionInfo error', e)
        }
    }

    build() {
        NavDestination() {
            Column() {
                if (BuildProfile.DEBUG) {
                    OptionItemView({
                        title: '隐私设置'
                    })
                        .onClick(() => {
                            showToast('TODO')
                        })
                }

                Column() {
                    OptionItemView({
                        title: '关于',
                        showDivider: true,
                        showBadge: this.versionNeedUpdate
                    }).onClick(() => {
                        this.mainNavPathStack.pushPathByName(appNavigationDestinations.AboutPage, {} as Record<string, Object>)
                    })

                    if (BuildProfile.DEBUG) {
                        OptionItemView({
                            title: '诊断'
                        })
                            .onClick(() => {
                                showToast('TODO')
                            })
                    }
                    OptionItemView({ title: '举报' })
                        .onClick(event => {
                            AlertDialog.show({
                                title: "举报",
                                message: $r("app.string.complaint"),
                                primaryButton: {
                                    value: "举报",
                                    fontColor: $r('app.color.wf_danger'),
                                    action: () => {
                                        let conversation = new Conversation(ConversationType.Single, 'cgc8c8VV', 0)
                                        this.mainNavPathStack.popToName(uikitNavigationDestinations.ConversationPage)
                                        this.mainNavPathStack.replacePathByName(uikitNavigationDestinations.ConversationPage, {
                                            'conversation': conversation
                                        } as Record<string, Object>)
                                    },
                                },
                                secondaryButton: {
                                    value: '取消',
                                    action: () => {

                                    }
                                }
                            })
                        })
                }
                .margin({ top: 10 })
                .backgroundColor($r('app.color.wf_background'))

                OptionItemView({ title: '注销' })
                    .onClick(event => {
                        AlertDialog.show({
                            title: "提示",
                            message: "账号注销之后，所有数据将被删除，无法恢复，请慎重！",
                            primaryButton: {
                                value: "注销",
                                fontColor: $r('app.color.wf_danger'),
                                action: () => {
                                    this.mainNavPathStack.pushPathByName(appNavigationDestinations.DestroyAccountPage, {} as Record<string, Object>)
                                },
                            },
                            secondaryButton: {
                                value: '取消',
                                action: () => {

                                }
                            }
                        })
                    })

                Button('退出')
                    .width(200)
                    .type(ButtonType.Normal)
                    .borderRadius(4)
                    .margin({ top: 30 })
                    .onClick(() => {
                        showToast('正在退出登录，请稍后...')
                        data_preferences.deletePreferences(getContext(this).getApplicationContext(), 'wfcstore')
                        this.mainNavPathStack.clear(false)
                        wfc.disconnect(true, false)
                    })
            }
            .width('100%')
            .height('100%')
        }
        .title('设置')
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.wf_primary_background_color'))
    }
}
