import CustomMessageContentType from './customMessageContentType'
import MessageContent from '../wfc/messages/messageContent'
import MessagePayload from '../wfc/messages/messagePayload'

/**
 * Agent 任务进度卡片消息，内容类型 208（机器人 -> 用户）。
 * 插件派生子任务/后台任务时首次 sendCard，之后 updateMessage 原地更新本卡片。
 * content = JSON：{"tasks":[{"kind":"subagent|job","id":"...","label":"可选",
 *   "status":"running|done|failed|completed|killed","reason":"失败原因可选","updatedAt":123}],"updatedAt":123}
 */
export class AgentTaskProgressTask {
    // subagent | job
    kind: string = ''
    id: string = ''
    label: string = ''
    // running | done | failed | completed | killed
    status: string = 'running'
    // 失败原因（可选）
    reason: string = ''
    updatedAt: number = 0
}

export class AgentTaskProgressData {
    tasks: AgentTaskProgressTask[] = []
    updatedAt: number = 0
}

/** 摘要：无任务返回 "🧩 任务：无"；有运行中显示 "🧩 任务 N（M 运行中）"，否则 "🧩 任务 N（全部完成）"。 */
export function summarizeAgentTaskProgress(content: AgentTaskProgressData): string {
    let tasks = content.tasks || []
    let running = 0
    tasks.forEach(t => {
        if (t.status === 'running') {
            running++
        }
    })
    if (tasks.length === 0) {
        return '🧩 任务：无'
    }
    return running > 0 ? `🧩 任务 ${tasks.length}（${running} 运行中）` : `🧩 任务 ${tasks.length}（全部完成）`
}

export default class AgentTaskProgressMessageContent extends MessageContent {
    content: AgentTaskProgressData = new AgentTaskProgressData()

    constructor() {
        super(CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_TASK_PROGRESS)
    }

    digest(): string {
        return summarizeAgentTaskProgress(this.content)
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
                this.content = JSON.parse(payload.content) as AgentTaskProgressData
            } catch (e) {
                console.error('decode AgentTaskProgressMessageContent error', e)
            }
        }
    }
}
