import { showToast } from '../../common/utils/Toast'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import GroupMemberType from '@wfc/client/src/main/ets/wfc/model/groupMemberType'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import PickGroupMemberModal from './PickGroupMemberModal'
import ActionSheetDialog from '../../view/ActionSheetDialog'

@Component
export default struct GroupManagerListPage {
    private customDialogController?: CustomDialogController
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State groupOwnerUerInfo?: UserInfo = undefined
    @State groupManagerUserInfos: UserInfo[] = []
    @State showPickGroupMemberModal: boolean = false
    private groupInfo?: GroupInfo

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo;
        let groupManagers = wfc.getGroupMembersByType(this.groupInfo.target, GroupMemberType.Manager)
        this.groupOwnerUerInfo = wfc.getUserInfo(this.groupInfo.owner, false, this.groupInfo.target);
        this.groupManagerUserInfos = wfc.getUserInfos(groupManagers.map(m => m.memberId), this.groupInfo.target)
    }

    @Builder
    pickGroupMemberModal(onPickResult: (userInfos: UserInfo[]) => void) {
        PickGroupMemberModal({
            groupId: this.groupInfo?.target,
            title: '添加管理员',
            showPickGroupMemberModal: $showPickGroupMemberModal,
            uncheckableUserIds: [this.groupOwnerUerInfo!.uid].concat(this.groupManagerUserInfos.map(u => u.uid)),
            initialCheckedUserIds: [this.groupOwnerUerInfo!.uid].concat(this.groupManagerUserInfos.map(u => u.uid)),
            onPickResult: onPickResult

        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor($r('app.color.wf_background'))
    }

    build() {
        NavDestination() {
            Column() {
                Text('群主')
                    .textAlign(TextAlign.Start)
                    .backgroundColor($r('app.color.wf_secondary_background'))
                    .padding({ left: 10, top: 5, bottom: 5 })
                    .width('100%')
                Row() {
                    Image(this.groupOwnerUerInfo!.portrait)
                        .width(40)
                        .height(40)
                        .margin(10)
                        .borderRadius(4)
                    Text(this.groupOwnerUerInfo?.displayName)
                        .maxLines(1)
                        .fontColor($r('app.color.wf_primary_text'))
                }
                .width('100%')
                .stateStyles({
                    pressed: {
                        .backgroundColor($r('app.color.wf_item_pressed'))
                    },
                    normal: {
                        .backgroundColor($r('app.color.wf_background'))
                    }
                })

                if (this.groupManagerUserInfos.length > 0) {
                    Text('管理员')
                        .textAlign(TextAlign.Start)
                        .backgroundColor($r('app.color.wf_secondary_background'))
                        .padding({ left: 10, top: 5, bottom: 5 })
                        .width('100%')
                    List() {
                        ForEach(this.groupManagerUserInfos, (info: UserInfo) => {
                            ListItem() {
                                Row() {
                                    Image(info.portrait)
                                        .width(40)
                                        .height(40)
                                        .margin(10)
                                        .borderRadius(4)
                                    Text(info.displayName)
                                        .maxLines(1)
                                        .fontColor($r('app.color.wf_primary_text'))
                                }
                                .width('100%')
                                .justifyContent(FlexAlign.Start)
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor($r('app.color.wf_item_pressed'))
                                    },
                                    normal: {
                                        .backgroundColor($r('app.color.wf_background'))
                                    }
                                })
                                .onClick(() => {
                                    let customDialogController: CustomDialogController = new CustomDialogController({
                                        builder: ActionSheetDialog({
                                            sheets: [
                                                {
                                                    title: '移除管理员',
                                                    action: () => {
                                                        wfc.setGroupManager(this.groupInfo!.target, false, [info.uid], [], null, () => {
                                                            this.groupManagerUserInfos = this.groupManagerUserInfos.filter(u => u.uid !== info.uid)
                                                        }, err => {
                                                            showToast('移除管理员失败 ' + err)

                                                        })
                                                        customDialogController.close()
                                                    }
                                                },
                                            ],
                                        }),
                                        autoCancel: true,
                                        alignment: DialogAlignment.Center,
                                        // gridCount: 4,
                                        customStyle: false
                                    })

                                    customDialogController.open()
                                })
                            }
                        }, (info: UserInfo) => info.uid + info.updateDt)
                    }
                    .width('100%')
                    .divider({
                        strokeWidth: 1,
                        startMargin: 60
                    })
                }

                if (this.groupInfo?.owner === wfc.getUserId()) {
                    Row() {
                        Image($r('app.media.avatar_def'))
                            .width(40)
                            .height(40)
                            .margin(10)
                            .borderRadius(4)
                        Text('添加管理员')
                            .maxLines(1)
                            .fontColor($r('app.color.wf_primary_text'))
                    }
                    .margin({ top: 20 })
                    .bindContentCover(this.showPickGroupMemberModal, this.pickGroupMemberModal((userInfos: UserInfo[]) => {
                        this.showPickGroupMemberModal = false
                        let pickUsers = userInfos
                        if (pickUsers?.length) {
                            let uids = pickUsers.map(info => info.uid)
                            wfc.setGroupManager(this.groupInfo!.target, true, uids, [0], null, () => {
                                let groupManagers = wfc.getGroupMembersByType(this.groupInfo!.target, GroupMemberType.Manager);
                                this.groupManagerUserInfos = wfc.getUserInfos(groupManagers.map(m => m.memberId), this.groupInfo!.target)
                                this.showPickGroupMemberModal = false
                            }, err => {
                                showToast('添加群管理员失败：' + err)
                                this.showPickGroupMemberModal = false
                            })
                        }
                    }), {
                        modalTransition: ModalTransition.DEFAULT,
                        onAppear: () => {
                        },

                        onDisappear: () => {
                        }
                    })
                    .onClick(() => {
                        this.showPickGroupMemberModal = true
                    })
                    .width('100%')
                    .stateStyles({
                        pressed: {
                            .backgroundColor($r('app.color.wf_item_pressed'))
                        },
                        normal: {
                            .backgroundColor($r('app.color.wf_background'))
                        }
                    })
                }
            }
        }
        .title('管理员列表')
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.wf_background'))
    }
}
