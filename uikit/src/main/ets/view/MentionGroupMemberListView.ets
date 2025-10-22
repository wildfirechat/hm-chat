import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { pinyin4js } from '@ohos/pinyin4js'
import { UIUserInfo } from '../common/Types'
import BasicDataSource from '../common/BasicDataSource'
import UserItemView from './UserItemView'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType'
import { groupUserInfos } from '../helper/asyncTaskHelper'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'

@Component
export default struct MentionGroupMemberListView {
    @State filteredUserInfos: UserInfo[] = []
    @State searchInputViewMaxWidth: string = '100%'
    private userInfos: UserInfo[] = []
    private userInfoDataSource: UserInfoDataSource = new UserInfoDataSource()
    private enableMentionAll = true;
    private groupInfo?: GroupInfo
    groupId: string = '';
    showCategory: boolean = false
    showSearchView: boolean = false
    onClickUser?: (userInfo: UserInfo) => void
    onClickMentionAll?: () => void

    aboutToAppear() {
        let groupMembers = wfc.getGroupMembers(this.groupId, false)
        this.groupInfo = wfc.getGroupInfo(this.groupId)
        let groupMemberIds = groupMembers.map(member => member.memberId);
        let userInfos = wfc.getUserInfos(groupMemberIds, this.groupId);
        this.userInfos = userInfos;
        this.filteredUserInfos = this.userInfos
        let groupMember = wfc.getGroupMember(this.groupId, wfc.getUserId())
        if ([GroupMemberType.Owner, GroupMemberType.Manager].indexOf(groupMember.type) >= 0) {
            this.enableMentionAll = true;
        }

        groupUserInfos(this.filteredUserInfos.map(u => u.uid), this.groupId)
            .then(infos => {
                this.userInfoDataSource.setUserInfos(infos)
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

        groupUserInfos(this.filteredUserInfos.map(u => u.uid), this.groupId)
            .then(infos => {
                this.userInfoDataSource.setUserInfos(infos)
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
                .margin({ left: 10, right: 10 })
            }
            List() {
                if (this.enableMentionAll) {
                    ListItem() {
                        Row() {
                            Image(this.groupInfo?.portrait)
                                .alt($r('app.media.avatar_def'))
                                .width(40)
                                .height(40)
                                .borderRadius(4)
                                .margin({ left: 10, right: 10 })
                            Text('所有人')
                                .maxLines(1)
                                .fontSize(15)
                                .layoutWeight(1)
                        }
                        .width('100%')
                        .height(60)
                        .padding({ left: 10, right: 10 })
                        .onClick(event => {
                            this.onClickMentionAll?.();
                        })
                        .stateStyles({
                            pressed: {
                                .backgroundColor('#E5E5E5')
                            },
                            normal: {
                                .backgroundColor(Color.White)
                            }
                        })
                    }
                    .key('mentionAll')
                }

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
