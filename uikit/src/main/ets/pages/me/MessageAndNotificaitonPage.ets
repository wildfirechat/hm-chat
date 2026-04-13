import { showToast } from '../../common/utils/Toast';
import OptionItemView from '../../view/OptionItemView'
import ToggleItemView from '../../view/ToggleItemView'

@Preview
@Component
export default struct MessageAndNotificationPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State enableNewMessageNotification: boolean = true

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Column() {
                Column() {
                    ToggleItemView({
                        title: '接受新消息通知',
                        isOn: true, // TODO
                        showDivider: true,
                        onChange: (isOn) => {
                            showToast('TODO')
                        }
                    })
                    ToggleItemView({
                        title: '接收语音或视频来电通知',
                        isOn: true, // TODO
                        onChange: (isOn) => {
                            showToast('TODO')
                        }
                    })
                }
                .backgroundColor($r('app.color.wf_background'))

                Column() {
                    ToggleItemView({
                        title: '通知显示消息详情',
                        isOn: true, // TODO
                        showDivider: true,
                        onChange: (isOn) => {
                            showToast('TODO')
                        }
                    })
                    ToggleItemView({
                        title: '消息回执',
                        isOn: true, // TODO
                        showDivider: true,
                        onChange: (isOn) => {
                            showToast('TODO')
                        }
                    })
                    ToggleItemView({
                        title: '草稿同步',
                        isOn: true, // TODO
                        onChange: (isOn) => {
                            showToast('TODO')
                        }
                    })
                }
                .margin({ top: 10 })
                .backgroundColor($r('app.color.wf_background'))


                Column() {
                    ToggleItemView({
                        title: '开启对讲功能',
                        isOn: true, // TODO
                        showDivider: true,
                        onChange: (isOn) => {
                            showToast('TODO')
                        }
                    })
                }
                .margin({ top: 10 })
                .backgroundColor($r('app.color.wf_background'))
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .title('消息与通知')
        .height('100%')
        .width('100%')
    }
}
