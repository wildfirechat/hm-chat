import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'

/**
 * 满屏水印。参考 android-chat 的 me.aurelion.x.ui.view.watermark 实现：
 * - {@link WaterMarkConfig} 对应 Android 的 WaterMarkInfo（样式配置）；
 * - {@link WaterMark} 组件对应 Android 的 WaterMarkView，用 Canvas 平铺绘制旋转文字，
 *   并自带每分钟刷新「用户ID + 时间」文案的逻辑（对应 WfcUIKit.updateWaterMark）。
 *
 * 接入方式（对应 Android 在每个 BaseActivity 的 content 上 addView）：
 * 鸿蒙这里页面都跑在 MainPage 的单个 Navigation 内，所以只需在 MainPage 用一个 Stack
 * 把 WaterMark 叠在 Navigation 之上即可覆盖所有页面（含 push 出来的 NavDestination，
 * 如图片预览 MMPreviewPage）。
 *
 * 关于事件透传：必须把水印放在自己可控的组件树里，并设置 hitTestBehavior(None)，
 * 这样水印自身不参与触摸测试、也不阻塞下层 Navigation，所有手势照常透传。
 *
 * 开关见 Config.ENABLE_WATER_MARK。
 */

export class WaterMarkConfig {
    // 文字倾斜角度（默认 -45）
    degrees: number = -45
    // 文字大小，单位 vp（默认 16）
    fontSize: number = 16
    // 文字颜色，半透明灰，深浅色模式下均可见（默认 #24999999）
    color: string = '#24999999'
    // 文字横向间距，单位 vp（默认 60）
    dx: number = 60
    // 文字纵向间距，单位 vp（默认 100）
    dy: number = 100
}

let waterMarkConfig: WaterMarkConfig = new WaterMarkConfig()

/** 设置水印样式（可选，需在 WaterMark 组件创建前调用）。 */
export function setWaterMarkConfig(config: WaterMarkConfig): void {
    waterMarkConfig = config
}

@Component
export struct WaterMark {
    @State @Watch('onTextChange') private text: string = ''
    private settings: RenderingContextSettings = new RenderingContextSettings(true)
    private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
    private timerId: number = -1

    aboutToAppear(): void {
        this.updateText()
        // 每分钟刷新一次文案，便于截图溯源
        this.timerId = setInterval(() => {
            this.updateText()
        }, 60 * 1000)
    }

    aboutToDisappear(): void {
        if (this.timerId >= 0) {
            clearInterval(this.timerId)
            this.timerId = -1
        }
    }

    private updateText(): void {
        const userId = wfc.getUserId()
        if (userId) {
            // 用户ID + 当前时间，与 android-chat 的 WfcUIKit.updateWaterMark 一致
            this.text = `${userId} ${formatTime(new Date())}`
        }
    }

    onTextChange() {
        this.draw()
    }

    build() {
        Canvas(this.context)
            .width('100%')
            .height('100%')
            // 水印不参与触摸测试，自身不响应、也不阻塞下层页面，所有手势透传
            .hitTestBehavior(HitTestMode.None)
            .onReady(() => {
                this.draw()
            })
    }

    private draw() {
        const ctx = this.context
        const w = ctx.width
        const h = ctx.height
        if (w <= 0 || h <= 0) {
            return
        }
        ctx.clearRect(0, 0, w, h)
        if (!this.text) {
            return
        }

        const cfg = waterMarkConfig
        ctx.save()
        ctx.font = `${cfg.fontSize}vp sans-serif`
        ctx.fillStyle = cfg.color
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'

        // 以中心为原点旋转，再在一个足够大的范围内平铺，保证旋转后四角也被覆盖
        // Canvas 默认单位为 vp（LengthMetricsUnit.DEFAULT），measureText/ctx.width/fillText 均为 vp，
        // 故所有间距直接用 vp 计算即可，天然与屏幕密度无关，切勿混入 px（vp2px）造成单位错乱
        const textWidth = ctx.measureText(this.text).width
        const stepX = textWidth + cfg.dx
        const stepY = cfg.fontSize + cfg.dy
        const diagonal = Math.sqrt(w * w + h * h)

        ctx.translate(w / 2, h / 2)
        ctx.rotate(cfg.degrees * Math.PI / 180)

        let row = 0
        for (let y = -diagonal; y < diagonal; y += stepY) {
            // 相邻行错位半格，排布更自然
            const offsetX = (row % 2 === 0) ? 0 : stepX / 2
            for (let x = -diagonal; x < diagonal; x += stepX) {
                ctx.fillText(this.text, x + offsetX, y)
            }
            row++
        }

        ctx.restore()
    }
}

function pad2(n: number): string {
    return n < 10 ? `0${n}` : `${n}`
}

// 格式化为 MM-dd HH:mm，与 android-chat 的 WfcUIKit.updateWaterMark 一致
function formatTime(date: Date): string {
    return `${pad2(date.getMonth() + 1)}-${pad2(date.getDate())} ${pad2(date.getHours())}:${pad2(date.getMinutes())}`
}
