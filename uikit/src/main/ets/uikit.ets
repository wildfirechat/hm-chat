import avenginekit from '@wfc/avenginekit';
import AVEngineCallbackImpl from './avengineCallbackImpl';
import { common } from '@kit.AbilityKit';

export class UIKit {
    bundleName = ''
    entryAbilityName = ''
    mainNavPathStack: NavPathStack = new NavPathStack()

    init(context: common.UIAbilityContext) {
        this.bundleName = context.abilityInfo.bundleName
        this.entryAbilityName = context.abilityInfo.name
        avenginekit.setup(context, new AVEngineCallbackImpl(context, this.mainNavPathStack));
    }

    isSupportConference(): boolean {
        return avenginekit.isSupportConference()
    }
}

const self = new UIKit()

export default self