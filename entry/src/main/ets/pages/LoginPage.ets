import common from '@ohos.app.ability.common';
import appServer from '../api/appServer';
import router from '@ohos.router';
import data_preferences from '@ohos.data.preferences';
import wfc from '../wfc/client/wfc';
import { showToast } from '../common/utils/Toast';


@Preview
@Entry
@Component
struct LoginPage {
    @State message: string = '野火 IM'

    // 是否切换密码登陆
    @State isLoginByPassword: boolean = false
    @State isLogin: boolean = false

    // 验证码登陆
    @State phoneNumber: string = ''
    @State authCode: string = ''

    // 密码登陆
    @State password: string = ''

    controller: TextInputController = new TextInputController()

    build() {
        Column() {
            Text(this.isLoginByPassword ? '密码登陆' : '验证码登录')
                .fontSize(26)
                .fontColor('#0C0C0C')

            Row() {
                Text('手机号')
                    .width(50)
                TextInput({
                    text: this.phoneNumber,
                    placeholder: '请输入手机号(仅支持中国大陆手机号)',
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
                    .enabled(!this.isLogin)
                    .fontColor(Color.Black)
                    .borderStyle(BorderStyle.Dashed)
                    .inputFilter('[a-zA-Z0-9]', (e) => {
                        console.log(JSON.stringify(e))
                    })
                    .onChange((value: string) => {
                        this.phoneNumber = value
                    })
            }
            .width('100%')
            .margin({ top: 30 })

            Row() {
                Text(this.isLoginByPassword ? '密码' : '验证码')
                    .width(50)
                if (this.isLoginByPassword) {
                    TextInput({ text: this.password, placeholder: '请输入密码', controller: this.controller })
                        .placeholderColor(Color.Grey)
                        .placeholderFont({ size: 14, weight: 400 })
                        .caretColor(Color.Blue)
                        .layoutWeight(1)
                        .height(40)
                        .margin(20)
                        .fontSize(14)
                        .borderRadius(4)
                        .type(InputType.Password)
                        .fontColor(Color.Black)
                        .enabled(!this.isLogin)
                        .showPasswordIcon(true)
                        .onChange((value: string) => {
                            this.password = value
                        })
                } else {
                    TextInput({ text: this.authCode, placeholder: '请输入验证码', controller: this.controller })
                        .placeholderColor(Color.Grey)
                        .placeholderFont({ size: 14, weight: 400 })
                        .caretColor(Color.Blue)
                        .layoutWeight(1)
                        .height(40)
                        .margin(20)
                        .fontSize(14)
                        .borderRadius(4)
                        .type(InputType.Number)
                        .fontColor(Color.Black)
                        .enabled(!this.isLogin)
                        .inputFilter('[a-zA-Z0-9]', (e) => {
                            console.log(JSON.stringify(e))
                        })
                        .onChange((value: string) => {
                            this.authCode = value
                        })

                    Button('获取验证码')
                        .fontSize(12)
                        .type(ButtonType.Normal)
                        .borderRadius(4)
                        .enabled(!this.isLogin && this.phoneNumber.length === 11)
                        .onClick(() => {
                            appServer.requestAuthCode(this.phoneNumber)
                                .then(res => {
                                    showToast('发送验证码成功')
                                })
                                .catch((reason: Error) => {
                                    showToast('发送验证码失败 ' + reason)
                                })
                        })
                }

            }
            .width('100%')
            .margin({ top: 20 })

            // 切换登陆方式
            Row() {
                Blank()
                    .layoutWeight(1)
                Text(this.isLoginByPassword ? '注册/验证码登录' : '使用密码登录')
                    .fontSize(14)
                    .fontColor('#0C0C0C')
                    .textAlign(TextAlign.End)
                    .onClick(() => {
                        this.isLoginByPassword = !this.isLoginByPassword
                    })
            }

            Row() {
                Button({ type: ButtonType.Normal, stateEffect: true }) {
                    Row() {
                        if (this.isLogin) {
                            LoadingProgress().width(20).height(20).margin({ left: 12 }).color(0xFFFFFF)
                        }
                        Text(this.isLogin ? '登录中...' : '登录').fontColor(0xffffff).margin({ left: 5 })
                    }.alignItems(VerticalAlign.Center)
                }
                .borderRadius(8)
                .backgroundColor(0x317aff)
                .width(90)
                .height(40)
                .focusable(true)
                .focusOnTouch(true)
                .enabled(!this.isLogin && ((this.isLoginByPassword && this.phoneNumber.length === 11 && this.password.length > 0) || (!this.isLoginByPassword && this.phoneNumber.length === 11 && this.authCode.length > 0)))
                .type(ButtonType.Normal)
                .width('100%')
                .borderRadius(4)
                .onClick(() => {
                    this.isLogin = true
                    if (this.isLoginByPassword) {
                        console.info('login_pwd', this.phoneNumber, appServer)
                        appServer.loinWithPassword(this.phoneNumber, this.password)
                            .then(async res => {
                                this.isLogin = false
                                this.onLoginSuccess(res as Record<string, Object>)
                            })
                            .catch((reason: Error) => {
                                this.isLogin = false
                                console.error('login failed', reason)
                            })

                    } else {
                        console.info('login', this.phoneNumber, this.authCode, appServer)
                        appServer.loginWithAuthCode(this.phoneNumber, this.authCode)
                            .then(async res => {
                                this.isLogin = false
                                this.onLoginSuccess(res as Record<string, Object>)
                            })
                            .catch((reason: Error) => {
                                this.isLogin = false
                                console.error('login failed', reason)
                            })

                    }
                })

            }
            .justifyContent(FlexAlign.Center)
            .margin({ top: 40 })
            .width('100%')


            Blank()
                .layoutWeight(1)

            Row() {
                Text('登录即代表同意')
                    .fontSize(12)
                Text('《野火IM用户协议》')
                    .fontColor(Color.Blue)
                    .fontSize(12)
                    .onClick(() => {
                        router.pushUrl({
                            url: 'pages/misc/WebViewPageWithRouter',
                            params: {
                                url: 'https://www.wildfirechat.net/wildfirechat_user_agreement.html',
                                title: '野火IM用户协议'
                            }
                        }, router.RouterMode.Standard)
                    })
                Text('和')
                    .fontSize(12)
                Text('《野火IM隐私政策》')
                    .fontColor(Color.Blue)
                    .fontSize(12)
                    .onClick(() => {
                        router.pushUrl({
                            url: 'pages/misc/WebViewPageWithRouter',
                            params: {
                                url: 'https://www.wildfirechat.net/wildfirechat_user_privacy.html',
                                title: '野火IM个人信息保护政策'
                            }
                        }, router.RouterMode.Standard)
                    })
            }
            .justifyContent(FlexAlign.Center)
            .padding({ bottom: 10 })
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 16 })
        .margin({ top: 120 })
        .width('100%')
    }

    async onLoginSuccess(res: Record<string, Object>) {
        console.log('login success', res);
        let context = getContext(this) as common.UIAbilityContext;
        let preference = await data_preferences.getPreferences(context, 'wfcstore')
        const userId = res['userId'] as string
        const token = res['token'] as string
        preference.put('userId', userId);
        preference.put('token', token);
        preference.flush()

        wfc.connect(userId, token);
        router.replaceUrl({
            url: "pages/MainPage",
            params: {}
        }, router.RouterMode.Standard)
    }
}