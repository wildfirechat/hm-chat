import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import client from 'marswrapper'
import { showToast } from '../../common/utils/Toast'
import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import SearchType from '../../wfc/model/searchType'
import router from '@ohos.router'
import FriendRequest from '../../wfc/model/friendRequest'

@Entry
@Component
@Preview
export default struct FriendRequestList {
    @State message: string = 'Hello Discovery'
    @State computedRequests: FriendRequestAndUserInfo[] = []

    async onPageShow() {
        let requests = wfc.getIncommingFriendRequest()
        let ids = requests.map(req => req.target)
        let userInfos = wfc.getUserInfos(ids, '')

        let tmpArray: FriendRequestAndUserInfo[] = requests.map(req => {
            let userInfo = userInfos.find(info => info.uid)
            return {
                request: req,
                userInfo: userInfo
            } as FriendRequestAndUserInfo
        })

        this.computedRequests = tmpArray
    }

    build() {
        Navigation() {
            Column() {
                if (this.computedRequests.length === 0) {
                    Column() {
                        Text('没有好友请求')
                    }
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .width('100%')
                    .height('100%')
                } else {
                    List() {
                        ForEach(this.computedRequests, (req: FriendRequestAndUserInfo) => {
                            ListItem() {
                                Row() {
                                    Image(req.userInfo.portrait)
                                        .alt($r('app.media.avatar_def'))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Column() {
                                        Text(req.userInfo.displayName)
                                            .fontSize(14)
                                        Text(req.request.reason)
                                            .padding({ top: 2 })
                                            .fontSize(12)
                                    }
                                    .alignItems(HorizontalAlign.Start)
                                    .padding({ left: 10 })
                                    .layoutWeight(1)

                                    if (req.request.status === 0) {
                                        Button('接受')
                                            .type(ButtonType.Normal)
                                            .fontSize(12)
                                            .height(30)
                                            .borderRadius(4)
                                            .onClick(() => {
                                                wfc.handleFriendRequest(req.request.target, true, '', () => {
                                                    showToast('添加好友成功')
                                                }, err => {
                                                    showToast('添加好友失败 ' + err)
                                                })
                                            })
                                    } else if (req.request.status === 1) {
                                        Text('已添加')
                                            .fontSize(12)
                                    } else if (req.request.status === 2) {
                                        Text('已拒绝')
                                            .fontSize(12)
                                    }
                                }
                                .width('100%')
                                .justifyContent(FlexAlign.Start)
                                .padding(10)
                            }
                            .width('100%')
                            .onClick(() => {
                                router.pushUrl({
                                    url: 'pages/user/UserInfoPage',
                                    params: {
                                        userInfo: req.userInfo
                                    }
                                }, router.RouterMode.Standard)
                            })
                        }, (req: FriendRequestAndUserInfo) => req.request.target)
                    }
                    .width('100%')
                    .layoutWeight(1)
                }
            }
            .height('100%')
            .width('100%')
        }
        .title('好友请求')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
        .menus([
            {
                value: '',
                icon: "common/image/ic_add.png",
                action: () => {
                    router.pushUrl({
                        url: 'pages/search/SearchUserPage'
                    }, router.RouterMode.Standard)
                }
            }
        ])
    }
}

interface FriendRequestAndUserInfo {
    request: FriendRequest,
    userInfo: UserInfo
}