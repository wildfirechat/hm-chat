import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import CheckableUserListView from '../../view/CheckableUserListView'
import { loadContactUserInfos } from '../../helper/asyncTaskHelper'
import Organization from '../../api/model/organization'

@Component
export default struct PickContactModal {
    @State checkedUsers: UserInfo[] = []
    @State userInfos?: UserInfo[] = undefined
    initialCheckedUserIds: string[] = []
    uncheckableUserIds: string[] = []
    organization?: Organization
    public static PICK_RESULT: string = 'pickContactResult'
    @Link showPickContactModal: boolean

    aboutToAppear() {
        loadContactUserInfos().then((userinfos: UserInfo[]) => {
            this.userInfos = userinfos;
            if (this.initialCheckedUserIds) {
                this.checkedUsers = this.userInfos.filter((info: UserInfo) => {
                    return this.initialCheckedUserIds.indexOf(info.uid) >= 0
                })
            }
        })
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
                    if (this.userInfos) {
                        CheckableUserListView({
                            checkedUsers: $checkedUsers,
                            userInfos: this.userInfos,
                            uncheckableUserIds: this.initialCheckedUserIds,
                            showCategory: true,
                            showSearchView: true,
                            showFavGroup: true,
                            showOrganization: true,
                        })
                    } else {
                        Text('加载中..')
                    }
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
        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.START])
        .menus(this.NavigationMenus())
    }

    @Builder
    NavigationMenus() {
        Row() {
            Button('确定')
                .type(ButtonType.Normal)
                .height(30)
                .width(60)
                .margin({ right: 18 })
                .enabled(this.newlyCheckedUsers().length > 0)
                .fontSize(14)
                .borderRadius(4)// .backgroundColor(Color.Blue)
                .onClick(() => {
                    LocalStorage.getShared()
                        .setOrCreate<UserInfo[]>(PickContactModal.PICK_RESULT, this.newlyCheckedUsers());
                    this.showPickContactModal = false
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
}
