import CustomMessageContentType from './customMessageContentType'
import MessageContent from '../wfc/messages/messageContent'
import MessagePayload from '../wfc/messages/messagePayload'

/**
 * DSH 审批卡片消息，内容类型 202（机器人 -> 用户）
 */
export class DshApprovalData {
    aid: string = ''
    toolName: string = ''
    reason: string = ''
    // pending/approved/rejected/expired
    state: string = 'pending'
}

export function summarizeDshApproval(content: DshApprovalData): string {
    return `🔐 工具审批：${content.toolName || '工具'}${content.reason ? `（${content.reason}）` : ''}`
}

export default class DshApprovalMessageContent extends MessageContent {
    content: DshApprovalData = new DshApprovalData()

    constructor() {
        super(CustomMessageContentType.MESSAGE_CONTENT_TYPE_DSH_APPROVAL)
    }

    digest(): string {
        return summarizeDshApproval(this.content)
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
                this.content = JSON.parse(payload.content) as DshApprovalData
            } catch (e) {
                console.error('decode DshApprovalMessageContent error', e)
            }
        }
    }
}
