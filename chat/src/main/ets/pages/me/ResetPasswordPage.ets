import appServer from '@wfc/uikit/src/main/ets/api/appServer';
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';

@Component
export default struct ResetPasswordPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    controller: TextInputController = new TextInputController()

    @State isProgress: boolean = false

    // 用户手机号码
    @State phoneNumber: string = ''
    @State verificationCode: string = ''
    // 密码登陆
    @State password: string = ''
    @State confirmPassword: string = ''

    aboutToAppear() {
        let selfUserInfo: UserInfo = wfc.getUserInfo(wfc.getUserId())
        this.phoneNumber = selfUserInfo.mobile
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    Text($r('app.string.verification_code')).width(70)
                    TextInput({
                        text: this.verificationCode,
                        placeholder: $r('app.string.enter_verification_code'),
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
                        .type(InputType.Number)
                        .fontColor(Color.Black)
                        .borderStyle(BorderStyle.Dashed)
                        .onChange((value: string) => {
                            this.verificationCode = value
                        })
                    Button($r('app.string.get_verification_code'))
                        .fontSize(12)
                        .type(ButtonType.Normal)
                        .borderRadius(4)
                        .enabled(!this.isProgress)
                        .margin({left: 8})
                        .onClick(() => {
                            this.requestResetPasswordAuthCode()
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
                    .enabled(!this.isProgress && this.verificationCode.length > 0 && this.password.length > 0 && this.confirmPassword.length > 0)
                    .type(ButtonType.Normal)
                    .width('100%')
                    .borderRadius(4)
                    .onClick(() => {
                        // 判断密码是否一致
                        if (this.password != this.confirmPassword) {
                            showToast($r('app.string.password_mismatch'))
                            return
                        }

                        console.info('resetPassword', this.phoneNumber, this.verificationCode, appServer)

                        this.resetPassword()
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

    resetPassword() {
        this.isProgress = true
        appServer.resetPassword(this.verificationCode, this.password)
            .then(async res => {
                showToast($r('app.string.password_reset_success'))
                this.isProgress = false
                this.mainNavPathStack.pop()
            })
            .catch((reason: Error) => {
                this.isProgress = false
                console.error('login failed', reason)
                showToast(getContext().resourceManager.getStringSync($r('app.string.password_reset_failed').id, reason.message))
            })
    }

    requestResetPasswordAuthCode() {
        appServer.requestResetPasswordAuthCode(this.phoneNumber)
            .then(res => {
                showToast('发送验证码成功')
            })
            .catch((reason: Error) => {
                showToast('发送验证码失败 ' + reason)
            })
    }
}
