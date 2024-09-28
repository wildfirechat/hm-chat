import { showToast } from '../../common/utils/Toast'
import { curves, display, router, window } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import avenginkeKit from '@wfc/avenginekit'

interface Position {
    x: number,
    y: number
}

@Entry
@Component
export default struct VoipFloatingPage {
    @State now: number = new Date().getTime()
    private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.All });
    // 创建位置变量，并使用@Watch监听，变量发生变化调用moveWindow方法移动窗口
    @State @Watch("moveWindow") windowPosition: Position = { x: 0, y: 0 };
    private floatWindow?: window.Window
    private callSession?: CallSession

    aboutToAppear(): void {
        this.floatWindow = window.findWindow("voipFloatingWindow")
        this.callSession = avenginkeKit.getCurrentSession();
        if (!this.callSession) {
            this.floatWindow.destroyWindow()
            return
        }
    }

    onPageShow(): void {
        setInterval(() => {
            this.now = new Date().getTime() - this.callSession!.startTime
        }, 1000)
    }

    moveWindow() {
        animateTo({ curve: curves.responsiveSpringMotion() }, () => {
            this.floatWindow!.moveWindowTo(this.windowPosition.x, this.windowPosition.y);
        })
    }

    build() {
        Column() {
            Text('Duration: ' + this.now)
        }
        .onClick(() => {
            showToast('Test')
            router.pushUrl({
                url: 'pages/voip/SingleAudioCallPage'
            })
                .then(() => {
                    console.log('xxx success')
                })
                .catch((e: BusinessError) => {
                    console.log('xxxxxxx', e)
                })
            this.floatWindow!.destroyWindow()
        })
        .gesture(
            // 绑定PanGesture事件，监听拖拽动作
            PanGesture(this.panOption)
                .onActionStart((event: GestureEvent) => {
                    console.info('Pan start');
                })
                .onActionUpdate((event: GestureEvent) => {
                    // 发生拖拽时，获取到触摸点的位置，并将位置信息传递给windowPosition
                    this.windowPosition.x += event.offsetX;
                    this.windowPosition.y += event.offsetY;

                    let _display = display.getDefaultDisplaySync()
                    let winRect = this.floatWindow!.getWindowProperties().windowRect

                    if (this.windowPosition.x < 0) {
                        this.windowPosition.x = 0
                    }
                    if (this.windowPosition.x > _display.width - winRect.width) {
                        this.windowPosition.x = _display.width - winRect.width;
                    }

                    if (this.windowPosition.y < 0) {
                        this.windowPosition.y = 0
                    }
                    if (this.windowPosition.y > _display.height - winRect.height) {
                        this.windowPosition.y = _display.height - winRect.height
                    }

                })
                .onActionEnd(() => {
                    console.info('Pan end');
                })
        )
        .clip(true)
        .backgroundColor(Color.Green)
        .width('100%')
        .height('100%')
        .borderRadius(5)
    }
}