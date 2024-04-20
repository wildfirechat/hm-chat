import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import client from 'marswrapper'
import wfc from '../wfc/client/wfc'
import router from '@ohos.router'
import Conversation from '../wfc/model/conversation'
import ConversationType from '../wfc/model/conversationType'
import { showToast } from '../common/utils/Toast'
import CheckableUserItemView from '../view/CheckableUserItemView'
import UserInfo from '../wfc/model/userInfo'
import { pinyin4js } from '@ohos/pinyin4js'
import { UIUserInfo } from '../common/Types'
import BasicDataSource from '../common/BasicDataSource'

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
        this.userInfoDataSource.setUserInfos(this.groupUserInfos(this.filteredUserInfos))
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
        this.userInfoDataSource.setUserInfos(this.groupUserInfos(this.filteredUserInfos))
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

    groupUserInfos(userInfos: UserInfo[]): UIUserInfo[] {
        let groupedUsers: UIUserInfo[] = []
        let lastCategory: string = '';

        if (!this.showCategory) {
            return this.userInfos.map((info: UserInfo) => {
                return {
                    showCategory: false,
                    userInfo: info
                } as UIUserInfo
            })
        }
        userInfos.forEach(user => {
            let category = pinyin4js.getShortPinyin(user.displayName).substring(0, 1).toUpperCase() as string
            if (category < 'A' || category > 'Z') {
                category = '#'
            }
            if (!lastCategory || lastCategory !== category) {
                groupedUsers.push({
                    showCategory: false,
                    category: category,
                    userInfo: user
                });
            } else {
                groupedUsers.push({
                    showCategory: false,
                    category: category,
                    userInfo: user
                });
            }
            lastCategory = category
        })

        groupedUsers.sort((a, b) => {
            if (a.category !== '#' && b.category !== '#') {
                return a.category > b.category ? 1 : 0
            } else {
                if (a.category === '#' && b.category !== '#') {
                    return 1
                } else if (a.category !== '#' && b.category === '#') {
                    return -1
                } else {
                    return 0
                }
            }
        })

        lastCategory = ''
        groupedUsers.forEach(gu => {
            if (!lastCategory || lastCategory !== gu.category) {
                gu.showCategory = true
            } else {
                gu.showCategory = false
            }
            lastCategory = gu.category
        })

        return groupedUsers
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
