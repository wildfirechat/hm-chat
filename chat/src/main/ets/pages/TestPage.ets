import TestCustomMessageContent from '@wfc/client/src/main/ets/wfc_custom_message/testCustomMessageContent';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import UserSettingScope from '@wfc/client/src/main/ets/wfc/client/userSettingScope';


@Entry({ routeName: 'apiTestPage' })
@Component
struct TestPage {
    async onPageShow() {
    }

    // 创建组件，并设置大小
    build() {
        Navigation() {
            Column() {
                Column() {
                    Text('本页用于 API 功能测试')
                }

                Button('test')
                    .onClick(() => {
                        wfc.setUserSetting(UserSettingScope.HiddenNotificationDetail, '', '1', () => {
                            console.log('update true')

                        }, err => {
                            console.log('update error', err)
                        })
                    })
                Button('test2')
                    .onClick(() => {
                        let value = wfc.getUserSetting(UserSettingScope.HiddenNotificationDetail, '')
                        console.log('xxxxxxxxxx', value)
                    })
            }
        }
        .title('API 测试页')
        .titleMode(NavigationTitleMode.Mini)
        .navBarPosition(NavBarPosition.Start)
    }
}