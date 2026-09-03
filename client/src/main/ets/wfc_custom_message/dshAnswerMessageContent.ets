import CustomMessageContentType from './customMessageContentType'
import MessageContent from '../wfc/messages/messageContent'
import MessagePayload from '../wfc/messages/messagePayload'

/**
 * DSH 回答消息，内容类型 201（用户 -> 机器人）
 */
export class AgentAnswerItem {
    id: string = ''
    selected: string[] = []
    custom: string = ''
}

export class AgentAnswerData {
    qid: string = ''
    answers: AgentAnswerItem[] = []
}

export default class AgentAnswerMessageContent extends MessageContent {
    content: AgentAnswerData = new AgentAnswerData()

    constructor() {
        super(CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_ANSWER)
    }

    digest(): string {
        let answers = this.content.answers ? this.content.answers : []
        let parts: string[] = []
        answers.forEach(a => {
            if (a.selected && a.selected.length > 0) {
                parts.push(a.selected.join('、'))
            } else if (a.custom) {
                parts.push(a.custom)
            }
        })
        return parts.length > 0 ? `已选择：${parts.join('；')}` : '（已作答）'
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
                this.content = JSON.parse(payload.content) as AgentAnswerData
            } catch (e) {
                console.error('decode AgentAnswerMessageContent error', e)
            }
        }
    }
}
