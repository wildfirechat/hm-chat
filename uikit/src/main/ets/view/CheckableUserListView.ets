import CheckableUserItemView from './CheckableUserItemView'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { UIUserInfo } from '../common/Types'
import BasicDataSource from '../common/BasicDataSource'
import { groupUserInfos } from '../helper/asyncTaskHelper'
import { showToast } from '../common/utils/Toast'
import Organization from '../api/model/organization'
import orgServer from '../api/orgServer'
import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig'
import PickOrganizationMemberModal from '../pages/organization/PickOrganizationMemberModal'
import Employee from '../api/model/employee'
import PickFavGroupModal from '../pages/picker/PickFavGroupModal'
import { Radius, scaledSize } from '../common/design/Tokens'
import { isWideScreen } from '../util/navUtil'
import { PickOrganizationMemberResult } from '../pages/organization/PickOrganizationMemberPage'

@Component
export default struct CheckableUserListView {
    @StorageProp('fontScale') fontScale: number = 1.0;
    @Link checkedUsers: UserInfo[]
    @State filteredUserInfos: UserInfo[] = []
    @State searchInputViewMaxWidth: string = '100%'
    @State userInfoDataSource?: UserInfoDataSource = undefined
    userInfos: UserInfo[] = []
    showCategory: boolean = false
    uncheckableUserIds: string[] = []
    initialCheckedUserIds: string[] = []
    showSearchView: boolean = false
    showOrganization: boolean = false
    showFavGroup: boolean = false
    singleCheck: boolean = false
    @State organizations?: Organization[] = []
    private checkedUserListScroller: Scroller = new Scroller()
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    @State showPickOrganizationModal: boolean = false
    @State activeOrg?: Organization = undefined
    @Link @Watch('onCheckEmployee') checkedEmployees: Employee[]
    @Link @Watch('onCheckOrganization') checkedOrganizations: Organization[]
    @State showPickFavGroupModal: boolean = false
    @Link checkedFavGroupInfo: GroupInfo

    aboutToAppear() {
        this.filteredUserInfos = this.userInfos
        groupUserInfos(this.filteredUserInfos.map(u => u.uid)).then(userInfos => {
            this.userInfoDataSource = new UserInfoDataSource();
            this.userInfoDataSource.setUserInfos(userInfos)
        })

        if (this.showOrganization) {
            orgServer.getRootOrganization()
                .then(orgs => {
                    this.organizations = orgs;
                })
        }
    }

    onCheckEmployee() {

    }

    onCheckOrganization() {
        let newlyCheckedUsers = this.checkedUsers.filter(info => this.uncheckableUserIds.indexOf(info.uid) === -1)
        let checkedUserWidth = 100 / 8 * (newlyCheckedUsers.length + this.checkedOrganizations.length + this.checkedEmployees.length)
        if (checkedUserWidth > 75) {
            this.searchInputViewMaxWidth = '25%'
        } else {
            this.searchInputViewMaxWidth = (100 - checkedUserWidth) + '%'
        }
    }

    onCheckUser = (info: UserInfo, checked?: boolean) => {
        if (this.singleCheck) {
            this.checkedUsers = checked ? [info] : []
        } else {
            let index = this.checkedUsers.findIndex(checkedUser => checkedUser.uid === info.uid)
            if (checked) {
                if (index < 0) {
                    this.checkedUsers.push(info)
                }
            } else {
                if (index >= 0) {
                    this.checkedUsers.splice(index, 1)
                }
            }
        }

        let newlyCheckedUsers = this.checkedUsers.filter(info => this.uncheckableUserIds.indexOf(info.uid) === -1)
        let checkedUserWidth = 100 / 8 * (newlyCheckedUsers.length + this.checkedOrganizations.length + this.checkedEmployees.length)
        if (checkedUserWidth > 75) {
            this.searchInputViewMaxWidth = '25%'
        } else {
            this.searchInputViewMaxWidth = (100 - checkedUserWidth) + '%'
        }

        this.checkedUserListScroller.scrollEdge(Edge.End)
    }

    filter(key: string) {
        key = key.trim()
        if (key) {
            this.filteredUserInfos = this.userInfos.filter((userInfo: UserInfo) => {
                // TODO
                // 优化搜索
                return userInfo.displayName.indexOf(key) >= 0
            })
        } else {
            this.filteredUserInfos = this.userInfos
        }
        groupUserInfos(this.filteredUserInfos.map(u => u.uid)).then(userInfos => {
            this.userInfoDataSource?.setUserInfos(userInfos)
        })
    }

