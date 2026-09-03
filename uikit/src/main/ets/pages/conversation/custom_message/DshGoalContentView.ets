import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import AgentGoalMessageContent, { AgentGoalData } from '@wfc/client/src/main/ets/wfc_custom_message/dshGoalMessageContent'
import { FontSize, Radius } from '../../../common/design/Tokens'

/**
 * DSH 目标进度卡片：phase 彩色徽标 + objective + 已执行轮数，纯展示。
 */
@Component
export default struct AgentGoalContentView {
    @Link message: Message

    private content(): AgentGoalData {
        return (this.message.messageContent as AgentGoalMessageContent).content
    }

    private phaseText(): string {
        let map: Record<string, string> = {
            'active': '进行中',
            'paused': '已暂停',
            'blocked': '受阻',
            'complete': '已完成'
        }
        return map[this.content().phase] || this.content().phase || ''
    }

    private phaseColor(): ResourceColor {
        switch (this.content().phase) {
            case 'active':
                return '#22c55e'
            case 'paused':
                return '#94a3b8'
            case 'blocked':
                return $r('app.color.wf_danger')
            case 'complete':
                return $r('app.color.wf_primary')
            default:
                return '#94a3b8'
        }
    }

    build() {
        Column() {
            Row() {
                Text('🎯 目标进度')
                    .fontSize(FontSize.md)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.wf_primary_text'))
                Text(this.phaseText())
                    .fontSize(11)
                    .fontColor(Color.White)
                    .padding({ left: 8, right: 8, top: 1, bottom: 1 })
                    .borderRadius(Radius.full)
                    .backgroundColor(this.phaseColor())
                    .margin({ left: 6 })
            }
            .width('100%')
            .margin({ bottom: 6 })

            Text(this.content().objective)
                .fontSize(FontSize.sm)
                .fontColor($r('app.color.wf_primary_text'))
                .width('100%')

            Text(`已执行 ${this.content().roundsStarted ?? 0} 轮`)
                .fontSize(FontSize.xs)
                .fontColor($r('app.color.wf_tertiary_text'))
                .margin({ top: 4 })
                .width('100%')
        }
        .width(240)
        .padding(12)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .borderRadius(Radius.lg)
        .alignItems(HorizontalAlign.Start)
    }
}
