import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import data_preferences from '@ohos.data.preferences';
import hilog from '@ohos.hilog';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast';
import { inputMethod } from '@kit.IMEKit';
import { SlideVerifyView, SlideVerifyViewDelegate } from '@wfc/uikit/src/main/ets/view/SlideVerifyView';
import Config from '@wfc/client/src/main/ets/config';
import { FontSize, Radius } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import appServer from '@wfc/uikit/src/main/ets/api/appServer'
import QRLoginSession from '@wfc/uikit/src/main/ets/api/model/qrLoginSession'
import AppServerError from '@wfc/uikit/src/main/ets/api/appServerError'
import { isWideScreen } from '@wfc/uikit/src/main/ets/util/navUtil'
import { LAST_LOGIN_MOBILE_KEY } from './LoginPage'

import('@wfc/uikit/src/main/ets/pages/misc/WebViewPageWithRouter') //引入共享包中的命名路由页面

// 扫码登录流程日志 TAG，抓取：hdc hilog | grep PadQR
const TAG = 'PadQR';

// 登录方式三态（与 Android/iOS/PC 端 loginType 一致）：
// 0 扫码登录（平板默认）：展示二维码，手机端扫码确认后自动登录；2s 轮询 + 60s 自动刷新
// 1 密码登录：手机号 + 密码
// 2 验证码登录：手机号 + 短信验证码（带倒计时）
const LOGIN_TYPE_QR = 0
const LOGIN_TYPE_PASSWORD = 1
const LOGIN_TYPE_SMS = 2

/**
 * 平板（宽屏）卡片式登录页，参考 android-chat PadLoginActivity / iOS WFCLoginViewController 的 pad 实现：
 * 所有内容（扫码 / 密码 / 验证码三种登录方式）放在一张白色圆角卡片上，居中显示。
 * 二维码内容为 wildfirechat://pcsession/<token>，与手机端扫码识别的格式一致；
 * 服务端接口 POST /pc_session 与 POST /session_login/<token>（0 成功 / 9 已扫码 / 18 已取消）。
 *
 * 本页仅在宽屏（断点 ≥ md，通常为平板）由 EntryAbility 路由进入；手机端登录仍走 LoginPage，不受影响。
 */
@Entry
@Component
struct PadLoginPage {
    // ==================== 表单 ====================
    @StorageLink(LAST_LOGIN_MOBILE_KEY) lastLoginMobile: string = ''
    @State isLoginByPassword: boolean = false
    @State phoneNumber: string = ''
    @State password: string = ''
    @State isLogin: boolean = false
    @State isAgreeUserAgreementAndPrivacyPolicy: boolean = false
    controller: TextInputController = new TextInputController()

    // ==================== 登录方式 ====================
    @State loginType: number = LOGIN_TYPE_QR

    // ==================== 扫码登录 ====================
    @State qrValue: string = ''
    @State qrLoading: boolean = false
    @State qrStatusText: string = ''
    @State qrScannedPortrait: string = ''
    @State qrScannedName: string = ''
    @State qrScanned: boolean = false
    private pcSessionToken: string = ''
    private qrCreating: boolean = false
    private qrPollTimer: number = -1
    private qrRefreshTimer: number = -1

    // ==================== 验证码登录 ====================
    @State countdownText: string = '获取验证码'
    @State hasSlideVerifiedForCode: boolean = false
    @State cachedSlideVerifyToken: string = ''
    @State showSlideVerify: boolean = false
    @State pendingAction: string = '' // 'send_code', 'password_login', 'code_login'
    private countdownSeconds: number = 60
    private countdownTimer: number = -1

    aboutToAppear(): void {
        hilog.info(0x0000, TAG, 'PadLoginPage aboutToAppear, isPadDevice=%{public}s, platform=%{public}d, isWideScreen=%{public}s, appServer=%{public}s',
            String(Config.isPadDevice()), Config.getWFCPlatform(), String(isWideScreen()), String(Config.getAppServer()))
        this.phoneNumber = this.lastLoginMobile
        // 平板默认扫码登录（参考 Android/iOS/PC 端）
        this.loginType = LOGIN_TYPE_QR
        this.refreshQRCode()
    }

