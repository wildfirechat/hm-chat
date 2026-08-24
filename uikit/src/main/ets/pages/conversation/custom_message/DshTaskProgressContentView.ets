import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import DshTaskProgressMessageContent, {
    DshTaskProgressData,
    DshTaskProgressTask
} from '@wfc/client/src/main/ets/wfc_custom_message/dshTaskProgressMessageContent'
import { FontSize, Radius } from '../../../common/design/Tokens'

/**
 * DSH 任务进度卡片（208）：标题「🧩 任务进度」+ 摘要角标 + 任务列表。
 * 每行 = 状态图标 + label（或 id 短前缀）+ 状态文字（失败附原因）；空任务显示「暂无任务」。
 * 插件 updateMessage 原地更新时，消息对象被数据源整体替换，build 随 @Link message 自动刷新。
 */
@Component
export default struct DshTaskProgressContentView {
    @Link message: Message

    private content(): DshTaskProgressData {
        return (this.message.messageContent as DshTaskProgressMessageContent).content
    }

    private tasks(): DshTaskProgressTask[] {
        let tasks = this.content().tasks
        return tasks ? tasks : []
    }

    // 摘要角标：有运行中 → "共 N 个 · M 运行中"；否则有失败 → "共 N 个 · F 失败"；否则 "共 N 个 · 全部完成"
    private summaryText(): string {
        let tasks = this.tasks()
        if (tasks.length === 0) {
            return ''
        }
        let running = 0
        let failed = 0
        tasks.forEach(t => {
            if (t.status === 'running') {
                running++
            } else if (t.status === 'failed') {
                failed++
            }
        })
        if (running > 0) {
            return `共 ${tasks.length} 个 · ${running} 运行中`
        }
        return failed > 0 ? `共 ${tasks.length} 个 · ${failed} 失败` : `共 ${tasks.length} 个 · 全部完成`
    }

    private statusIcon(t: DshTaskProgressTask): string {
        let map: Record<string, string> = {
            'running': '⏳',
            'done': '✅',
            'completed': '✅',
            'failed': '❌',
            'killed': '⛔'
        }
        return map[t.status] || '⚪'
    }

    private statusText(t: DshTaskProgressTask): string {
        let map: Record<string, string> = {
            'running': '运行中',
            'done': '已完成',
            'completed': '已完成',
            'failed': '失败',
            'killed': '已终止'
        }
        return map[t.status] || t.status || ''
    }

    // 状态行文案：状态文字 + 失败原因
    private statusMeta(t: DshTaskProgressTask): string {
        let text = this.statusText(t)
        if (t.reason) {
            text += ` · ${t.reason}`
        }
        return text
    }

    private isErrorStatus(t: DshTaskProgressTask): boolean {
        return t.status === 'failed' || t.status === 'killed'
    }

    // 标签：优先 label，否则取 id 短前缀（超长时保留末 8 位）
    private taskLabel(t: DshTaskProgressTask): string {
        if (t.label) {
            return t.label
        }
        let s = String(t.id || '')
        if (s.length === 0) {
            return '子任务'
        }
        return s.length > 12 ? `子任务 ${s.slice(-8)}` : s
    }

    build() {
        Column() {
            Row() {
                Text('🧩 任务进度')
                    .fontSize(FontSize.md)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.wf_primary_text'))
                if (this.summaryText()) {
                    Text(this.summaryText())
                        .fontSize(11)
                        .fontColor(Color.White)
                        .padding({ left: 8, right: 8, top: 1, bottom: 1 })
                        .borderRadius(Radius.full)
                        .backgroundColor('#4f8ff7')
                        .margin({ left: 6 })
                }
            }
            .width('100%')
            .margin({ bottom: 6 })

            if (this.tasks().length === 0) {
                Text('暂无任务')
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_secondary_text'))
                    .width('100%')
            } else {
                ForEach(this.tasks(), (t: DshTaskProgressTask, ti: number) => {
                    Row() {
                        Text(this.statusIcon(t))
                            .fontSize(FontSize.sm)
                            .margin({ right: 8 })
                        Column() {
                            Text(this.taskLabel(t))
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_primary_text'))
                                .width('100%')
                            Text(this.statusMeta(t))
                                .fontSize(FontSize.xs)
                                .fontColor(this.isErrorStatus(t) ? $r('app.color.wf_danger') : $r('app.color.wf_secondary_text'))
                                .margin({ top: 2 })
                                .width('100%')
                        }
                        .layoutWeight(1)
                        .alignItems(HorizontalAlign.Start)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Top)
                    .padding({ top: 5, bottom: 5 })
                    if (ti < this.tasks().length - 1) {
                        Divider()
                            .strokeWidth(0.5)
                            .color($r('app.color.wf_divider'))
                            .margin({ top: 1, bottom: 1 })
                    }
                }, (t: DshTaskProgressTask, ti: number) => `${t.kind}-${t.id}-${ti}`)
            }
        }
        .width(280)
        .padding(12)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .borderRadius(Radius.lg)
        .alignItems(HorizontalAlign.Start)
    }
}
