import Message from '../wfc/messages/message'
import notificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import { WantAgent } from '@ohos.app.ability.wantAgent';
import Base, { BusinessError } from '@ohos.base';
import wfc from '../wfc/client/wfc';
import { common, Want } from '@kit.AbilityKit';

class VoipFloatingWindowManager {
    private notificationMessages: Message[] = []

    constructor() {
    }

    showVoipFloatingWindow() {
        let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext; // UIAbilityContext

        let want: Want = {
            deviceId: '', // deviceId为空表示本设备
            bundleName: 'cn.wildfirechat.messenger',
            abilityName: 'VoipFloatingEntryAbility',
            action: '',
            entities: [],
            uri: '',
            parameters: {
                // 自定义信息
                info: '来自EntryAbility UIAbilityComponentsInteractive页面'
            }
        };
        context.startAbilityForResult(want).then((data) => {
            // ...
            console.log('xxxxxxxx', data)
        }).catch((err: BusinessError) => {
            // hilog.error(0, "xxx", `Failed to start ability for result. Code is ${err.code}, message is ${err.message}`);
        });
    }
}

const self = new VoipFloatingWindowManager()

export default self