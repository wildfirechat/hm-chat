import CheckableUserItemView from '../view/CheckableUserItemView'
import UserInfo from '../wfc/model/userInfo'
import { UIUserInfo } from '../common/Types'
import BasicDataSource from '../common/BasicDataSource'
import { groupUserInfos } from '../helper/groupUserHelper'

@Component
export default struct CheckableUserListView {
    @Link checkedUsers: UserInfo[]
    @State filteredUserInfos: UserInfo[] = []
    @State searchInputViewMaxWidth: string = '100%'
    private userInfos: UserInfo[] = []
    private userInfoDataSource: UserInfoDataSource = new UserInfoDataSource()
    private showCategory: boolean = false
    private uncheckableUserIds: string[] = []
    private showSearchView: boolean = false
    private checkedUserListScroller: Scroller = new Scroller()

    aboutToAppear() {
        this.filteredUserInfos = this.userInfos
        groupUserInfos(this.filteredUserInfos.map(u => u.uid)).then(userInfos => {
            this.userInfoDataSource.setUserInfos(userInfos)
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
            this.userInfoDataSource.setUserInfos(userInfos)
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
            List() {
                LazyForEach(this.userInfoDataSource, (info: UIUserInfo) => {
                    ListItem() {
                        CheckableUserItemView({
                            checkedUsers: $checkedUsers,
                            uiUserInfo: info,
                            paddingLeft: 10,
                            paddingRight: 10,
                            enable: !this.isUncheckable(info.userInfo),
                            onCheckUser: this.onCheckUser,
                        })
                    }
                    .key('ooo')
                }, (info: UIUserInfo) => info.userInfo.uid + '-' + info.userInfo.updateDt)
            }
            .width('100%')
            .layoutWeight(1)
            .divider({
                strokeWidth: 1,
                startMargin: 80
            })
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
