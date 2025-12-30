import OptionItemView from '../../view/OptionItemView'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import ActionSheetDialog from '../../view/ActionSheetDialog'
import ModifyGroupInfoType from '@wfc/client/src/main/ets/wfc/model/modifyGroupInfoType'
import { showToast } from '../../common/utils/Toast'
import GroupType from '@wfc/client/src/main/ets/wfc/model/groupType'

@Component
export default struct GroupManagePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State groupInfo?: GroupInfo = undefined

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo

    }

    joinType() {
        let str = ''
        switch (this.groupInfo?.joinType) {
            case 0:
                str = '不限制加入'
                break;
            case 1:
                str = '群成员可以拉人'
                break;
            case 2:
                str = '只能群管理拉人'
                break;
            case 3:
                str = '需要群管理审批'
                break;
            default:
                str = '只能群管理拉人'
                break
        }
        return str
    }

    build() {
        NavDestination() {
            Column() {
                Column() {
                    Text('成员管理')
                        .textAlign(TextAlign.Start)
                        .backgroundColor('#EDEDED')
                        .padding({ left: 10, top: 5, bottom: 5 })
                        .width('100%')
                    OptionItemView({
                        title: '管理员',
                        showDivider: true,
                    })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupManagerListPage, {
                                'groupInfo': this.groupInfo
                            } as Record<string, Object>)
                        })
                    OptionItemView({
                        title: '设置禁言',
                        showDivider: true,
                    })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupMemberMuteOrAllowListPage, {
                                'groupInfo': this.groupInfo
                            } as Record<string, Object>)
                        })
                    OptionItemView({
                        title: '成员权限',
                        showDivider: false,
                    })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupMemberPermissionPage, {
                                'groupInfo': this.groupInfo
                            } as Record<string, Object>)
                        })
                }

                Column() {
                    Text('群基本设置')
                        .textAlign(TextAlign.Start)
                        .backgroundColor('#EDEDED')
                        .padding({ left: 10, top: 15, bottom: 5 })
                        .width('100%')
                    if (this.groupInfo?.type === GroupType.Restricted) {
                        OptionItemView({
                            title: '加群方式',
                            desc: this.joinType(),
                            showDivider: true,
                            showRightArrow: false
                        })
                            .onClick(() => {
                                let func = (joinType: number) => {
                                    customDialogController.close()
                                    wfc.modifyGroupInfo(this.groupInfo!.target, ModifyGroupInfoType.Modify_Group_JoinType, joinType + '', [], null, () => {
                                        this.groupInfo!.joinType = joinType
                                    }, err => {
                                        showToast('修改加群方式失败')
                                    })
                                }
                                let customDialogController = new CustomDialogController({
                                    builder: ActionSheetDialog({
                                        cancel: {
                                            title: '取消',
                                            action: () => {
                                                customDialogController.close()
                                            }
                                        },
                                        sheets: [
                                            {
                                                title: '不限制加入',
                                                action: () => {
                                                    func(0)
                                                }
                                            },
                                            {
                                                title: '群成员可以拉人',
                                                action: () => {
                                                    func(1)
                                                }
                                            },
                                            {
                                                title: '只能管理员拉人',
                                                action: () => {
                                                    func(2)
                                                }
                                            },
                                            {
                                                title: '需要群管理审批',
                                                action: () => {
                                                    func(3)
                                                }
                                            },
                                        ]
                                    }),
                                    autoCancel: true,
                                    alignment: DialogAlignment.Center,
                                    // gridCount: 4,
                                    customStyle: false
                                })

                                customDialogController.open()
                            })
                    }
                    OptionItemView({
                        title: '查找方式',
                        desc: this.groupInfo?.searchable === 0 ? '允许查找' : '不允许查找',
                        showDivider: true,
                        showRightArrow: false
                    })
                        .onClick(() => {
                            let func = (searchable: number) => {
                                customDialogController.close()
                                wfc.modifyGroupInfo(this.groupInfo!.target, ModifyGroupInfoType.Modify_Group_Searchable, searchable + '', [], null, () => {
                                    this.groupInfo!.searchable = searchable
                                }, err => {
                                    showToast('修改群查找方式失败')
                                })
                            }
                            let customDialogController = new CustomDialogController({
                                builder: ActionSheetDialog({
                                    cancel: {
                                        title: '取消',
                                        action: () => {
                                            customDialogController.close()
                                        }
                                    },
                                    sheets: [
                                        {
                                            title: '允许查找',
                                            action: () => {
                                                func(0)
                                            }
                                        },
                                        {
                                            title: '不允许查找',
                                            action: () => {
                                                func(1)
                                            }
                                        },
                                    ]
                                }),
                                autoCancel: true,
                                alignment: DialogAlignment.Center,
                                // gridCount: 4,
                                customStyle: false
                            })

                            customDialogController.open()
                        })
                    OptionItemView({
                        title: '群历史消息',
                        desc: this.groupInfo?.historyMessage === 0 ? '不允许新成员查看历史消息' : '允许新成员查看历史消息',
                        showDivider: false,
                        showRightArrow: false
                    })
                        .onClick(() => {
                            let func = (historyMsg: number) => {
                                customDialogController.close()
                                wfc.modifyGroupInfo(this.groupInfo!.target, ModifyGroupInfoType.Modify_Group_History_Message, historyMsg + '', [], null, () => {
                                    this.groupInfo!.historyMessage = historyMsg
                                }, err => {
                                    showToast('修改是否允许查看群历史消息失败')
                                })
                            }
                            let customDialogController = new CustomDialogController({
                                builder: ActionSheetDialog({
                                    cancel: {
                                        title: '取消',
                                        action: () => {
                                            customDialogController.close()
                                        }
                                    },
                                    sheets: [
                                        {
                                            title: '不允许新成员查看历史消息',
                                            action: () => {
                                                func(0)
                                            }
                                        },
                                        {
                                            title: '允许新成员查看历史消息',
                                            action: () => {
                                                func(1)
                                            }
                                        },
                                    ]
                                }),
                                autoCancel: true,
                                alignment: DialogAlignment.Center,
                                // gridCount: 4,
                                customStyle: false
                            })

                            customDialogController.open()
                        })

                    if (this.groupInfo?.type === GroupType.Restricted && this.groupInfo?.joinType === 3) {
                        Column() {
                            Text('加群申请')
                                .textAlign(TextAlign.Start)
                                .backgroundColor('#EDEDED')
                                .padding({ left: 10, top: 15, bottom: 5 })
                                .width('100%')
                            OptionItemView({
                                title: '加群申请',
                                showDivider: false,
                            })
                                .onClick(() => {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupJoinRequestListPage, {
                                        'groupId': this.groupInfo?.target
                                    } as Record<string, Object>)
                                })
                        }
                    }
                }
            }
            .backgroundColor(Color.White)
        }
        .title('群管理')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
