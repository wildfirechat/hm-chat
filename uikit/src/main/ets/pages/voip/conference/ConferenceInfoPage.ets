import OptionItemView from "../../../view/OptionItemView";
import ToggleItemView from "../../../view/ToggleItemView";
import ConferenceInfo from "@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo";
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import avengineKit from '@wfc/avenginekit'
import appServer from '../../../api/appServer';
import { showToast } from "../../../common/utils/Toast";
import wfc from "@wfc/client";
import { navigationDestinations } from "../../navigationConfig";

@Component
export default struct ConferenceInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State conferenceInfo: ConferenceInfo | undefined = undefined
    @State enableAudio: boolean = true;
    @State enableVideo: boolean = false;
    @State ownerUserInfo: UserInfo | undefined = undefined
    @State expired: boolean = false

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let conferenceId = params['conferenceId'] as string;
        let password = params['password'] as string;

        appServer.queryConferenceInfo(conferenceId, password)
            .then(conferenceInfo => {
                this.conferenceInfo = conferenceInfo;
                this.expired = this.conferenceInfo.endTime * 1000 < new Date().getTime()
                wfc.getUserInfoEx(conferenceInfo.owner, false, userInfo => {
                    this.ownerUserInfo = userInfo
                }, err => {

                })
            })
            .catch((e: Error) => {
                showToast('获取会议详情失败 ' + e)
                this.mainNavPathStack.pop()
            })
    }

    build() {
        NavDestination() {
            Column() {
                Column() {
                    OptionItemView({
                        title: '会议主题',
                        desc: this.conferenceInfo?.conferenceTitle,
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false
                    })

                    OptionItemView({
                        title: '发起人',
                        desc: this.ownerUserInfo?.displayName,
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
                            this.enableVideo = value;
                        }
                    })
                    ToggleItemView({
                        title: '开启音频',
                        isOn: this.enableAudio,
                        paddingLeft: 20,
                        onChange: value => {
                            this.enableAudio = value;
                        }
                    })
                }
                .margin({ top: 20 })
                .backgroundColor(Color.White)

                Column() {
                    Button(this.expired ? '会议已过期' : '加入会议')
                        .enabled(!this.expired)
                        .type(ButtonType.Normal)
                        .borderRadius(4)
                        .width('50%')
                        .onClick(() => {
                            let info = this.conferenceInfo!
                            let callSession = avengineKit.joinConference(info?.conferenceId, false, info?.pin, info?.owner, info?.conferenceTitle, '', false, info?.advance, !this.enableAudio, !this.enableVideo, '', '')
                            if (callSession) {
                                let params = {} as Record<string, Object>
                                params['conferenceInfo'] = info
                                this.mainNavPathStack.pushPathByName(navigationDestinations.ConferencePage, params)
                            } else {
                                showToast('加入会议失败');
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
        .title('会议详情')
    }
}
