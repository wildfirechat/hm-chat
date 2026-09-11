/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import { curves } from '@kit.ArkUI'

// 按住说话浮层的各部分都画在同一个全屏 Canvas 上，坐标单位是 vp，原点是浮层左上角

export const ZONE_SEND = 0
export const ZONE_CANCEL = 1
export const ZONE_TEXT = 2

export type Easing = (fraction: number) => number

const FAST_OUT_SLOW_IN = curves.cubicBezierCurve(0.2, 0, 0, 1)

export class Easings {
    static readonly linear: Easing = (t: number): number => t
    static readonly fastOutSlowIn: Easing = (t: number): number => FAST_OUT_SLOW_IN.interpolate(t)
    static readonly accelerateDecelerate: Easing = (t: number): number => Math.cos((t + 1) * Math.PI) / 2 + 0.5

    static decelerate(factor: number): Easing {
        return (t: number): number => 1 - Math.pow(1 - t, 2 * factor)
    }

    static accelerate(factor: number): Easing {
        return (t: number): number => Math.pow(t, 2 * factor)
    }

    static overshoot(tension: number): Easing {
        return (t: number): number => {
            let s = t - 1
            return s * s * ((tension + 1) * s + tension) + 1
        }
    }
}

/**
 * 在 Canvas 帧回调里推进的数值动画，从当前值过渡到目标值
 */
export class Tween {
    value: number
    private from: number = 0
    private to: number = 0
    private startTime: number = 0
    private delay: number = 0
    private duration: number = 1
    private easing: Easing = Easings.linear
    private running: boolean = false
    private onEnd?: () => void

    constructor(value: number) {
        this.value = value
    }

    set(value: number) {
        this.value = value
        this.cancel()
    }

    animate(to: number, duration: number, easing: Easing, delay: number = 0, onEnd?: () => void) {
        this.from = this.value
        this.to = to
        this.startTime = Date.now()
        this.delay = delay
        this.duration = Math.max(1, duration)
        this.easing = easing
        this.running = true
        this.onEnd = onEnd
    }

    /**
     * 停在当前值，不回调 onEnd
     */
    cancel() {
        this.running = false
        this.onEnd = undefined
    }

    isRunning(): boolean {
        return this.running
    }

    /**
     * @returns 这一帧是否还在动画中
     */
    update(now: number): boolean {
        if (!this.running) {
            return false
        }
        let elapsed = now - this.startTime - this.delay
        if (elapsed < 0) {
            return true
        }
        let fraction = Math.min(1, elapsed / this.duration)
        this.value = fraction >= 1 ? this.to : this.from + (this.to - this.from) * this.easing(fraction)
        if (fraction >= 1) {
            this.running = false
            let onEnd = this.onEnd
            this.onEnd = undefined
            onEnd?.()
        }
        return true
    }
}

export function lerp(from: number, to: number, fraction: number): number {
    return from + (to - from) * fraction
}

function clamp01(value: number): number {
    return Math.max(0, Math.min(1, value))
}

/**
 * 按比例混合两个 ARGB 颜色
 */
export function blendColor(from: number, to: number, fraction: number): number {
    let f = clamp01(fraction)
    let a = Math.round(lerp((from >>> 24) & 0xff, (to >>> 24) & 0xff, f))
    let r = Math.round(lerp((from >>> 16) & 0xff, (to >>> 16) & 0xff, f))
    let g = Math.round(lerp((from >>> 8) & 0xff, (to >>> 8) & 0xff, f))
    let b = Math.round(lerp(from & 0xff, to & 0xff, f))
    return ((a << 24) | (r << 16) | (g << 8) | b) >>> 0
}

/**
 * ARGB 颜色转成 Canvas 使用的 rgba 字符串，alpha 会和颜色本身的透明度相乘
 */
export function colorString(color: number, alpha: number = 1): string {
    let a = ((color >>> 24) & 0xff) / 255 * clamp01(alpha)
    return `rgba(${(color >>> 16) & 0xff},${(color >>> 8) & 0xff},${color & 0xff},${a.toFixed(3)})`
}

/**
 * ARGB 颜色转成 ArkUI 组件使用的 #AARRGGBB 字符串
 */
export function colorHex(color: number): string {
    return '#' + (color >>> 0).toString(16).padStart(8, '0')
}

