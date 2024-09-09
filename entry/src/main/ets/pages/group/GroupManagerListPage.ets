import { showToast } from '../../common/utils/Toast'
import OptionItemView from '../../view/OptionItemView'
import wfc from '../../wfc/client/wfc'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'
import GroupMember from '../../wfc/model/groupMember'
import GroupMemberType from '../../wfc/model/groupMemberType'
import UserInfo from '../../wfc/model/userInfo'
import { navigationDestinations } from '../navigationConfig'
import PickGroupMemberModal from './PickGroupMemberModal'

@Entry
@Component
export default struct GroupManagerListPage {
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
    pickGroupMemberModal() {
        PickGroupMemberModal({
            groupId: this.groupInfo?.target,
            title: '添加管理员',
            showPickGroupMemberModal: $showPickGroupMemberModal,
            uncheckableUserIds: [this.groupOwnerUerInfo!.uid].concat(this.groupManagerUserInfos.map(u => u.uid)),
            initialCheckedUserIds: [this.groupOwnerUerInfo!.uid].concat(this.groupManagerUserInfos.map(u => u.uid))

        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    build() {
        NavDestination() {
            Column() {
                Text('群主')
                    .padding(10)
                    .width('100%')
                Row() {
                    Image(this.groupOwnerUerInfo?.portrait)
                        .width(40)
                        .height(40)
                        .margin(10)
                        .borderRadius(4)
                    Text(this.groupOwnerUerInfo?.displayName)
                        .maxLines(1)
                }
                .width('100%')
                .stateStyles({
                    pressed: {
                        .backgroundColor('#E5E5E5')
                    },
                    normal: {
                        .backgroundColor(Color.White)
                    }
                })

                if (this.groupManagerUserInfos.length > 0) {
                    Text('管理员')
                        .padding(10)
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
                            }
                        }, (info: UserInfo) => info.uid + info.updateDt)
                    }
                    .width('100%')
                    .backgroundColor(Color.White)
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
                    }
                    .margin({ top: 20 })
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
                                wfc.setGroupManager(this.groupInfo?.target, true, uids, [0], null, () => {
                                    let groupManagers = wfc.getGroupMembersByType(this.groupInfo?.target, GroupMemberType.Manager);
                                    this.groupManagerUserInfos = wfc.getUserInfos(groupManagers.map(m => m.memberId), this.groupInfo!.target)
                                    this.showPickGroupMemberModal = false
                                }, err => {
                                    showToast('移除群成员失败：' + err)
                                    this.showPickGroupMemberModal = false
                                })
                            }
                        }
                    })
                    .onClick(() => {
                        this.showPickGroupMemberModal = true
                    })
                    .width('100%')
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })
                }
            }
        }
        .title('管理员列表')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
