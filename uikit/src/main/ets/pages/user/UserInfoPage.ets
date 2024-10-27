import { showToast } from '../../common/utils/Toast';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent';
import { navigationDestinations } from '../navigationConfig';
import ActionSheetDialog from '../../view/ActionSheetDialog';
import { selectImage } from '../../helper/mediaHelper';
import { imageThumbnail } from '../../helper/imageVideoHelper';
import MessageContentMediaType from '@wfc/client/src/main/ets/wfc/messages/messageContentMediaType';
import ModifyMyInfoEntry from '@wfc/client/src/main/ets/wfc/model/modifyMyInfoEntry';
import ModifyMyInfoType from '@wfc/client/src/main/ets/wfc/model/modifyMyInfoType';
import OptionItemView from '../../view/OptionItemView';
import avenginekit from '@wfc/avenginekit';

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

    async updatePortrait() {
        try {
            let imgUris = await selectImage(1);
            imgUris.forEach(async imgUri => {
                let base64Data = await imageThumbnail(getContext(this), imgUri, {
                    width: 640,
                    height: 640
                })
                wfc.uploadMedia(new Date().getTime() + '.jpg', base64Data, MessageContentMediaType.Image, remoteUrl => {
                    let modifyPortraitEntry: ModifyMyInfoEntry = {
                        type: ModifyMyInfoType.Modify_Portrait,
                        value: remoteUrl
                    }
                    wfc.modifyMyInfo([modifyPortraitEntry], () => {
                        this.userInfo!.portrait = remoteUrl;
                    }, err => {
                        showToast('修改头像失败 ' + err)
                    })

                }, err => {
                    console.log('uploadMedia err', err)

                }, (progress, total) => {
                    console.log('uploadMedia progress ', progress, total)

                })
            })
        } catch (reason) {
            showToast('选取照片失败: ' + reason)
        }
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    Image(this.userInfo!.portrait)
                        .width(60)
                        .height(60)
                        .borderRadius(4)
                        .onClick(() => {
                            if (this.userInfo?.uid === wfc.getUserId()) {
                                this.updatePortrait()
                            }
                        })
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

                Divider()
                OptionItemView({
                    title: '设置昵称或别名',
                    showRightArrow: true,
                    showDivider: false
                })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(navigationDestinations.UpdateUserNickNameOrAliasPage, {
                            'userInfo': this.userInfo,
                        } as Record<string, Object>)
                    })

                Column() {
                    Text('发消息')
                        .width('100%')
                        .padding(15)
                        .textAlign(TextAlign.Center)
                        .stateStyles({
                            pressed: {
                                .backgroundColor('#E5E5E5')
                            },
                            normal: {
                                .backgroundColor(Color.White)
                            }
                        })
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
                        .stateStyles({
                            pressed: {
                                .backgroundColor('#E5E5E5')
                            },
                            normal: {
                                .backgroundColor(Color.White)
                            }
                        })
                        .onClick(() => {
                            this.voipDialogController = new CustomDialogController({
                                builder: ActionSheetDialog({
                                    cancel: '取消',
                                    controller: this.voipDialogController,
                                    sheets: [
                                        {
                                            title: '语音通话',
                                            action: () => {
                                                let conversation = new Conversation(ConversationType.Single, this.userInfo!.uid, 0)
                                                avenginekit.startCall(conversation, [this.userInfo!.uid], true)
                                            }
                                        },
                                        {
                                            title: '视频通话',
                                            action: () => {
                                                let conversation = new Conversation(ConversationType.Single, this.userInfo!.uid, 0)
                                                avenginekit.startCall(conversation, [this.userInfo!.uid], false)
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
        .hideTitleBar(false)
        .title('用户信息')
        .height('100%')
        .width('100%')
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
}