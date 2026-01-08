import common from '@ohos.app.ability.common';
import appServer from '@wfc/uikit/src/main/ets/api/appServer';
import router from '@ohos.router';
import data_preferences from '@ohos.data.preferences';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast';
import { inputMethod } from '@kit.IMEKit';
import { SlideVerifyView, SlideVerifyViewDelegate } from '@wfc/uikit/src/main/ets/view/SlideVerifyView';

import('@wfc/uikit/src/main/ets/pages/misc/WebViewPageWithRouter') //引入共享包中的命名路由页面

// 上一次登陆的手机号码
export const LAST_LOGIN_MOBILE_KEY = "last_login_mobile_key";

@Preview
@Entry
@Component
struct LoginPage {
    @State message: string = '野火 IM'

    // 上一次登陆的手机号
    @StorageLink(LAST_LOGIN_MOBILE_KEY) lastLoginMobile: string = ''

    // 是否切换密码登陆
    @State isLoginByPassword: boolean = false
    @State isLogin: boolean = false

    // 验证码登陆
    @State phoneNumber: string = ''
    @State authCode: string = ''

    // 密码登陆
    @State password: string = ''

    @State isAgreeUserAgreementAndPrivacyPolicy: boolean = false

    // 滑动验证状态
    @State showSlideVerify: boolean = false
    @State cachedSlideVerifyToken: string = ''
    @State hasSlideVerifiedForCode: boolean = false // 标记是否已通过发送验证码的滑动验证
    @State pendingAction: string = '' // 'send_code', 'password_login'

    controller: TextInputController = new TextInputController()


    aboutToAppear(): void {
        this.phoneNumber = this.lastLoginMobile
    }

    build() {
        Stack() {
            // 原有的登录界面
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
                            .margin({ left: 20, bottom: 20, top: 20 })
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
                                // 发送验证码时需要滑动验证
                                inputMethod.getController().stopInputSession()
                                this.pendingAction = 'send_code'
                                this.showSlideVerify = true
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
                        .fontSize(13)
                        .fontColor(Color.Grey)
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
                        inputMethod.getController().stopInputSession()
                        if(!this.isAgreeUserAgreementAndPrivacyPolicy){
                            showToast('请同意用户协议及隐私政策')
                            return
                        }
                        this.isLogin = true
                        if (this.isLoginByPassword) {
                            // 密码登录需要滑动验证
                            this.pendingAction = 'password_login'
                            this.showSlideVerify = true
                        } else {
                            // 验证码登录：如果已通过发送验证码时的验证，则直接登录
                            // 注意：登录时不传递 slideVerifyToken，因为 token 在发送验证码时已被后端删除
                            if (this.hasSlideVerifiedForCode) {
                                appServer.loginWithAuthCode(this.phoneNumber, this.authCode)
                                    .then(async res => {
                                        this.isLogin = false
                                        this.onLoginSuccess(res as Record<string, Object>)
                                    })
                                    .catch((reason: Error) => {
                                        this.isLogin = false
                                        showToast(reason.message)
                                        console.error('login failed', reason)
                                    })
                            } else {
                                // 未验证过，需要先滑动验证
                                showToast('请先获取验证码')
                                this.isLogin = false
                            }
                        }
                    })

                }
                .justifyContent(FlexAlign.Center)
                .margin({ top: 40 })
                .width('100%')


                Blank()
                    .layoutWeight(1)

                Row() {
                    Checkbox()
                        .select(this.isAgreeUserAgreementAndPrivacyPolicy)
                        .onChange(checked => {
                            this.isAgreeUserAgreementAndPrivacyPolicy = checked
                        })
                    Text('登录即代表同意')
                        .fontSize(12)
                    Text('《野火IM用户协议》')
                        .fontColor(Color.Blue)
                        .fontSize(12)
                        .onClick(() => {
                            router.pushNamedRoute({
                                name: 'webViewPageWithRouter',
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
                            router.pushNamedRoute({
                                name: 'webViewPageWithRouter',
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

            // 滑动验证弹窗
            if (this.showSlideVerify) {
                Stack() {
                    // 半透明背景
                    Column()
                        .width('100%')
                        .height('100%')
                        .backgroundColor('rgba(0, 0, 0, 0.5)')
                        .onClick(() => {
                            // 点击外部区域，取消验证
                            this.showSlideVerify = false
                            showToast('已取消')
                        })

                    // 滑动验证组件
                    SlideVerifyView({
                        delegate: this.createSlideVerifyDelegate()
                    })
                }
                .width('100%')
                .height('100%')
                .position({ x: 0, y: 0 })
                .zIndex(9999)
            }
        }
        .width('100%')
        .height('100%')
    }

    async onLoginSuccess(res: Record<string, Object>) {
        console.log('login success', res);
        //  记录手机号
        this.lastLoginMobile = this.phoneNumber

        let context = getContext(this) as common.UIAbilityContext;
        let preference = await data_preferences.getPreferences(context.getApplicationContext(), 'wfcstore')
        const userId = res['userId'] as string
        const token = res['token'] as string
        preference.putSync('userId', userId);
        preference.putSync('token', token);
        await preference.flush()

        wfc.connect(userId, token);
        router.replaceUrl({
            url: "pages/MainPage",
            params: {}
        }, router.RouterMode.Standard)
    }

    createSlideVerifyDelegate(): SlideVerifyViewDelegate {
        class LoginDelegate implements SlideVerifyViewDelegate {
            private page: LoginPage

            constructor(page: LoginPage) {
                this.page = page
            }

            slideVerifyViewDidVerifySuccess(token: string): void {
                console.info('[LoginPage] 滑动验证成功，token:', token)
                this.page.cachedSlideVerifyToken = token

                if (this.page.pendingAction === 'send_code') {
                    // 发送验证码
                    this.page.hasSlideVerifiedForCode = true
                    appServer.requestAuthCode(this.page.phoneNumber, this.page.cachedSlideVerifyToken)
                        .then(res => {
                            showToast('发送验证码成功')
                        })
                        .catch((reason: Error) => {
                            // 发送失败，重置验证标志
                            this.page.hasSlideVerifiedForCode = false
                            showToast('发送验证码失败 ' + reason)
                        })
                } else if (this.page.pendingAction === 'password_login') {
                    // 密码登录
                    console.info('login_pwd', this.page.phoneNumber, appServer)
                    appServer.loinWithPassword(this.page.phoneNumber, this.page.password, this.page.cachedSlideVerifyToken)
                        .then(async res => {
                            this.page.isLogin = false
                            this.page.onLoginSuccess(res as Record<string, Object>)
                        })
                        .catch((reason: Error) => {
                            this.page.isLogin = false
                            showToast(reason.message)
                            console.error('login failed', reason)
                        })
                }

                this.page.showSlideVerify = false
                this.page.pendingAction = ''
            }

            slideVerifyViewDidVerifyFailed(): void {
                console.info('[LoginPage] 滑动验证失败')
                this.page.cachedSlideVerifyToken = ''
                this.page.isLogin = false
                // 验证失败时不关闭窗口，SlideVerifyView 会自动刷新
            }

            slideVerifyViewDidLoadFailed(): void {
                console.info('[LoginPage] 滑动验证加载失败')
                this.page.cachedSlideVerifyToken = ''
                this.page.pendingAction = ''
                this.page.isLogin = false
                showToast('验证码加载失败，请重试')
            }
        }

        return new LoginDelegate(this)
    }
}
