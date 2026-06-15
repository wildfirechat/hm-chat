import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import CheckableUserListView from '../../view/CheckableUserListView'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import Employee from '../../api/model/employee'
import Organization from '../../api/model/organization'
import orgServer from '../../api/orgServer'

@Component
export default struct AddGroupMemberModal {
    @State checkedUsers: UserInfo[] = []
    @State checkedEmployees: Employee[] = []
    @State checkedOrganizations: Organization[] = []
    @State checkedFavGroupInfo?: GroupInfo = undefined
    groupInfo?: GroupInfo
    private userInfos: UserInfo[] = []
    private initialCheckedUserIds: string[] = []
    private uncheckableUserIds: string[] = []
    public static TAG: string = 'addGroupMember'
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

    newlyCheckedUsers(): UserInfo[] {
        return this.checkedUsers.filter(info => this.initialCheckedUserIds.indexOf(info.uid) === -1)
    }

    async allNewlyCheckedUsers(): Promise<UserInfo[]> {
        let users = this.checkedUsers.filter(info => this.initialCheckedUserIds.indexOf(info.uid) === -1)
        let checkedUserMap = new Map<string, UserInfo>()
        users.forEach(u => {
            checkedUserMap.set(u.uid, u);
        })
        if (this.checkedOrganizations.length > 0) {
            let employees = await orgServer.getOrganizationEmployees(this.checkedOrganizations.map(o => o.id))
            employees.forEach(e => {
                let u = Employee.toUserInfo(e);
                checkedUserMap.set(u.uid, u);
            })
        }
        this.checkedEmployees.forEach(e => {
            let u = Employee.toUserInfo(e);
            checkedUserMap.set(u.uid, u);
        })
        return Array.from(checkedUserMap.values());
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
                        showSearchView: true,
                        showOrganization: true,
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
                .enabled(this.newlyCheckedUsers().length + this.checkedOrganizations.length + this.checkedEmployees.length > 0)
                .fontSize(14)
                .borderRadius(4)// .backgroundColor(Color.Blue)
                .onClick(async () => {
                    let users = await this.allNewlyCheckedUsers();
                    LocalStorage.getShared()
                        .setOrCreate<UserInfo[]>(AddGroupMemberModal.PICK_RESULT, users);
                    this.showAddGroupMemberModal = false;
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
}
