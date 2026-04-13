import common from '@ohos.app.ability.common';
import appServer from '@wfc/uikit/src/main/ets/api/appServer';
import router from '@ohos.router';
import data_preferences from '@ohos.data.preferences';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast';
import { inputMethod } from '@kit.IMEKit';

import('@wfc/uikit/src/main/ets/pages/misc/WebViewPageWithRouter') //引入共享包中的命名路由页面


@Preview
@Component
export default struct DestroyAccountPage {
    @State message: string = '野火 IM'
    @State isDestroy: boolean = false
    @State authCode: string = ''
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    controller: TextInputController = new TextInputController()

    build() {
        NavDestination() {

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
                            appServer.requestDestroyAuthCode()
                                .then(res => {
                                    showToast('发送验证码成功')
                                })
                                .catch((reason: Error) => {
                                    showToast('发送验证码失败 ' + reason)
                                })
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
}
