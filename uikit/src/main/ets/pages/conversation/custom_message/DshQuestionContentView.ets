import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import DshQuestionMessageContent, { DshQuestionData, DshQuestionItem, DshQuestionOption } from '@wfc/client/src/main/ets/wfc_custom_message/dshQuestionMessageContent'
import DshAnswerMessageContent, { DshAnswerData, DshAnswerItem } from '@wfc/client/src/main/ets/wfc_custom_message/dshAnswerMessageContent'
import { FontSize, Radius } from '../../../common/design/Tokens'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'

/**
 * DSH 提问卡片：选项垂直排列整行可点；单选点击即答，多选勾选后点「提交」；
 * 「自定义回答」聚焦会话主输入框（用户直接发的文本由服务端当作自定义回答）；
 * plan-review 时计划全文不内联，点「查看计划」打开全屏计划详情页。
 */
@Component
export default struct DshQuestionContentView {
    @Link message: Message
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
    @State locallyAnswered: boolean = false
    // 多选勾选状态：问题 id -> 已选中的选项 label 列表（重新赋值触发刷新）
    @State selectedMap: Map<string, string[]> = new Map()

    private content(): DshQuestionData {
        return (this.message.messageContent as DshQuestionMessageContent).content
    }

    private questions(): DshQuestionItem[] {
        let questions = this.content().questions
        return questions ? questions : []
    }

    private header(): string {
        let questions = this.questions()
        return questions.length > 0 && questions[0].header ? questions[0].header : ''
    }

    private hasMulti(): boolean {
        return this.questions().some(q => q.multiSelect)
    }

    private isLocked(): boolean {
        let state = this.content().state
        return this.locallyAnswered || state === 'answered' || state === 'expired'
    }

    private stateText(): string {
        if (this.locallyAnswered || this.content().state === 'answered') {
            return '已作答'
        }
        if (this.content().state === 'expired') {
            return '已过期'
        }
        return ''
    }

    private selectedCount(): number {
        let count = 0
        this.selectedMap.forEach(arr => {
            count += arr ? arr.length : 0
        })
        return count
    }

    private isPlanReview(q: DshQuestionItem): boolean {
        return !!q.intent && q.intent.kind === 'plan-review'
    }

    private isApproveOption(q: DshQuestionItem, label: string): boolean {
        // plan-review：intent.approve 命中的选项为主按钮（批准），其余为次按钮（拒绝/修改）
        return !!q.intent && !!q.intent.approve && label === q.intent.approve
    }

    private isSelected(qid: string, label: string): boolean {
        let arr = this.selectedMap.get(qid)
        return !!arr && arr.indexOf(label) >= 0
    }

    private onClickOption(q: DshQuestionItem, label: string) {
        if (this.isLocked()) {
            return
        }
        if (q.multiSelect) {
            let current = this.selectedMap.get(q.id) || []
            let index = current.indexOf(label)
            if (index >= 0) {
                current.splice(index, 1)
            } else {
                current.push(label)
            }
            this.selectedMap.set(q.id, current)
            this.selectedMap = new Map(this.selectedMap)
        } else {
            // 单选：点击即答
            this.sendSingleAnswer(q.id, label)
        }
    }

    private sendSingleAnswer(questionId: string, label: string) {
        let item = new DshAnswerItem()
        item.id = questionId
        item.selected = [label]
        this.sendAnswer([item])
    }

    private sendSelected() {
        let answers: DshAnswerItem[] = []
        this.questions().forEach(q => {
            let selected = this.selectedMap.get(q.id) || []
            if (selected.length > 0) {
                let item = new DshAnswerItem()
                item.id = q.id
                item.selected = selected
                answers.push(item)
            }
        })
        if (answers.length > 0) {
            this.sendAnswer(answers)
        }
    }

    private sendAnswer(answers: DshAnswerItem[]) {
        if (this.isLocked()) {
            return
        }
        let content = new DshAnswerMessageContent()
        let data = new DshAnswerData()
        data.qid = this.content().qid
        data.answers = answers
        content.content = data
        wfc.sendConversationMessage(this.message.conversation, content)
        this.locallyAnswered = true
    }

    // 卡片内不嵌输入框：聚焦会话主输入框并弹键盘，用户直接发的文本由服务端当作自定义回答
    private focusConversationInput() {
        focusControl.requestFocus('textInput')
    }