    aboutToDisappear(): void {
        this.stopQRPolling()
        this.resetCountdown()
    }

    // ==================== 扫码登录 ====================

    private refreshQRCode() {
        if (this.qrCreating) {
            hilog.warn(0x0000, TAG, 'refreshQRCode: session creation in flight, skip')
            return
        }
        this.stopQRPolling()
        this.pcSessionToken = ''
        this.qrValue = ''
        this.qrScanned = false
        this.qrScannedPortrait = ''
        this.qrScannedName = ''
        this.qrStatusText = '正在生成二维码...'
        this.qrLoading = true
        this.qrCreating = true
        hilog.info(0x0000, TAG, 'refreshQRCode: createPCLoginSession start')
        this.createSessionWithTimeout()
            .then((session: QRLoginSession) => {
                this.qrCreating = false
                if (this.loginType !== LOGIN_TYPE_QR) {
                    hilog.warn(0x0000, TAG, 'refreshQRCode: loginType changed, ignore session')
                    return
                }
                if (!session.token) {
                    // 服务端成功但未返回 token：按失败处理，进入可重试状态
                    hilog.error(0x0000, TAG, 'createPCLoginSession success but token empty')
                    this.qrLoading = false
                    this.qrStatusText = '二维码生成失败，点击重试'
                    return
                }
                this.pcSessionToken = session.token
                this.qrValue = Config.QR_CODE_PREFIX_PC_SESSION + session.token
                this.qrLoading = false
                this.qrStatusText = '请使用手机版野火IM扫一扫登录'
                hilog.info(0x0000, TAG, 'createPCLoginSession success, token=%{public}s, qrValue=%{public}s', session.token, this.qrValue)
                this.startQRPolling()
            })
            .catch((err: AppServerError) => {
                this.qrCreating = false
                if (this.loginType !== LOGIN_TYPE_QR) {
                    return
                }
                this.qrLoading = false
                this.qrStatusText = '二维码生成失败，点击重试'
                hilog.error(0x0000, TAG, 'createPCLoginSession failed, errorCode=%{public}d, message=%{public}s', err.errorCode, err.message)
            })
    }

    // 创建扫码会话并带超时保护：请求挂起（网络异常/服务端无响应）时 10s 后转入可重试的失败态，
    // 避免界面一直停在「正在生成二维码」
    private createSessionWithTimeout(): Promise<QRLoginSession> {
        return new Promise((resolve, reject) => {
            let settled = false
            let timer = setTimeout(() => {
                if (!settled) {
                    settled = true
                    hilog.error(0x0000, TAG, 'createPCLoginSession timeout(10s), treat as failure')
                    reject(new AppServerError(-1, '创建会话超时'))
                }
            }, 10 * 1000)
            appServer.createPCLoginSession('pad')
                .then((session: QRLoginSession) => {
                    if (!settled) {
                        settled = true
                        clearTimeout(timer)
                        resolve(session)
                    }
                })
                .catch((err: AppServerError) => {
                    if (!settled) {
                        settled = true
                        clearTimeout(timer)
                        reject(err)
                    }
                })
        })
    }

    private startQRPolling() {
        if (this.qrPollTimer >= 0) {
            return
        }
        hilog.info(0x0000, TAG, 'startQRPolling: 1s poll + 60s refresh, token=%{public}s', this.pcSessionToken)
        // 1s 轮询扫码状态（扫码后尽快更新为头像/已扫码态）；60s 后自动刷新二维码（与 PC 端一致）
        this.qrPollTimer = setInterval(() => {
            this.pollQRStatus()
        }, 1000)
        this.qrRefreshTimer = setTimeout(() => {
            hilog.info(0x0000, TAG, '60s timer fired, auto refresh QR')
            this.refreshQRCode()
        }, 60 * 1000)
    }

