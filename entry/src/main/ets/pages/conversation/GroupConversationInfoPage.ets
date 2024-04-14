import router from '@ohos.router';
import { showToast } from '../../common/utils/Toast';
import OptionItemView from '../../view/OptionItemView';
import wfc from '../../wfc/client/wfc';
import Conversation from '../../wfc/model/conversation';
import ConversationInfo from '../../wfc/model/conversationInfo';
import ConversationType from '../../wfc/model/conversationType';
import GroupInfo from '../../wfc/model/groupInfo';
import GroupMember from '../../wfc/model/groupMember';
import GroupMemberType from '../../wfc/model/groupMemberType';
import GroupType from '../../wfc/model/groupType';
import UserInfo from '../../wfc/model/userInfo';
import ActionSheetDialog from '../../view/ActionSheetDialog'
import promptAction from '@ohos.promptAction';

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
    private isAddOrRemoveNewGroupMember: boolean = false
    dialogController: CustomDialogController = new CustomDialogController({
        builder: ActionSheetDialog({
            title: 'ojooo',
        }),
        cancel: () => {
            console.log('xxxxxxxxxxx cancel')
        },
        autoCancel: true,
        alignment: DialogAlignment.Center,
        // offset: { dx: 0, dy: -20 },
        gridCount: 4,
        customStyle: false
    })

    aboutToAppear() {
        const params = router.getParams() as Record<string, Object>;
        this.conversationInfo = params['conversationInfo'] as ConversationInfo
        this.groupInfo = wfc.getGroupInfo(this.conversationInfo.conversation.target)
        this.groupMembers = wfc.getGroupMembers(this.conversationInfo.conversation.target, false)

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
    }

    onPageShow() {
        if (this.isAddOrRemoveNewGroupMember) {
            this.isAddOrRemoveNewGroupMember = false
            let params = router.getParams() as Record<string, Object>
            if (params) {
                let tag = params['tag']
                if (tag === 'addGroupMember') {
                    let newUsers: UserInfo[] = params['result'] as UserInfo[]
                    let uids = newUsers.map(info => info.uid)

                    wfc.addGroupMembers(this.groupInfo.target, uids, '', [0], null, () => {
                        this.groupMembers = wfc.getGroupMembers(this.conversationInfo!.conversation.target, false)
                        showToast('添加新群成员成功')
                    }, (err: number) => {
                        showToast('添加新成员失败：' + err)
                    })
                } else if (tag === 'removeGroupMember') {
                    let newUsers: UserInfo[] = params['result'] as UserInfo[]
                    let uids = newUsers.map(info => info.uid)

                    wfc.kickoffGroupMembers(this.groupInfo.target, uids, [0], null, () => {
                        this.groupMembers = wfc.getGroupMembers(this.conversationInfo!.conversation.target, false)
                    }, (err: number) => {
                        showToast('移除群成员失败：' + err)
                    })
                }
            }
        }
    }

    build() {
        Navigation() {
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
                                    .onClick(() => {
                                        this.isAddOrRemoveNewGroupMember = true
                                        router.pushUrl({
                                            url: 'pages/group/AddGroupMemberPage',
                                            params: {
                                                groupInfo: this.groupInfo
                                            }
                                        })
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
                                    .onClick(() => {
                                        this.isAddOrRemoveNewGroupMember = true
                                        router.pushUrl({
                                            url: 'pages/group/RemoveGroupMemberPage',
                                            params: {
                                                groupInfo: this.groupInfo
                                            }
                                        })
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
                            desc: '服务器稳定性测试'
                        })
                        OptionItemView({
                            title: ' 群头像',
                            imgUrl: 'http://static.wildfirechat.cn/wx_wfc_qrcode.jpg'
                        })
                        OptionItemView({
                            title: '二维码',
                            imgUrl: 'http://static.wildfirechat.cn/wx_wfc_qrcode.jpg'
                        })
                        OptionItemView({
                            title: '群公告',
                            subTitle: '你好，群公告'
                        })
                        OptionItemView({
                            title: '群备注',
                            desc: '测试备注'
                        })
                        OptionItemView({
                            title: '群管理',
                        })
                    }
                    .margin({ top: 10 })
                    .width('100%')
                    .backgroundColor(Color.White)

                    Column() {
                        OptionItemView({ title: '查找聊天记录' })
                            .onClick(() => {
                                showToast('todo')
                            })
                        OptionItemView({ title: '文件记录' })
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
                        OptionItemView({ title: '我在本群的昵称', desc: '昵称' })

                        Row() {
                            Text('显示群成员昵称聊天')
                            Toggle({ type: ToggleType.Switch })
                                .onChange((value: boolean) => {
                                    showToast('TODO')
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

                        Row() {
                            Text('删除并退出')
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
                            let dialogController: CustomDialogController = new CustomDialogController({
                                builder: ActionSheetDialog({
                                    title: 'Test',
                                    sheets: [
                                        {
                                            title: '项目 1',
                                            action: () => {
                                                showToast('000000000')
                                            }
                                        },
                                        {
                                            title: '项目 2',
                                            action: () => {
                                                showToast('0000000002')
                                            }
                                        },
                                        {
                                            title: '项目 3',
                                            action: () => {
                                                showToast('0000000003')
                                            }
                                        }
                                    ]
                                }),
                                autoCancel: true,
                                alignment: DialogAlignment.Default,
                                gridCount: 4,
                                customStyle: false
                            })

                            dialogController.open()
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
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
    }
}