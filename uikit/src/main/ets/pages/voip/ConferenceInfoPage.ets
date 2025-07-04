import OptionItemView from "../../view/OptionItemView";
import ToggleItemView from "../../view/ToggleItemView";
import ConferenceInfo from "@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo";
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import ConferenceInviteMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/conferenceInviteMessageContent'
import avengineKit from '@wfc/avenginekit'
import appServer from '../../api/appServer';

@Component
export default struct ConferenceInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State conferenceInfo: ConferenceInfo | undefined = undefined
    @State muteVideo: boolean = false
    @State muteAudio: boolean = false
    @State hostUserInfo: UserInfo | undefined = undefined
    @State enableAudio: boolean = true;
    @State enableVideo: boolean = false;
    private conferenceInviteContent ?: ConferenceInviteMessageContent

    async aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let conferenceInviteMessage = params['message'] as Message;
        this.conferenceInviteContent = conferenceInviteMessage.messageContent as ConferenceInviteMessageContent;

        this.conferenceInfo = await appServer.queryConferenceInfo(this.conferenceInviteContent.callId, this.conferenceInviteContent.password)
    }

    build() {
        NavDestination() {
            Column() {
                Column() {
                    OptionItemView({
                        title: '会议主题',
                        desc: this.conferenceInviteContent?.title,
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false
                    })

                    OptionItemView({
                        title: '发起人',
                        desc: this.conferenceInfo?.owner,
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false
                    })

                    OptionItemView({
                        title: '会议号',
                        desc: this.conferenceInfo?.conferenceId,
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false
                    })

                    OptionItemView({
                        title: '二维码',
                        paddingLeft: 20,
                        imgUrl: 'http://static.wildfirechat.cn/wx_wfc_qrcode.jpg',
                        showRightArrow: true,
                        showDivider: false
                    })
                }
                .backgroundColor(Color.White)

                Column() {
                    OptionItemView({
                        title: '开始时间',
                        desc: this.conferenceInfo ? new Date(this.conferenceInfo!.startTime * 1000).toString() : '',
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false
                    })
                    OptionItemView({
                        title: '结束时间',
                        desc: this.conferenceInfo ? new Date(this.conferenceInfo!.endTime * 1000).toString() : '',
                        paddingLeft: 20,
                        showDivider: false,
                        showRightArrow: false
                    })
                }
                .backgroundColor(Color.White)
                .margin({ top: 20 })

                Column() {
                    ToggleItemView({
                        title: '开启视频',
                        isOn: this.enableVideo,
                        showDivider: true,
                        paddingLeft: 20,
                        onChange: value => {

                        }
                    })
                    ToggleItemView({
                        title: '开启音频',
                        isOn: this.enableAudio,
                        paddingLeft: 20,
                        onChange: value => {

                        }
                    })
                }
                .margin({ top: 20 })
                .backgroundColor(Color.White)

                Column() {
                    Button('加入会议')
                        .enabled(true)
                        .type(ButtonType.Normal)
                        .borderRadius(4)
                        .width('50%')
                        .onClick(() => {
                            let inviteContent = this.conferenceInviteContent!;
                            avengineKit.joinConference(inviteContent.callId, inviteContent.audioOnly, inviteContent.pin, inviteContent.host, inviteContent.title, inviteContent.desc, false, inviteContent.advanced, false, false, '', '')
                        })
                }
                .width('100%')
                .margin({ top: 40 })
                .justifyContent(FlexAlign.Center)
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Start)
            .width('100%')
        }
        .backgroundColor('#EDEDED')
        .height('100%')
        .width('100%')
        .hideTitleBar(false)
        .title('会议详情')
    }
}