import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import appServer from '../api/appServer'
import router from '@ohos.router';
import data_preferences from '@ohos.data.preferences';
import wfc from '../wfc/client/wfc';
import { showToast } from '../common/utils/Toast';


@Preview
@Entry
@Component
struct LoginPage {
    @State message: string = '野火 IM'
    @State phoneNumber: string = ''
    @State authCode: string = ''
    controller: TextInputController = new TextInputController()

    build() {
        Column() {
            Text('验证码登录')
                .fontSize(26)
                .fontColor('#0C0C0C')

            Row() {
                Text('手机号')
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
                Text('验证码')
                TextInput({ text: this.authCode, placeholder: '请输入验证码', controller: this.controller })
                    .placeholderColor(Color.Grey)
                    .placeholderFont({ size: 14, weight: 400 })
                    .caretColor(Color.Blue)
                    .layoutWeight(1)
                    .height(40)
                    .margin(20)
                    .fontSize(14)
                    .borderRadius(4)
                    .fontColor(Color.Black)
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
                    .enabled(this.phoneNumber.length === 11)
                    .onClick(() => {
                        appServer.requestAuthCode(this.phoneNumber)
                            .then(res => {
                                showToast('发送验证码成功')
                            })
                            .catch(reason => {
                                showToast('发送验证码失败 ' + reason)
                            })
                    })
            }
            .width('100%')
            .margin({ top: 20 })

            Row() {
                Button('登录')
                    .enabled(this.phoneNumber.length === 11 && this.authCode.length > 0)
                    .type(ButtonType.Normal)
                    .width('100%')
                    .borderRadius(4)
                    .onClick(() => {
                        console.info('login', this.phoneNumber, this.authCode, appServer)
                        appServer.loginWithAuthCode(this.phoneNumber, this.authCode)
                            .then(async res => {
                                console.log('login success', res);
                                let context = getContext(this) as common.UIAbilityContext;
                                let preference = await data_preferences.getPreferences(context, 'wfcstore')
                                // @ts-ignore
                                preference.put('userId', <string> res.userId);
                                // @ts-ignore
                                preference.put('token', <string> res.token);
                                preference.flush()

                                // @ts-ignore
                                wfc.connect(res.userId, res.token);
                                router.replaceUrl({
                                    url: "pages/MainPage",
                                    params: {}
                                }, router.RouterMode.Standard)
                            })
                            .catch(reason => {
                                console.error('login failed', reason)
                            })
                        console.log('ooo end11')
                    })

            }
            .justifyContent(FlexAlign.Center)
            .margin({ top: 40 })
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 16 })
        .margin({ top: 120 })
        .width('100%')
    }
}