import { NodeController, PiPWindow } from "@kit.ArkUI";
import uikit from "../../uikit";

class PiPHelper {
    private mainNavPathStack?: NavPathStack;
    private navDestinationName?: string
    private pipController?: PiPWindow.PiPController;
    private pipOriginalPagePendingResume: boolean = false

    async createPipController(context: UIContext, componentController: XComponentController, customUIController: NodeController, mainNavPathStack: NavPathStack, navDestinationName: string): Promise<PiPWindow.PiPController> {
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
        return this.pipController
    }

    stopCurrentPiP() {
        this.pipController?.stopPiP()
    }

    destroyPipController() {
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
        console.log('onStateChange', state, reason)
        switch (state) {
            case PiPWindow.PiPState.STARTED:
                this.pipOriginalPagePendingResume = true
                let paths = this.mainNavPathStack?.getAllPathName()
                if (paths && paths.length > 0 && paths[paths.length - 1] === this.navDestinationName) {
                    this.mainNavPathStack?.pop()
                }
                break
            case PiPWindow.PiPState.ABOUT_TO_RESTORE:
                this.pipOriginalPagePendingResume = false
                break
            case PiPWindow.PiPState.STOPPED:
                if (this.pipOriginalPagePendingResume) {
                    this.pipOriginalPagePendingResume = false
                    this.mainNavPathStack?.pushPathByName(this.navDestinationName, {} as Record<string, Object>)
                }
                if (this.pipController) {
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