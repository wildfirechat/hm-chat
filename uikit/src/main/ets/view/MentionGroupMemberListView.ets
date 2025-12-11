import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { pinyin4js } from '@ohos/pinyin4js'
import { UIUserInfo } from '../common/Types'
import BasicDataSource from '../common/BasicDataSource'
import UserItemView from './UserItemView'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType'
import { groupUserInfos } from '../helper/asyncTaskHelper'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import Config from '@wfc/client/src/main/ets/config'
import { it } from '@ohos/hypium'

@Component
export default struct MentionGroupMemberListView {
    @State filteredGroupMemberUserInfos: UserInfo[] = []
    @State filteredRobotUserInfos: UserInfo[] = []
    @State searchInputViewMaxWidth: string = '100%'
    private groupMemberUserInfos: UserInfo[] = []
    private robotUserInfos: UserInfo[] = []
    private userInfoDataSource: UserInfoDataSource = new UserInfoDataSource()
    private enableMentionAll = true;
    private groupInfo?: GroupInfo
    groupId: string = '';
    showCategory: boolean = false
    showSearchView: boolean = false
    onClickGroupMemberUser?: (userInfo: UserInfo) => void
    onClickRobotMemberUser?: (userInfo: UserInfo) => void
    onClickMentionAll?: () => void

    aboutToAppear() {
        if (Config.AI_ROBOT) {
            let robots = [Config.AI_ROBOT];
            this.robotUserInfos = wfc.getUserInfos(robots)
            this.filteredRobotUserInfos = this.robotUserInfos;
        }
        if (this.groupId) {
            let groupMembers = wfc.getGroupMembers(this.groupId, false)
            this.groupInfo = wfc.getGroupInfo(this.groupId)
            let groupMemberIds = groupMembers.map(member => member.memberId);
            this.groupMemberUserInfos = wfc.getUserInfos(groupMemberIds, this.groupId);
        }
        this.filteredGroupMemberUserInfos = this.groupMemberUserInfos
        let groupMember = wfc.getGroupMember(this.groupId, wfc.getUserId())
        if ([GroupMemberType.Owner, GroupMemberType.Manager].indexOf(groupMember.type) >= 0) {
            this.enableMentionAll = true;
        }

        groupUserInfos(this.filteredGroupMemberUserInfos.map(u => u.uid), this.groupId)
            .then(infos => {
                this.userInfoDataSource.setUserInfos(infos)
            })
    }

    filter(key: string) {
        key = key.trim()
        if (key) {
            // TODO
            // 优化搜索
            // 拼音、首字母
            this.filteredGroupMemberUserInfos = this.groupMemberUserInfos.filter((userInfo: UserInfo) => {
                return userInfo.displayName.indexOf(key) >= 0
            })

            this.filteredRobotUserInfos = this.robotUserInfos.filter((userInfo: UserInfo) => {
                return userInfo.displayName.indexOf(key) >= 0
            })
        } else {
            this.filteredGroupMemberUserInfos = this.groupMemberUserInfos
            this.filteredRobotUserInfos = this.robotUserInfos
        }

        groupUserInfos(this.filteredGroupMemberUserInfos.map(u => u.uid), this.groupId)
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
                ForEach(this.filteredRobotUserInfos, (item: UserInfo, index: number) => {
                    UserItemView({
                        uiUserInfo: {
                            showCategory: index === 0,
                            category: 'AI Robot',
                            userInfo: item,
                        } as UIUserInfo,
                        paddingLeft: 10,
                        paddingRight: 10,
                        onClickUser: this.onClickRobotMemberUser,
                    })
                }, (item: UserInfo, index) => {
                    return 'ai-' + item.uid;
                })
                if (this.groupId && this.enableMentionAll) {
                    ListItem() {
                        Column() {
                            Row() {
                                Text('群成员')
                                    .width('100%')
                                    .fontSize(13)
                                    .fontColor('#828282')
                            }
                            .height(30)
                            .padding({ left: 10 })
                            .alignItems(VerticalAlign.Center)
                            .backgroundColor('#EDEDED')

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
                    }
                    .key('mentionAll')
                }

                LazyForEach(this.userInfoDataSource, (info: UIUserInfo) => {
                    ListItem() {
                        UserItemView({
                            uiUserInfo: info,
                            paddingLeft: 10,
                            paddingRight: 10,
                            onClickUser: this.onClickGroupMemberUser,
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
