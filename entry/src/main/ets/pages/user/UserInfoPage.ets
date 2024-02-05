import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { showToast } from '../../common/utils/Toast';
import wfc from '../../wfc/client/wfc';
import Conversation from '../../wfc/model/conversation';
import ConversationType from '../../wfc/model/conversationType';
import UserInfo from '../../wfc/model/userInfo'
import EventType from '../../wfc/client/wfcEvent';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';

@Entry
@Component
export default struct UserInfoPage {
    @State userInfo: UserInfo = null
    private isMyFriend: boolean

    aboutToAppear() {
        const params = router.getParams();
        this.userInfo = params['userInfo'];
        let userId = params['userId'];
        if (!this.userInfo && userId) {
            this.userInfo = wfc.getUserInfo(userId);
        }
        this.isMyFriend = wfc.isMyFriend(this.userInfo.uid)

        getContext(this).eventHub.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
    }

    aboutToDisappear() {
        getContext(this).eventHub.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)
    }

    onUserInfosUpdate = (infos: UserInfo[]) => {
        for (let info of infos) {
            if (info.uid === this.userInfo.uid) {
                this.userInfo = info
                break
            }
        }
    }


    // @Builder NavigationMenus() {
    //     Row() {
    //         Image($r('app.media.ic_search'))
    //             .width(30)
    //             .height(30)
    //             .padding(6)
    //             .onClick(() => {
    //                 showToast('搜索')
    //             })
    //
    //         Image($r('app.media.ic_add'))
    //             .width(30)
    //             .height(30)
    //             .padding(6)
    //             .margin({ left: 24 })
    //             .bindMenu(this.SubMoreMenus())
    //     }
    // }

    build() {
        Navigation() {
            Column() {
                Row() {
                    Image(this.userInfo.portrait)
                        .width(60)
                        .height(60)
                        .borderRadius(4)
                    Column() {
                        Text(this.userInfo.displayName)
                            .width('100%')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .fontSize(20)
                        Text(`野火ID： ${this.userInfo.name}`)
                            .width('100%')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .fontSize(14)
                    }
                    .padding({ left: 10 })
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                }
                .padding(10)
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .backgroundColor(Color.White)

                if (this.isMyFriend || this.userInfo.uid === wfc.getUserId()) {
                    Text('发消息')
                        .width('100%')
                        .padding(15)
                        .margin({ top: 20 })
                        .textAlign(TextAlign.Center)
                        .backgroundColor(Color.White)
                        .onClick(() => {
                            router.pushUrl({
                                url: 'pages/conversation/ConversationPage',
                                params: {
                                    conversation: new Conversation(ConversationType.Single, this.userInfo.uid, 0)
                                }
                            }, router.RouterMode.Standard)
                        })
                } else {
                    Text('添加到通讯录')
                        .width('100%')
                        .padding(15)
                        .margin({ top: 20 })
                        .textAlign(TextAlign.Center)
                        .backgroundColor(Color.White)
                        .onClick(() => {
                            let selfUserInfo = wfc.getUserInfo(wfc.getUserId())
                            wfc.sendFriendRequest(this.userInfo.uid, '我是 ' + selfUserInfo.displayName, '', () => {
                                showToast('已发送好友请求')
                            }, err => {
                                showToast('发送好友请求失败：' + err)

                            })
                        })
                }
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#EDEDED')
        }
        .title('用户信息')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
        // .menus([
        //     {
        //         value: 'item1'
        //     },
        //     {
        //         value: 'item2'
        //     },
        //     {
        //         value: 'item3'
        //     },
        //     {
        //         value: 'item4'
        //     },
        //     {
        //         value: 'item5'
        //     }
        // ])
    }
}