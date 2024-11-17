import { PiPWindow } from '@kit.ArkUI';
import uikit from '@wfc/uikit';
import TestTextNodeController from './TestTextNodeController';
import { BusinessError } from '@kit.BasicServicesKit';


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
            // customUIController: this.textNodeController,
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
                    // .enableAnalyzer(false)
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