    private stopQRPolling() {
        if (this.qrPollTimer >= 0) {
            hilog.info(0x0000, TAG, 'stopQRPolling: clear poll timer')
            clearInterval(this.qrPollTimer)
            this.qrPollTimer = -1
        }
        if (this.qrRefreshTimer >= 0) {
            clearTimeout(this.qrRefreshTimer)
            this.qrRefreshTimer = -1
        }
    }

    private pollQRStatus() {
        let token = this.pcSessionToken
        if (!token || this.loginType !== LOGIN_TYPE_QR) {
            hilog.warn(0x0000, TAG, 'pollQRStatus: skip, token empty or loginType=%{public}d', this.loginType)
            return
        }
        hilog.info(0x0000, TAG, 'poll: request session_login, token=%{public}s', token)
        appServer.loginWithQRSession(token)
            .then((res: Record<string, Object>) => {
                if (token !== this.pcSessionToken || this.loginType !== LOGIN_TYPE_QR) {
                    // 二维码已刷新/已切换登录方式，丢弃过期结果
                    hilog.warn(0x0000, TAG, 'poll: stale response, ignore (token changed or loginType=%{public}d)', this.loginType)
                    return
                }
                let code = res['code'] as number
                hilog.info(0x0000, TAG, 'poll: code=%{public}d, result=%{public}s', code, JSON.stringify(res['result']))
                if (code === 0) {
                    // 登录成功，拿到 userId + imToken
                    let result = res['result'] as Record<string, Object>
                    if (!result) {
                        hilog.warn(0x0000, TAG, 'poll: code 0 but result missing, ignore')
                        return
                    }
                    let userId = result['userId'] as string
                    let imToken = result['token'] as string
                    hilog.info(0x0000, TAG, 'poll: login success, userId=%{public}s, imTokenLen=%{public}d', userId, imToken ? imToken.length : 0)
                    if (!userId || !imToken) {
                        hilog.warn(0x0000, TAG, 'poll: code 0 but userId/token empty, ignore')
                        return
                    }
                    // 登录等于同意用户协议：未勾选时提示并刷新回新的二维码，不登录
                    if (!this.isAgreeUserAgreementAndPrivacyPolicy) {
                        hilog.warn(0x0000, TAG, 'poll: agreement not checked, refresh QR')
                        showToast('请同意用户协议及隐私政策')
                        this.refreshQRCode()
                        return
                    }
                    this.stopQRPolling()
                    this.loginSuccess(userId, imToken)
                } else if (code === 9) {
                    // 已被手机端扫码，等手机端确认
                    if (!this.qrScanned) {
                        this.qrScanned = true
                        let result = res['result'] as Record<string, Object>
                        this.qrScannedPortrait = (result ? result['portrait'] as string : '') || ''
                        this.qrScannedName = (result ? result['userName'] as string : '') || ''
                        this.qrStatusText = this.qrScannedName ? `已扫码：${this.qrScannedName}，请在手机上确认` : '已扫码，请在手机上确认登录'
                        hilog.info(0x0000, TAG, 'poll: scanned, userName=%{public}s, portrait=%{public}s', this.qrScannedName, this.qrScannedPortrait)
                    }
                } else if (code === 18) {
                    // 手机端取消/拒绝登录，重新生成二维码
                    hilog.info(0x0000, TAG, 'poll: canceled by phone, refresh QR')
                    this.refreshQRCode()
                }
            })
            .catch((err: AppServerError) => {
                // 网络波动等暂时性错误：继续轮询即可
                hilog.error(0x0000, TAG, 'poll: session_login error, errorCode=%{public}d, message=%{public}s', err.errorCode, err.message)
            })
    }

    // ==================== 密码 / 验证码登录 ====================

