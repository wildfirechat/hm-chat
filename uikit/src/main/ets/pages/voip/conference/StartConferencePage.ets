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
export default struct StartConferencePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State title: string = ''
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
                        desc: '现在',
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false,

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
                                        showToast('结束时间，不能小于当前时间')
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
                    Button('进入会议')
                        .enabled(true)
                        .type(ButtonType.Normal)
                        .borderRadius(4)
                        .width('50%')
                        .onClick(async () => {
                            if (this.title.trim().length === 0) {
                                showToast('请输入会议主题')
                                return
                            }
                            try {
                                let info = await this.createConference()
                                let callSession = avengineKit.joinConference(info.conferenceId, false, info.pin, info.owner, info.conferenceTitle, '', false, info.advance, false, true, '', '')
                                if (callSession) {
                                    let params = {} as Record<string, Object>
                                    params['conferenceInfo'] = info
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConferencePage, params)
                                    this.mainNavPathStack.removeByName(uikitNavigationDestinations.StartConferencePage)
                                } else {
                                    showToast('加入会议失败');
                                }

                            } catch (e) {
                                showToast('发起会议失败 ' + e);
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
                .onClick(async () => {
                    if (this.title.trim().length === 0) {
                        showToast('请输入会议主题')
                        return
                    }
                    try {
                        await this.createConference()
                    } catch (e) {
                        console.log('创建会议失败', e)
                        showToast('创建会议失败')
                    }
                    this.mainNavPathStack.pop()
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }

    async createConference(): Promise<ConferenceInfo> {
        let info = new ConferenceInfo();
        info.password = this.passwordSwitch ? this.password : ''
        info.conferenceTitle = this.title;
        info.pin = `${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}`
        info.owner = wfc.getUserId()
        info.startTime = Math.ceil(new Date().getTime() / 1000);
        info.endTime = Math.ceil(this.endTime.getTime() / 1000);
        info.audience = this.audienceSwitch;
        info.allowSwitchMode = this.modeSwitch;
        info.advance = this.advancedSwitch;
        let conferenceId = await appServer.createConference(info)
        info.conferenceId = conferenceId
        return info
    }
}