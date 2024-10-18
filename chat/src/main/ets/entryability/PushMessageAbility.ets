import { UIAbility } from '@kit.AbilityKit';
import { pushService } from '@kit.PushKit';
import { window } from '@kit.ArkUI';
import { voipCall } from '@kit.CallKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';

// 定义端侧从云侧下发的消息中解析场景类型的字段，例如：端侧定义scene字段，此时从云侧传递extraData时携带scene字段，可决定是音频呼叫或视频呼叫
interface VoipScene {
    scene: string;
}

interface Content {
    data: string;
    header: string;
    callId: string;
}

export default class PushMessageAbility extends UIAbility {
    onCreate(): void {
        hilog.info(0x0000, 'testTag', 'PushMessageAbility onCreate.');
        try {
            pushService.receiveMessage('VoIP', this, (data) => {
                // process message，并建议对Callback进行try-catch
                try {
                    hilog.info(0x0000, 'testTag', ` VOIP get message:${JSON.stringify(data)}`);
                    this.processVoIPMainMsg(data.data);
                } catch (error) {
                    hilog.error(0x0000, 'testTag', 'Failed to process data: %{public}d %{public}s', error.code, error.message);
                }
            });
            hilog.info(0x0000, 'testTag', 'Succeeded in registering VoIP.');
        } catch (e) {
            hilog.info(0x0000, 'testTag', `Failed to register VOIP, error: ${e.code}, ${e.message}.`);
        }
    }

    private async processVoIPMainMsg(data: string): Promise<void> {
        hilog.info(0x0000, 'testTag', 'processVoIPMainMsg');
        let content: Content = JSON.parse(data);
        let scene: VoipScene = JSON.parse(content.data);
        let callId: string = content.callId;
        hilog.info(0x0000, 'testTag', `callId: ${callId}.`);
        hilog.info(0x0000, 'testTag', `scene: ${scene}.`);
        if (callId) {
            voipCall.on('voipCallUiEvent', async (event) => {
                hilog.info(0x0000, 'testTag', `PushMessageAbility voipCallUiEvent: ${JSON.stringify(event)}.`);
                // TimeoutUtil.stop();
                switch (event.voipCallUiEvent) {
                    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VOICE_ANSWER:
                    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VIDEO_ANSWER:
                        // VoipCallUtil.reportCallStateChange(voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE);
                        AppStorage.setOrCreate('answered', true);
                        break;
                    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_REJECT:
                    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_HANGUP:
                        // CalleeUtil.close();
                        break;
                    default: {
                        break;
                    }
                }
            })
            const resourceMgr: resourceManager.ResourceManager = this.context.resourceManager;
            // example.png表示用户头像，取值为“/resources/rawfile”路径下的文件名
            const fileData: Uint8Array = await resourceMgr.getRawFileContent('avatar_def.png');
            const buffer = fileData.buffer;
            const imageSource: image.ImageSource = image.createImageSource(buffer);
            const pixelMap: image.PixelMap = await imageSource.createPixelMap();
            if (pixelMap) {
                pixelMap.getImageInfo((err, imageInfo) => {
                    if (imageInfo) {
                        hilog.info(0x0000, 'testTag', `DemoPushMessageAbility imageInfo: ${imageInfo.size.width} * ${imageInfo.size.height}.`);
                    }
                });
            }
            // 定义应用内通话时传入的数据。注意，voipCallType.scene为您自定义的场景类型字段，从云侧推送消息时，请注意与端侧取值保持一致
            let call: voipCall.VoipCallAttribute = {
                callId: callId,
                voipCallType: scene?.scene === 'video' ? voipCall.VoipCallType.VOIP_CALL_VIDEO : voipCall.VoipCallType.VOIP_CALL_VOICE,
                userName: 'push',
                userProfile: pixelMap,
                abilityName: 'PushMessageAbility',
                voipCallState: voipCall.VoipCallState.VOIP_CALL_STATE_RINGING
            };
            try {
                let error = await voipCall.reportIncomingCall(call);
                if (error) {
                    hilog.info(0x0000, 'testTag', ` PushMessageAbility reportIncomingCall result: ${error}.`);
                    let err: voipCall.ErrorReason = error as voipCall.ErrorReason;
                    if (err !== voipCall.ErrorReason.ERROR_NONE) {
                        hilog.info(0x0000, 'testTag', `PushMessageAbility reportIncomingCall failed: ${error}.`);
                        return;
                    }
                }
                // VoipCallUtil.init(callId);
            } catch (e) {
                hilog.info(0x0000, 'testTag', ` PushMessageAbility reportIncomingCall exception: ${e}.`);
            }
        }
        hilog.info(0x0000, 'testTag', `processVoIPMainMsg end.`);
    }

    onWindowStageCreate(windowStage: window.WindowStage): void {
        hilog.info(0x0000, 'testTag', `PushMessageAbility onWindowStageCreate.`);
        windowStage.loadContent('pages/TestPage');
    }

    onDestroy(): void {
        hilog.info(0x0000, 'testTag', 'PushMessageAbility onDestroy.');
    }
}