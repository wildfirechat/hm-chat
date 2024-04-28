import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import router from '@ohos.router'
import CheckableUserListView from '../../view/CheckableUserListView'
import GroupInfo from '../../wfc/model/groupInfo'

@Entry
@Component
export default struct RemoveGroupMemberPage {
    @State checkedUsers: UserInfo[] = []
    private userInfos: UserInfo[] = []
    private initialCheckedUserIds: string[] = []
    private uncheckableUserIds: string[] = []
    public static TAG: string = 'removeGroupMember'
    private groupInfo?: GroupInfo

    aboutToAppear() {
        let params = router.getParams() as Record<string, Object>
        this.groupInfo = params['groupInfo'] as GroupInfo
        let groupMemberIds = wfc.getGroupMemberIds(this.groupInfo.target, false)

        this.userInfos = wfc.getUserInfos(groupMemberIds, '')
        // TODO
        // 不能移除自己，以及级别更高的
        // this.uncheckableUserIds = groupMemberIds
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
                .enabled(this.newlyCheckedUsers().length > 0)
                .fontSize(14)
                .borderRadius(4)// .backgroundColor(Color.Blue)
                    // TODO
                .onClick(() => {
                    let options: router.RouterOptions = {
                        url: '',
                        params: {
                            tag: RemoveGroupMemberPage.TAG,
                            result: this.newlyCheckedUsers(),
                        }
                    }
                    router.back(options)
                })
        }
    }
}
