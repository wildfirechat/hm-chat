import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import UserSettingScope from '@wfc/client/src/main/ets/wfc/client/userSettingScope'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'

/**
 * DSH 会话运行时数据（scope=31 会话级用户设置，两个独立通道）：
 * - type=1（键后缀 _1）「状态」：`<convType>-<line>-<target>_1` 存 {state, phase, toolName,
 *   model, reasoningEffort, cwd, reason, error, interaction, ...} JSON，运行态/面板值由此读取；
 * - type=2（键后缀 _2）「Token 统计」：`<convType>-<line>-<target>_2` 存 {usage, turn, context,
 *   cacheHitRatePct, speed, metricsAt} JSON，回合结束必推（含出错/取消），独立于状态推送。
 * 群成员均可收到该会话级用户设置。
 */
/** context 计量：模型上下文窗口占用（usedPct 为百分比，可能带 1 位小数）。 */
export class DshStateContext {
    usedTokens: number = 0
    windowTokens: number = 0
    usedPct: number = 0
}

/** speed 计量：本轮生成速度。 */
export class DshStateSpeed {
    tokensPerSec: number = 0
    ttftMs: number = 0
}

/** turn 计量：本轮输入/输出 token。 */
export class DshStateTurn {
    inputTokens: number = 0
    outputTokens: number = 0
    cacheHitTokens: number = 0
    durationMs: number = 0
}

/** usage 计量：会话累计 token 用量。 */
export class DshStateUsage {
    promptTokens: number = 0
    outputTokens: number = 0
    cacheReadTokens: number = 0
    cacheWriteTokens: number = 0
    totalTokens: number = 0
}

export class DshState {
    // idle / running / waiting_user / done
    state: string = ''
    // thinking / tool
    phase: string = ''
    toolName: string = ''
    model: string = ''
    // 当前推理等级（如 low / medium / high；未设置时为空字符串）
    reasoningEffort: string = ''
    // 当前工作目录（会话激活后有值；未设置时为空字符串）
    cwd: string = ''
    // completed / error / cancelled（上回合结果）
    reason: string = ''
    // reason=error 时的出错信息字符串
    error: string = ''
    // question / approval（state=waiting_user 时：等待确认/等待审批）
    interaction: string = ''
    // 最近一次面板变更描述（如 "模型 → deepseek-official/deepseek-v4-pro"、"推理等级 → low"）；
    // 插件在 207 set 执行后写入，标题栏状态行展示（变更可见）；未变更为空字符串
    lastChange: string = ''
    // 当前 DSH 会话 ID（回合开始时由插件写入；切目录/重置后为新会话 ID；旧数据/未设置时为空字符串）。
    // 用于与 type=2 统计的 sessionId 比对：不一致 = 旧会话残留统计，不展示
    sessionId: string = ''
}

/** Token/上下文计量（scope=31 type=2 独立通道，键 ..._2）：回合结束必推，独立于状态推送。 */
export class DshMetrics {
    context: DshStateContext | null = null
    cacheHitRatePct: number = 0
    speed: DshStateSpeed | null = null
    turn: DshStateTurn | null = null
    usage: DshStateUsage | null = null
    // 统计生成时间戳（毫秒），用于排查/调试
    metricsAt: number = 0
    // 统计所属 DSH 会话 ID（插件回合结束必推）；与 type=1 状态（DshState）sessionId
    // 不一致 = 切目录后旧会话残留统计，客户端不展示；旧数据/未设置时为空字符串
    sessionId: string = ''
}

const DSH_STATE_TYPE = 1 // 1=状态（业务约定）
const DSH_METRICS_TYPE = 2 // 2=Token 统计（独立通道，回合结束必推）
const DSH_PANEL_TYPE = 3 // 3=AI 面板数据（207 query 组合查询结果，面板打开/更新后刷新）

export function dshStateKey(conversation: Conversation): string {
    return `${conversation.type}-${conversation.line}-${conversation.target}_${DSH_STATE_TYPE}`
}

/** type=2 统计键：`<convType>-<line>-<target>_2`。 */
export function dshMetricsKey(conversation: Conversation): string {
    return `${conversation.type}-${conversation.line}-${conversation.target}_${DSH_METRICS_TYPE}`
}

/** type=3 面板数据键：`<convType>-<line>-<target>_3`。 */
export function dshPanelKey(conversation: Conversation): string {
    return `${conversation.type}-${conversation.line}-${conversation.target}_${DSH_PANEL_TYPE}`
}

