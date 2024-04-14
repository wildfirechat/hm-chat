import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import client from 'marswrapper'
import UserInfo from '../wfc/model/userInfo'
import wfc from '../wfc/client/wfc'
import router from '@ohos.router'
import data_preferences from '@ohos.data.preferences';
import EventType from '../wfc/client/wfcEvent'
import ConnectionStatus from '../wfc/client/connectionStatus'
import { showToast } from '../common/utils/Toast'
import OptionItemView from '../view/OptionItemView'

@Component
export default struct MeTab {
    @State message: string = 'Hello Me'
    @State userInfo?: UserInfo = undefined
    private userId: string = ''
    @Link meTabUnreadCount: number

    aboutToAppear() {
        this.loadSelfUserInfo()
        getContext(this).eventHub.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        getContext(this).eventHub.on(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
    }

    onUserInfosUpdate = (usersInfo: UserInfo[]) => {
        for (const userinfo of usersInfo) {
            if (userinfo.uid === this.userId)
                this.userInfo = userinfo
        }
    }
    onConnectionStatusChange = (status: number) => {
        if (status === ConnectionStatus.ConnectionStatusConnected) {
            this.loadSelfUserInfo()
        }
    }

    loadSelfUserInfo() {
        this.userId = wfc.getUserId()
        this.userInfo = wfc.getUserInfo(this.userId)
    }

    aboutToDisappear() {
        getContext(this).eventHub.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        getContext(this).eventHub.off(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
    }

    build() {
        Column() {
            Row() {
                Image(this.userInfo!.portrait)
                    .width(60)
                    .height(60)
                    .borderRadius(4)
                Column() {
                    Text(this.userInfo!.displayName)
                        .fontSize(20)
                        .maxLines(1)
                    Text(`野火号:${this.userInfo!.name}`)
                        .maxLines(1)
                        .fontSize(14)
                        .fontColor(Color.Gray)
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.SpaceBetween)
                .layoutWeight(1)
                .height(60)
                .padding({ top: 5, bottom: 5 })
                .margin({ left: 10 })

                Image($r('app.media.ic_right'))
                    .width(12)
                    .height(12)
            }
            .width('100%')
            .height(100)
            .padding(10)
            .alignItems(VerticalAlign.Center)
            .backgroundColor(Color.White)

            OptionItemView({ icon: $r('app.media.ic_account'), title: '账号与安全' })
                .margin({ top: 10, bottom: 10 })

            OptionItemView({ icon: $r('app.media.ic_notification'), title: '消息与通知' })
                .margin({ top: 10, bottom: 10 })

            Column() {
                OptionItemView({ icon: $r('app.media.ic_settings_file'), title: '文件' })
                Divider()
                    .margin({ left: 40 })
                    .color('#F7F7F7')
                OptionItemView({ icon: $r('app.media.ic_star'), title: '收藏' })
            }
            .margin({ top: 10, bottom: 10 })
            .backgroundColor(Color.White)

            Column() {
                OptionItemView({ icon: $r('app.media.ic_theme'), title: '主题' })
                Divider()
                    .margin({ left: 40 })
                    .color('#F7F7F7')
                OptionItemView({ icon: $r('app.media.ic_setting'), title: '设置' })
            }
            .margin({ top: 10, bottom: 10 })
            .backgroundColor(Color.White)

            OptionItemView({ title: 'API测试页' })
                .onClick(() => {
                    router.pushUrl({
                        url: 'pages/misc/WebViewPage', params: {
                            url: 'https://baidu.com',
                            title: '百度。。'
                        }
                    }, router.RouterMode.Standard)
                    // router.pushUrl({
                    //     url: 'pages/conversation/forward/ForwardMessagePage'
                    // })
                })

            Button('退出')
                .width(100)
                .type(ButtonType.Normal)
                .borderRadius(4)
                .margin({ top: 50 })
                .onClick(() => {
                    data_preferences.deletePreferences(getContext(this), 'wfcstore')
                    wfc.disconnect(true, false)
                    router.replaceUrl({ url: 'pages/LoginPage' }, router.RouterMode.Standard)
                })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#EDEDED')
    }
}