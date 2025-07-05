import OptionItemView from "../../view/OptionItemView";
import ToggleItemView from "../../view/ToggleItemView";
import ConferenceInfo from "@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo";
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import ConferenceInviteMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/conferenceInviteMessageContent'
import avengineKit from '@wfc/avenginekit'
import appServer from '../../api/appServer';
import { faceDetector } from "@kit.CoreVisionKit";

@Component
export default struct StartConferencePage {
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
                    Text('会议主题')
                    TextInput()
                        .borderRadius(0)
                        .backgroundColor(Color.White)
                        .border({ color: Color.Black })
                        .borderWidth({
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 0.5
                        })
                        .maxLines(1)
                        .maxLength(50)
                        .padding({ left: 0, right: 0 })
                }
                .alignItems(HorizontalAlign.Start)
                .padding({
                    left: 20,
                    right: 20,
                    top: 10,
                    bottom: 10
                })
                .backgroundColor(Color.White)

                Column() {
                    OptionItemView({
                        title: '开始时间',
                        desc: '现在',
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false,

                    })
                    OptionItemView({
                        title: '结束时间',
                        desc: this.conferenceInfo ? new Date(this.conferenceInfo!.endTime * 1000).toString() : '',
                        paddingLeft: 20,
                        showDivider: false,
                        showRightArrow: false
                    })
                        .onClick(() => {
                            TimePickerDialog.show({
                                useMilitaryTime: true
                            })
                        })
                }
                .backgroundColor(Color.White)
                .margin({ top: 20 })

                Column() {
                    ToggleItemView({
                        title: '参与者开启摄像头、麦克风入会',
                        isOn: this.enableVideo,
                        showDivider: true,
                        paddingLeft: 20,
                        onChange: value => {

                        }
                    })
                    ToggleItemView({
                        title: '允许参与者自主开启摄像头、麦克风',
                        isOn: this.enableAudio,
                        paddingLeft: 20,
                        onChange: value => {

                        }
                    })
                }
                .margin({ top: 20 })
                .backgroundColor(Color.White)


                Column() {
                    ToggleItemView({
                        title: '启用会议密码',
                        isOn: this.enableVideo,
                        showDivider: true,
                        paddingLeft: 20,
                        onChange: value => {

                        }
                    })
                }
                .margin({ top: 20 })
                .backgroundColor(Color.White)

                Column() {
                    ToggleItemView({
                        title: '大规模会议',
                        desc: '参会人数大于 50 人',
                        isOn: this.enableVideo,
                        showDivider: false,
                        paddingLeft: 20,
                        onChange: value => {
                        }
                    })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ top: 20 })
                .backgroundColor(Color.White)

                Column() {
                    Button('进入会议')
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
        .title('发起会议')
        .menus(this.NavigationMenus())
    }

    @Builder
    NavigationMenus() {
        Row() {
            Button('创建')
                .type(ButtonType.Normal)
                .height(30)
                .width(60)
                .margin({ right: 14 })
                .fontSize(14)
                .borderRadius(4)// .backgroundColor(Color.Blue)
                .backgroundColor(Color.Transparent)
                .fontColor(Color.Blue)
                .onClick(() => {
                    this.mainNavPathStack.pop()
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
}