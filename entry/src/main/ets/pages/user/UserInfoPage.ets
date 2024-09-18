import { showToast } from '../../common/utils/Toast';
import wfc from '../../wfc/client/wfc';
import Conversation from '../../wfc/model/conversation';
import ConversationType from '../../wfc/model/conversationType';
import UserInfo from '../../wfc/model/userInfo';
import EventType from '../../wfc/client/wfcEvent';
import { navigationDestinations } from '../navigationConfig';
import ActionSheetDialog from '../../view/ActionSheetDialog';

@Entry
@Component
export default struct UserInfoPage {
    @State userInfo?: UserInfo = undefined
    private isMyFriend: boolean = false
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private voipDialogController?: CustomDialogController

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.userInfo = params['userInfo'] as UserInfo;
        let userId = params['userId'] as string;
        if (!this.userInfo && userId) {
            this.userInfo = wfc.getUserInfo(userId);
        }
        this.isMyFriend = wfc.isMyFriend(this.userInfo!.uid)

        wfc.eventEmitter!.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
    }

    aboutToDisappear() {
        wfc.eventEmitter!.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)
    }

    onUserInfosUpdate = (infos: UserInfo[]) => {
        for (let info of infos) {
            if (info.uid === this.userInfo!.uid) {
                this.userInfo = info
                break
            }
        }
    }

    build() {
        NavDestination() {
            Navigation() {
                Column() {
                    Row() {
                        Image(this.userInfo!.portrait)
                            .width(60)
                            .height(60)
                            .borderRadius(4)
                        Column() {
                            Text(this.userInfo!.displayName)
                                .width('100%')
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .fontSize(20)
                            Text(`野火ID： ${this.userInfo!.name}`)
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

                    Column() {
                        Text('发消息')
                            .width('100%')
                            .padding(15)
                            .textAlign(TextAlign.Center)
                            .clickEffect({ level: ClickEffectLevel.HEAVY })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                                    'conversation': new Conversation(ConversationType.Single, this.userInfo!.uid, 0)
                                } as Record<string, Object>)
                            })

                        Divider()
                            .width('100%')

                        Text('音视频通话')
                            .width('100%')
                            .padding(15)
                            .textAlign(TextAlign.Center)
                            .clickEffect({ level: ClickEffectLevel.HEAVY })
                            .onClick(() => {
                                this.voipDialogController = new CustomDialogController({
                                    builder: ActionSheetDialog({
                                        cancel: '取消',
                                        controller: this.voipDialogController,
                                        sheets: [
                                            {
                                                title: '语音通话',
                                                action: () => {
                                                    // TODO
                                                    showToast('TODO')
                                                }
                                            },
                                            {
                                                title: '视频通话',
                                                action: () => {
                                                    // TODO
                                                    showToast('TODO')
                                                }
                                            },
                                        ]
                                    }),
                                    autoCancel: true,
                                    alignment: DialogAlignment.Center,
                                    // gridCount: 4,
                                    customStyle: false
                                })

                                this.voipDialogController.open()
                            })
                    }
                    .backgroundColor(Color.White)
                    .margin({ top: 20 })

                    if (!this.isMyFriend && this.userInfo!.uid !== wfc.getUserId()) {
                        Text('添加到通讯录')
                            .width('100%')
                            .padding(15)
                            .margin({ top: 20 })
                            .textAlign(TextAlign.Center)
                            .backgroundColor(Color.White)
                            .onClick(() => {
                                let selfUserInfo = wfc.getUserInfo(wfc.getUserId())
                                wfc.sendFriendRequest(this.userInfo!.uid, '我是 ' + selfUserInfo.displayName, '', () => {
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
            .width('100%')
            .height('100%')
            .title('用户信息')
            .titleMode(NavigationTitleMode.Mini)
            .hideBackButton(false)
            .menus([
                {
                    value: '',
                    icon: 'resources/base/media/ic_public_more.svg',
                    action: () => {
                        this.mainNavPathStack.pushPathByName(navigationDestinations.UpdateUserInfoPage, {
                            'userInfo': this.userInfo
                        } as Record<string, Object>)

                    }
                }
            ])
        }
        .hideTitleBar(true)
        .height('100%')
        .width('100%')
    }
}