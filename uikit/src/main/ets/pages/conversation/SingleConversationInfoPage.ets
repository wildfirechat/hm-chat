import { showToast } from '../../common/utils/Toast';
import ActionSheetDialog from '../../view/ActionSheetDialog';
import OptionItemView from '../../view/OptionItemView';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import GroupType from '@wfc/client/src/main/ets/wfc/model/groupType';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import { navigationDestinations } from '../navigationConfig';
import PickMultiContactModal from '../picker/PickMultiContactModal';

@Preview
@Entry
@Component
export default struct SingleConversationInfoPage {
    @State targetUserInfo: UserInfo = {} as UserInfo
    private conversationInfo?: ConversationInfo
    @State isTop: boolean = false
    @State isSilent: boolean = false
    @State showPickContactModal: boolean = false
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conversationInfo = params['conversationInfo'] as ConversationInfo
        this.targetUserInfo = wfc.getUserInfo(this.conversationInfo!.conversation.target)
    }

    @Builder
    pickMultiContactModal() {
        PickMultiContactModal({
            showPickContactModal: $showPickContactModal,
            initialCheckedUserIds: [this.conversationInfo!.conversation.target],
            uncheckableUserIds: [this.conversationInfo!.conversation.target]

        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    Image(this.targetUserInfo.portrait)
                        .width(48)
                        .height(48)
                    Image($r('app.media.ic_add_team_member'))
                        .width(48)
                        .height(48)
                        .margin({ left: 20 })
                        .bindContentCover(this.showPickContactModal, this.pickMultiContactModal(), {
                            modalTransition: ModalTransition.DEFAULT,
                            onAppear: () => {
                            },

                            onDisappear: () => {
                                this.showPickContactModal = false
                                let localStorage = LocalStorage.getShared();
                                let pickUsers = localStorage.get<UserInfo[]>(PickMultiContactModal.PICK_RESULT);
                                if (pickUsers?.length) {
                                    showToast('创建群...')
                                    localStorage.delete(PickMultiContactModal.PICK_RESULT)
                                    let memberIds: string[] = pickUsers.map(userInfo => userInfo.uid)
                                    memberIds.push(this.conversationInfo!.conversation.target)
                                    let selfUserInfo = wfc.getUserInfo(wfc.getUserId())
                                    pickUsers.splice(0, 0, selfUserInfo);
                                    pickUsers.splice(1, 0, this.targetUserInfo);
                                    let first5Members = pickUsers.slice(0, 5)
                                    let groupName = ''
                                    first5Members.forEach(userInfo => {
                                        groupName += userInfo.displayName
                                        groupName += '、'
                                    })
                                    groupName = groupName.substring(0, groupName.length - 1)
                                    wfc.createGroup('', GroupType.Normal, groupName, '', '', memberIds, '', [0], null, (groupId) => {
                                        let conversation = new Conversation(ConversationType.Group, groupId, 0);
                                        this.mainNavPathStack.popToName(navigationDestinations.ConversationPage)
                                        this.mainNavPathStack.replacePathByName(navigationDestinations.ConversationPage, {
                                            'conversation': conversation
                                        } as Record<string, Object>)
                                    }, err => {

                                    })
                                }
                            }
                        })
                        .onClick(() => {
                            this.showPickContactModal = true
                        })
                }
                .padding(20)
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .backgroundColor(Color.White)

                Column() {
                    Row() {
                        Text('消息免打扰')
                        Toggle({ type: ToggleType.Switch, isOn: this.conversationInfo!.isSilent })
                            .onChange(isOn => {
                                wfc.setConversationSlient(this.conversationInfo!.conversation, isOn, () => {

                                }, err => {
                                    showToast('设置消息免打扰失败 ' + err)
                                })
                            })
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width('100%')
                    .height(56)

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
                }
                .padding({ left: 10, right: 10 })
                .margin({ top: 10 })
                .width('100%')
                .backgroundColor(Color.White)

                Column() {
                    OptionItemView({
                        title: '查找聊天记录',
                    })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(navigationDestinations.SearchConversationMessagePage, {
                                'conversation': this.conversationInfo?.conversation
                            } as Record<string, Object>)
                        })
                    OptionItemView({ title: '文件记录' })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(navigationDestinations.FileRecordPage, {
                                'conversation': this.conversationInfo?.conversation,
                            } as Record<string, Object>)
                        })
                }
                .margin({ top: 10 })
                .width('100%')
                .backgroundColor(Color.White)

                Column() {
                    OptionItemView({ title: '清空聊天记录' })
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
                    OptionItemView({ title: '举报' })
                        .onClick(event => {
                            AlertDialog.show({
                                title: "举报",
                                message: $r("app.string.complaint"),
                                primaryButton: {
                                    value: "举报",
                                    fontColor: Color.Red,
                                    action: () => {
                                        let conversation = new Conversation(ConversationType.Single, 'uiuJuJcc', 0)
                                        this.mainNavPathStack.popToName(navigationDestinations.ConversationPage)
                                        this.mainNavPathStack.replacePathByName(navigationDestinations.ConversationPage, {
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
            }
            .width('100%')
            .height('100%')
        }
        .backgroundColor('#EEEEEE')
        .title('会话详情')
        // .hideBackButton(false)
        .height('100%')
        .width('100%')
    }
}