import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import data_preferences from '@ohos.data.preferences'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { navigationDestinations } from '@wfc/uikit/src/main/ets/pages/navigationConfig';
import { mainNavigationDestinations } from '../mainNavigationConfig';

@Preview
@Entry
@Component
export default struct SettingPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Column() {
                OptionItemView({
                    title: '隐私设置'
                })

                Column() {
                    OptionItemView({
                        title: '关于',
                        showDivider: true
                    }).onClick(() => {
                        this.mainNavPathStack.pushPathByName(mainNavigationDestinations.AboutPage, {} as Record<string, Object>)
                    })

                    OptionItemView({
                        title: ' 诊断'
                    })
                }
                .margin({ top: 10 })
                .backgroundColor(Color.White)

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
        .backgroundColor('#EDEDED')
    }
}
