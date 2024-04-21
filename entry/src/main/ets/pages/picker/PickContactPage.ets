import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import router from '@ohos.router'
import CheckableUserListView from '../../view/CheckableUserListView'

@Entry
@Component
export default struct PickContactPage {
    @State checkedUsers: UserInfo[] = []
    private userInfos: UserInfo[] = []
    private initialCheckedUserIds: string[] = []
    private uncheckableUserIds: string[] = []
    public static TAG: string = 'pickUser'
    public static PICKER_RESULT: string = 'pickerResult'

    aboutToAppear() {
        let friendUserIds = wfc.getMyFriendList()
        this.userInfos = wfc.getUserInfos(friendUserIds, '')
        // this.initialCheckedUserIds = friendUserIds
        if (this.initialCheckedUserIds) {
            this.checkedUsers = this.userInfos.filter((info: UserInfo) => {
                return this.initialCheckedUserIds.indexOf(info.uid) >= 0
            })
        }
    }

    onCheckUser = (info: UserInfo, checked?: boolean) => {
        let index = this.checkedUsers.findIndex(checkedUser => checkedUser.uid === info.uid)
        if (checked) {
            if (index < 0) {
                this.checkedUsers.push(info)
            }
        } else {
            if (index >= 0) {
                this.checkedUsers.splice(index, 1)
            } else {
                this.checkedUsers.push(info)
            }
        }
    }

    newlyCheckedUsers(): UserInfo[] {
        return this.checkedUsers.filter(info => this.initialCheckedUserIds.indexOf(info.uid) === -1)
    }

    build() {
        Navigation() {
            Scroll() {
                Column() {
                    CheckableUserListView({
                        checkedUsers: $checkedUsers,
                        userInfos: this.userInfos,
                        uncheckableUserIds: this.initialCheckedUserIds,
                        showCategory: true,
                        showSearchView: true
                    })
                }
                .height('100%')
                .width('100%')
                .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .height('100%')
            .padding({ top: 5 })
        }
        .title('选取联系人')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
        .menus(this.NavigationMenus())
    }

    @Builder
    NavigationMenus() {
        Row() {
            Button('确定')
                .type(ButtonType.Normal)
                .height(30)
                .width(60)
                .margin({right: 18})
                .enabled(this.newlyCheckedUsers().length > 0)
                .fontSize(14)
                .borderRadius(4)// .backgroundColor(Color.Blue)
                    // TODO
                .onClick(() => {
                    let options: router.RouterOptions = {
                        url: '',
                        params: {
                            tag: PickContactPage.TAG,
                            result: this.newlyCheckedUsers(),
                        }
                    }
                    router.back(options)
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
}
