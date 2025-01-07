import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import data_preferences from '@ohos.data.preferences'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { navigationDestinations } from '@wfc/uikit/src/main/ets/pages/navigationConfig';
import { mainNavigationDestinations } from '../mainNavigationConfig';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import BuildProfile from 'BuildProfile';

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
                    .onClick(() => {
                        showToast('TODO')
                    })

                Column() {
                    OptionItemView({
                        title: '关于',
                        showDivider: true
                    }).onClick(() => {
                        this.mainNavPathStack.pushPathByName(mainNavigationDestinations.AboutPage, {} as Record<string, Object>)
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
                                    fontColor: Color.Red,
                                    action: () => {
                                        let conversation = new Conversation(ConversationType.Single, 'cgc8c8VV', 0)
                                        this.mainNavPathStack.popToName(navigationDestinations.ConversationPage)
                                        this.mainNavPathStack.replacePathByName(navigationDestinations.ConversationPage, {
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
                .backgroundColor(Color.White)

                OptionItemView({ title: '注销' })
                    .onClick(event => {
                        AlertDialog.show({
                            title: "提示",
                            message: "账号注销之后，所有数据将被删除，无法恢复，请慎重！",
                            primaryButton: {
                                value: "注销",
                                fontColor: Color.Red,
                                action: () => {
                                    this.mainNavPathStack.pushPathByName(mainNavigationDestinations.DestroyAccountPage, {} as Record<string, Object>)
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
        .backgroundColor('#EDEDED')
    }
}
