import router from '@ohos.router';
import { showToast } from '../../common/utils/Toast';
import OptionItemView from '../../view/OptionItemView';
import wfc from '../../wfc/client/wfc';
import ConversationInfo from '../../wfc/model/conversationInfo';
import GroupInfo from '../../wfc/model/groupInfo';
import GroupMember from '../../wfc/model/groupMember';
import GroupMemberType from '../../wfc/model/groupMemberType';
import GroupType from '../../wfc/model/groupType';
import UserInfo from '../../wfc/model/userInfo';
import ActionSheetDialog from '../../view/ActionSheetDialog';
import AddGroupMemberModal from '../group/AddGroupMemberModal';
import PickGroupMemberModal from '../group/PickGroupMemberModal';
import appServer from '../../api/appServer';
import GroupAnnouncement from '../../api/model/groupAnnouncement';
import AppServerError from '../../api/appServerError';
import { navigationDestinations } from '../navigationConfig';
import EventType from '../../wfc/client/wfcEvent';
import { imageThumbnail, imageThumbnailFile } from '../../helper/imageVideoHelper';
import { selectImage } from '../../helper/mediaHelper';
import MessageContentMediaType from '../../wfc/messages/messageContentMediaType';
import ModifyGroupInfoType from '../../wfc/model/modifyGroupInfoType';

@Preview
@Entry
@Component
export default struct GroupConversationInfoPage {
    @State groupInfo: GroupInfo = {} as GroupInfo
    @State isTop: boolean = false
    @State isSilent: boolean = false
    @State groupMembers: GroupMember[] = []
    private conversationInfo?: ConversationInfo
    private enableAddMember: boolean = false
    private enableRemoveMember: boolean = false
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State showAddGroupMemberModal: boolean = false
    @State showRemoveGroupMemberModal: boolean = false
    @State groupAnnouncement: string = ''
    @State userInfo?: UserInfo = undefined
    private clearConversationHistoryDialogController?: CustomDialogController
    @State showGroupMemberNickName: boolean = false

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conversationInfo = params['conversationInfo'] as ConversationInfo
        this.groupInfo = wfc.getGroupInfo(this.conversationInfo.conversation.target)
        this.groupMembers = wfc.getGroupMembers(this.conversationInfo.conversation.target, false)

        if (this.groupInfo.memberDt < 0) {
            showToast('你已被移除群聊')
            this.mainNavPathStack.pop()
            return
        }

        if (this.groupInfo.type !== GroupType.Organization) {
            let groupMember = wfc.getGroupMember(this.groupInfo.target, wfc.getUserId())
            if (this.groupInfo.joinType === 2) {
                if (groupMember.type === GroupMemberType.Owner || groupMember.type === GroupMemberType.Manager) {
                    this.enableAddMember = true
                    this.enableRemoveMember = true
                }
            } else {
                this.enableAddMember = true
                if (groupMember.type === GroupMemberType.Owner || groupMember.type === GroupMemberType.Manager) {
                    this.enableRemoveMember = true
                }
            }
        }

        appServer.getGroupAnnouncement(this.groupInfo.target)
            .then((groupAnnouncement: GroupAnnouncement) => {
                this.groupAnnouncement = groupAnnouncement.text
            })
            .catch((err: AppServerError) => {
                // showToast('获取群公告失败 ' + err.message)
            })

        wfc.eventEmitter?.on(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)

        this.userInfo = wfc.getUserInfo(wfc.getUserId(), false, this.groupInfo.target)

