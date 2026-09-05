import CustomMessageContentType from './customMessageContentType'
import MessageContent from '../wfc/messages/messageContent'
import MessagePayload from '../wfc/messages/messagePayload'
import { AgentAnswerItem } from './agentAnswerMessageContent'

/**
 * Agent 提问卡片消息，内容类型 200（机器人 -> 用户）
 *
 * payload 约定（与 PC 端/服务端对齐）：
 *   payload.content           = JSON 字符串（结构化数据）
 *   payload.searchableContent = 摘要文本
 */
export class AgentQuestionOption {
    label: string = ''
}

export class AgentQuestionIntent {
    kind: string = ''
    approve: string = ''
}

export class AgentQuestionItem {
    id: string = ''
    header: string = ''
    question: string = ''
    detail: string = ''
    options: AgentQuestionOption[] = []
    multiSelect: boolean = false
    intent?: AgentQuestionIntent
}

export class AgentQuestionData {
    qid: string = ''
    questions: AgentQuestionItem[] = []
    // pending/answered/expired
    state: string = 'pending'
    // 服务端 answered 后回填的用户选择（插件 updateMessage 写入，只读展示用）
    answers: AgentAnswerItem[] = []
}

export function summarizeAgentQuestion(content: AgentQuestionData): string {
    let first = content.questions && content.questions.length > 0 ? content.questions[0] : null
    if (!first) {
        return '🤔 需要你确认'
    }
    return `🤔 ${first.header ? `【${first.header}】` : ''}${first.question}`
}

export default class AgentQuestionMessageContent extends MessageContent {
    content: AgentQuestionData = new AgentQuestionData()

    constructor() {
        super(CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_QUESTION)
    }

    digest(): string {
        return summarizeAgentQuestion(this.content)
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
                this.content = JSON.parse(payload.content) as AgentQuestionData
            } catch (e) {
                console.error('decode AgentQuestionMessageContent error', e)
            }
        }
    }
}
