import { showToast } from '../../common/utils/Toast'
import OptionItemView from '../../view/OptionItemView'
import data_preferences from '@ohos.data.preferences'
import wfc from '../../wfc/client/wfc';
import { navigationDestinations } from '../navigationConfig';

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
                        this.mainNavPathStack.pushPathByName(navigationDestinations.AboutPage, {} as Record<string, Object>)
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
                        data_preferences.deletePreferences(getContext(this), 'wfcstore')
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
