import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import UserSettingScope from '@wfc/client/src/main/ets/wfc/client/userSettingScope'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'

/**
 * DSH 会话运行时状态（scope=31 会话级用户设置，key 后缀 _1 为业务约定的「状态」类型）。
 * 机器人侧往 key `<convType>-<line>-<target>_1` 写 {state, phase, toolName, model, ...} JSON，
 * 群成员均可收到该会话级用户设置。
 */
export class DshState {
    // idle / running / waiting_user / done
    state: string = ''
    // thinking / tool
    phase: string = ''
    toolName: string = ''
    model: string = ''
}

const DSH_STATE_TYPE = 1 // 1=状态（业务约定）

export function dshStateKey(conversation: Conversation): string {
    return `${conversation.type}-${conversation.line}-${conversation.target}_${DSH_STATE_TYPE}`
}

/** 群 extra 是否带 {"dsh":true} 标记（容错：非 JSON 时返回 false）。 */
export function isDshGroupExtra(extra: string): boolean {
    if (!extra) {
        return false
    }
    try {
        return !!(JSON.parse(extra) as Record<string, Object>)['dsh']
    } catch (e) {
        return false
    }
}

/**
 * DSH 会话类型：'single'（单聊且对方是机器人 UserInfo.type === 1）/
 * 'group'（群 extra 带 {"dsh":true} 标记）/ ''（非 DSH 会话）。
 * 用户信息/群信息未缓存时返回 ''，待 UserInfosUpdate/GroupInfosUpdate 后再判断。
 */
export function dshConversationKind(conversation?: Conversation): string {
    if (!conversation || !conversation.target) {
        return ''
    }
    try {
        if (conversation.type === ConversationType.Single) {
            let userInfo = wfc.getUserInfo(conversation.target, false)
            return userInfo && userInfo.type === 1 ? 'single' : ''
        }
        if (conversation.type === ConversationType.Group) {
            let groupInfo = wfc.getGroupInfo(conversation.target, false)
            return groupInfo && isDshGroupExtra(groupInfo.extra) ? 'group' : ''
        }
    } catch (e) {
        return ''
    }
    return ''
}

/** 是否 DSH 会话。非 DSH 会话不查询/不展示 DSH 状态。 */
export function isDshConversation(conversation?: Conversation): boolean {
    return dshConversationKind(conversation) !== ''
}

/** 读取会话的 DSH 运行时状态，未设置/非法时返回 null。 */
export function getDshState(conversation?: Conversation): DshState | null {
    if (!conversation || !isDshConversation(conversation)) {
        return null
    }
    try {
        let raw = wfc.getUserSetting(UserSettingScope.Conversation_User_Setting, dshStateKey(conversation))
        if (!raw) {
            return null
        }
        let parsed = JSON.parse(raw) as DshState
        return parsed && parsed.state ? parsed : null
    } catch (e) {
        return null
    }
}

/** 状态文案：空闲/运行中/等待确认/已完成；phase 为 tool 时追加工具名。 */
export function dshStateText(state: DshState | null): string {
    if (!state || !state.state) {
        return ''
    }
    let map: Record<string, string> = {
        'idle': '空闲',
        'running': '运行中',
        'waiting_user': '等待确认',
        'done': '已完成'
    }
    let text = map[state.state] || ''
    if (text && state.phase === 'tool') {
        text += ` · ${state.toolName || '工具'}`
    }
    return text
}

/** 状态圆点颜色（会话列表/标题栏共用）。 */
export function dshStateColor(state: string): ResourceColor {
    switch (state) {
        case 'running':
            return $r('app.color.wf_primary')
        case 'waiting_user':
            return '#f59e0b'
        case 'done':
            return '#22c55e'
        default:
            return '#94a3b8'
    }
}
