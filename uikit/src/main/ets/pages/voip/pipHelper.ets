import { NodeController, PiPWindow } from "@kit.ArkUI";
import { BusinessError } from '@kit.BasicServicesKit'
import uikit from "../../uikit";

class PiPHelper {
    private mainNavPathStack?: NavPathStack;
    private navDestinationName?: string
    private pipController?: PiPWindow.PiPController;
    private pipState: number = 0
    private pipOriginalPagePendingResume: boolean = false
    private static TAG = 'PiPHelper'

    async createPipController(context: UIContext, componentController: XComponentController, customUIController: NodeController, mainNavPathStack: NavPathStack, navDestinationName: string) {
        console.log(PiPHelper.TAG, 'createPipController')
        if (this.pipController) {
            return
        }
        this.mainNavPathStack = mainNavPathStack
        this.navDestinationName = navDestinationName
        this.pipController = await PiPWindow.create({
            context: context.getHostContext(),
            componentController: componentController,
            customUIController: customUIController,
            navigationId: uikit.bundleName,
            templateType: PiPWindow.PiPTemplateType.VIDEO_MEETING,
            contentWidth: 200,
            contentHeight: 300,
        });
        this.pipOriginalPagePendingResume = false
        this.pipController.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
            this.onStateChange(state, reason);
        });
        this.pipController.on('controlPanelActionEvent', (event: PiPWindow.PiPActionEventType, status?: number) => {
            this.onActionEvent(event, status);
        });
        this.pipController.setAutoStartEnabled(true)
        console.log('createPipController')
    }

    startPiP() {
        console.log(PiPHelper.TAG, 'startPiP')
        this.pipController?.startPiP()
            .catch((reason: BusinessError) => {
                console.error(PiPHelper.TAG, 'startPiP error', reason.code, reason.name, reason.message)
            })
    }

    stopPiP() {
        if (this.pipController && this.pipState === PiPWindow.PiPState.STARTED.valueOf()) {
            console.log(PiPHelper.TAG, 'stopPiP')
            this.pipController?.stopPiP()
        }
    }

    destroyPipController() {
        console.log(PiPHelper.TAG, 'destroyPipController')
        if (!this.pipController) {
            return;
        }
        this.pipController.setAutoStartEnabled(false)
        this.pipController.off('stateChange');
        this.pipController.off('controlPanelActionEvent');
        this.pipController.stopPiP()
        this.pipController = undefined;
    }

    onStateChange(state: PiPWindow.PiPState, reason: string) {
        console.log(PiPHelper.TAG, ' onStateChange', state, reason)
        this.pipState = state.valueOf()
        switch (state) {
            case PiPWindow.PiPState.ABOUT_TO_START:
                this.pipOriginalPagePendingResume = true
                console.log(PiPHelper.TAG, ' pipOriginalPagePendingResume true')
                let paths = this.mainNavPathStack?.getAllPathName()
                if (paths && paths.length > 0 && paths[paths.length - 1] === this.navDestinationName) {
                    this.mainNavPathStack?.pop()
                }
                break
            case PiPWindow.PiPState.ABOUT_TO_RESTORE:
                console.log(PiPHelper.TAG, ' pipOriginalPagePendingResume false')
                this.pipOriginalPagePendingResume = false
                break
            case PiPWindow.PiPState.STOPPED:
                console.log(PiPHelper.TAG, ' pipOriginalPagePendingResume check', this.pipOriginalPagePendingResume)
                if (this.pipOriginalPagePendingResume) {
                    console.log(PiPHelper.TAG, ' pushPathByName and destroy')
                    this.pipOriginalPagePendingResume = false
                    this.mainNavPathStack?.pushPathByName(this.navDestinationName, {} as Record<string, Object>)
                    this.destroyPipController()
                }
                break
            default:
                break

        }
    }

    onActionEvent(event: PiPWindow.PiPActionEventType, status: number | undefined) {
        console.log('onActionEvent', event, status)
    }
}

let self = new PiPHelper()

export default self
