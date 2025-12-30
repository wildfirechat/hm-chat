import router from '@ohos.router';
import { showToast } from '../../common/utils/Toast';
import OptionItemView from '../../view/OptionItemView';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo';
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo';
import GroupMember from '@wfc/client/src/main/ets/wfc/model/groupMember';
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType';
import GroupType from '@wfc/client/src/main/ets/wfc/model/groupType';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import ActionSheetDialog from '../../view/ActionSheetDialog';
import AddGroupMemberModal from '../group/AddGroupMemberModal';
import PickGroupMemberModal from '../group/PickGroupMemberModal';
import appServer from '../../api/appServer';
import GroupAnnouncement from '../../api/model/groupAnnouncement';
import AppServerError from '../../api/appServerError';
import { uikitNavigationDestinations } from '../uikitNavigationConfig';
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent';
import { imageThumbnail, imageThumbnailFile } from '../../helper/imageVideoHelper';
import { selectImage } from '../../helper/mediaHelper';
import MessageContentMediaType from '@wfc/client/src/main/ets/wfc/messages/messageContentMediaType';
import ModifyGroupInfoType from '@wfc/client/src/main/ets/wfc/model/modifyGroupInfoType';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';

import JoinGroupRequestDialog from '../group/JoinGroupRequestDialog';

@Preview
@Component
export default struct GroupConversationInfoPage {
    @State groupInfo: GroupInfo = {} as GroupInfo
    @State isTop: boolean = false
    @State isSilent: boolean = false
    @State groupMembers: GroupMember[] = []
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State showAddGroupMemberModal: boolean = false
    @State showRemoveGroupMemberModal: boolean = false
    @State groupAnnouncement: string = ''
    @State userInfo?: UserInfo = undefined
    @State showGroupMemberNickName: boolean = false
    private conversationInfo?: ConversationInfo
    private groupMember?: GroupMember
    private enableAddMember: boolean = false
    private enableRemoveMember: boolean = false
    private maxShowGroupMemberCount = 20
    private toShowGroupMemberCount = this.maxShowGroupMemberCount

