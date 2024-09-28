import appServer from '../../api/appServer';
import { showToast } from '../../common/utils/Toast';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';

@Entry
@Component
export default struct ChangePasswordPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    controller: TextInputController = new TextInputController()

    @State isProgress: boolean = false

    // 密码登陆
    @State originalPassword: string = ''
    @State password: string = ''
    @State confirmPassword: string = ''

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    Text($r('app.string.original_password')).width(70)
                    TextInput({
                        text: this.originalPassword,
                        placeholder: $r('app.string.enter_original_password'),
                        controller: this.controller
                    })
                        .placeholderColor(Color.Grey)
                        .placeholderFont({ size: 14, weight: 400 })
                        .caretColor(Color.Blue)
                        .layoutWeight(1)
                        .height(40)
                        .margin({ left: 20 })
                        .fontSize(14)
                        .borderRadius(4)
                        .type(InputType.Password)
                        .fontColor(Color.Black)
                        .borderStyle(BorderStyle.Dashed)
                        .onChange((value: string) => {
                            this.originalPassword = value
                        })
                }

                Row() {
                    Text($r('app.string.new_password')).width(70)
                    TextInput({
                        text: this.password,
                        placeholder: $r('app.string.enter_new_password'),
                        controller: this.controller
                    })
                        .placeholderColor(Color.Grey)
                        .placeholderFont({ size: 14, weight: 400 })
                        .caretColor(Color.Blue)
                        .layoutWeight(1)
                        .height(40)
                        .margin({ left: 20 })
                        .fontSize(14)
                        .borderRadius(4)
                        .type(InputType.Password)
                        .fontColor(Color.Black)
                        .borderStyle(BorderStyle.Dashed)
                        .onChange((value: string) => {
                            this.password = value
                        })
                }.margin({top: 16})

                Row() {
                    Text($r('app.string.confirm_password')).width(70)
                    TextInput({
                        text: this.confirmPassword,
                        placeholder: $r('app.string.confirm_new_password'),
                        controller: this.controller
                    })
                        .placeholderColor(Color.Grey)
                        .placeholderFont({ size: 14, weight: 400 })
                        .caretColor(Color.Blue)
                        .layoutWeight(1)
                        .height(40)
                        .margin({ left: 20 })
                        .fontSize(14)
                        .borderRadius(4)
                        .type(InputType.Password)
                        .fontColor(Color.Black)
                        .borderStyle(BorderStyle.Dashed)
                        .onChange((value: string) => {
                            this.confirmPassword = value
                        })
                }.margin({top: 16})

                Row() {
                    Button({ type: ButtonType.Normal, stateEffect: true }) {
                        Row() {
                            if (this.isProgress) {
                                LoadingProgress().width(20).height(20).margin({ left: 12 }).color(0xFFFFFF)
                            }
                            Text($r('app.string.btn_reset_password')).fontColor(0xffffff).margin({ left: 5 })
                        }.alignItems(VerticalAlign.Center)
                    }
                    .borderRadius(8)
                    .backgroundColor(0x317aff)
                    .width(90)
                    .height(40)
                    .focusable(true)
                    .focusOnTouch(true)
                    .enabled(!this.isProgress && this.originalPassword.length > 0
                        && this.password.length > 0 && this.confirmPassword.length > 0)
                    .type(ButtonType.Normal)
                    .width('100%')
                    .borderRadius(4)
                    .onClick(() => {
                        // 判断密码是否一致
                        if (this.password != this.confirmPassword) {
                            showToast($r('app.string.password_mismatch'))
                            return
                        }

                        console.info('changePassword', appServer)

                        this.changePassword()
                    })

                }
                .justifyContent(FlexAlign.Center)
                .margin({ top: 40 })
                .width('100%')
            }
            .padding({ left: 16, right: 16 })
            .width('100%')
        }
        .title('设置新密码')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }

    changePassword() {
        this.isProgress = true
        appServer.changePassword(this.originalPassword, this.password)
            .then(async res => {
                showToast($r('app.string.password_reset_success'))
                this.isProgress = false
                this.mainNavPathStack.pop()
            })
            .catch((reason: Error) => {
                this.isProgress = false
                console.error('changePassword failed', reason)
                showToast(getContext().resourceManager.getStringSync($r('app.string.password_reset_failed').id, reason.message))
            })
    }
}