/**
 * 群 extra 是否带 {"dsh":true} 标记（容错：非 JSON 时返回 false）。
 * 注意：已不再作为 DSH 会话判定依据（判定依据统一为 line === 2），
 * 仅保留供其他场景（如标记展示）兼容使用。
 */
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
 * AI/DSH 会话类型：'single'（line 2 单聊）/ 'group'（line 2 群聊）/ ''（非 AI 会话）。
 * 判断依据：会话 line === 2（AI 消息统一使用 line 2，普通消息 line 0，朋友圈 line 1）。
 * 不再依赖 userInfo.type === 1（机器人）或群 extra {"dsh":true} 标记。
 */
export function dshConversationKind(conversation?: Conversation): string {
    if (!conversation || !conversation.target) {
        return ''
    }
    // AI 会话统一使用 line 2
    if (conversation.line !== 2) {
        return ''
    }
    return conversation.type === ConversationType.Group ? 'group' : 'single'
}

/**
 * 是否 DSH 会话（判断依据：conversation.line === 2）。
 * 非 DSH 会话不查询/不展示 DSH 状态。
 */
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
        console.info('[dsh-dbg] getDshState key=' + dshStateKey(conversation) + ' raw=' + String(raw))
        if (!raw) {
            return null
        }
        let parsed = JSON.parse(raw) as DshState
        return parsed && parsed.state ? parsed : null
    } catch (e) {
        return null
    }
}

/** 读取会话的 DSH Token 统计（scope=31 type=2 计量，键 ..._2），未设置/非法时返回 null。 */
export function getDshMetrics(conversation?: Conversation): DshMetrics | null {
    if (!conversation || !isDshConversation(conversation)) {
        return null
    }
    try {
        let raw = wfc.getUserSetting(UserSettingScope.Conversation_User_Setting, dshMetricsKey(conversation))
        console.info('[dsh-dbg] getDshMetrics key=' + dshMetricsKey(conversation) + ' raw=' + String(raw))
        if (!raw) {
            return null
        }
        let parsed = JSON.parse(raw) as DshMetrics
        // 至少含一个计量子对象才视为有效统计（容错：解析为 null/空对象/非对象时返回 null）
        return parsed && (parsed.context || parsed.speed || parsed.turn || parsed.usage) ? parsed : null
    } catch (e) {
        return null
    }
}

/** 面板模型可选项：{value: "provider/id", label: "provider/id（名）"}。 */
export class DshPanelModelOption {
    value: string = ''
    label: string = ''
}

/** 面板模型段：当前值 + 可选目录。 */
export class DshPanelModel {
    current: string = ''
    options: DshPanelModelOption[] = []
}

/** 面板推理等级段：当前值 + 可选项（如 ["low","medium","high"]）。 */
export class DshPanelEffort {
    current: string = ''
    options: string[] = []
}

/** 面板沙箱段：当前值 + 可选项（如 ["read-only","workspace-write","danger-full-access"]）。 */
export class DshPanelSandbox {
    current: string = ''
    options: string[] = []
}

/** 面板计划模式段。 */
export class DshPanelPlan {
    on: boolean = false
}

/**
 * AI 面板数据（scope=31 type=3，键 ..._3）：207 DSH_Command query 组合查询结果。
 * 结构：model/effort/sandbox/plan/cwd/sessionId/dirs。
 */
export class DshPanelData {
    model: DshPanelModel | null = null
    effort: DshPanelEffort | null = null
    sandbox: DshPanelSandbox | null = null
    plan: DshPanelPlan | null = null
    cwd: string = ''
    sessionId: string = ''
    // 项目根目录子目录（cwd 切换候选）
    dirs: string[] = []
}

/**
 * 读取会话的 AI 面板数据（scope=31 type=3，键 ..._3），未设置/非法时返回 null。
 * 面板打开时先读已有数据渲染，再发 207 query 让插件刷新；面板监听设置更新事件重读。
 */
export function getDshPanelData(conversation?: Conversation): DshPanelData | null {
    if (!conversation || !isDshConversation(conversation)) {
        return null
    }
    try {
        let raw = wfc.getUserSetting(UserSettingScope.Conversation_User_Setting, dshPanelKey(conversation))
        console.info('[dsh-dbg] getDshPanelData key=' + dshPanelKey(conversation) + ' raw=' + String(raw))
        if (!raw) {
            return null
        }
        let parsed = JSON.parse(raw) as Record<string, Object>
        if (!parsed) {
            return null
        }
        let data = new DshPanelData()
        let model = parsed['model'] as Record<string, Object>
        if (model) {
            let m = new DshPanelModel()
            m.current = model['current'] as string || ''
            let options = model['options'] as Record<string, Object>[]
            if (options) {
                for (const opt of options) {
                    let o = new DshPanelModelOption()
                    o.value = opt['value'] as string || ''
                    o.label = opt['label'] as string || o.value
                    m.options.push(o)
                }
            }
            data.model = m
        }
        let effort = parsed['effort'] as Record<string, Object>
        if (effort) {
            let e = new DshPanelEffort()
            e.current = effort['current'] as string || ''
            e.options = (effort['options'] as string[]) || []
            data.effort = e
        }
        let sandbox = parsed['sandbox'] as Record<string, Object>
        if (sandbox) {
            let s = new DshPanelSandbox()
            s.current = sandbox['current'] as string || ''
            s.options = (sandbox['options'] as string[]) || []
            data.sandbox = s
        }
        let plan = parsed['plan'] as Record<string, Object>
        if (plan) {
            let p = new DshPanelPlan()
            p.on = !!(plan['on'] as boolean)
            data.plan = p
        }
        data.cwd = parsed['cwd'] as string || ''
        data.sessionId = parsed['sessionId'] as string || ''
        data.dirs = (parsed['dirs'] as string[]) || []
        return data
    } catch (e) {
        return null
    }
}

