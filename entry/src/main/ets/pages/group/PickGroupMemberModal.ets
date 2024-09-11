import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import CheckableUserListView from '../../view/CheckableUserListView'
import Employee from '../../api/model/employee'
import Organization from '../../api/model/organization'
import GroupInfo from '../../wfc/model/groupInfo'

@Component
export default struct PickGroupMemberModal {
    @State checkedUsers: UserInfo[] = []
    @State checkedEmployees: Employee[] = []
    @State checkedOrganizations: Organization[] = []
    @State checkedFavGroupInfo?: GroupInfo = undefined
    private userInfos: UserInfo[] = []
    private initialCheckedUserIds: string[] = []
    private uncheckableUserIds: string[] = []
    public static TAG: string = 'pickGroupMember'
    public groupId: string = ''
    @Link showPickGroupMemberModal: boolean
    onPickResult?: (users: UserInfo[]) => void = undefined
    public static PICK_RESULT = 'pickGroupMembers'
    public title: string = ''

    aboutToAppear() {
        let groupMemberIds = wfc.getGroupMemberIds(this.groupId, false)
        this.userInfos = wfc.getUserInfos(groupMemberIds, '')
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
                        uncheckableUserIds: this.uncheckableUserIds,
                        initialCheckedUserIds: this.initialCheckedUserIds,
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
        .title(this.title)
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
                    if (this.onPickResult) {
                        this.onPickResult(this.newlyCheckedUsers())
                    } else {
                    LocalStorage.getShared()
                        .setOrCreate<UserInfo[]>(PickGroupMemberModal.PICK_RESULT, this.newlyCheckedUsers());
                    }
                    this.showPickGroupMemberModal = false;
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .align(Alignment.Center)
    }
}
