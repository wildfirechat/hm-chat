import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import CheckableUserListView from '../../view/CheckableUserListView'
import GroupInfo from '../../wfc/model/groupInfo'
import Employee from '../../api/model/employee'
import Organization from '../../api/model/organization'

@Component
export default struct AddGroupMemberModal {
    @State checkedUsers: UserInfo[] = []
    @State checkedEmployees: Employee[] = []
    @State checkedOrganizations: Organization[] = []
    @State checkedFavGroupInfo?: GroupInfo = undefined
    private userInfos: UserInfo[] = []
    private initialCheckedUserIds: string[] = []
    private uncheckableUserIds: string[] = []
    public static TAG: string = 'addGroupMember'
    private groupInfo?: GroupInfo
    @Link showAddGroupMemberModal: boolean
    public static PICK_RESULT = 'pickResult'

    aboutToAppear() {
        let groupMemberIds = wfc.getGroupMemberIds(this.groupInfo!.target, false)

        let friendUserIds = wfc.getMyFriendList()
        this.userInfos = wfc.getUserInfos(friendUserIds, '')
        this.uncheckableUserIds = groupMemberIds
        this.initialCheckedUserIds = groupMemberIds

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
                        checkedEmployees: $checkedEmployees,
                        checkedOrganizations: $checkedOrganizations,
                        checkedFavGroupInfo: $checkedFavGroupInfo,
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
        .title('添加群成员')
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
                .margin({ right: 18 })
                .enabled(this.newlyCheckedUsers().length > 0)
                .fontSize(14)
                .borderRadius(4)// .backgroundColor(Color.Blue)
                .onClick(() => {
                    LocalStorage.getShared()
                        .setOrCreate<UserInfo[]>(AddGroupMemberModal.PICK_RESULT, this.newlyCheckedUsers());
                    this.showAddGroupMemberModal = false;
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
}
