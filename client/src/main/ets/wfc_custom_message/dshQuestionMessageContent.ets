import CustomMessageContentType from './customMessageContentType'
import MessageContent from '../wfc/messages/messageContent'
import MessagePayload from '../wfc/messages/messagePayload'
import { DshAnswerItem } from './dshAnswerMessageContent'

/**
 * DSH 提问卡片消息，内容类型 200（机器人 -> 用户）
 *
 * payload 约定（与 PC 端/服务端对齐）：
 *   payload.content           = JSON 字符串（结构化数据）
 *   payload.searchableContent = 摘要文本
 */
export class DshQuestionOption {
    label: string = ''
}

export class DshQuestionIntent {
    kind: string = ''
    approve: string = ''
}

export class DshQuestionItem {
    id: string = ''
    header: string = ''
    question: string = ''
    detail: string = ''
    options: DshQuestionOption[] = []
    multiSelect: boolean = false
    intent?: DshQuestionIntent
}

export class DshQuestionData {
    qid: string = ''
    questions: DshQuestionItem[] = []
    // pending/answered/expired
    state: string = 'pending'
    // 服务端 answered 后回填的用户选择（插件 updateMessage 写入，只读展示用）
    answers: DshAnswerItem[] = []
}

export function summarizeDshQuestion(content: DshQuestionData): string {
    let first = content.questions && content.questions.length > 0 ? content.questions[0] : null
    if (!first) {
        return '🤔 需要你确认'
    }
    return `🤔 ${first.header ? `【${first.header}】` : ''}${first.question}`
}

export default class DshQuestionMessageContent extends MessageContent {
    content: DshQuestionData = new DshQuestionData()

    constructor() {
        super(CustomMessageContentType.MESSAGE_CONTENT_TYPE_DSH_QUESTION)
    }

    digest(): string {
        return summarizeDshQuestion(this.content)
    }

    encode() {
        let payload = super.encode()
        payload.content = JSON.stringify(this.content)
        payload.searchableContent = this.digest()
        return payload
    }

    decode(payload: MessagePayload) {
        super.decode(payload)
        if (payload.content) {
            try {
                this.content = JSON.parse(payload.content) as DshQuestionData
            } catch (e) {
                console.error('decode DshQuestionMessageContent error', e)
            }
        }
    }
}
