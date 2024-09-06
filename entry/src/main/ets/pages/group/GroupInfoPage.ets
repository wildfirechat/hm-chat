import { showToast } from '../../common/utils/Toast';
import LoadingView from '../../view/LoadingView';
import wfc from '../../wfc/client/wfc';
import Conversation from '../../wfc/model/conversation';
import ConversationType from '../../wfc/model/conversationType';
import GroupInfo from '../../wfc/model/groupInfo';
import { navigationDestinations } from '../navigationConfig';

@Component
export default struct GroupInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State groupInfo: GroupInfo | undefined = undefined
    private groupId?: string

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupId = params['groupId'] as string
        if (!this.groupId) {
            this.mainNavPathStack.pop()
            return
        }
        wfc.getGroupInfoEx(this.groupId, true, info => {
            this.groupInfo = info
        }, err => {
            showToast('获取群信息失败 ' + +err)
            this.mainNavPathStack.pop()
            return
        })
    }

    actionButtonText() {
        let text = '加入群聊'
        if (this.groupInfo!.memberDt < -1) {
            // 已退出群组
            text = '加入群聊'
        } else if (this.groupInfo?.memberDt === -1) {
            // 未加入
            text = '加入群聊'
        } else {
            // 已加入群组
            text = '进入群聊'
        }
        return text;
    }

    showGroupConversationPage() {
        let conversation = new Conversation(ConversationType.Group, this.groupInfo!.target, 0)
        wfc.clearConversationUnreadStatus(conversation!)
        this.mainNavPathStack.pop()
        this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
            'conversation': conversation
        } as Record<string, Object>)
    }

    action() {
        if (this.groupInfo!.memberDt > 0) {
            this.showGroupConversationPage()
        } else {
            wfc.addGroupMembers(this.groupId!, [wfc.getUserId()], '', [0], null, () => {
                this.showGroupConversationPage()
            }, err => {
                showToast('加入群聊失败 ' + err)
            })
        }
    }

    build() {
        NavDestination() {
            if (this.groupInfo) {
                Column() {
                    Image(this.groupInfo?.portrait)
                        .width(100)
                        .height(100)
                        .borderRadius(4)
                        .margin({ top: 50 })
                        .alt('')
                    Text(this.groupInfo?.name)
                        .margin({ top: 10 })
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .maxLines(1)
                    Button(this.actionButtonText())
                        .margin({ top: 20 })
                        .borderRadius(8)
                        .width('70%')
                        .onClick(() => {
                            this.action()
                        })
                }
                .alignItems(HorizontalAlign.Center)
            } else {
                LoadingView()
            }
        }
        .title('群信息')
        .height('100%')
        .width('100%')
    }
}