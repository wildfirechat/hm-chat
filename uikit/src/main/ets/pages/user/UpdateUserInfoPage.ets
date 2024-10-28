import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { showToast } from '../../common/utils/Toast'
import OptionItemView from '../../view/OptionItemView'
import ToggleItemView from '../../view/ToggleItemView'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct UpdateUserInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State isFriend: boolean = false
    @State isFav: boolean = false
    @State isInBlackList: boolean = false
    private userInfo?: UserInfo

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.userInfo = params['userInfo'] as UserInfo;
        if (!this.userInfo) {
            return
        }
        this.isFriend = wfc.isMyFriend(this.userInfo.uid)
        this.isFav = wfc.isFavUser(this.userInfo.uid)
        this.isInBlackList = wfc.isBlackListed(this.userInfo.uid)
    }

    build() {
        NavDestination() {
            Column() {
                Column() {
                    if (this.isFriend) {
                        ToggleItemView({
                            title: '设为星标好友',
                            isOn: this.isFav,
                            showDivider: true,
                            onChange: (isOn) => {
                                wfc.setFavUser(this.userInfo!.uid, isOn, () => {
                                    showToast('设置星标好友成功')
                                }, err => {
                                    showToast('设置星标好友失败 ' + err)
                                })
                            }
                        })
                    }
                    ToggleItemView({
                        title: '加入黑名单',
                        isOn: this.isInBlackList,
                        showDivider: true,
                        onChange: (isOn) => {
                            wfc.setBlackList(this.userInfo!.uid, isOn, () => {
                                showToast('加入黑名单成功')
                            }, err => {
                                showToast('加入黑名单失败 ' + err)
                            })
                        }
                    })
                }
                .margin({ top: 10 })
                .backgroundColor(Color.White)
            }

            if (this.isFriend) {
                Text('删除')
                    .margin({ top: 20 })
                    .width('100%')
                    .height(60)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(Color.White)
                    .fontColor(Color.Red)
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })
                    .onClick(() => {
                        wfc.deleteFriend(this.userInfo!.uid, () => {
                            showToast('删除好友成功')
                            wfc.setFavUser(this.userInfo!.uid, false, () => {
                            }, err => {
                            })
                            this.mainNavPathStack.clear()
                        }, err => {
                            showToast('删除好友失败 ' + err)
                        })
                    })
            }
        }
        .title('资料设置')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
