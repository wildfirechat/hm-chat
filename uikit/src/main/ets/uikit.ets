import avenginekit from '@wfc/avenginekit';
import AVEngineCallbackImpl from './avengineCallbackImpl';
import { common } from '@kit.AbilityKit';

export class UIKit {
    bundleName = ''
    entryAbilityName = ''

    init(context: common.UIAbilityContext) {
        this.bundleName = context.abilityInfo.bundleName
        this.entryAbilityName  = context.abilityInfo.name
        avenginekit.setup(context, new AVEngineCallbackImpl(context));
    }
}

const self = new UIKit()

export default self