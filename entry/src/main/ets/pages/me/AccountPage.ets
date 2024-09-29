import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import { navigationDestinations } from '@wfc/uikit/src/main/ets/pages/navigationConfig'


@CustomDialog
struct CustomListDialog {
    controller: CustomDialogController
    items: string[] = []
    onItemClick: (item: string) => void = () => {
    }
    build() {
        Column() {

            ForEach(this.items, (item: string) => {
                Text(item)
                    .fontSize(16)
                    .padding(10)
                    .onClick(() => {
                        this.controller.close()
                        this.onItemClick(item)
                    })
            })
        }
        .padding({top:10, bottom:10})
        .margin({left:48, right:48})
    }
}

@Entry
@Component
export default struct AccountPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    dialogController: CustomDialogController = new CustomDialogController({
        builder: CustomListDialog({
            items: [getContext().resourceManager.getStringSync($r('app.string.sms_verification_code_verification').id),
                getContext().resourceManager.getStringSync($r('app.string.password_verification').id)],

            onItemClick: (item) => {
                if (item == getContext().resourceManager.getStringSync($r('app.string.sms_verification_code_verification').id)) {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.ResetPasswordPage, {
                    } as Record<string, Object>)
                } else if (item == getContext().resourceManager.getStringSync($r('app.string.password_verification').id)) {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.ChangePasswordPage, {
                    } as Record<string, Object>)
                }
            }
        }),
        alignment: DialogAlignment.Center,
        gridCount: 3,
    })


    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Column() {
                OptionItemView({
                    title: '修改密码',
                    showDivider: false
                }).onClick(() => {
                    this.dialogController.open()
                })
            }
            .width('100%')
            .height('100%')
        }
        .title('账号与安全')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}