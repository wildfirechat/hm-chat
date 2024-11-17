import OptionItemView from "../../view/OptionItemView";
import ToggleItemView from "../../view/ToggleItemView";
import ConferenceInfo from "@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo";

@Component
export default struct ConferenceInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State conferenceInfo: ConferenceInfo | undefined = undefined

    build() {
        NavDestination() {
            Column() {
                Column() {
                    OptionItemView({
                        title: '会议主题',
                        desc: 'TODO',
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false
                    })

                    OptionItemView({
                        title: '发起人',
                        desc: 'TODO',
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false
                    })

                    OptionItemView({
                        title: '会议号',
                        desc: 'TODO',
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
                        desc: 'TODO',
                        paddingLeft: 20,
                        showDivider: true,
                        showRightArrow: false
                    })
                    OptionItemView({
                        title: '结束时间',
                        desc: 'TODO',
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
                        isOn: false,
                        showDivider: true,
                        paddingLeft: 20,
                        onChange: value => {

                        }
                    })
                    ToggleItemView({
                        title: '开启音频',
                        isOn: true,
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