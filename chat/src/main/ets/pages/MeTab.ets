import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import ConnectionStatus from '@wfc/client/src/main/ets/wfc/client/connectionStatus'
import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import { uikitNavigationDestinations } from '@wfc/uikit/src/main/ets/pages/uikitNavigationConfig'
import { appNavigationDestinations } from './mainNavigationConfig'
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
                        .fontColor($r('app.color.wf_primary_text'))
                        .maxLines(1)
                    Text(`野火号:${this.userInfo!.name}`)
                        .maxLines(1)
                        .fontSize(14)
                        .wordBreak(WordBreak.BREAK_ALL)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .fontColor($r('app.color.wf_tertiary_text'))
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.SpaceBetween)
                .layoutWeight(1)
                .height(60)
                .padding({ top: 5, bottom: 5 })
                .margin({ left: 16 })

                Image($r('app.media.ic_public_arrow_right'))
                    .width(22)
                    .height(22)
                    .fillColor($r('app.color.c_gray'))
            }
            .width('100%')
            .height(100)
            .padding({
                left:26,
                right: 20,
                top: 10,
                bottom: 10
            })
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.wf_background'))
            .onClick(() => {
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                    'userInfo': this.userInfo,
                } as Record<string, Object>)
            })

            if(BuildProfile.DEBUG){
                OptionItemView({ icon: $r('app.media.ic_account'), title: '账号与安全' })
                    .margin({ top: 10 })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.AccountPage, {} as Record<string, Object>)
                    })
            }

            OptionItemView({ icon: $r('app.media.ic_notification'), title: '消息与通知' })
                .margin({ top: 10 })
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.NotificationPage, {} as Record<string, Object>)
                })

            Column() {
                OptionItemView({ icon: $r('app.media.ic_settings_file'), title: '文件' })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.FileRecordPortalPage, {} as Record<string, Object>)
                    })
                OptionItemView({ icon: $r('app.media.ic_star'), title: '收藏', showDivider: false })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.FavRecordPage, {} as Record<string, Object>)
                    })
            }
            .margin({ top: 10 })
            .backgroundColor($r('app.color.wf_background'))

            Column() {
                OptionItemView({ icon: $r('app.media.ic_theme'), title: '主题' })
                    .onClick(() => {
                        showToast('TODO')
                    })
                    .visibility(Visibility.None)
                OptionItemView({ icon: $r('app.media.ic_setting'), title: '设置' })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(appNavigationDestinations.SettingPage, {} as Record<string, Object>)
                    })
                OptionItemView({ icon: $r('app.media.ic_settings_file'), title: '备份与恢复', showDivider: false })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(appNavigationDestinations.BackupAndRestorePage, {} as Record<string, Object>)
                    })
            }
            .margin({ top: 10, bottom: 10 })
            .backgroundColor($r('app.color.wf_background'))

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
        .backgroundColor($r('app.color.wf_primary_background_color'))
    }
}