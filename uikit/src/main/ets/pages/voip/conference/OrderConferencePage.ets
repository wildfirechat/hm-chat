import OptionItemView from "../../../view/OptionItemView";
import ToggleItemView from "../../../view/ToggleItemView";
import ConferenceInfo from "@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo";
import avengineKit from '@wfc/avenginekit'
import appServer from '../../../api/appServer';
import { showToast } from "../../../common/utils/Toast";
import wfc from "@wfc/client";
import ConferencePasswordDialog from "./ConferencePasswordDialog";
import { uikitNavigationDestinations } from "../../uikitNavigationConfig";

@Component
export default struct OrderConferencePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State title: string = ''
    @State startTime: Date = new Date(new Date().getTime())
    @State endTime: Date = new Date(new Date().getTime() + 60 * 60 * 1000)
    @State modeSwitch: boolean = false
    @State audienceSwitch: boolean = false
    @State passwordSwitch: boolean = false
    @State advancedSwitch: boolean = false
    @State password: string = ''
    private conferencePasswordDialogController?: CustomDialogController

    async aboutToAppear() {
        this.title = wfc.getUserInfo(wfc.getUserId()).displayName + ' 发起的会议'
    }

    build() {
        NavDestination() {
            Column() {
                Column() {
                    Text('会议主题')
                    TextInput({ text: this.title })
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
                        .onChange(value => {
                            this.title = value;
                        })
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
                        desc: this.startTime.toString(),
                        paddingLeft: 20,
                        showDivider: false,
                        showRightArrow: true
                    })
                        .onClick(() => {
                            this.getUIContext().showDatePickerDialog({
                                showTime: true,
                                onDateAccept: (date: Date) => {
                                    if (date.getTime() <= this.startTime.getTime()) {
                                        showToast('结束时间，不能早于开始时间')
                                        return
                                    }
                                    this.startTime = date
                                }
                            })
                        })
                    OptionItemView({
                        title: '结束时间',
                        desc: this.endTime.toString(),
                        paddingLeft: 20,
                        showDivider: false,
                        showRightArrow: true
                    })
                        .onClick(() => {
                            this.getUIContext().showDatePickerDialog({
                                showTime: true,
                                onDateAccept: (date: Date) => {
                                    if (date.getTime() <= new Date().getTime()) {
                                        showToast('结束时间，不能早于当前时间')
                                        return
                                    }
                                    this.endTime = date
                                }
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
                            this.audienceSwitch = value;

                        }
                    })
                    ToggleItemView({
                        title: '允许参与者自主开启摄像头、麦克风',
                        isOn: this.modeSwitch,
                        paddingLeft: 20,
                        onChange: value => {
                            this.modeSwitch = value;
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
                            this.advancedSwitch = value;
                        }
                    })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ top: 20 })
                .backgroundColor(Color.White)

                Column() {
                    Button('预定')
                        .enabled(true)
                        .type(ButtonType.Normal)
                        .borderRadius(4)
                        .width('50%')
                        .onClick(async () => {
                            if (this.title.trim().length === 0) {
                                showToast('请输入会议主题')
                                return
                            }
                            let info = new ConferenceInfo();
                            info.password = this.passwordSwitch ? this.password : ''
                            info.conferenceTitle = this.title;
                            info.pin = `${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}`
                            info.owner = wfc.getUserId()
                            info.startTime = Math.ceil(this.startTime.getTime() / 1000);
                            info.endTime = Math.ceil(this.endTime.getTime() / 1000);
                            info.audience = this.audienceSwitch;
                            info.allowSwitchMode = this.modeSwitch;
                            info.advance = this.advancedSwitch;
                            try {
                                let conferenceId = await appServer.createConference(info)
                                showToast('预定会议成功');
                                this.mainNavPathStack.pop()

                            } catch (e) {
                                showToast('预定会议失败 ' + e);
                            }
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
        .title('预定会议')
    }
}