import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import AgentApprovalMessageContent, { AgentApprovalData } from '@wfc/client/src/main/ets/wfc_custom_message/agentApprovalMessageContent'
import AgentApprovalResultMessageContent, { AgentApprovalResultData } from '@wfc/client/src/main/ets/wfc_custom_message/agentApprovalResultMessageContent'
import { FontSize, Radius } from '../../../common/design/Tokens'

/**
 * Agent 审批卡片：「同意」（主色）/「拒绝」（红）并排各半宽；
 * 点击发送 AGENT_ApprovalResult 并立即本地置灰。
 */
@Component
export default struct AgentApprovalContentView {
    @Link message: Message
    @State locallyDecided: boolean = false

    private content(): AgentApprovalData {
        return (this.message.messageContent as AgentApprovalMessageContent).content
    }

    private isLocked(): boolean {
        let state = this.content().state
        return this.locallyDecided || state === 'approved' || state === 'rejected' || state === 'expired'
    }

    private stateText(): string {
        if (this.locallyDecided || this.content().state === 'approved') {
            return '已同意'
        }
        if (this.content().state === 'rejected') {
            return '已拒绝'
        }
        if (this.content().state === 'expired') {
            return '已过期'
        }
        return ''
    }

    private decide(action: string) {
        if (this.isLocked()) {
            return
        }
        let content = new AgentApprovalResultMessageContent()
        let data = new AgentApprovalResultData()
        data.aid = this.content().aid
        data.action = action
        content.content = data
        wfc.sendConversationMessage(this.message.conversation, content)
        this.locallyDecided = true
    }

    build() {
        Column() {
            Text('🔐 工具审批')
                .fontSize(FontSize.md)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.wf_primary_text'))
                .margin({ bottom: 6 })
                .width('100%')

            Text(this.content().toolName)
                .fontSize(FontSize.sm)
                .fontFamily('monospace')
                .fontColor($r('app.color.wf_primary_text'))
                .width('100%')

            if (this.content().reason) {
                Text(`原因：${this.content().reason}`)
                    .fontSize(FontSize.xs)
                    .fontColor($r('app.color.wf_secondary_text'))
                    .margin({ top: 4 })
                    .width('100%')
            }

            if (!this.isLocked()) {
                Row({ space: 8 }) {
                    Text('同意')
                        .fontSize(FontSize.md)
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Center)
                        .constraintSize({ minHeight: 40 })
                        .padding({ top: 8, bottom: 8 })
                        .borderRadius(Radius.sm)
                        .backgroundColor($r('app.color.wf_primary'))
                        .layoutWeight(1)
                        .onClick(() => {
                            this.decide('approve')
                        })
                    Text('拒绝')
                        .fontSize(FontSize.md)
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Center)
                        .constraintSize({ minHeight: 40 })
                        .padding({ top: 8, bottom: 8 })
                        .borderRadius(Radius.sm)
                        .backgroundColor($r('app.color.wf_danger'))
                        .layoutWeight(1)
                        .onClick(() => {
                            this.decide('reject')
                        })
                }
                .width('100%')
                .margin({ top: 10 })
            }

            if (this.isLocked()) {
                Text(this.stateText())
                    .fontSize(FontSize.xs)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .margin({ top: 6 })
                    .width('100%')
            }
        }
        .width(280)
        .padding(12)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .borderRadius(Radius.lg)
        .alignItems(HorizontalAlign.Start)
    }
}
