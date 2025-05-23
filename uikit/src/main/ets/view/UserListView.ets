import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { pinyin4js } from '@ohos/pinyin4js'
import { UIUserInfo } from '../common/Types'
import BasicDataSource from '../common/BasicDataSource'
import UserItemView from './UserItemView'
import { groupUserInfos } from '../helper/asyncTaskHelper'

@Component
export default struct UserListView {
    @State filteredUserInfos: UserInfo[] = []
    @State searchInputViewMaxWidth: string = '100%'
    private userInfos: UserInfo[] = []
    private userInfoDataSource: UserInfoDataSource = new UserInfoDataSource()
    private showCategory: boolean = false
    private showSearchView: boolean = false
    private onClickUser?: (userInfo: UserInfo) => void

    aboutToAppear() {
        this.filteredUserInfos = this.userInfos
        groupUserInfos(this.filteredUserInfos.map(u => u.uid), '')
            .then(userInfos => {
                this.userInfoDataSource.setUserInfos(userInfos)
            })
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
        groupUserInfos(this.filteredUserInfos.map(u => u.uid), '')
            .then(userInfos => {
                this.userInfoDataSource.setUserInfos(userInfos)
            })
    }

    build() {
        Column() {
            if (this.showSearchView) {
                Row() {
                    TextInput({ placeholder: '搜索' })
                        .margin({ left: 10, right: 10 })
                        .onChange((value: string) => {
                            this.filter(value)
                        })
                        .borderRadius(4)
                }
                .constraintSize({ minWidth: '25%', maxWidth: this.searchInputViewMaxWidth })
                .width('100%')
                .height(60)
            }
            List() {
                LazyForEach(this.userInfoDataSource, (info: UIUserInfo) => {
                    ListItem() {
                        UserItemView({
                            uiUserInfo: info,
                            paddingLeft: 10,
                            paddingRight: 10,
                            onClickUser: this.onClickUser,
                        })
                    }
                    .key(info.userInfo.uid + info.userInfo.updateDt)
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
