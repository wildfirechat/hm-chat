import CheckableUserItemView from '../view/CheckableUserItemView'
import UserInfo from '../wfc/model/userInfo'
import { UIUserInfo } from '../common/Types'
import BasicDataSource from '../common/BasicDataSource'
import { groupUserInfos } from '../helper/asyncTaskHelper'
import { showToast } from '../common/utils/Toast'
import Organization from '../api/model/organization'
import orgServer from '../api/orgServer'
import { navigationDestinations } from '../pages/navigationConfig'
import { router } from '@kit.ArkUI'
import PickOrganizationMemberModal from '../pages/organization/PickOrganizationMemberModal'

@Component
export default struct CheckableUserListView {
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
    @State organizations?: Organization[] = []
    private checkedUserListScroller: Scroller = new Scroller()
    // @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State showPickOrganizationModal: boolean = false

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

    onCheckUser = (info: UserInfo, checked?: boolean) => {
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

        let newlyCheckedUsers = this.checkedUsers.filter(info => this.uncheckableUserIds.indexOf(info.uid) === -1)
        let checkedUserWidth = 100 / 8 * newlyCheckedUsers.length
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
    pickOrganizationModal(org: Organization) {
        PickOrganizationMemberModal({ showPickOrganizationModal: $showPickOrganizationModal, curOrganization: org })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    build() {
        Column() {
            if (this.showSearchView) {
                List({ scroller: this.checkedUserListScroller }) {
                    ForEach(this.checkedUsers.filter(info => this.uncheckableUserIds.indexOf(info.uid) === -1), (info: UserInfo) => {
                        ListItem() {
                            Image(info.portrait)
                                .width(40)
                                .height(40)
                                .borderRadius(4)
                                .margin({ left: 10 })
                                .onClick(() => {
                                    this.checkedUsers = this.checkedUsers.filter(userInfo => userInfo.uid !== info.uid)
                                })
                        }
                    }, (info: UserInfo) => info.uid + '-' + info.updateDt)
                    ListItem() {
                        Row() {
                            TextInput({ placeholder: '搜索' })
                                .margin({ left: 10, right: 10 })
                                .onChange((value: string) => {
                                    this.filter(value)
                                })
                                .borderRadius(4)
                        }
                        .constraintSize({ minWidth: '25%', maxWidth: this.searchInputViewMaxWidth })
                    }
                }
                .scrollBar(BarState.Off)
                .listDirection(Axis.Horizontal)
                .width('100%')
                .height(60)
                .margin({ left: 10, right: 10 })
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
                                            .width(40)
                                            .height(40)
                                            .borderRadius(4)
                                        Text(org.name)
                                            .maxLines(1)
                                            .padding({ left: 10 })
                                    }
                                    .height(60)
                                    .width('100%')
                                    .padding({ left: 10, right: 10 })
                                    .stateStyles({
                                        pressed: {
                                            .backgroundColor('#E5E5E5')
                                        },
                                        normal: {
                                            .backgroundColor(Color.White)
                                        }
                                    })
                                    .onClick(() => {
                                        this.showPickOrganizationModal = true
                                        // this.mainNavPathStack.pushPathByName(navigationDestinations.PickOrganizationMemberPage, {
                                        //     'organization': org
                                        // } as Record<string, Object>)
                                        // router.pushUrl({
                                        //     url: 'pages/organization/PickOrganizationMemberPage',
                                        //     params: {
                                        //         organization: org
                                        //     }
                                        // }, router.RouterMode.Standard)
                                    })
                                }
                                .bindContentCover(this.showPickOrganizationModal,
                                    this.pickOrganizationModal(org),
                                    {
                                        // transition: TransitionEffect.SLIDE,
                                        modalTransition: ModalTransition.NONE,
                                        onDisappear: () => {
                                            this.showPickOrganizationModal = false;
                                        }
                                    })
                            }, (org: Organization, index: number) => org.id + '')
                        }

                        if (this.showFavGroup) {
                            ListItem() {
                                Row() {
                                    Image($r('app.media.ic_group_chat'))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Text('群聊(保存到通讯录的群组)')
                                        .maxLines(1)
                                        .padding({ left: 10 })
                                }
                                .height(60)
                                .width('100%')
                                .padding({ left: 10, right: 10 })
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor('#E5E5E5')
                                    },
                                    normal: {
                                        .backgroundColor(Color.White)
                                    }
                                })
                                .onClick(() => {
                                    showToast('todo favGroup')
                                })
                            }
                        }
                    }
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
                .divider({
                    strokeWidth: 1,
                    startMargin: 80
                })
            } else {
                Text('加载中..')
            }
        }
        .width('100%')
        .height('100%')
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
