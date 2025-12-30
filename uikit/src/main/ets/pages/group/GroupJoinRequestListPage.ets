import { showToast } from '../../common/utils/Toast'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { JoinGroupRequest } from '@wfc/client/src/main/ets/wfc/model/JoinGroupRequest'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'

@Component
export default struct GroupJoinRequestListPage {
    @State computedRequests: JoinGroupRequestAndUserInfo[] = []
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private groupId: string = ''

    async aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupId = params['groupId'] as string
        if (!this.groupId) {
            this.mainNavPathStack.pop()
            return
        }

        // 0 for pending?
        let requests = wfc.getJoinGroupRequests(this.groupId)
        let ids = requests.map(req => req.requestUserId)
        let userInfos = wfc.getUserInfos(ids, '')

        let tmpArray: JoinGroupRequestAndUserInfo[] = requests.map(req => {
            let userInfo = userInfos.find(info => info.uid === req.requestUserId)
            return {
                request: req,
                userInfo: userInfo
            } as JoinGroupRequestAndUserInfo
        })

        this.computedRequests = tmpArray
    }

    build() {
        NavDestination() {
            Navigation() {
                Column() {
                    if (this.computedRequests.length === 0) {
                        Column() {
                            Text('没有加群申请')
                        }
                        .justifyContent(FlexAlign.Center)
                        .alignItems(HorizontalAlign.Center)
                        .width('100%')
                        .height('100%')
                    } else {
                        List() {
                            ForEach(this.computedRequests, (req: JoinGroupRequestAndUserInfo) => {
                                ListItem() {
                                    NewGroupJoinRequestsCard({status: req.request.status, req})
                                }
                                .width('100%')
                                .onClick(() => {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                                        'userInfo': req.userInfo
                                    } as Record<string, Object>)
                                })
                            }, (req: JoinGroupRequestAndUserInfo) => req.request.memberId + req.request.timestamp)
                        }
                        .width('100%')
                        .height('100%')
                        .layoutWeight(1)
                    }
                }
                .height('100%')
                .width('100%')
            }
            .title('加群申请')
            .titleMode(NavigationTitleMode.Mini)
            .hideBackButton(false)
            .height('100%')
            .width('100%')
            .navBarPosition(NavBarPosition.Start)
        }
        .width('100%')
        .height('100%')
        .hideTitleBar(true)
    }
}

@Component
struct NewGroupJoinRequestsCard {
    @State status: number = 0;
    @Prop req: JoinGroupRequestAndUserInfo;

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
                        wfc.handleJoinGroupRequest(this.req.request.groupId, this.req.request.memberId, this.req.request.requestUserId, 1, '', [0], () => {
                            this.status = 1
                            this.req.request.status = 1
                            showToast('已接受')
                        }, err => {
                            showToast('接受失败 ' + err)
                        })
                    })
            } else if (this.status === 1) {
                Text('已接受')
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

interface JoinGroupRequestAndUserInfo {
    request: JoinGroupRequest,
    userInfo: UserInfo
}
