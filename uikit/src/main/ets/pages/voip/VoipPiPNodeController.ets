import { BuilderNode, FrameNode, NodeController } from "@kit.ArkUI";
import avengineKit from '@wfc/avenginekit'
import CallSession from "@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession";
import CallState from "@wfc/avenginekit/src/main/ets/wfc/av/engine/callState";
import WFCVideoRenderController, { ScalingMode } from '@wfc/avenginekit/src/main/ets/wfc/av/xcomponent/WFCVideoRenderController'
import { timestampFormat } from "../../util/helper";

class VoipPiPParams {
    durationText: string = '';
    audioOnly: boolean = false;
    videoRenderController?: WFCVideoRenderController

    constructor(durationText: string, audioOnly: boolean, videoRenderController?: WFCVideoRenderController) {
        this.durationText = durationText;
        this.audioOnly = audioOnly
        this.videoRenderController = videoRenderController;
    }
}


@Builder
function buildVoipPiPNode(params: VoipPiPParams) {
    if (!params.audioOnly) {
        XComponent({
            id: 'pip-xcp',
            type: XComponentType.SURFACE,
            controller: params.videoRenderController,
        })
            .onLoad(() => {
                console.log('WFCVideoRenderController pip-xcp onLoad')
            })
            .enableAnalyzer(false)
            .width('100%')
            .height('100%')
            .backgroundColor(Color.Black)
    } else {
        Column() {
            Image($r('app.media.av_float_audio'))
                .width(vp2px(40))
                .height(vp2px(40))

            Text(params.durationText)
                .fontSize(30)
                .fontColor(Color.White)
        }
        .padding(20)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.Red)
        .width('100%') // 宽度方向充满画中画窗口
        .height('100%') // 高度方向充满画中画窗口
    }
}


// 开发者可通过继承NodeController实现自定义UI控制器
export default class VoipPiPNodeController extends NodeController {
    private durationText: string;
    private videoRenderController?: WFCVideoRenderController
    private voipPipNode: BuilderNode<[VoipPiPParams]> | null = null;
    private updatePiPInterval: number = 0

    constructor(message: string, videoRenderController?: WFCVideoRenderController) {
        super();
        this.durationText = message;
        this.videoRenderController = videoRenderController;
    }

    // 通过BuilderNode加载自定义布局
    makeNode(context: UIContext): FrameNode | null {
        this.voipPipNode = new BuilderNode(context, {
            selfIdealSize: {
                width: 100, height: 100
            }
        });
        let callSession = avengineKit.getCurrentSession()
        if (!callSession) {
            return null
        }
        this.videoRenderController = new WFCVideoRenderController('pip-xcp')
        this.voipPipNode.build(wrapBuilder<[VoipPiPParams]>(buildVoipPiPNode), new VoipPiPParams(this.durationText, this._audioOnly(callSession), this.videoRenderController));
        this.updatePiPInterval = setInterval(() => {
            this._updatePiP()
        }, 1000)
        return this.voipPipNode.getFrameNode();
    }

    aboutToDisappear(): void {
        clearInterval(this.updatePiPInterval)
    }

    _updatePiP() {
        let callSession = avengineKit.getCurrentSession()
        if (!callSession || callSession.status === CallState.STATUS_IDLE) {
            return
        }

        let millis = new Date().getTime() - callSession!.connectedTime
        let durationText = timestampFormat(millis)
        let audioOnly = this._audioOnly(callSession)
        if (!audioOnly) {
            let pfs = [...callSession.getParticipantProfiles()]
            pfs.push(callSession.getSelfProfile())

            for (let i = 0; i < pfs.length; i++) {
                let p = pfs[i]
                if (!p.audience && !p.videoMuted) {
                    this.videoRenderController?.setVideoTrack(callSession.getParticipantVideoTrack(p.userId, p.screenSharing))
                    this.videoRenderController?.setScalingMode(ScalingMode.AspectFit)
                    break
                }
            }
        }

        if (this.voipPipNode !== null) {
            this.voipPipNode.update(new VoipPiPParams(durationText, audioOnly, this.videoRenderController));
        }
    }

    _audioOnly(callSession: CallSession) {
        let audioOnly = callSession.audioOnly
        if (!audioOnly) {
            audioOnly = true
            let profiles = callSession?.getParticipantProfiles()!;
            for (let i = 0; i < profiles.length; i++) {
                if (!profiles[i].audience && !profiles[i].videoMuted) {
                    audioOnly = false
                    break
                }
            }
            if (audioOnly) {
                audioOnly = callSession.videoMuted || callSession.isScreenSharing()
            }
        }
        return audioOnly
    }
}