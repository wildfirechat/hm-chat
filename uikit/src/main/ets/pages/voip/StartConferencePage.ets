import OptionItemView from "../../view/OptionItemView";
import ToggleItemView from "../../view/ToggleItemView";
import ConferenceInfo from "@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo";
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import avengineKit from '@wfc/avenginekit'
import appServer from '../../api/appServer';
import { faceDetector } from "@kit.CoreVisionKit";
import { showToast } from "../../common/utils/Toast";
import wfc from "@wfc/client";
import ConferencePasswordDialog from "./ConferencePasswordDialog";

@Component
export default struct StartConferencePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State conferenceInfo: ConferenceInfo | undefined = undefined
    @State muteVideo: boolean = false
    @State muteAudio: boolean = false
    @State hostUserInfo: UserInfo | undefined = undefined
    @State endTime: number = new Date().getTime();
    @State modeSwitch: boolean = false
    @State audienceSwitch: boolean = false
    @State passwordSwitch: boolean = false
    @State advancedSwitch: boolean = false
    @State password: string = ''
    private conferencePasswordDialogController?: CustomDialogController

    async aboutToAppear() {
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
                        desc: this.endTime + '',
                        paddingLeft: 20,
                        showDivider: false,
                        showRightArrow: true
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
                        isOn: this.audienceSwitch,
                        showDivider: true,
                        paddingLeft: 20,
                        onChange: value => {

                        }
                    })
                    ToggleItemView({
                        title: '允许参与者自主开启摄像头、麦克风',
                        isOn: this.modeSwitch,
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
                        desc: this.password,
                        isOn: this.passwordSwitch,
                        showDivider: true,
                        paddingLeft: 20,
                        onChange: value => {
                            if (value) {
                                this.conferencePasswordDialogController = new CustomDialogController({
                                    builder: ConferencePasswordDialog({
                                        controller: this.conferencePasswordDialogController,
                                        onConfirm: (password: string) => {
                                            this.password = password;
                                            showToast('TODO ' + password)
                                        }
                                    }),
                                    cancel: () => {
                                        this.passwordSwitch = false
                                    }
                                })
                                this.conferencePasswordDialogController.open()
                            } else {
                                this.password = ''
                            }
                        }
                    })
                }
                .margin({ top: 20 })
                .backgroundColor(Color.White)

                Column() {
                    ToggleItemView({
                        title: '大规模会议',
                        desc: '参会人数大于 50 人',
                        isOn: this.advancedSwitch,
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
                            // ConferenceInfo info = new ConferenceInfo();
                            // Toast.makeText(this, R.string.conference_creating, Toast.LENGTH_SHORT).show();
                            // info.setPassword(password);
                            // info.setConferenceTitle(titleEditText.getText().toString());
                            // Random random = new Random();
                            // String pin = String.format("%d%d%d%d", random.nextInt() % 10, random.nextInt() % 10, random.nextInt() % 10, random.nextInt() % 10);
                            // info.setPin(pin);
                            //
                            // info.setOwner(ChatManager.Instance().getUserId());
                            // info.setStartTime(System.currentTimeMillis() / 1000);
                            // info.setEndTime(endDateTime.getTime() / 1000);
                            // info.setAudience(!audienceSwitch.isChecked());
                            // info.setAllowTurnOnMic(modeSwitch.isChecked());
                            // info.setAdvance(advancedSwitch.isChecked());
                            // // 可根据实际情况调整
                            // info.setMaxParticipants(20);
                            //
                            let conference = new ConferenceInfo();
                            conference.owner = wfc.getUserId()
                            conference.startTime = new Date().getTime();
                            //avengineKit.joinConference(inviteContent.callId, inviteContent.audioOnly, inviteContent.pin, inviteContent.host, inviteContent.title, inviteContent.desc, false, inviteContent.advanced, false, false, '', '')
                            // appServer.createConference()
                            showToast('TODO')
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