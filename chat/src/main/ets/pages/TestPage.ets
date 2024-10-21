import TestCustomMessageContent from '@wfc/client/src/main/ets/wfc_custom_message/testCustomMessageContent';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import UserSettingScope from '@wfc/client/src/main/ets/wfc/client/userSettingScope';
import { util, xml } from '@kit.ArkTS';
import { PiPWindow } from '@kit.ArkUI';
import uikit from '@wfc/uikit';
import { BusinessError } from '@kit.BasicServicesKit';
import TestTextNodeController from './test/TestTextNodeController';


@Entry({ routeName: 'apiTestPage' })
@Component
export default struct TestPage {
    private mXComponentController: XComponentController = new XComponentController()
    private pipController?: PiPWindow.PiPController;
    private textNodeController: TestTextNodeController = new TestTextNodeController('');

    async aboutToAppear() {
        this.createPipController()
    }

    async createPipController() {
        this.pipController = await PiPWindow.create({
            context: getContext(this),
            componentController: this.mXComponentController,
            customUIController: this.textNodeController,
            navigationId: uikit.bundleName,
            templateType: PiPWindow.PiPTemplateType.VIDEO_CALL,
            contentWidth: 200,
            contentHeight: 300,
        });
        this.pipController.setAutoStartEnabled(true)
        console.log('createPipController')
    }

    build() {
        NavDestination() {
            Column() {
                XComponent({
                    id: 'Test',
                    type: XComponentType.SURFACE,
                    controller: this.mXComponentController,
                })
                    .enableAnalyzer(false)
                    .width(200)
                    .height(300)
                    .backgroundColor(Color.Green)
                Text('测试123')
                    .fontSize(20)
                    .fontColor(Color.Red)
                    .onClick(() => {
                        this.pipController?.startPiP()
                            .catch((reason: BusinessError) => {
                                console.error('startPiP error', reason.code, reason.name, reason.message)
                            })
                    })
            }
            .justifyContent(FlexAlign.Center)
            .height('100%')
            .width('100%')
        }
    }
}