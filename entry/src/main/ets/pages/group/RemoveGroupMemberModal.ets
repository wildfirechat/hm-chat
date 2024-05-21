import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import CheckableUserListView from '../../view/CheckableUserListView'
import GroupInfo from '../../wfc/model/groupInfo'

@Component
export default struct RemoveGroupMemberModal {
    @State checkedUsers: UserInfo[] = []
    private userInfos: UserInfo[] = []
    private initialCheckedUserIds: string[] = []
    private uncheckableUserIds: string[] = []
    public static TAG: string = 'removeGroupMember'
    private groupInfo?: GroupInfo
    @Link showRemoveGroupMemberModal: boolean
    public static PICK_RESULT = 'removeGroupMembers'

    aboutToAppear() {
        let groupMemberIds = wfc.getGroupMemberIds(this.groupInfo!.target, false)

        this.userInfos = wfc.getUserInfos(groupMemberIds, '')
        // TODO
        // 不能移除级别更高的
        this.uncheckableUserIds = [wfc.getUserId()]
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
                        uncheckableUserIds: this.uncheckableUserIds,
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
        .title('移除群成员')
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
                        .setOrCreate<UserInfo[]>(RemoveGroupMemberModal.PICK_RESULT, this.newlyCheckedUsers());
                    this.showRemoveGroupMemberModal = false;
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .align(Alignment.Center)
    }
}
