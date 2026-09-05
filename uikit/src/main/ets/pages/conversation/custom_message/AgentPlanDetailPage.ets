import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import AgentQuestionMessageContent from '@wfc/client/src/main/ets/wfc_custom_message/agentQuestionMessageContent'
import AgentAnswerMessageContent, { AgentAnswerData, AgentAnswerItem } from '@wfc/client/src/main/ets/wfc_custom_message/agentAnswerMessageContent'
import { FontSize, Radius } from '../../../common/design/Tokens'

/**
 * Agent plan-review 全屏计划详情页：等宽字体展示计划全文，底部固定 批准/拒绝 按钮。
 * 批准/拒绝等同点击卡片上对应选项（发送 AGENT_ANSWER），回答后关闭本页并通知卡片本地置灰。
 */
@Component
export default struct AgentPlanDetailPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
    @State planText: string = ''
    @State pageTitle: string = '计划详情'
    @State answered: boolean = false
    private message?: Message
    private payloadQid: string = ''
    private questionId: string = ''
    private approveLabel: string = '批准'
    private rejectLabel: string = '拒绝'
    private onAnswered?: () => void

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>
        this.planText = params['planText'] as string
        this.pageTitle = params['title'] as string || '计划详情'
        this.message = params['message'] as Message
        this.payloadQid = params['payloadQid'] as string
        this.questionId = params['questionId'] as string
        this.approveLabel = params['approveLabel'] as string || '批准'
        this.rejectLabel = params['rejectLabel'] as string || '拒绝'
        this.onAnswered = params['onAnswered'] as () => void
    }

    private isLocked(): boolean {
        if (this.answered) {
            return true
        }
        if (!this.message) {
            return true
        }
        let state = (this.message.messageContent as AgentQuestionMessageContent).content.state
        return state === 'answered' || state === 'expired'
    }

    private answer(label: string) {
        if (this.isLocked() || !this.message) {
            return
        }
        let content = new AgentAnswerMessageContent()
        let data = new AgentAnswerData()
        data.qid = this.payloadQid
        let item = new AgentAnswerItem()
        item.id = this.questionId
        item.selected = [label]
        data.answers = [item]
        content.content = data
        wfc.sendConversationMessage(this.message.conversation, content)
        this.answered = true
        if (this.onAnswered) {
            this.onAnswered()
        }
        this.mainNavPathStack.pop()
    }

    build() {
        NavDestination() {
            Column() {
                Scroll() {
                    Text(this.planText)
                        .fontSize(FontSize.sm)
                        .fontFamily('monospace')
                        .fontColor($r('app.color.wf_primary_text'))
                        .width('100%')
                        .textAlign(TextAlign.Start)
                }
                .scrollBar(BarState.Auto)
                .edgeEffect(EdgeEffect.Spring)
                .width('100%')
                .layoutWeight(1)

                if (this.isLocked()) {
                    Text('已作答')
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.wf_tertiary_text'))
                        .padding(12)
                } else {
                    Row({ space: 12 }) {
                        Text(this.rejectLabel)
                            .fontSize(FontSize.md)
                            .fontColor($r('app.color.wf_danger'))
                            .textAlign(TextAlign.Center)
                            .constraintSize({ minHeight: 40 })
                            .padding({ top: 8, bottom: 8 })
                            .borderRadius(Radius.sm)
                            .border({ width: 1, color: $r('app.color.wf_danger') })
                            .layoutWeight(1)
                            .onClick(() => {
                                this.answer(this.rejectLabel)
                            })
                        Text(this.approveLabel)
                            .fontSize(FontSize.md)
                            .fontColor(Color.White)
                            .textAlign(TextAlign.Center)
                            .constraintSize({ minHeight: 40 })
                            .padding({ top: 8, bottom: 8 })
                            .borderRadius(Radius.sm)
                            .backgroundColor($r('app.color.wf_primary'))
                            .layoutWeight(1)
                            .onClick(() => {
                                this.answer(this.approveLabel)
                            })
                    }
                    .width('100%')
                    .padding({ top: 12, bottom: 12 })
                }
            }
            .padding({ left: 16, right: 16 })
            .width('100%')
            .height('100%')
            .alignItems(HorizontalAlign.Start)
        }
        .title(this.pageTitle)
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.wf_primary_background_color'))
    }
}