    private doLogin() {
        if (!this.isAgreeUserAgreementAndPrivacyPolicy) {
            showToast('请同意用户协议及隐私政策')
            return
        }
        inputMethod.getController().stopInputSession()
        this.isLogin = true
        if (Config.ENABLE_SLIDE_VERIFY) {
            if (this.isLoginByPassword) {
                this.pendingAction = 'password_login'
                this.showSlideVerify = true
            } else {
                if (this.hasSlideVerifiedForCode) {
                    // 已通过滑动验证（发送验证码时已验证），直接登录
                    this.doCodeLogin()
                } else {
                    this.pendingAction = 'code_login'
                    this.showSlideVerify = true
                }
            }
        } else {
            if (this.isLoginByPassword) {
                this.passwordLogin()
            } else {
                this.doCodeLogin()
            }
        }
    }

    private passwordLogin() {
        appServer.loinWithPassword(this.phoneNumber, this.password)
            .then(async res => {
                this.isLogin = false
                let result = res as Record<string, Object>
                this.lastLoginMobile = this.phoneNumber
                this.loginSuccess(result['userId'] as string, result['token'] as string)
            })
            .catch((reason: Error) => {
                this.isLogin = false
                showToast(reason.message)
            })
    }

    private doCodeLogin() {
        appServer.loginWithAuthCode(this.phoneNumber, this.password)
            .then(async res => {
                this.isLogin = false
                let result = res as Record<string, Object>
                this.lastLoginMobile = this.phoneNumber
                this.loginSuccess(result['userId'] as string, result['token'] as string)
            })
            .catch((reason: Error) => {
                this.isLogin = false
                showToast(reason.message)
            })
    }

    // 登录成功：保存凭证、连接 IM、进入主界面（扫码 / 密码 / 验证码三种方式共用）
    private async loginSuccess(userId: string, token: string) {
        hilog.info(0x0000, TAG, 'loginSuccess: save credentials & connect, userId=%{public}s', userId)
        try {
            let context = getContext(this) as common.UIAbilityContext;
            let preference = await data_preferences.getPreferences(context.getApplicationContext(), 'wfcstore')
            preference.putSync('userId', userId);
            preference.putSync('token', token);
            await preference.flush()

            wfc.connect(userId, token);
            router.replaceUrl({
                url: "pages/MainPage",
                params: {}
            }, router.RouterMode.Standard)
        } catch (e) {
            hilog.error(0x0000, TAG, 'loginSuccess failed: %{public}s', JSON.stringify(e))
            showToast('登录失败，请重试')
            // 恢复可重试状态：扫码模式下重新生成二维码，表单模式下停留在表单
            if (this.loginType === LOGIN_TYPE_QR) {
                this.refreshQRCode()
            }
        }
    }

    // ==================== 验证码 ====================

    private requestAuthCode() {
        if (this.phoneNumber.length !== 11) {
            showToast('请输入正确的手机号')
            return
        }
        inputMethod.getController().stopInputSession()
        if (Config.ENABLE_SLIDE_VERIFY) {
            this.pendingAction = 'send_code'
            this.showSlideVerify = true
        } else {
            this.performRequestAuthCode()
        }
    }

    private performRequestAuthCode(slideVerifyToken?: string) {
        this.startCountdown()
        let request = slideVerifyToken
            ? appServer.requestAuthCode(this.phoneNumber, slideVerifyToken)
            : appServer.requestAuthCode(this.phoneNumber)
        request.then(() => {
            showToast('发送验证码成功')
            this.hasSlideVerifiedForCode = true
            if (slideVerifyToken) {
                this.cachedSlideVerifyToken = slideVerifyToken
            }
        }).catch((reason: Error) => {
            showToast('发送验证码失败 ' + reason.message)
            this.hasSlideVerifiedForCode = false
            this.cachedSlideVerifyToken = ''
            this.resetCountdown()
        })
    }

    private startCountdown() {
        this.resetCountdown()
        this.countdownSeconds = 60
        this.countdownText = '60s后重发'
        this.countdownTimer = setInterval(() => {
            this.countdownSeconds--
            if (this.countdownSeconds <= 0) {
                this.resetCountdown()
            } else {
                this.countdownText = this.countdownSeconds + 's后重发'
            }
        }, 1000)
    }

