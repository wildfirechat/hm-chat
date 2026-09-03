import CustomMessageContentType from './customMessageContentType'
import MessageContent from '../wfc/messages/messageContent'
import MessagePayload from '../wfc/messages/messagePayload'

/**
 * DSH 目标进度卡片消息，内容类型 206（机器人 -> 用户）
 */
export class AgentGoalData {
    gid: string = ''
    objective: string = ''
    // active/paused/blocked/complete
    phase: string = 'active'
    roundsStarted: number = 0
}

export function summarizeDshGoal(content: AgentGoalData): string {
    return `🎯 ${content.objective || '目标'}（${content.phase || ''}，round ${content.roundsStarted ?? 0}）`
}

export default class AgentGoalMessageContent extends MessageContent {
    content: AgentGoalData = new AgentGoalData()

    constructor() {
        super(CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_GOAL)
    }

    digest(): string {
        return summarizeDshGoal(this.content)
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
                this.content = JSON.parse(payload.content) as AgentGoalData
            } catch (e) {
                console.error('decode AgentGoalMessageContent error', e)
            }
        }
    }
}