    isChecked(userInfo: UserInfo): boolean {
        if (this.checkedUsers) {
            return this.checkedUsers.findIndex((info: UserInfo) => info.uid === userInfo.uid) >= 0
        }
        return false
    }

    isUncheckable(userInfo: UserInfo) {
        if (this.uncheckableUserIds) {
            return this.uncheckableUserIds.indexOf(userInfo.uid) >= 0
        }
        return false
    }

    @Builder
    pickOrganizationModal(org?: Organization) {
        if (org) {
            PickOrganizationMemberModal({
                showPickOrganizationModal: $showPickOrganizationModal,
                checkedEmployees: $checkedEmployees,
                checkedOrganizations: $checkedOrganizations,
                curOrganization: org
            })
                .height('100%')
                .width('100%')
                .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
                .backgroundColor($r('app.color.wf_background'))
        }
    }

    @Builder
    pickSingleFavGroupModal() {
        PickFavGroupModal({
            showPickFavGroupModal: $showPickFavGroupModal,
            checkedFavGroupInfo: $checkedFavGroupInfo,
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor($r('app.color.wf_background'))
    }

    build() {
        Column() {
            if (this.showSearchView) {
                List({ scroller: this.checkedUserListScroller }) {
                    ForEach(this.checkedUsers.filter(info => this.uncheckableUserIds.indexOf(info.uid) === -1), (info: UserInfo) => {
                        ListItem() {
                            Image(info.portrait)
                                .width(scaledSize(40, this.fontScale))
                                .height(scaledSize(40, this.fontScale))
                                .borderRadius(Radius.sm)
                                .margin({ left: 12 })
                                .onClick(() => {
                                    this.checkedUsers = this.checkedUsers.filter(userInfo => userInfo.uid !== info.uid)
                                })
                        }
                    }, (info: UserInfo) => info.uid + '-' + info.updateDt)

                    ForEach(this.checkedOrganizations, (org: Organization) => {
                        ListItem() {
                            Image(org.portraitUrl)
                                .alt($r('app.media.ic_deparment'))
                                .width(scaledSize(40, this.fontScale))
                                .height(scaledSize(40, this.fontScale))
                                .borderRadius(Radius.sm)
                                .margin({ left: 12 })
                                .onClick(() => {
                                    this.checkedOrganizations = this.checkedOrganizations.filter(o => o.id !== org.id)
                                })
                        }
                    }, (org: Organization) => 'org-' + org.id)

                    ForEach(this.checkedEmployees, (employee: Employee) => {
                        ListItem() {
                            Image(employee.portraitUrl)
                                .alt($r('app.media.avatar_def'))
                                .width(scaledSize(40, this.fontScale))
                                .height(scaledSize(40, this.fontScale))
                                .borderRadius(Radius.sm)
                                .margin({ left: 12 })
                                .onClick(() => {
                                    this.checkedEmployees = this.checkedEmployees.filter(e => e.employeeId !== employee.employeeId)
                                })
                        }
                    }, (e: Employee) => e.employeeId)

                    ListItem() {
                        Row() {
                            TextInput({ placeholder: '搜索' })
                                .margin({ left: 12, right: 12 })
                                .onChange((value: string) => {
                                    this.filter(value)
                                })
                                .borderRadius(Radius.sm)
                        }
                        .constraintSize({ minWidth: '25%', maxWidth: this.searchInputViewMaxWidth })
                    }
                }
                .scrollBar(BarState.Off)
                .listDirection(Axis.Horizontal)
                .width('100%')
                .height(60)
                .margin({ left: 12, right: 12 })
                .alignListItem(ListItemAlign.Center)
            }
            if (this.userInfoDataSource) {
                List() {
                    ListItemGroup() {
                        if (this.organizations && this.organizations.length > 0) {
                            ForEach(this.organizations, (org: Organization, index: number) => {
                                ListItem() {
                                    Row() {
                                        Image(org.portraitUrl)
                                            .alt($r('app.media.ic_organization'))
                                            .width(scaledSize(40, this.fontScale))
                                            .height(scaledSize(40, this.fontScale))
                                            .borderRadius(Radius.sm)
                                        Text(org.name)
                                            .maxLines(1)
                                            .margin({ left: 12 })
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                            .fontColor($r('app.color.wf_primary_text'))
                                    }
                                    .height(60)
                                    .width('100%')
                                    .padding({ left: 12, right: 12 })
                                    .stateStyles({
                                        pressed: {
                                            .backgroundColor($r('app.color.wf_item_pressed'))
                                        },
                                        normal: {
                                            .backgroundColor($r('app.color.wf_background'))
                                        }
                                    })
                                    .onClick(() => {
                                        if (isWideScreen()) {
                                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PickOrganizationMemberPage, {
                                                'organization': org,
                                                'onChecked': (result: PickOrganizationMemberResult) => {
                                                    this.checkedEmployees = result.employees
                                                    this.checkedOrganizations = result.organizations
                                                }
                                            } as Record<string, Object>)
                                        } else {
                                            this.activeOrg = org
                                            this.showPickOrganizationModal = true
                                        }
                                    })
                                }
                                .width('100%')
                            }, (org: Organization, index: number) => org.id + '')
                        }

                        if (this.showFavGroup) {
                            ListItem() {
                                Row() {
                                    Image($r('app.media.ic_group_chat'))
                                        .width(scaledSize(40, this.fontScale))
                                        .height(scaledSize(40, this.fontScale))
                                        .borderRadius(Radius.sm)
                                    Text('群聊(保存到通讯录的群组)')
                                        .maxLines(1)
                                        .margin({ left: 12 })
                                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                                        .fontColor($r('app.color.wf_primary_text'))
                                }
                                .height(scaledSize(60, this.fontScale))
                                .width('100%')
                                .padding({ left: 12, right: 12 })
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor($r('app.color.wf_item_pressed'))
                                    },
                                    normal: {
                                        .backgroundColor($r('app.color.wf_background'))
                                    }
                                })
                                .onClick(() => {
                                    if (isWideScreen()) {
                                        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PickFavGroupPage, {
                                            'onCheckFavGroup': (groupInfo: GroupInfo) => {
                                                this.checkedFavGroupInfo = groupInfo
                                            }
                                        } as Record<string, Object>)
                                    } else {
                                        this.showPickFavGroupModal = true
                                    }
                                })
                            }
                            .width('100%')
                        }
                    }
                    .width('100%')
                    .divider({ strokeWidth: 1, startMargin: 10 })

                    LazyForEach(this.userInfoDataSource, (info: UIUserInfo) => {
                        ListItem() {
                            CheckableUserItemView({
                                checkedUsers: $checkedUsers,
                                uiUserInfo: info,
                                paddingLeft: 10,
                                paddingRight: 10,
                                enable: !this.isUncheckable(info.userInfo),
                                initialChecked: this.initialCheckedUserIds.indexOf(info.userInfo.uid) >= 0,
                                onCheckUser: this.onCheckUser,
                            })
                        }
                    }, (info: UIUserInfo) => info.userInfo.uid + '-' + info.userInfo.updateDt)
                }
                .width('100%')
                .layoutWeight(1)
                .backgroundColor($r('app.color.wf_background'))
                .divider({
                    strokeWidth: 1,
                    startMargin: scaledSize(80, this.fontScale),
                })
            } else {
                Text('加载中..')
                    .fontColor($r('app.color.wf_tertiary_text'))
            }
        }
        .width('100%')
        .height('100%')
        .bindContentCover(!isWideScreen() && this.showPickOrganizationModal,
            this.pickOrganizationModal(this.activeOrg),
            {
                modalTransition: ModalTransition.NONE,
                onDisappear: () => {
                }
            })
        .bindContentCover(!isWideScreen() && this.showPickFavGroupModal,
            this.pickSingleFavGroupModal(),
            {
                modalTransition: ModalTransition.NONE,
                onDisappear: () => {
                }
            })
    }
}

class UserInfoDataSource extends BasicDataSource<UIUserInfo> {
    private userInfos: UIUserInfo[] = []

    setUserInfos(userInfos: UIUserInfo[]): void {
        this.userInfos = userInfos
        this.notifyDataReload()
    }

    public totalCount(): number {
        return this.userInfos.length
    }

    public getData(index: number): UIUserInfo {
        return this.userInfos[index]
    }
}
