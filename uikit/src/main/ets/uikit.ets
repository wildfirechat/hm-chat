import avenginekitImpl from '@wfc/avenginekit';
import avenginekit from '@wfc/avenginekit/src/main/ets/wfc/av/engine/avenginekit';
// import VideoProfile from '@wfc/avenginekit/src/main/ets/wfc/av/engine/videoProfile';
import AVEngineCallbackImpl from './avengineCallbackImpl';
import { common } from '@kit.AbilityKit';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import CollectionMessageContent from '@wfc/client/src/main/ets/wfc/messages/CollectionMessageContent';

import archiveServer from './api/archiveServer';

export { archiveServer };


export class UIKit {
    bundleName = ''
    entryAbilityName = ''
    mainNavPathStack: NavPathStack = new NavPathStack()

    init(context: common.UIAbilityContext) {
        this.bundleName = context.abilityInfo.bundleName
        this.entryAbilityName = context.abilityInfo.name
        avenginekitImpl.setup(context, new AVEngineCallbackImpl(context, this.mainNavPathStack));
        avenginekit.SCREEN_SHARING_REPLACE_MODE = true;
        // 仅高级版音视频 SDK 支持
        // avenginekit.VIDEO_PROFILE = VideoProfile.VP360P_8;
    }

    isSupportConference(): boolean {
        return avenginekitImpl.isSupportConference()
    }
}

const self = new UIKit()

export default self