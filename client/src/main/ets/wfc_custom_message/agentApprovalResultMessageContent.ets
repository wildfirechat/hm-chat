import CustomMessageContentType from './customMessageContentType'
import MessageContent from '../wfc/messages/messageContent'
import MessagePayload from '../wfc/messages/messagePayload'

/**
 * Agent 审批结果消息，内容类型 203（用户 -> 机器人）
 */
export class AgentApprovalResultData {
    aid: string = ''
    // approve / reject
    action: string = 'reject'
}

export default class AgentApprovalResultMessageContent extends MessageContent {
    content: AgentApprovalResultData = new AgentApprovalResultData()

    constructor() {
        super(CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_APPROVAL_RESULT)
    }

    digest(): string {
        return this.content.action === 'approve' ? '（已同意）' : '（已拒绝）'
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
                this.content = JSON.parse(payload.content) as AgentApprovalResultData
            } catch (e) {
                console.error('decode AgentApprovalResultMessageContent error', e)
            }
        }
    }
}
