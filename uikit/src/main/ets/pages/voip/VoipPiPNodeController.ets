import { BuilderNode, FrameNode, NodeController } from "@kit.ArkUI";

class Params {
    text: string = '';

    constructor(text: string) {
        this.text = text;
    }
}

// TODO
// FIXME
// 大小不对

// 开发者可以通过@Builder装饰器实现布局构建
@Builder
function buildText(params: Params) {
    Column() {
        Image($r('app.media.av_float_audio'))
            .width(40)
            .height(40)

        Text(params.text)
            .fontSize(20)
            .fontColor(Color.White)
    }
    .padding(20)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%') // 宽度方向充满画中画窗口
    .height('100%') // 高度方向充满画中画窗口
}


// 开发者可通过继承NodeController实现自定义UI控制器
export default class VoipPiPNodeController extends NodeController {
    private message: string;
    private voipPipNode: BuilderNode<[Params]> | null = null;

    constructor(message: string) {
        super();
        this.message = message;
    }

    // 通过BuilderNode加载自定义布局
    makeNode(context: UIContext): FrameNode | null {
        this.voipPipNode = new BuilderNode(context, {
            selfIdealSize: {
                width: 100, height: 100
            }
        });
        this.voipPipNode.build(wrapBuilder<[Params]>(buildText), new Params(this.message));
        return this.voipPipNode.getFrameNode();
    }

    // 开发者可自定义该方法实现布局更新
    update(message: string) {
        console.log(`update message: ${message}`);
        if (this.voipPipNode !== null) {
            this.voipPipNode.update(new Params(message));
        }
    }
}