    private resetCountdown() {
        if (this.countdownTimer >= 0) {
            clearInterval(this.countdownTimer)
            this.countdownTimer = -1
        }
        this.countdownText = '获取验证码'
    }

    // ==================== 登录方式切换 ====================

    private switchQRForm() {
        hilog.info(0x0000, TAG, 'switchQRForm: %{public}d -> %{public}s', this.loginType, this.loginType === LOGIN_TYPE_QR ? 'form' : 'qr')
        if (this.loginType === LOGIN_TYPE_QR) {
            // 扫码 ⇄ 验证码登录（参考 Android/iOS：扫码切换回验证码）
            this.stopQRPolling()
            this.loginType = LOGIN_TYPE_SMS
        } else {
            this.loginType = LOGIN_TYPE_QR
            this.refreshQRCode()
        }
        // 切换登录方式后，重置滑动验证标志并更新按钮状态
        this.hasSlideVerifiedForCode = false
        this.cachedSlideVerifyToken = ''
        this.password = ''
    }

    private getFormTitle(): string {
        if (this.loginType === LOGIN_TYPE_QR) {
            return '扫码登录'
        }
        return this.isLoginByPassword ? '密码登录' : '验证码登录'
    }

    // ==================== 滑动验证 ====================

    createSlideVerifyDelegate(): SlideVerifyViewDelegate {
        class PadLoginDelegate implements SlideVerifyViewDelegate {
            private page: PadLoginPage

            constructor(page: PadLoginPage) {
                this.page = page
            }

            slideVerifyViewDidVerifySuccess(token: string): void {
                console.info('[PadLoginPage] 滑动验证成功')
                this.page.cachedSlideVerifyToken = token

                if (this.page.pendingAction === 'send_code') {
                    this.page.hasSlideVerifiedForCode = true
                    this.page.performRequestAuthCode(token)
                } else if (this.page.pendingAction === 'password_login') {
                    appServer.loinWithPassword(this.page.phoneNumber, this.page.password, token)
                        .then(async res => {
                            this.page.isLogin = false
                            let result = res as Record<string, Object>
                            this.page.lastLoginMobile = this.page.phoneNumber
                            this.page.loginSuccess(result['userId'] as string, result['token'] as string)
                        })
                        .catch((reason: Error) => {
                            this.page.isLogin = false
                            showToast(reason.message)
                        })
                } else if (this.page.pendingAction === 'code_login') {
                    this.page.hasSlideVerifiedForCode = true
                    this.page.doCodeLogin()
                }

                this.page.showSlideVerify = false
                this.page.pendingAction = ''
            }

            slideVerifyViewDidVerifyFailed(): void {
                console.info('[PadLoginPage] 滑动验证失败')
                this.page.cachedSlideVerifyToken = ''
                this.page.isLogin = false
                // 验证失败时不关闭窗口，SlideVerifyView 会自动刷新
            }

            slideVerifyViewDidLoadFailed(): void {
                console.info('[PadLoginPage] 滑动验证加载失败')
                this.page.cachedSlideVerifyToken = ''
                this.page.pendingAction = ''
                this.page.isLogin = false
                showToast('验证码加载失败，请重试')
            }
        }

        return new PadLoginDelegate(this)
    }

    // ==================== UI ====================