/** 状态文案：空闲/运行中/等待确认/已完成；运行中按 phase 追加思考中/工具名。 */
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
    if (text && state.state === 'running' && state.phase === 'tool') {
        text += ` · ${state.toolName || '工具'}`
    } else if (text && state.state === 'running' && state.phase === 'thinking') {
        text += ' · 思考中'
    }
    return text
}

/** 数字格式化：整数不带小数，否则保留 1 位（如 0.8、70.5、98）。 */
function fmtNum(n: number): string {
    return n === Math.floor(n) ? `${n}` : `${Math.round(n * 10) / 10}`
}

/**
 * Token 统计（scope=31 type=2 计量，键 ..._2）→ 一行展示文本（标题栏展示用）。
 * 字段：context.usedPct / cacheHitRatePct / speed.tokensPerSec / turn.outputTokens / usage.totalTokens。
 * 只输出统计段（上下文/缓存/速度/本轮/累计）；运行态提示（等待确认/审批、出错、已取消）走
 * dshStatusHint（type=1 状态），不在此处。
 * 各段用 " · " 连接；返回 '' 表示没有可展示的统计（不占位）。
 * 数值均以 typeof === 'number' 判有，避免把字符串当数字；cacheHitRatePct 为 0 也要显示。
 */
export function dshMetricsText(metrics: DshMetrics | null): string {
    if (!metrics) {
        return ''
    }
    let parts: string[] = []

    // 上下文占用（下一请求预估成本 / 模型窗口）
    if (metrics.context && typeof metrics.context.usedPct === 'number') {
        parts.push(`上下文 ${fmtNum(metrics.context.usedPct)}%`)
    }
    // 缓存命中率（累计口径）
    if (typeof metrics.cacheHitRatePct === 'number') {
        parts.push(`缓存 ${fmtNum(metrics.cacheHitRatePct)}%`)
    }
    // 本轮生成速度 + 输出 token
    if (metrics.speed && typeof metrics.speed.tokensPerSec === 'number') {
        parts.push(`${fmtNum(metrics.speed.tokensPerSec)} tok/s`)
    }
    if (metrics.turn && typeof metrics.turn.outputTokens === 'number' && metrics.turn.outputTokens > 0) {
        parts.push(`本轮 ${metrics.turn.outputTokens} tok`)
    }
    // 累计用量
    if (metrics.usage && typeof metrics.usage.totalTokens === 'number') {
        parts.push(`累计 ${metrics.usage.totalTokens} tok`)
    }
    return parts.join(' · ')
}

/**
 * 运行态提示（scope=31 type=1 状态）→ 一段文本（标题栏展示用）：
 *   state=waiting_user → 🤔 等待确认 / 🔐 等待审批（interaction=approval）；
 *   reason=error → ⚠️ 错误信息；reason=cancelled → 已取消。
 * 返回 '' 表示无提示。
 */
export function dshStatusHint(state: DshState | null): string {
    if (!state) {
        return ''
    }
    if (state.state === 'waiting_user') {
        return state.interaction === 'approval' ? '🔐 等待审批' : '🤔 等待确认'
    }
    if (state.reason === 'error') {
        return `⚠️ ${state.error || '出错了'}`
    }
    if (state.reason === 'cancelled') {
        return '已取消'
    }
    return ''
}

/** 状态颜色（会话列表圆点/标题栏共用）：running=主色/waiting_user=#f59e0b/idle·done=#22c55e（绿色表示可继续输入指示任务）/其他兜底同绿色。 */
export function dshStateColor(state: string): ResourceColor {
    switch (state) {
        case 'running':
            return $r('app.color.wf_primary')
        case 'waiting_user':
            return '#f59e0b'
        case 'idle':
        case 'done':
            return '#22c55e'
        default:
            // 未知状态兜底同 idle：绿色
            return '#22c55e'
    }
}