    private openPlanDetail(q: DshQuestionItem) {
        // 拒绝标签取 intent.approve 之外的第一个选项，兜底「拒绝」
        let rejectLabel = '拒绝'
        if (q.options) {
            let other = q.options.find(o => !this.isApproveOption(q, o.label))
            if (other) {
                rejectLabel = other.label
            }
        }
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.DshPlanDetailPage, {
            'planText': q.detail,
            'title': q.header ? q.header : '计划详情',
            'message': this.message,
            'payloadQid': this.content().qid,
            'questionId': q.id,
            'approveLabel': q.intent && q.intent.approve ? q.intent.approve : '批准',
            'rejectLabel': rejectLabel,
            'onAnswered': () => {
                this.locallyAnswered = true
            }
        } as Record<string, Object>)
    }

    build() {
        Column() {
            if (this.header()) {
                Text(`【${this.header()}】`)
                    .fontSize(FontSize.md)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.wf_primary_text'))
                    .margin({ bottom: 6 })
                    .width('100%')
            }

            ForEach(this.questions(), (q: DshQuestionItem, qi: number) => {
                Column() {
                    Text(`${qi + 1}. ${q.question}`)
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.wf_primary_text'))
                        .width('100%')
                    if (q.detail && !this.isPlanReview(q)) {
                        Text(q.detail)
                            .fontSize(FontSize.xs)
                            .fontColor($r('app.color.wf_secondary_text'))
                            .margin({ top: 2 })
                            .width('100%')
                    }
                    if (this.isPlanReview(q) && q.detail) {
                        Text('查看计划')
                            .fontSize(FontSize.xs)
                            .fontColor($r('app.color.wf_primary'))
                            .margin({ top: 6 })
                            .padding({ top: 6, bottom: 6, left: 12, right: 12 })
                            .borderRadius(Radius.sm)
                            .border({ width: 1, color: $r('app.color.wf_primary') })
                            .onClick(() => {
                                this.openPlanDetail(q)
                            })
                    }
                    if (q.options && q.options.length > 0) {
                        Column({ space: 6 }) {
                            ForEach(q.options, (opt: DshQuestionOption, oi: number) => {
                                if (this.isPlanReview(q)) {
                                    // plan-review：按钮样式，approve 命中的为主色主按钮
                                    Text(opt.label)
                                        .fontSize(FontSize.sm)
                                        .fontColor(this.isApproveOption(q, opt.label) ? Color.White : $r('app.color.wf_secondary_text'))
                                        .textAlign(TextAlign.Center)
                                        .width('100%')
                                        .constraintSize({ minHeight: 40 })
                                        .padding({ top: 8, bottom: 8 })
                                        .borderRadius(Radius.sm)
                                        .backgroundColor(this.isApproveOption(q, opt.label) ? $r('app.color.wf_primary') : Color.Transparent)
                                        .border({ width: this.isApproveOption(q, opt.label) ? 0 : 1, color: $r('app.color.wf_divider') })
                                        .opacity(this.isLocked() ? 0.5 : 1)
                                        .enabled(!this.isLocked())
                                        .onClick(() => {
                                            this.sendSingleAnswer(q.id, opt.label)
                                        })
                                } else {
                                    // 普通选项：整行可点（>=40vp），多选高亮已选
                                    Row() {
                                        Text(opt.label)
                                            .fontSize(FontSize.sm)
                                            .fontColor(this.isSelected(q.id, opt.label) ? Color.White : $r('app.color.wf_primary'))
                                            .textAlign(TextAlign.Center)
                                            .width('100%')
                                    }
                                    .width('100%')
                                    .constraintSize({ minHeight: 40 })
                                    .padding({ top: 8, bottom: 8 })
                                    .borderRadius(Radius.sm)
                                    .backgroundColor(this.isSelected(q.id, opt.label) ? $r('app.color.wf_primary') : Color.Transparent)
                                    .border({ width: 1, color: $r('app.color.wf_primary') })
                                    .opacity(this.isLocked() ? 0.5 : 1)
                                    .enabled(!this.isLocked())
                                    .onClick(() => {
                                        this.onClickOption(q, opt.label)
                                    })
                                }
                            }, (opt: DshQuestionOption, oi: number) => `${q.id}-${oi}`)
                        }
                        .width('100%')
                        .margin({ top: 6 })
                    }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ bottom: 8 })
            }, (q: DshQuestionItem, qi: number) => `${q.id}-${qi}`)

            if (!this.isLocked()) {
                Row({ space: 8 }) {
                    Text('自定义回答')
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.wf_primary'))
                        .textAlign(TextAlign.Center)
                        .constraintSize({ minHeight: 40 })
                        .padding({ top: 8, bottom: 8, left: 12, right: 12 })
                        .borderRadius(Radius.sm)
                        .border({ width: 1, color: $r('app.color.wf_primary') })
                        .layoutWeight(1)
                        .onClick(() => {
                            this.focusConversationInput()
                        })
                    if (this.hasMulti()) {
                        Text('提交')
                            .fontSize(FontSize.sm)
                            .fontColor(Color.White)
                            .textAlign(TextAlign.Center)
                            .constraintSize({ minHeight: 40 })
                            .padding({ top: 8, bottom: 8, left: 12, right: 12 })
                            .borderRadius(Radius.sm)
                            .backgroundColor($r('app.color.wf_primary'))
                            .layoutWeight(1)
                            .opacity(this.selectedCount() === 0 ? 0.5 : 1)
                            .enabled(this.selectedCount() > 0)
                            .onClick(() => {
                                this.sendSelected()
                            })
                    }
                }
                .width('100%')
                .margin({ top: 4 })
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