    @Builder
    QRLoginContent() {
        Column() {
            Stack() {
                if (this.qrScanned) {
                    // 扫码后、手机端确认前：二维码区域换成扫码用户的头像（参考 Android/iOS/PC 端）
                    Image(this.qrScannedPortrait || Config.DEFAULT_PORTRAIT_URL)
                        .width(240)
                        .height(240)
                        .objectFit(ImageFit.Cover)
                        .borderRadius(12)
                        .backgroundColor(Color.White)
                        .onError(() => {
                            hilog.error(0x0000, TAG, 'avatar load failed, portrait=%{public}s, fallback to default', this.qrScannedPortrait)
                            // 头像 URL 加载失败时回退默认头像，避免二维码区域空白
                            this.qrScannedPortrait = Config.DEFAULT_PORTRAIT_URL
                        })
                } else if (this.qrValue) {
                    QRCode(this.qrValue)
                        .width(240)
                        .height(240)
                        .color(0xFF000000)
                        .backgroundColor(Color.White)
                }
                if (this.qrLoading) {
                    LoadingProgress()
                        .width(40)
                        .color($r('app.color.wf_primary'))
                }
            }
            .width(240)
            .height(240)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ top: 20 })
            .onClick(() => {
                // 点击二维码刷新（生成失败时也可点击重试）
                if (this.loginType === LOGIN_TYPE_QR) {
                    this.refreshQRCode()
                }
            })

