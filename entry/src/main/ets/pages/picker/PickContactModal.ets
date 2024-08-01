import UserInfo from '../../wfc/model/userInfo'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import CheckableUserListView from '../../view/CheckableUserListView'
import { loadContactUserInfos } from '../../helper/asyncTaskHelper'
import Organization from '../../api/model/organization'
import Employee from '../../api/model/employee'
import orgServer from '../../api/orgServer'
import GroupInfo from '../../wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'

@Component
export default struct PickContactModal {
    @State checkedUsers: UserInfo[] = []
    @State checkedOrganizations: Organization[] = []
    @State checkedEmployees: Employee[] = []
    @State userInfos?: UserInfo[] = undefined
    @State @Watch('_onCheckFavGroup') checkedFavGroupInfo?: GroupInfo = undefined
    initialCheckedUserIds: string[] = []
    uncheckableUserIds: string[] = []
    organization?: Organization
    public static PICK_RESULT: string = 'pickContactResult'
    @Link showPickContactModal: boolean
    onCheckFavGroup?: (info: GroupInfo) => void
    onCheckUser?: (users: UserInfo[]) => void

    // TODO
    // fixme
    // 添加选人结束、选中favGroup 的处理方法

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

    _onCheckFavGroup() {
        if (this.checkedFavGroupInfo) {
            this.onCheckFavGroup?.(this.checkedFavGroupInfo)
            this.showPickContactModal = false;
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
                    if (this.userInfos) {
                        CheckableUserListView({
                            checkedUsers: $checkedUsers,
                            checkedEmployees: $checkedEmployees,
                            checkedOrganizations: $checkedOrganizations,
                            checkedFavGroupInfo: $checkedFavGroupInfo,
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
                .enabled(this.newlyCheckedUsers().length + this.checkedOrganizations.length + this.checkedEmployees.length > 0)
                .fontSize(14)
                .borderRadius(4)// .backgroundColor(Color.Blue)
                .onClick(async () => {
                    let users = await this.allNewlyCheckedUsers();
                    this.onCheckUser?.(users)
                    this.showPickContactModal = false
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
}
