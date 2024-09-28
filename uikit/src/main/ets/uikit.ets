import avenginekit from '@wfc/avenginekit';
import AVEngineCallbackImpl from './avengineCallbackImpl';

export class UIKit {
    init(context: Context) {
        avenginekit.setup(context, new AVEngineCallbackImpl(context));
    }
}

const self = new UIKit()

export default self