import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import router from '@ohos.router'
import data_preferences from '@ohos.data.preferences'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import ConnectionStatus from '@wfc/client/src/main/ets/wfc/client/connectionStatus'
import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import { navigationDestinations } from '@wfc/uikit/src/main/ets/pages/navigationConfig'
import { mainNavigationDestinations } from './mainNavigationConfig'
import { BusinessError } from '@kit.BasicServicesKit'
import BuildProfile from 'BuildProfile'


@Component
export default struct MeTab {
    @State message: string = 'Hello Me'
    @State userInfo?: UserInfo = undefined
    private userId: string = ''
    @Link meTabUnreadCount: number
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private context: Context = getContext(this);

    async aboutToAppear() {
        this.loadSelfUserInfo()
        getContext(this).eventHub.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
        getContext(this).eventHub.on(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
    }

    onUserInfosUpdate = (usersInfos: UserInfo[]) => {
        for (const userinfo of usersInfos) {
            if (userinfo.uid === this.userId) {
                this.userInfo = userinfo
            }
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
                        .wordBreak(WordBreak.BREAK_ALL)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .fontColor(Color.Gray)
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.SpaceBetween)
                .layoutWeight(1)
                .height(60)
                .padding({ top: 5, bottom: 5 })
                .margin({ left: 10 })

                Image($r('app.media.ic_public_arrow_right'))
                    .width(22)
                    .height(22)
                    .fillColor('#B6B6B6')
            }
            .width('100%')
            .height(100)
            .padding(10)
            .alignItems(VerticalAlign.Center)
            .backgroundColor(Color.White)
            .onClick(() => {
                this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, {
                    'userInfo': this.userInfo,
                } as Record<string, Object>)
            })

            OptionItemView({ icon: $r('app.media.ic_account'), title: '账号与安全' })
                .margin({ top: 10 })
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.AccountPage, {} as Record<string, Object>)
                })

            OptionItemView({ icon: $r('app.media.ic_notification'), title: '消息与通知' })
                .margin({ top: 10 })
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.NotificationPage, {} as Record<string, Object>)
                })

            Column() {
                OptionItemView({ icon: $r('app.media.ic_settings_file'), title: '文件' })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(navigationDestinations.FileRecordPortalPage, {} as Record<string, Object>)
                    })
                Divider()
                    .margin({ left: 40 })
                    .color('#F7F7F7')
                OptionItemView({ icon: $r('app.media.ic_star'), title: '收藏', showDivider: false })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(navigationDestinations.FavRecordPage, {} as Record<string, Object>)
                    })
            }
            .margin({ top: 10 })
            .backgroundColor(Color.White)

            Column() {
                OptionItemView({ icon: $r('app.media.ic_theme'), title: '主题' })
                    .onClick(() => {
                        showToast('TODO')
                    })
                    .visibility(Visibility.None)
                Divider()
                    .margin({ left: 40 })
                    .color('#F7F7F7')
                OptionItemView({ icon: $r('app.media.ic_setting'), title: '设置', showDivider: false })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(mainNavigationDestinations.SettingPage, {} as Record<string, Object>)
                    })
            }
            .margin({ top: 10, bottom: 10 })
            .backgroundColor(Color.White)

            if (BuildProfile.DEBUG) {
                OptionItemView({ title: 'API测试页' })
                    .onClick(() => {
                        // router.pushUrl({
                        //     url: 'pages/TestPage'
                        // })
                        //     .catch((e: BusinessError) => {
                        //         console.log(e.message)
                        //     })
                        this.mainNavPathStack.pushPathByName('testPage', {} as Record<string, object>)
                    })
            }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#EDEDED')
    }
}