            Text(this.qrStatusText)
                .fontSize(FontSize.xs)
                .fontColor($r('app.color.wf_tertiary_text'))
                .margin({ top: 12 })
                .textAlign(TextAlign.Center)
                .maxLines(2)
        }
        .width('100%')
    }

    @Builder
    FormLoginContent() {
        Column() {
            // 手机号
            Row() {
                Text('手机号')
                    .width(56)
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_primary_text'))
                TextInput({
                    text: this.phoneNumber,
                    placeholder: '请输入手机号',
                    controller: this.controller
                })
                    .layoutWeight(1)
                    .height(44)
                    .margin({ left: 12 })
                    .fontSize(FontSize.sm)
                    .type(InputType.Number)
                    .enabled(!this.isLogin)
                    .fontColor($r('app.color.wf_primary_text'))
                    .backgroundColor($r('app.color.wf_secondary_background'))
                    .borderRadius(Radius.sm)
                    .padding({ left: 12 })
                    .onChange((value: string) => {
                        this.phoneNumber = value
                    })
            }
            .width('100%')
            .margin({ top: 24 })

            // 密码 / 验证码
            Row() {
                Text(this.isLoginByPassword ? '密码' : '验证码')
                    .width(56)
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_primary_text'))
                if (this.isLoginByPassword) {
                    TextInput({ text: this.password, placeholder: '请输入密码', controller: this.controller })
                        .layoutWeight(1)
                        .height(44)
                        .margin({ left: 12 })
                        .fontSize(FontSize.sm)
                        .type(InputType.Password)
                        .enabled(!this.isLogin)
                        .fontColor($r('app.color.wf_primary_text'))
                        .backgroundColor($r('app.color.wf_secondary_background'))
                        .borderRadius(Radius.sm)
                        .padding({ left: 12 })
                        .onChange((value: string) => {
                            this.password = value
                        })
                } else {
                    TextInput({ text: this.password, placeholder: '请输入验证码', controller: this.controller })
                        .layoutWeight(1)
                        .height(44)
                        .margin({ left: 12 })
                        .fontSize(FontSize.sm)
                        .type(InputType.Number)
                        .enabled(!this.isLogin)
                        .fontColor($r('app.color.wf_primary_text'))
                        .backgroundColor($r('app.color.wf_secondary_background'))
                        .borderRadius(Radius.sm)
                        .padding({ left: 12 })
                        .onChange((value: string) => {
                            this.password = value
                        })
                    Text(this.countdownText)
                        .fontSize(FontSize.xs)
                        .fontColor(this.countdownTimer >= 0 ? $r('app.color.wf_tertiary_text') : $r('app.color.wf_primary'))
                        .margin({ left: 12 })
                        .onClick(() => {
                            if (this.countdownTimer < 0) {
                                this.requestAuthCode()
                            }
                        })
                }
            }
            .width('100%')
            .margin({ top: 16 })

            // 切换密码/验证码登录
            Row() {
                Text(this.isLoginByPassword ? '使用验证码登录' : '使用密码登录')
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_primary'))
                    .onClick(() => {
                        this.isLoginByPassword = !this.isLoginByPassword
                        this.password = ''
                        this.hasSlideVerifiedForCode = false
                        this.cachedSlideVerifyToken = ''
                    })
            }
            .width('100%')
            .margin({ top: 12 })

            // 登录按钮
            Button({ type: ButtonType.Normal, stateEffect: true }) {
                Row() {
                    if (this.isLogin) {
                        LoadingProgress().width(20).height(20).margin({ left: 12 }).color(Color.White)
                    }
                    Text(this.isLogin ? '登录中...' : '登录').fontColor(Color.White).margin({ left: 4 })
                }.alignItems(VerticalAlign.Center)
            }
            .borderRadius(Radius.sm)
            .backgroundColor($r('app.color.wf_primary'))
            .width('100%')
            .height(44)
            .margin({ top: 28 })
            .focusable(true)
            .focusOnTouch(true)
            .enabled(!this.isLogin && this.phoneNumber.length === 11 && this.password.length > 0)
            .onClick(() => {
                this.doLogin()
            })
        }
        .width('100%')
    }

    build() {
        Stack() {
            // 背景 + 居中卡片
            Column() {
                Scroll() {
                    Column() {
                        Column() {
                            // 标题
                            Text(this.getFormTitle())
                                .fontSize(22)
                                .fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.wf_primary_text'))

                            if (this.loginType === LOGIN_TYPE_QR) {
                                this.QRLoginContent()
                            } else {
                                this.FormLoginContent()
                            }

                            // 底部「扫码登录 ⇄ 使用密码/验证码登录」切换
                            Text(this.loginType === LOGIN_TYPE_QR ? '使用密码/验证码登录' : '扫码登录')
                                .fontSize(14)
                                .fontColor($r('app.color.wf_primary'))
                                .margin({ top: 28 })
                                .onClick(() => {
                                    this.switchQRForm()
                                })

                            // 协议
                            Row() {
                                Checkbox()
                                    .select(this.isAgreeUserAgreementAndPrivacyPolicy)
                                    .onChange(checked => {
                                        this.isAgreeUserAgreementAndPrivacyPolicy = checked
                                    })
                                Text('登录即代表同意')
                                    .fontSize(FontSize.xs)
                                    .fontColor($r('app.color.wf_secondary_text'))
                                Text('《野火IM用户协议》')
                                    .fontColor($r('app.color.wf_link'))
                                    .fontSize(FontSize.xs)
                                    .onClick(() => {
                                        router.pushNamedRoute({
                                            name: 'webViewPageWithRouter',
                                            params: {
                                                url: Config.USER_AGREEMENT_URL,
                                                title: '野火IM用户协议'
                                            }
                                        }, router.RouterMode.Standard)
                                    })
                                Text('和')
                                    .fontSize(FontSize.xs)
                                    .fontColor($r('app.color.wf_secondary_text'))
                                Text('《野火IM隐私政策》')
                                    .fontColor($r('app.color.wf_link'))
                                    .fontSize(FontSize.xs)
                                    .onClick(() => {
                                        router.pushNamedRoute({
                                            name: 'webViewPageWithRouter',
                                            params: {
                                                url: Config.PRIVACY_AGREEMENT_URL,
                                                title: '野火IM个人信息保护政策'
                                            }
                                        }, router.RouterMode.Standard)
                                    })
                            }
                            .width('100%')
                            .justifyContent(FlexAlign.Center)
                            .margin({ top: 20 })
                        }
                        .width(400)
                        .padding({ left: 28, right: 28, top: 32, bottom: 24 })
                        .borderRadius(20)
                        .backgroundColor(Color.White)
                        .shadow({ radius: 24, color: '#1A000000', offsetX: 0, offsetY: 8 })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Center)
                    .padding({ top: 48, bottom: 48 })
                }
                .width('100%')
                .height('100%')
                .scrollBar(BarState.Off)
                .align(Alignment.Center)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#F2F2F2')

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
                            this.isLogin = false
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
}
