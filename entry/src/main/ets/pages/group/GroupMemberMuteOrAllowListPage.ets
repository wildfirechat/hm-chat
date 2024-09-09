import { showToast } from '../../common/utils/Toast';
import ToggleItemView from '../../view/ToggleItemView'
import wfc from '../../wfc/client/wfc';
import GroupInfo from '../../wfc/model/groupInfo'
import GroupMemberType from '../../wfc/model/groupMemberType';
import ModifyGroupInfoType from '../../wfc/model/modifyGroupInfoType';
import UserInfo from '../../wfc/model/userInfo';
import PickGroupMemberModal from './PickGroupMemberModal';

@Entry
@Component
export default struct GroupMemberMuteOrAllowListPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State groupInfo?: GroupInfo = undefined
    @State mutedGroupMemberUsers: UserInfo[] = []
    @State allowGroupMemberUsers: UserInfo[] = []
    @State showPickGroupMemberModal: boolean = false
    private groupOwnerUid?: string
    private groupManagerUids: string[] = []

    aboutToAppear(): void {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo;

        this.groupOwnerUid = this.groupInfo.owner;
        let groupManagers = wfc.getGroupMembersByType(this.groupInfo.target, GroupMemberType.Manager)
        this.groupManagerUids = groupManagers.map(m => m.memberId)
        this.groupManagerUids.push(this.groupOwnerUid)
        this.loadMuteOrAllowGroupMembers()
    }

    private loadMuteOrAllowGroupMembers() {
        if (this.groupInfo!.mute === 1) {
            let allowMembers = wfc.getGroupMembersByType(this.groupInfo!.target, GroupMemberType.Allowed)
            this.allowGroupMemberUsers = wfc.getUserInfos(allowMembers.map(m => m.memberId), this.groupInfo!.target)
        } else {
            let mutedMembers = wfc.getGroupMembersByType(this.groupInfo!.target, GroupMemberType.Muted)
            this.mutedGroupMemberUsers = wfc.getUserInfos(mutedMembers.map(m => m.memberId), this.groupInfo!.target)
        }
    }

    @Builder
    pickGroupMemberModal() {
        PickGroupMemberModal({
            groupId: this.groupInfo?.target,
            title: this.groupInfo?.mute === 0 ? '添加群禁言黑名单' : '添加群禁言白名单',
            showPickGroupMemberModal: $showPickGroupMemberModal,
            uncheckableUserIds: [this.groupOwnerUid!].concat(this.groupManagerUids),
            initialCheckedUserIds: [this.groupOwnerUid!].concat(this.groupManagerUids)

        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    build() {
        NavDestination() {
            Column() {
                ToggleItemView(
                    {
                        title: '全员禁言',
                        isOn: this.groupInfo?.mute === 1,
                        onChange: isOn => {
                            wfc.modifyGroupInfo(this.groupInfo!.target, ModifyGroupInfoType.Modify_Group_Mute, isOn ? '1' : '0', [0], null, () => {
                                this.groupInfo!.mute = isOn ? 1 : 0
                                this.allowGroupMemberUsers = []
                                this.mutedGroupMemberUsers = []
                            }, err => {
                                showToast((isOn ? '设置全局禁言失败 ' : '取消全局禁言失败') + " " + err)
                            })
                        }
                    }
                )
                Row() {
                    Image($r('app.media.ic_add_team_member'))
                        .width(40)
                        .height(40)
                        .margin(10)
                    Text(this.groupInfo?.mute === 0 ? '禁言成员' : '发言白名单')
                }
                .alignItems(VerticalAlign.Center)
                .width('100%')
                .stateStyles({
                    pressed: {
                        .backgroundColor('#E5E5E5')
                    },
                    normal: {
                        .backgroundColor(Color.White)
                    }
                })
                .onClick(() => {
                    if (this.groupInfo?.mute === 1) {
                        // 添加白名单

                    } else {
                        // 添加黑名单
                    }
                })
                .bindContentCover(this.showPickGroupMemberModal, this.pickGroupMemberModal(), {
                    modalTransition: ModalTransition.DEFAULT,
                    onAppear: () => {
                    },

                    onDisappear: () => {
                        this.showPickGroupMemberModal = false
                        let localStorage = LocalStorage.getShared();
                        let pickUsers = localStorage.get<UserInfo[]>(PickGroupMemberModal.PICK_RESULT);
                        if (pickUsers?.length) {
                            localStorage.delete(PickGroupMemberModal.PICK_RESULT)
                            let uids = pickUsers.map(info => info.uid)
                            // TODO
                            if (this.groupInfo?.mute === 1) {
                                wfc.allowGroupMembers(this.groupInfo.target, true, uids, [0], null, () => {
                                    let userInfos = wfc.getUserInfos(uids, this.groupInfo!.target)
                                    this.allowGroupMemberUsers = this.allowGroupMemberUsers.concat(userInfos)
                                }, err => {
                                    showToast('添加白名单失败 ' + err)

                                })
                            } else {
                                wfc.muteGroupMembers(this.groupInfo!.target, true, uids, [0], null, () => {
                                    let userInfos = wfc.getUserInfos(uids, this.groupInfo!.target)
                                    this.mutedGroupMemberUsers = this.allowGroupMemberUsers.concat(userInfos)
                                }, err => {
                                    showToast('添加黑名单失败 ' + err)
                                })
                            }
                        }
                    }
                })
                .onClick(() => {
                    this.showPickGroupMemberModal = true
                })

                List() {
                    ForEach(this.groupInfo?.mute === 0 ? this.mutedGroupMemberUsers : this.allowGroupMemberUsers, (info: UserInfo, index: number) => {
                        ListItem() {
                            Row() {
                                Image(info.portrait)
                                    .width(40)
                                    .height(40)
                                    .margin(10)
                                    .borderRadius(4)
                                Text(info.displayName)
                                    .maxLines(1)
                            }
                            .width('100%')
                            .justifyContent(FlexAlign.Start)
                            .stateStyles({
                                pressed: {
                                    .backgroundColor('#E5E5E5')
                                },
                                normal: {
                                    .backgroundColor(Color.White)
                                }
                            })
                            .onClick(() => {
                                if (this.groupInfo?.mute === 1) {
                                    wfc.allowGroupMembers(this.groupInfo.target, false, [info.uid], [0], null, () => {
                                        this.allowGroupMemberUsers.splice(index, 1)
                                    }, err => {
                                        showToast('取消允许发言失败')
                                    })
                                } else {
                                    wfc.muteGroupMembers(this.groupInfo!.target, false, [info.uid], [0], null, () => {
                                        this.mutedGroupMemberUsers.splice(index, 1)
                                    }, err => {
                                        showToast('取消禁言失败')
                                    })
                                }
                            })
                        }
                    }, (info: UserInfo) => info.uid + info.updateDt)
                }
                .width('100%')
            }
        }
        .title('群禁言')
        .height('100%')
        .width('100%')
    }
}