    private joinGroupRequestDialogController?: CustomDialogController = new CustomDialogController({
        builder: JoinGroupRequestDialog({
            confirm: (text: string) => {
                this.joinGroupRequestDialogController?.close()
                this.sendJoinGroupRequest(text)
            },
            cancel: () => {
                this.pendingMemberIds = []
            }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center,
        customStyle: false
    })
    private pendingMemberIds: string[] = []

    sendJoinGroupRequest(reason: string) {
        if (this.pendingMemberIds.length > 0) {
            wfc.sendJoinGroupRequest(this.groupInfo.target, this.pendingMemberIds, reason, '', () => {
                showToast('已发送加群申请')
                this.pendingMemberIds = []
            }, err => {
                showToast('发送加群申请失败：' + err)
                this.pendingMemberIds = []
            })
        }
    }

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conversationInfo = params['conversationInfo'] as ConversationInfo
        this.groupInfo = wfc.getGroupInfo(this.conversationInfo.conversation.target)
        this.groupMembers = wfc.getGroupMembersByCount(this.conversationInfo.conversation.target, this.maxShowGroupMemberCount)

        if (this.groupInfo.memberDt < 0) {
            showToast('你已被移除群聊')
            this.mainNavPathStack.pop()
            return
        }

        this.groupMember = wfc.getGroupMember(this.groupInfo.target, wfc.getUserId())
        if (this.groupInfo.type !== GroupType.Organization) {
            if (this.groupInfo.joinType === 2) {
                if (this.groupMember.type === GroupMemberType.Owner || this.groupMember.type === GroupMemberType.Manager) {
                    this.enableAddMember = true
                    this.enableRemoveMember = true
                    this.toShowGroupMemberCount -= 2
                }
            } else {
                this.enableAddMember = true
                this.toShowGroupMemberCount--
                if (this.groupMember.type === GroupMemberType.Owner || this.groupMember.type === GroupMemberType.Manager) {
                    this.enableRemoveMember = true
                    this.toShowGroupMemberCount--
                }
            }
        }

        appServer.getGroupAnnouncement(this.groupInfo.target)
            .then((groupAnnouncement: GroupAnnouncement) => {
                this.groupAnnouncement = groupAnnouncement.text
            })
            .catch((err: AppServerError) => {
                showToast('获取群公告失败 ' + err.message)
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

    private unremovableGroupMemberIds() {
        let selfUid = wfc.getUserId()
        let uids: string[] = [selfUid]
        if (this.groupMember?.type === GroupMemberType.Manager) {
            let otherManagerIds = this.groupMembers.filter(m => m.type === GroupMemberType.Manager || m.type === GroupMemberType.Owner)
                .filter(m => m.memberId !== selfUid)
                .map(m => m.memberId)
            uids.push(...otherManagerIds)
        }
        return uids
    }

    @Builder
    removeGroupMemberModal() {
        PickGroupMemberModal({
            groupId: this.groupInfo.target,
            showPickGroupMemberModal: $showRemoveGroupMemberModal,
            uncheckableUserIds: this.unremovableGroupMemberIds(),
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
                        ForEach(this.groupMembers.slice(0, this.toShowGroupMemberCount), (groupMember: GroupMember) => {
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
                            .onClick(() => {
                                if (this.groupInfo.privateChat === 1 && [GroupMemberType.Owner, GroupMemberType.Manager].indexOf(this.groupMember!.type) === -1) {
                                    showToast('禁止私聊')
                                } else {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                                        'userInfo': wfc.getUserInfo(groupMember.memberId)
                                    } as Record<string, Object>)
                                }
                            })
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
                                                    if (err === 13) {
                                                        this.pendingMemberIds = uids
                                                        this.joinGroupRequestDialogController?.open()
                                                    } else {
                                                        showToast('添加新成员失败：' + err)
                                                    }
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
                        if (this.groupInfo.memberCount > this.groupMembers.length) {
                            Row() {
                                Text('查看全部成员')
                            }
                            .justifyContent(FlexAlign.Center)
                            .alignItems(VerticalAlign.Center)
                            .width('100%')
                            .height(60)
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupMemberListPage, { 'groupInfo': this.groupInfo } as Record<string, object>)
                            })
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
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UpdateGroupNamePage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })
                        OptionItemView({
                            title: '群头像',
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
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupQRCodePage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })
                        OptionItemView({
                            title: '群公告',
                            subTitle: this.groupAnnouncement
                        })
                            .onClick(() => {
                                if ([GroupMemberType.Owner, GroupMemberType.Manager].indexOf(this.groupMember!.type) >= 0) {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UpdateGroupAnnouncementPage, {
                                        'groupInfo': this.groupInfo
                                    } as Record<string, Object>)
                                } else {
                                    showToast('仅管理员或群主可以设置群公告')
                                }
                            })
                        OptionItemView({
                            title: '群备注',
                            desc: this.groupInfo.remark
                        })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UpdateGroupRemarkPage, {
                                    'groupInfo': this.groupInfo
                                } as Record<string, Object>)
                            })
                        if ([GroupMemberType.Owner, GroupMemberType.Manager].indexOf(this.groupMember!.type) >= 0) {
                            OptionItemView({
                                title: '群管理',
                                showDivider: false
                            })
                                .onClick(() => {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupManagePage, {
                                        'groupInfo': this.groupInfo
                                    } as Record<string, Object>)
                                })
                        }

                        OptionItemView({ title: '举报' })
                            .onClick(event => {
                                AlertDialog.show({
                                    title: "举报",
                                    message: $r("app.string.complaint"),
                                    primaryButton: {
                                        value: "举报",
                                        fontColor: Color.Red,
                                        action: () => {
                                            let conversation = new Conversation(ConversationType.Single, 'cgc8c8VV', 0)
                                            this.mainNavPathStack.popToName(uikitNavigationDestinations.ConversationPage)
                                            this.mainNavPathStack.replacePathByName(uikitNavigationDestinations.ConversationPage, {
                                                'conversation': conversation
                                            } as Record<string, Object>)
                                        },
                                    },
                                    secondaryButton: {
                                        value: '取消',
                                        action: () => {

                                        }
                                    }
                                })
                            })
                    }
                    .margin({ top: 10 })
                    .width('100%')
                    .backgroundColor(Color.White)

                    Column() {
                        OptionItemView({ title: '查找聊天记录' })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.SearchConversationMessagePage, {
                                    'conversation': this.conversationInfo?.conversation
                                } as Record<string, Object>)
                            })
                        OptionItemView({ title: '文件记录', showDivider: false })
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.FileRecordPage, {
                                    'conversation': this.conversationInfo?.conversation,
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
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UpdateMyGroupAliasPage, {
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
                            let clearConversationHistoryDialogController = new CustomDialogController({
                                builder: ActionSheetDialog({
                                    title: '清空聊天记录?',
                                    sheets: [
                                        {
                                            title: '清除本地聊天记录',
                                            action: () => {
                                                clearConversationHistoryDialogController.close()
                                                wfc.clearMessages(this.conversationInfo!.conversation)
                                            }
                                        },
                                        {
                                            title: '清除远程聊天记录',
                                            action: () => {
                                                clearConversationHistoryDialogController.close()
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

                            clearConversationHistoryDialogController.open()
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
                            AlertDialog.show({
                                // title: '解散群组',
                                message: '解散群组',
                                primaryButton: {
                                    value: '确定',
                                    action: () => {
                                        wfc.dismissGroup(this.groupInfo.target, [0], null, () => {
                                            this.mainNavPathStack.clear()
                                        }, err => {
                                            showToast('解散群组失败 ' + err)
                                        })
                                    }
                                },
                                secondaryButton: {
                                    value: '取消',
                                    action: () => {
                                    }
                                }
                            })
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
        }
        .backgroundColor('#EEEEEE')
        .title('会话详情')
        .height('100%')
        .width('100%')
    }
}