/**
 * 颜色的相对亮度，0~1
 */
export function colorLuminance(color: number): number {
    let channel = (value: number): number => {
        let c = value / 255
        return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel((color >>> 16) & 0xff) + 0.7152 * channel((color >>> 8) & 0xff) + 0.0722 * channel(color & 0xff)
}

// region 背景

const DIM_COLOR = 0xCC111111
const PANEL_COLOR = 0xFF444444
// 深灰背景上边缘渐变区域的高度
const PANEL_FADE_HEIGHT = 130

/**
 * 浮层的背景：整屏半透明的深色遮罩，底部再叠一块深灰色背景，上边缘从透明线性渐变到不透明。
 * 录音时深灰背景从弧形按钮处开始，编辑文字时升到气泡下方
 */
export class VoiceInputBackgroundPainter {
    // 显示程度，0 完全透明，1 完全显示
    progress: Tween = new Tween(0)
    // 深灰背景完全不透明处的 y 坐标
    panelTop: Tween = new Tween(0)
    private stageLeft: number = 0
    private stageRight: number = 0

    /**
     * 深灰背景的左右边界，双栏时只覆盖会话界面
     */
    setStage(left: number, right: number) {
        this.stageLeft = left
        this.stageRight = right
    }

    update(now: number): boolean {
        let progressRunning = this.progress.update(now)
        let panelRunning = this.panelTop.update(now)
        return progressRunning || panelRunning
    }

    draw(ctx: CanvasRenderingContext2D, width: number, height: number) {
        let progress = this.progress.value
        if (progress <= 0) {
            return
        }
        ctx.globalAlpha = 1
        ctx.fillStyle = colorString(DIM_COLOR, progress)
        ctx.fillRect(0, 0, width, height)
        if (this.stageRight <= this.stageLeft) {
            return
        }
        let panelTop = this.panelTop.value
        let fadeTop = panelTop - PANEL_FADE_HEIGHT
        let gradient = ctx.createLinearGradient(0, fadeTop, 0, panelTop)
        gradient.addColorStop(0, colorString(PANEL_COLOR, 0))
        gradient.addColorStop(1, colorString(PANEL_COLOR, 1))
        ctx.globalAlpha = progress
        ctx.fillStyle = gradient
        let top = Math.max(0, fadeTop)
        ctx.fillRect(this.stageLeft, top, this.stageRight - this.stageLeft, height - top)
        ctx.globalAlpha = 1
    }
}

// endregion

// region 底部操作区

// 配色参考微信深色模式，画在深灰背景上
const ARC_COLOR = 0xFF575757
const ARC_SELECTED_TOP_COLOR = 0xFF636363
const ARC_SELECTED_BOTTOM_COLOR = 0xFF808080
const ARC_RIM_COLOR = 0xFF767676
const ARC_LABEL_COLOR = 0xFFDDDDDD
const PILL_COLOR = 0xFF575757
const PILL_SELECTED_COLOR = 0xFF9A9A9A
const PILL_LABEL_COLOR = 0xFFE6E6E6
const SELECTED_LABEL_COLOR = 0xFF111111
const HINT_COLOR = 0xFFD0D0D0

const ARC_LABEL_SIZE = 18
const PILL_LABEL_SIZE = 17
const HINT_SIZE = 14

/**
 * 按住说话时的底部操作区：最下方弧形的「松开 发送」区域，上方左右两条弧形的「取消」和「转文字」按钮
 *
 * 通过 zoneAt 判断手指所在的目标，setZone 让对应的按钮平滑高亮
 */
export class VoiceRecordBottomPainter {
    private voiceLabel: string = '语音'
    private sendLabel: string = '松开 发送'
    private cancelLabel: string = '取消'
    private cancelHint: string = '松手 取消'
    private textLabel: string = '滑到这里 转文字'
    private textHint: string = '松手 编辑文字'

    private speechToTextEnabled: boolean = false
    private hasStage: boolean = false
    private stageLeft: number = 0
    private stageRight: number = 0
    private stageWidth: number = 0
    private centerX: number = 0
    // 底部弧形区域：圆心在底部中间下方的大圆
    private arcTop: number = 0
    private arcRadius: number = 0
    private arcCenterY: number = 0
    // 两条弧形按钮的中线在同一个更大的圆上
    private pillThickness: number = 0
    private pillGap: number = 0
    private pillRadius: number = 0
    private pillCenterY: number = 0
    // 按钮文字中心到中线的水平距离
    private labelOffsetX: number = 0
    private maxLabelWidth: number = 0

    private zone: number = ZONE_SEND
    // 各个目标的高亮程度，0~1，按 ZONE_* 索引
    private selection: Tween[] = [new Tween(1), new Tween(0), new Tween(0)]
    // 入场进度，0 完全隐藏，1 完全显示
    private appear: Tween = new Tween(0)
    private textWidthCache: Map<string, number> = new Map()

    setSpeechToTextEnabled(enabled: boolean) {
        this.speechToTextEnabled = enabled
    }

    /**
     * 设置操作区的位置
     *
     * @param left   左边界
     * @param right  右边界
     * @param arcTop 底部弧形区域最高点的 y 坐标，按住说话按钮需要在弧形区域内
     */
    setStage(left: number, right: number, arcTop: number) {
        this.stageLeft = left
        this.stageRight = right
        this.stageWidth = right - left
        this.centerX = left + this.stageWidth / 2
        this.arcTop = arcTop
        this.arcRadius = this.stageWidth * 1.68
        this.arcCenterY = arcTop + this.arcRadius

        this.pillThickness = Math.max(56, Math.min(72, this.stageWidth * 0.17))
        this.pillGap = 22
        this.pillRadius = this.stageWidth * 1.72
        this.pillCenterY = arcTop - 16 - this.pillThickness / 2 + this.pillRadius
        this.labelOffsetX = Math.min(this.stageWidth * 0.29, 170)
        this.maxLabelWidth = Math.max(48, 2 * Math.min(this.labelOffsetX - this.pillGap / 2 - 12,
            this.stageWidth / 2 - 8 - this.labelOffsetX))
        this.hasStage = true
    }

    /**
     * 弧形按钮上边缘最高点的 y 坐标
     */
    getPillTop(): number {
        return this.pillCenterY - this.pillRadius - this.pillThickness / 2
    }

    /**
     * 「取消」按钮文字中心的 x 坐标
     */
    getCancelCenterX(): number {
        return this.centerX - this.labelOffsetX
    }

    /**
     * 手指所在的目标：ZONE_SEND、ZONE_CANCEL 或 ZONE_TEXT
     */
    zoneAt(x: number, y: number): number {
        if (!this.hasStage) {
            return ZONE_SEND
        }
        let dx = x - this.centerX
        if (Math.abs(dx) < this.arcRadius
            && y >= this.arcCenterY - Math.sqrt(this.arcRadius * this.arcRadius - dx * dx)) {
            return ZONE_SEND
        }
        return this.speechToTextEnabled && x >= this.centerX ? ZONE_TEXT : ZONE_CANCEL
    }

    getZone(): number {
        return this.zone
    }

    setZone(zone: number) {
        if (this.zone === zone) {
            return
        }
        this.zone = zone
        for (let i = 0; i < this.selection.length; i++) {
            this.selection[i].animate(i === zone ? 1 : 0, 220, Easings.decelerate(1.5))
        }
    }

    /**
     * 恢复到未显示、选中发送的状态
     */
    reset() {
        this.zone = ZONE_SEND
        this.selection[ZONE_SEND].set(1)
        this.selection[ZONE_CANCEL].set(0)
        this.selection[ZONE_TEXT].set(0)
        this.appear.set(0)
    }

    /**
     * 弧形区域和按钮从底部升起
     */
    show() {
        this.appear.animate(1, 340, Easings.decelerate(2))
    }

    /**
     * 按钮和弧形区域落回底部
     */
    hide() {
        this.appear.animate(0, 220, Easings.accelerate(1.5))
    }

    update(now: number): boolean {
        let running = this.appear.update(now)
        for (let tween of this.selection) {
            running = tween.update(now) || running
        }
        return running
    }

    draw(ctx: CanvasRenderingContext2D, height: number) {
        let appear = this.appear.value
        if (!this.hasStage || appear <= 0) {
            return
        }
        ctx.save()
        ctx.beginPath()
        ctx.rect(this.stageLeft, 0, this.stageWidth, height)
        ctx.clip()
        this.drawArcArea(ctx, height, appear)
        // 按钮比弧形区域稍晚升起，更早落下
        let pillAppear = clamp01((appear - 0.15) / 0.85)
        if (pillAppear > 0) {
            ctx.save()
            ctx.translate(0, (1 - pillAppear) * (height - this.getPillTop()))
            this.drawPill(ctx, true, this.selection[ZONE_CANCEL].value, this.cancelLabel, this.cancelHint, pillAppear)
            if (this.speechToTextEnabled) {
                this.drawPill(ctx, false, this.selection[ZONE_TEXT].value, this.textLabel, this.textHint, pillAppear)
            }
            ctx.restore()
        }
        ctx.restore()
    }

    private drawArcArea(ctx: CanvasRenderingContext2D, height: number, appear: number) {
        let selected = this.selection[ZONE_SEND].value
        ctx.save()
        ctx.translate(0, (1 - appear) * (height - this.arcTop))
        ctx.globalAlpha = 1
        ctx.fillStyle = colorString(ARC_COLOR)
        ctx.beginPath()
        ctx.arc(this.centerX, this.arcCenterY, this.arcRadius, 0, Math.PI * 2)
        ctx.fill()
        if (selected > 0) {
            let gradient = ctx.createLinearGradient(0, this.arcTop, 0, Math.max(this.arcTop + 1, height))
            gradient.addColorStop(0, colorString(ARC_SELECTED_TOP_COLOR))
            gradient.addColorStop(1, colorString(ARC_SELECTED_BOTTOM_COLOR))
            ctx.globalAlpha = clamp01(selected)
            ctx.fillStyle = gradient
            ctx.beginPath()
            ctx.arc(this.centerX, this.arcCenterY, this.arcRadius, 0, Math.PI * 2)
            ctx.fill()
            ctx.strokeStyle = colorString(ARC_RIM_COLOR)
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.arc(this.centerX, this.arcCenterY, this.arcRadius - 1, 0, Math.PI * 2)
            ctx.stroke()
            ctx.globalAlpha = 1
        }
        // 「语音」和「松开 发送」交叉淡入淡出，文字同时轻微上移
        let labelCenterY = this.arcTop + 44 - 8 * selected
        this.drawCenteredText(ctx, this.voiceLabel, labelCenterY, ARC_LABEL_COLOR, 1 - selected)
        this.drawCenteredText(ctx, this.sendLabel, labelCenterY, SELECTED_LABEL_COLOR, selected)
        ctx.restore()
    }

    private drawCenteredText(ctx: CanvasRenderingContext2D, text: string, centerY: number, color: number, alpha: number) {
        if (alpha <= 0) {
            return
        }
        ctx.font = `normal normal ${ARC_LABEL_SIZE}vp sans-serif`
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        ctx.fillStyle = colorString(color, alpha)
        ctx.fillText(text, this.centerX, centerY)
    }

    private drawPill(ctx: CanvasRenderingContext2D, left: boolean, selected: number, label: string, hint: string, alpha: number) {
        // 选中时稍微变粗
        let thickness = this.pillThickness * (1 + 0.06 * selected)
        let inner = Math.asin((this.pillGap / 2 + this.pillThickness / 2) / this.pillRadius)
        let outer = Math.asin(Math.min(1, (this.stageWidth / 2 + thickness) / this.pillRadius))
        // 圆的最高点是 -π/2，角度顺时针增加，弧线从左往右画
        let start = left ? -Math.PI / 2 - outer : -Math.PI / 2 + inner
        ctx.beginPath()
        ctx.arc(this.centerX, this.pillCenterY, this.pillRadius, start, start + outer - inner)
        ctx.lineWidth = thickness
        ctx.lineCap = 'round'
        ctx.strokeStyle = colorString(blendColor(PILL_COLOR, PILL_SELECTED_COLOR, selected), alpha)
        ctx.stroke()

        let offsetX = left ? -this.labelOffsetX : this.labelOffsetX
        let labelColor = colorString(blendColor(PILL_LABEL_COLOR, SELECTED_LABEL_COLOR, selected), alpha)
        this.drawTextOnArc(ctx, label, labelColor, PILL_LABEL_SIZE, this.pillRadius, offsetX, this.maxLabelWidth)
        if (selected > 0) {
            // 按钮上方的提示随高亮淡入，并向上浮起
            let hintRadius = this.pillRadius + thickness / 2 + 24 - 8 * (1 - selected)
            this.drawTextOnArc(ctx, hint, colorString(HINT_COLOR, alpha * selected), HINT_SIZE, hintRadius, offsetX,
                this.maxLabelWidth + 40)
        }
    }

    /**
     * 沿以 (centerX, pillCenterY) 为圆心的圆弧逐字绘制文字，文字中心在 centerX + offsetX 附近，太长时缩小字号
     */
    private drawTextOnArc(ctx: CanvasRenderingContext2D, text: string, color: string, textSize: number, radius: number,
        offsetX: number, maxWidth: number) {
        let width = this.measureText(ctx, text, textSize)
        let size = textSize
        if (width > maxWidth) {
            size = textSize * maxWidth / width
            width = maxWidth
        }
        ctx.font = `normal normal ${size}vp sans-serif`
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        ctx.fillStyle = color
        let scale = size / textSize
        let angle = -Math.PI / 2 + Math.asin(Math.max(-1, Math.min(1, offsetX / radius))) - width / 2 / radius
        for (let ch of text) {
            let charWidth = this.measureText(ctx, ch, textSize) * scale
            let charAngle = angle + charWidth / 2 / radius
            ctx.save()
            ctx.translate(this.centerX + radius * Math.cos(charAngle), this.pillCenterY + radius * Math.sin(charAngle))
            ctx.rotate(charAngle + Math.PI / 2)
            ctx.fillText(ch, 0, 0)
            ctx.restore()
            angle += charWidth / radius
        }
    }

    private measureText(ctx: CanvasRenderingContext2D, text: string, size: number): number {
        let key = `${size}|${text}`
        let cached = this.textWidthCache.get(key)
        if (cached !== undefined) {
            return cached
        }
        let font = ctx.font
        ctx.font = `normal normal ${size}vp sans-serif`
        let width = ctx.measureText(text).width
        ctx.font = font
        this.textWidthCache.set(key, width)
        return width
    }
}

// endregion

// region 气泡

// 气泡圆角、底部尖角的尺寸
const BUBBLE_RADIUS = 18
const BUBBLE_TAIL_WIDTH = 18
export const BUBBLE_TAIL_HEIGHT = 8

/**
 * 气泡某一形态的位置、大小和内容，left 相对于浮层，声波和尖角的坐标相对于气泡左上角
 */
export class BubbleFrame {
    left: number = 0
    width: number = 0
    // 包含底部尖角
    height: number = 0
    tailX: number = 0
    color: number = 0
    waveColor: number = 0xFFFFFFFF
    waveWidth: number = 0
    waveHeight: number = 0
    waveCenterX: number = 0
    waveCenterY: number = 0
    waveAlpha: number = 0
    textAlpha: number = 0
    hintAlpha: number = 0
    textBottomMargin: number = 0

    copy(): BubbleFrame {
        let frame = new BubbleFrame()
        frame.set(this, this, 1)
        return frame
    }

    set(from: BubbleFrame, to: BubbleFrame, fraction: number) {
        this.left = lerp(from.left, to.left, fraction)
        this.width = lerp(from.width, to.width, fraction)
        this.height = lerp(from.height, to.height, fraction)
        this.tailX = lerp(from.tailX, to.tailX, fraction)
        this.color = blendColor(from.color, to.color, fraction)
        this.waveColor = blendColor(from.waveColor, to.waveColor, fraction)
        this.waveWidth = lerp(from.waveWidth, to.waveWidth, fraction)
        this.waveHeight = lerp(from.waveHeight, to.waveHeight, fraction)
        this.waveCenterX = lerp(from.waveCenterX, to.waveCenterX, fraction)
        this.waveCenterY = lerp(from.waveCenterY, to.waveCenterY, fraction)
        this.waveAlpha = lerp(from.waveAlpha, to.waveAlpha, fraction)
        this.textAlpha = lerp(from.textAlpha, to.textAlpha, fraction)
        this.hintAlpha = lerp(from.hintAlpha, to.hintAlpha, fraction)
        this.textBottomMargin = lerp(from.textBottomMargin, to.textBottomMargin, fraction)
    }
}

/**
 * 气泡的变换：整体透明度、以底部中点为中心的缩放、平移
 */
export class BubbleTransform {
    alpha: Tween = new Tween(0)
    scale: Tween = new Tween(1)
    translateX: Tween = new Tween(0)
    translateY: Tween = new Tween(0)

    reset() {
        this.alpha.set(0)
        this.scale.set(1)
        this.translateX.set(0)
        this.translateY.set(0)
    }

    update(now: number): boolean {
        let running = this.alpha.update(now)
        running = this.scale.update(now) || running
        running = this.translateX.update(now) || running
        running = this.translateY.update(now) || running
        return running
    }
}

/**
 * 画气泡：圆角矩形，底部有一个指向当前手势目标的小尖角，里面画声波
 *
 * @param bottom 气泡底部（尖角尖端）的 y 坐标
 */
export function drawBubble(ctx: CanvasRenderingContext2D, frame: BubbleFrame, bottom: number, transform: BubbleTransform,
    wave: VoiceWavePainter, now: number) {
    let alpha = clamp01(transform.alpha.value)
    let bodyBottom = frame.height - BUBBLE_TAIL_HEIGHT
    if (alpha <= 0 || frame.width <= 0 || bodyBottom <= 0) {
        wave.pause()
        return
    }
    let scale = transform.scale.value
    ctx.save()
    ctx.translate(frame.left + frame.width / 2 + transform.translateX.value, bottom + transform.translateY.value)
    ctx.scale(scale, scale)
    ctx.translate(-frame.width / 2, -frame.height)

    let width = frame.width
    let r = Math.min(BUBBLE_RADIUS, Math.min(width, bodyBottom) / 2)
    ctx.globalAlpha = alpha
    ctx.fillStyle = colorString(frame.color)
    ctx.beginPath()
    ctx.moveTo(r, 0)
    ctx.lineTo(width - r, 0)
    ctx.arc(width - r, r, r, -Math.PI / 2, 0)
    ctx.lineTo(width, bodyBottom - r)
    ctx.arc(width - r, bodyBottom - r, r, 0, Math.PI / 2)
    ctx.lineTo(r, bodyBottom)
    ctx.arc(r, bodyBottom - r, r, Math.PI / 2, Math.PI)
    ctx.lineTo(0, r)
    ctx.arc(r, r, r, Math.PI, Math.PI * 1.5)
    ctx.closePath()
    ctx.fill()

    let half = BUBBLE_TAIL_WIDTH / 2
    let x = Math.max(Math.min(r + half, width / 2), Math.min(Math.max(width - r - half, width / 2), frame.tailX))
    // 尖角向上多画 1 与气泡主体重叠，避免抗锯齿留下接缝；尖端画成小圆角
    let tip = 1.5
    ctx.beginPath()
    ctx.moveTo(x - half, bodyBottom - 1)
    ctx.lineTo(x - tip, frame.height - 1)
    ctx.quadraticCurveTo(x, frame.height, x + tip, frame.height - 1)
    ctx.lineTo(x + half, bodyBottom - 1)
    ctx.closePath()
    ctx.fill()

    wave.draw(ctx, frame.waveCenterX, frame.waveCenterY, frame.waveWidth, frame.waveHeight, frame.waveColor,
        alpha * frame.waveAlpha, now)
    ctx.globalAlpha = 1
    ctx.restore()
}

// endregion

// region 声波

// 竖条升高、回落的时间常数，回落慢一些更自然
const RISE_TIME_MS = 50
const FALL_TIME_MS = 140
// 声波和等待动画之间切换的时间常数
const LOADING_SWITCH_TIME_MS = 100
const LOADING_DOT_COUNT = 3
const BAR_WIDTH = 2
const BAR_GAP = 2.2
const MIN_BAR_HEIGHT = 3
const DOT_RADIUS = 2.6
const DOT_SPACING = 9

/**
 * 语音输入的声波：一排圆角竖条，中间高两边低，高度随音量平滑起落；录音结束、等待识别结果时换成三个依次跳动的圆点
 */
export class VoiceWavePainter {
    private level: number = 0
    private loading: boolean = false
    // 等待动画的显示程度，0 显示声波，1 显示等待动画
    private loadingProgress: number = 0
    // 每个竖条当前和目标的高度比例，0~1
    private heights: number[] = []
    private targets: number[] = []
    private lastFrameTime: number = 0

    /**
     * @param level 音量，0~1
     */
    setLevel(level: number) {
        this.level = clamp01(level)
        this.updateTargets()
    }

    setLoading(loading: boolean) {
        this.loading = loading
    }

    reset() {
        this.level = 0
        this.loading = false
        this.loadingProgress = 0
        this.heights = []
        this.targets = []
        this.lastFrameTime = 0
    }

    /**
     * 声波没有显示，下次显示时重新计时
     */
    pause() {
        this.lastFrameTime = 0
    }

    private updateTargets() {
        let count = this.targets.length
        for (let i = 0; i < count; i++) {
            let x = count === 1 ? 0 : i / (count - 1) * 2 - 1
            let envelope = 0.3 + 0.7 * Math.exp(-x * x * 2.5)
            let jitter = 0.5 + 0.5 * Math.random()
            // 不说话时也保留一点起伏
            let idle = 0.06 + 0.1 * Math.random() * envelope
            this.targets[i] = Math.min(1, idle + this.level * envelope * jitter * 1.2)
        }
    }

    private ensureBars(width: number) {
        let count = Math.max(1, Math.floor((width + BAR_GAP) / (BAR_WIDTH + BAR_GAP)))
        if (count === this.heights.length) {
            return
        }
        // 宽度变化时按比例重采样，形变过程中竖条高度不会突变
        let heights: number[] = []
        for (let i = 0; i < count; i++) {
            heights.push(this.heights.length === 0 ? 0
                : this.heights[Math.min(this.heights.length - 1, Math.floor(i * this.heights.length / count))])
        }
        this.heights = heights
        this.targets = heights.map(() => 0)
        this.updateTargets()
    }

    draw(ctx: CanvasRenderingContext2D, centerX: number, centerY: number, width: number, height: number, color: number,
        alpha: number, now: number) {
        if (width <= 0 || height <= 0 || alpha <= 0.01) {
            this.lastFrameTime = 0
            return
        }
        this.ensureBars(width)
        let dt = this.lastFrameTime === 0 ? 16 : Math.min(64, now - this.lastFrameTime)
        this.lastFrameTime = now
        this.loadingProgress += ((this.loading ? 1 : 0) - this.loadingProgress) * (1 - Math.exp(-dt / LOADING_SWITCH_TIME_MS))

        let count = this.heights.length
        let totalWidth = count * BAR_WIDTH + (count - 1) * BAR_GAP
        let left = centerX - totalWidth / 2
        let range = Math.max(0, height - MIN_BAR_HEIGHT)
        // 等待识别结果时竖条落下并淡出
        let barAlpha = 1 - this.loadingProgress
        ctx.fillStyle = colorString(color)
        ctx.globalAlpha = alpha * barAlpha
        for (let i = 0; i < count; i++) {
            let target = this.loading ? 0 : this.targets[i]
            let timeConstant = target > this.heights[i] ? RISE_TIME_MS : FALL_TIME_MS
            this.heights[i] += (target - this.heights[i]) * (1 - Math.exp(-dt / timeConstant))
            if (barAlpha > 0.01) {
                let h = MIN_BAR_HEIGHT + range * this.heights[i]
                let r = BAR_WIDTH / 2
                ctx.beginPath()
                ctx.arc(left + r, centerY - h / 2 + r, r, Math.PI, 0)
                ctx.arc(left + r, centerY + h / 2 - r, r, 0, Math.PI)
                ctx.closePath()
                ctx.fill()
            }
            left += BAR_WIDTH + BAR_GAP
        }
        if (this.loadingProgress > 0.01) {
            // 三个圆点从左到右依次变大变亮
            let phase = now / 1000 * Math.PI * 2 * 1.2
            for (let i = 0; i < LOADING_DOT_COUNT; i++) {
                let pulse = 0.5 + 0.5 * Math.sin(phase - i * 0.9)
                let radius = DOT_RADIUS * (0.7 + 0.3 * pulse) * (0.5 + 0.5 * this.loadingProgress)
                ctx.globalAlpha = alpha * this.loadingProgress * (0.4 + 0.6 * pulse)
                ctx.beginPath()
                ctx.arc(centerX + (i - (LOADING_DOT_COUNT - 1) / 2) * DOT_SPACING, centerY, radius, 0, Math.PI * 2)
                ctx.fill()
            }
        }
        ctx.globalAlpha = alpha
    }
}

// endregion
