import { showToast } from '../../common/utils/Toast'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import FriendRequest from '@wfc/client/src/main/ets/wfc/model/friendRequest'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
@Preview
export default struct FriendRequestListPage {
    @State message: string = 'Hello Discovery'
    @State computedRequests: FriendRequestAndUserInfo[] = []
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    async aboutToAppear() {
        let requests = wfc.getIncommingFriendRequest()
        let ids = requests.map(req => req.target)
        let userInfos = wfc.getUserInfos(ids, '')

        let tmpArray: FriendRequestAndUserInfo[] = requests.map(req => {
            let userInfo = userInfos.find(info => info.uid === req.target)
            return {
                request: req,
                userInfo: userInfo
            } as FriendRequestAndUserInfo
        })

        this.computedRequests = tmpArray
    }

    build() {
        NavDestination() {
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
                                    NewFriendRequestsCard({status: req.request.status, req})
                                }
                                .width('100%')
                                .onClick(() => {
                                    this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, {
                                        'userInfo': req.userInfo
                                    } as Record<string, Object>)
                                })
                            }, (req: FriendRequestAndUserInfo) => req.request.target)
                        }
                        .width('100%')
                        .height('100%')
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
                        this.mainNavPathStack.pushPathByName(navigationDestinations.SearchUserPage, {} as Record<string, Object>)
                    }
                }
            ])
        }
        .width('100%')
        .height('100%')
        .hideTitleBar(true)
        .onShown(() => {

        })
    }
}

@Component
struct NewFriendRequestsCard {
    @State status: number = 0;
    @Prop req: FriendRequestAndUserInfo;

    build() {
        Row() {
            Image(this.req.userInfo!!.portrait)
                .alt($r('app.media.avatar_def'))
                .width(40)
                .height(40)
                .borderRadius(4)
            Column() {
                Text(this.req.userInfo!!.displayName)
                    .fontSize(14)
                Text(this.req.request!!.reason)
                    .padding({ top: 2 })
                    .fontSize(12)
            }
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 10 })
            .layoutWeight(1)

            if (this.status === 0) {
                Button('接受')
                    .type(ButtonType.Normal)
                    .fontSize(12)
                    .height(30)
                    .borderRadius(4)
                    .onClick(() => {
                        wfc.handleFriendRequest(this.req.request.target, true, '', () => {
                            this.status = 1
                            this.req.request.status = 1
                            showToast('添加好友成功')
                        }, err => {
                            showToast('添加好友失败 ' + err)
                        })
                    })
            } else if (this.status === 1) {
                Text('已添加')
                    .fontSize(12)
            } else if (this.status === 2) {
                Text('已拒绝')
                    .fontSize(12)
            }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .padding(10)
    }
}

interface FriendRequestAndUserInfo {
    request: FriendRequest,
    userInfo: UserInfo
}