        this.showGroupMemberNickName = !wfc.isHiddenGroupMemberName(this.groupInfo.target)
    }

    onPageShow() {
        this.userInfo = wfc.getUserInfo(wfc.getUserId(), false, this.groupInfo.target)
    }

    onGroupInfosUpdate = (infos: GroupInfo[]) => {
        let info = infos.find(i => i.target === this.groupInfo.target)
        if (info) {
            this.groupInfo = info
        }
    }

    aboutToDisappear(): void {
        wfc.eventEmitter?.off(EventType.GroupInfosUpdate, this.onGroupInfosUpdate)
    }

    @Builder
    addGroupMemberModal() {
        AddGroupMemberModal({ groupInfo: this.groupInfo, showAddGroupMemberModal: $showAddGroupMemberModal })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    @Builder
    removeGroupMemberModal() {
        PickGroupMemberModal({
            groupId: this.groupInfo.target,
            showPickGroupMemberModal: $showRemoveGroupMemberModal,
            title: '移除群成员'
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    build() {
        NavDestination() {
            Scroll() {

                Column() {
                    Flex({
                        justifyContent: FlexAlign.Start,
                        alignContent: FlexAlign.SpaceAround,
                        wrap: FlexWrap.Wrap
                    }) {
                        ForEach(this.groupMembers, (groupMember: GroupMember) => {
                            Column() {
                                Image(groupMember.getPortrait())
                                    .width(48)
                                    .height(48)
                                    .borderRadius(4)
                                Text(groupMember.getName())
                                    .maxLines(1)
                                    .fontColor('#7E7E7E')
                                    .fontSize(12)
                                    .margin({ top: 5 })
                            }
                            .width('20%')
                            .padding(8)
                            .justifyContent(FlexAlign.Center)
                            .alignItems(HorizontalAlign.Center)
                        }, (groupMember: GroupMember) => groupMember.memberId + '-' + groupMember.updateDt)

                        if (this.enableAddMember) {
                            Column() {
                                Image($r('app.media.ic_add_team_member'))
                                    .width(48)
                                    .height(48)
                                    .bindContentCover(this.showAddGroupMemberModal, this.addGroupMemberModal(), {
                                        modalTransition: ModalTransition.DEFAULT,
                                        onAppear: () => {
                                        },

                                        onDisappear: () => {
                                            this.showAddGroupMemberModal = false
                                            let localStorage = LocalStorage.getShared();
                                            let pickUsers = localStorage.get<UserInfo[]>(AddGroupMemberModal.PICK_RESULT);
                                            if (pickUsers?.length) {
                                                localStorage.delete(AddGroupMemberModal.PICK_RESULT)
                                                let uids = pickUsers.map(info => info.uid)

                                                wfc.addGroupMembers(this.groupInfo.target, uids, '', [0], null, () => {
                                                    this.groupMembers = wfc.getGroupMembers(this.conversationInfo!.conversation.target, false)
                                                    showToast('添加新群成员成功')
                                                }, (err: number) => {
                                                    showToast('添加新成员失败：' + err)
                                                })
                                            }
                                        }
                                    })
                                    .onClick(() => {
                                        this.showAddGroupMemberModal = true
                                    })
                            }
                            .padding(8)
                            .justifyContent(FlexAlign.Center)
                            .alignItems(HorizontalAlign.Center)
                        }
                        if (this.enableRemoveMember) {
                            Column() {
                                Image($r('app.media.ic_remove_team_member'))
                                    .width(48)
                                    .height(48)
                                    .bindContentCover(this.showRemoveGroupMemberModal, this.removeGroupMemberModal(), {
                                        modalTransition: ModalTransition.DEFAULT,
                                        onAppear: () => {
                                        },

                                        onDisappear: () => {
                                            this.showRemoveGroupMemberModal = false
                                            let localStorage = LocalStorage.getShared();
                                            let pickUsers = localStorage.get<UserInfo[]>(PickGroupMemberModal.PICK_RESULT);
                                            if (pickUsers?.length) {
                                                localStorage.delete(PickGroupMemberModal.PICK_RESULT)
                                                let uids = pickUsers.map(info => info.uid)
                                                wfc.kickoffGroupMembers(this.groupInfo.target, uids, [0], null, () => {
                                                    this.groupMembers = wfc.getGroupMembers(this.conversationInfo!.conversation.target, false)
                                                }, (err: number) => {
                                                    showToast('移除群成员失败：' + err)
                                                })
                                            }
                                        }
                                    })
                                    .onClick(() => {
                                        this.showRemoveGroupMemberModal = true
                                    })
                            }
                            .padding(8)
                            .justifyContent(FlexAlign.Center)
                            .alignItems(HorizontalAlign.Center)
                        }
                    }
                    .padding(10)
                    .width('100%')
                    .backgroundColor(Color.White)

                    Column() {
                        // TODO

                    }
                    .margin({ top: 10 })
                    .width('100%')

                    Column() {
                        OptionItemView({
                            title: '群聊名称',
                            desc: this.groupInfo.name
                        })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.UpdateGroupNamePage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })
                        OptionItemView({
                            title: ' 群头像',
                            imgUrl: this.groupInfo.portrait
                        })
                            .onClick(async () => {
                                try {
                                    let imgUris = await selectImage(1);
                                    imgUris.forEach(async imgUri => {
                                        let base64Data = await imageThumbnail(getContext(this), imgUri, {
                                            width: 640,
                                            height: 640
                                        })
                                        wfc.uploadMedia(new Date().getTime() + '.jpg', base64Data, MessageContentMediaType.Image, remoteUrl => {
                                            wfc.modifyGroupInfo(this.groupInfo.target, ModifyGroupInfoType.Modify_Group_Portrait, remoteUrl, [0], null, () => {
                                                this.groupInfo.portrait = remoteUrl;
                                            }, err => {
                                                showToast('修改群头像失败 ' + err)
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
                            })
                        OptionItemView({
                            title: '二维码',
                            imgUrl: 'http://static.wildfirechat.cn/wx_wfc_qrcode.jpg'
                        })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.GroupQRCodePage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })
                        OptionItemView({
                            title: '群公告',
                            subTitle: this.groupAnnouncement
                        })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.UpdateGroupAnnouncementPage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })
                        OptionItemView({
                            title: '群备注',
                            desc: this.groupInfo.remark
                        })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.UpdateGroupRemarkPage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })
                        OptionItemView({
                            title: '群管理',
                            showDivider: false
                        })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.GroupManagePage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })
                    }
                    .margin({ top: 10 })
                    .width('100%')
                    .backgroundColor(Color.White)

                    Column() {
                        OptionItemView({ title: '查找聊天记录' })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.SearchConversationMessagePage, {
                                    'conversation': this.conversationInfo?.conversation
                                } as Record<string, Object>)
                            })
                        OptionItemView({ title: '文件记录', showDivider: false })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationFileRecordPage, {
                                    'conversation': this.conversationInfo?.conversation
                                } as Record<string, Object>)
                            })
                    }
                    .margin({ top: 10 })
                    .width('100%')
                    .backgroundColor(Color.White)

                    Column() {
                        Row() {
                            Text('消息免打扰')
                            Toggle({ type: ToggleType.Switch, isOn: this.conversationInfo!.isSilent })
                                .onChange(isOn => {
                                    wfc.setConversationSlient(this.conversationInfo!.conversation, isOn, () => {
                                        // do nothing
                                    }, err => {
                                        showToast('设置消息免打扰失败 ' + err)
                                    })
                                })
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .width('100%')
                        .height(56)
                        .padding({ left: 10, right: 10 })

                        Divider()
                            .strokeWidth(0.6)
                            .color('#EDEDED')
                            .padding({ left: 10 })

                        Row() {
                            Text('置顶聊天')
                            Toggle({ type: ToggleType.Switch, isOn: this.conversationInfo!.top > 0 })
                                .onChange((value: boolean) => {
                                    wfc.setConversationTop(this.conversationInfo!.conversation, value ? 1 : 0, () => {

                                    }, (err: number) => {
                                        showToast(value ? '会话置顶失败' : '取消置顶失败')
                                    })
                                })
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .width('100%')
                        .height(56)
                        .padding({ left: 10, right: 10 })

                        Divider()
                            .strokeWidth(0.6)
                            .color('#EDEDED')
                            .padding({ left: 10 })

                        Row() {
                            Text('保存到通讯录')
                            Toggle({
                                type: ToggleType.Switch,
                                isOn: wfc.isFavGroup(this.groupInfo.target)
                            })// .select(this.conversationInfo.top > 0)
                                .onChange((value: boolean) => {
                                    wfc.setFavGroup(this.conversationInfo!.conversation.target, value, null, err => {
                                        showToast('保存到通讯录失败' + err)
                                    })
                                })
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .width('100%')
                        .height(56)
                        .padding({ left: 10, right: 10 })
                    }
                    .margin({ top: 10 })
                    .width('100%')
                    .backgroundColor(Color.White)

                    Column() {
                        OptionItemView({ title: '我在本群的昵称', desc: this.userInfo?.groupAlias })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.UpdateMyGroupAliasPage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })

                        Row() {
                            Text('显示群成员昵称聊天')
                            Toggle({ type: ToggleType.Switch, isOn: this.showGroupMemberNickName })
                                .onChange((value: boolean) => {
                                    wfc.setHiddenGroupMemberName(this.groupInfo.target, !value, () => {
                                        this.showGroupMemberNickName = value;
                                    }, err => {
                                        showToast('设置失败')
                                    })
                                })
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .width('100%')
                        .height(56)
                        .padding({ left: 10, right: 10 })

                    }
                    .margin({ top: 10 })
                    .width('100%')
                    .backgroundColor(Color.White)

                    Column() {
                        Row() {
                            Text('清空聊天记录')
                                .fontColor(Color.Red)
                        }
                        .height(56)
                        .width('100%')
                        .justifyContent(FlexAlign.Center)
                        .alignItems(VerticalAlign.Center)
                        .stateStyles({
                            pressed: {
                                .backgroundColor('#E5E5E5')
                            },
                            normal: {
                                .backgroundColor(Color.White)
                            }
                        })
                        .onClick(event => {
                            this.clearConversationHistoryDialogController = new CustomDialogController({
                                builder: ActionSheetDialog({
                                    title: '清空聊天记录?',
                                    controller: this.clearConversationHistoryDialogController,
                                    sheets: [
                                        {
                                            title: '清除本地聊天记录',
                                            action: () => {
                                                wfc.clearMessages(this.conversationInfo!.conversation)
                                            }
                                        },
                                        {
                                            title: '清除远程聊天记录',
                                            action: () => {
                                                wfc.clearRemoteConversationMessages(this.conversationInfo!.conversation, () => {
                                                    showToast('清除远程远程会话消息失败')
                                                }, err => {
                                                    showToast('清除远程会话消息失败')
                                                })
                                            }
                                        }
                                    ]
                                }),
                                autoCancel: true,
                                alignment: DialogAlignment.Center,
                                gridCount: 6,
                                customStyle: false
                            })

                            this.clearConversationHistoryDialogController.open()
                        })

                        Divider()
                            .strokeWidth(0.6)
                            .color('#EDEDED')

                        Row() {
                            Text(this.groupInfo.owner === wfc.getUserId() ? '解散群组' : '删除并退出')
                                .fontColor(Color.Red)
                        }
                        .margin({ top: 2 })
                        .height(56)
                        .width('100%')
                        .justifyContent(FlexAlign.Center)
                        .alignItems(VerticalAlign.Center)
                        .stateStyles({
                            pressed: {
                                .backgroundColor('#E5E5E5')
                            },
                            normal: {
                                .backgroundColor(Color.White)
                            }
                        })
                        .onClick(() => {
                            showToast('TODO')
                            // let dialogController: CustomDialogController = new CustomDialogController({
                            //     builder: ActionSheetDialog({
                            //         title: 'Test',
                            //         sheets: [
                            //             {
                            //                 title: '项目 1',
                            //                 action: () => {
                            //                     showToast('000000000')
                            //                 }
                            //             },
                            //             {
                            //                 title: '项目 2',
                            //                 action: () => {
                            //                     showToast('0000000002')
                            //                 }
                            //             },
                            //             {
                            //                 title: '项目 3',
                            //                 action: () => {
                            //                     showToast('0000000003')
                            //                 }
                            //             }
                            //         ]
                            //     }),
                            //     autoCancel: true,
                            //     alignment: DialogAlignment.Default,
                            //     gridCount: 4,
                            //     customStyle: false
                            // })
                            //
                            // dialogController.open()
                        })
                    }
                    .margin({ top: 10, bottom: 20 })
                    .width('100%')
                    .backgroundColor(Color.White)
                }
            }
            .scrollBar(BarState.Off)
            .width('100%')
            .height('100%')
            .backgroundColor('#EDEDED')
        }
        .title('会话详情')
        .height('100%')
        .width('100%')
    }
}
