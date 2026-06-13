import common from '@ohos.app.ability.common';
import appServer from '@wfc/uikit/src/main/ets/api/appServer';
import router from '@ohos.router';
import data_preferences from '@ohos.data.preferences';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast';
import { inputMethod } from '@kit.IMEKit';
import { SlideVerifyView, SlideVerifyViewDelegate } from '@wfc/uikit/src/main/ets/view/SlideVerifyView';
import Config from '@wfc/client/src/main/ets/config';

import('@wfc/uikit/src/main/ets/pages/misc/WebViewPageWithRouter') //引入共享包中的命名路由页面


@Preview
@Component
export default struct DestroyAccountPage {
    @State message: string = '野火 IM'
    @State isDestroy: boolean = false
    @State authCode: string = ''
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    controller: TextInputController = new TextInputController()

    // 滑动验证状态
    @State showSlideVerify: boolean = false
    @State cachedSlideVerifyToken: string = ''

    build() {
        NavDestination() {
            Stack() {
                Column() {
                    Text('亲，真的要狠心离开我们吗😭😭😭！')
                        .fontColor($r('app.color.wf_primary_text'))

                    Row() {
                        Text('验证码')
                            .width(50)
                        TextInput({ text: this.authCode, placeholder: '请输入验证码', controller: this.controller })
                            .placeholderColor($r('app.color.wf_tertiary_text'))
                            .placeholderFont({ size: 14, weight: 400 })
                            .caretColor($r('app.color.wf_primary'))
                            .layoutWeight(1)
                            .height(40)
                            .margin(20)
                            .fontSize(14)
                            .borderRadius(4)
                            .type(InputType.Number)
                            .fontColor($r('app.color.wf_primary_text'))
                            .enabled(!this.isDestroy)
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
                            .enabled(!this.isDestroy)
                            .onClick(() => {
                                inputMethod.getController().stopInputSession()
                                if (Config.ENABLE_SLIDE_VERIFY) {
                                    this.showSlideVerify = true
                                } else {
                                    appServer.requestDestroyAuthCode()
                                        .then(res => {
                                            showToast('发送验证码成功')
                                        })
                                        .catch((reason: Error) => {
                                            showToast('发送验证码失败 ' + reason)
                                        })
                                }
                            })

                    }
                    .width('100%')
                    .margin({ top: 20 })

                    Row() {
                        Button({ type: ButtonType.Normal, stateEffect: true }) {
                            Row() {
                                if (this.isDestroy) {
                                    LoadingProgress().width(20).height(20).margin({ left: 12 }).color($r('app.color.wf_background'))
                                }
                                Text(this.isDestroy ? '注销中...' : '注销').fontColor($r('app.color.wf_danger')).margin({ left: 5 })
                            }.alignItems(VerticalAlign.Center)
                        }
                        .borderRadius(8)
                        .backgroundColor("#e1e1e1")
                        .width(90)
                        .height(40)
                        .focusable(true)
                        .focusOnTouch(true)
                        .enabled(!this.isDestroy && this.authCode.length > 0)
                        .type(ButtonType.Normal)
                        .width('100%')
                        .borderRadius(4)
                        .onClick(() => {
                            inputMethod.getController().stopInputSession()
                            this.isDestroy = true
                            console.info('destroy', this.authCode, appServer)
                            appServer.destroy(this.authCode)
                                .then(async res => {
                                    this.isDestroy = false
                                    this.onDestroySuccess(res as Record<string, Object>)
                                })
                                .catch((reason: Error) => {
                                    this.isDestroy = false
                                    console.error('login failed', reason)
                                })

                        })

                    }
                    .justifyContent(FlexAlign.Center)
                    .margin({ top: 40 })
                    .width('100%')


                    Blank()
                        .layoutWeight(1)

                }
                .alignItems(HorizontalAlign.Start)
                .padding({ left: 16, right: 16 })
                .margin({ top: 100 })
                .width('100%')

                // 滑动验证弹窗
                if (this.showSlideVerify) {
                    Stack() {
                        Column()
                            .width('100%')
                            .height('100%')
                            .backgroundColor('rgba(0, 0, 0, 0.5)')
                            .onClick(() => {
                                this.showSlideVerify = false
                                showToast('已取消')
                            })

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
        }
        .title('销毁账号')
        .height('100%')
        .width('100%')
    }

    async onDestroySuccess(res: Record<string, Object>) {
        console.log('login success', res);
        data_preferences.deletePreferences(getContext(this).getApplicationContext(), 'wfcstore')
        this.mainNavPathStack.clear(false)
        wfc.disconnect(true, false)
    }

    createSlideVerifyDelegate(): SlideVerifyViewDelegate {
        class DestroyAccountDelegate implements SlideVerifyViewDelegate {
            private page: DestroyAccountPage

            constructor(page: DestroyAccountPage) {
                this.page = page
            }

            slideVerifyViewDidVerifySuccess(token: string): void {
                console.info('[DestroyAccountPage] 滑动验证成功，token:', token)
                this.page.cachedSlideVerifyToken = token
                this.page.showSlideVerify = false

                appServer.requestDestroyAuthCode(this.page.cachedSlideVerifyToken)
                    .then(res => {
                        showToast('发送验证码成功')
                    })
                    .catch((reason: Error) => {
                        showToast('发送验证码失败 ' + reason)
                    })
            }

            slideVerifyViewDidVerifyFailed(): void {
                console.info('[DestroyAccountPage] 滑动验证失败')
                this.page.cachedSlideVerifyToken = ''
                // 验证失败时不关闭窗口，SlideVerifyView 会自动刷新
            }

            slideVerifyViewDidLoadFailed(): void {
                console.info('[DestroyAccountPage] 滑动验证加载失败')
                this.page.cachedSlideVerifyToken = ''
                this.page.showSlideVerify = false
                showToast('验证码加载失败，请重试')
            }
        }

        return new DestroyAccountDelegate(this)
    }
}
