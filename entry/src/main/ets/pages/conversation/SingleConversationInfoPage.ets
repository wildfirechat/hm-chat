import router from '@ohos.router';
import { showToast } from '../../common/utils/Toast';
import OptionItemView from '../../view/OptionItemView';
import wfc from '../../wfc/client/wfc';
import Conversation from '../../wfc/model/conversation';
import ConversationInfo from '../../wfc/model/conversationInfo';
import ConversationType from '../../wfc/model/conversationType';
import UserInfo from '../../wfc/model/userInfo'

@Preview
@Entry
@Component
export default struct SingleConversationInfoPage {
    @State userInfo: UserInfo = {} as UserInfo
    private conversationInfo?: ConversationInfo
    @State isTop: boolean = false
    @State isSilent: boolean = false

    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conversationInfo = params['conversationInfo'] as ConversationInfo
        this.userInfo = wfc.getUserInfo(this.conversationInfo!.conversation.target)
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    Image(this.userInfo.portrait)
                        .width(48)
                        .height(48)
                    Image($r('app.media.ic_add_team_member'))
                        .width(48)
                        .height(48)
                        .margin({ left: 20 })
                        .onClick(() => {
                            // TODO
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
                        subTitle: '测试',
                        desc: '描述',
                        imgUrl: 'http://static.wildfirechat.cn/wx_wfc_qrcode.jpg'
                    })
                        .onClick(() => {
                            showToast('todo')
                        })
                    OptionItemView({ title: '文件记录' })
                }
                .margin({ top: 10 })
                .width('100%')
                .backgroundColor(Color.White)

                Column() {
                    OptionItemView({ title: '清空聊天记录' })
                }
                .margin({ top: 10 })
                .width('100%')
                .backgroundColor(Color.White)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#EDEDED')
        }
        .title('会话详情')
        // .hideBackButton(false)
        .height('100%')
        .width('100%')
    }
}