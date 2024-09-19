import appServer from '../../api/appServer'
import Platform from '../../wfc/client/platform'
import AppServerError from '../../api/appServerError'
import { showToast } from '../../common/utils/Toast'
import wfc from '../../wfc/client/wfc'
import PCSession from '../../wfc/model/pcsession'

@Entry
@Component
@Preview
export default struct PCLoginPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State loginDesc: string = '允许 PC 端登录'
    private token = ''
    private isConfirmPCLogin = false
    @State platform: Platform = new Platform(0)
    @State enableConfirmButton: boolean = false

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.token = params['token'] as string
        this.isConfirmPCLogin = params['isConfirmPCLogin'] as boolean
        let p = params['platform'] as number

        if (!this.isConfirmPCLogin && !this.token) {
            this.mainNavPathStack.pop()
            return
        }

        this.platform = new Platform(p)
    }

    onPageShow(): void {
        if (this.isConfirmPCLogin) {
            this.enableConfirmButton = true
        } else {
            appServer.scanPCLogin(this.token)
                .then((pcSession: PCSession) => {
                    this.enableConfirmButton = true
                    this.platform = new Platform(pcSession.platform)
                })
                .catch((err: AppServerError) => {
                    showToast('扫码失败 ' + err.message)
                    this.mainNavPathStack.pop()
                })
        }
    }

    build() {
        NavDestination() {
            Column() {
                Text(`允许 ${this.platform?.getPlatFormName()} 登录`)
                    .fontSize(20)
                    .margin({ top: 80 })

                Image($r('app.media.pc'))
                    .height(250)

                Blank()

                Column() {
                    Button('确定', { type: ButtonType.Normal, stateEffect: true })
                        .backgroundColor(0x317aff)
                        .borderRadius(8)
                        .height(40)
                        .enabled(this.enableConfirmButton)
                        .focusable(true)
                        .focusOnTouch(true)
                        .type(ButtonType.Normal)
                        .width('100%')
                        .borderRadius(4)
                        .onClick(() => {
                            appServer.confirmPCLogin(this.token, wfc.getUserId())
                                .then(async res => {
                                    this.mainNavPathStack.pop()
                                })
                                .catch((reason: AppServerError) => {
                                    showToast('确定登录失败 ' + reason.message)
                                    this.mainNavPathStack.pop()
                                })
                        })
                    Button('取消', { type: ButtonType.Normal, stateEffect: true })
                        .borderRadius(8)
                        .backgroundColor('#D6D7D7')
                        .height(40)
                        .margin({ top: 20 })
                        .focusable(true)
                        .focusOnTouch(true)
                        .type(ButtonType.Normal)
                        .width('100%')
                        .borderRadius(4)
                        .onClick(() => {
                            appServer.cancelPCLogin(this.token)
                                .then(async res => {
                                    this.mainNavPathStack.pop()
                                })
                                .catch((reason: Error) => {
                                    this.mainNavPathStack.pop()
                                })
                        })
                }
                .padding({ bottom: 50, left: 30, right: 30 })
                .width('100%')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
        }
        .title('PC/Web登录确认')
        .height('100%')
        .width('100%')
        .onShown(() => {
            this.onPageShow()
        })
    }
}
