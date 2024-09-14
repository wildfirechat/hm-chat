import OptionItemView from '../../view/OptionItemView'
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LengthUnit, router } from '@kit.ArkUI';
import Config from '../../config';
import wfc from 'marswrapper'

@Preview
@Entry
@Component
export default struct AboutPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    @State version: string = 'v1.0.0'
    @State appInfo: string = ''

    aboutToAppear() {
        bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
            .then((bundleInfo) => {
                let bundleName = bundleInfo.name; // 包名
                this.version = bundleInfo.versionName; //应用版本名
                let versionNo = bundleInfo.versionCode; //应用版本号
                let info = `${bundleName}\n`
                    + `${versionNo} ${this.version}\n`
                    + `${wfc.getProtoRevision()}\n`
                    // + `${Config.IM_SERVER_HOST}\n`
                    + `${Config.APP_SERVER}\n`;

                // todo
                // if (wfc.isSupportConference()) {
                //     info += "高级版音视频\n";
                // } else {
                //     info += "多人版版音视频\n";
                    for (const ice of Config.ICE_SERVERS) {
                        info += `${ice[0]} ${ice[1]} ${ice[2]}\n`;
                    }
                // }

                this.appInfo = info;

            })
            .catch((error: BusinessError) => {
                console.error("get bundleInfo failed,error is " + error)
            })


    }

    build() {
        NavDestination() {
            Column() {

                Image($r('app.media.app_icon'))
                    .width(80)

                Text($r('app.string.app_name'))
                    .margin({top:8})

                Text($r('app.string.version_tag_s', this.version))
                    .fontColor($r('app.color.c_gray'))
                    .fontSize(12)
                    .margin({top:4})

                Text(this.appInfo)
                    .textAlign(TextAlign.Start)
                    .lineSpacing({value: 4, unit: LengthUnit.VP})
                    .padding(16)
                    .width('100%')

                Column() {
                    OptionItemView({
                        title: getContext().resourceManager.getStringSync($r('app.string.feature_introduction').id),
                        showDivider: true
                    }).onClick(() => {
                        router.pushUrl({
                            url: 'pages/misc/WebViewPageWithRouter',
                            params: {
                                url: 'https://docs.wildfirechat.cn/',
                                title: '野火IM功能介绍'
                            }
                        }, router.RouterMode.Standard)
                    })
                    OptionItemView({
                        title: getContext().resourceManager.getStringSync($r('app.string.user_agreement').id),
                        showDivider: true
                    }).onClick(() => {
                        router.pushUrl({
                            url: 'pages/misc/WebViewPageWithRouter',
                            params: {
                                url: 'https://www.wildfirechat.net/wildfirechat_user_agreement.html',
                                title: '野火IM用户协议'
                            }
                        }, router.RouterMode.Standard)
                    })
                    OptionItemView({
                        title: getContext().resourceManager.getStringSync($r('app.string.privacy_policy').id),
                    }).onClick(() => {
                        router.pushUrl({
                            url: 'pages/misc/WebViewPageWithRouter',
                            params: {
                                url: 'https://www.wildfirechat.net/wildfirechat_user_privacy.html',
                                title: '野火IM个人信息保护政策'
                            }
                        }, router.RouterMode.Standard)
                    })
                }
                .backgroundColor(Color.White)
            }
            .width('100%')
            .height('100%')
        }
        .title(getContext().resourceManager.getStringSync($r('app.string.app_about').id))
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
