import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import UserSettingScope from '@wfc/client/src/main/ets/wfc/client/userSettingScope'
import UserSettingEntry from '@wfc/client/src/main/ets/wfc/model/userSettingEntry'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'

/**
 * Agent 会话运行时数据（scope=31 会话级用户设置，三个独立通道）：
 * - type=1（键后缀 _1）「状态」：`<convType>-<line>-<target>_1_<机器人uid>` 存 {state, phase,
 *   toolName, model, reasoningEffort, cwd, reason, error, interaction, ...} JSON；
 * - type=2（键后缀 _2）「Token 统计」：`<convType>-<line>-<target>_2_<机器人uid>` 存 {usage,
 *   turn, context, cacheHitRatePct, speed, metricsAt} JSON，回合结束必推（含出错/取消）；
 * - type=3（键后缀 _3）「AI 面板数据」：`<convType>-<line>-<target>_3_<机器人uid>`。
 * 服务端 v2：key 末尾由 im-server 按写入请求的机器人身份追加其 uid；客户端不预知
 * 机器人 uid，统一按「前缀 + 槽位」扫描 scope=31 设置表（后缀通配，多机器人兼容）。
 * 群成员均可收到该会话级用户设置。
 */
/** context 计量：模型上下文窗口占用（usedPct 为百分比，可能带 1 位小数）。 */
export class AgentStateContext {
    usedTokens: number = 0
    windowTokens: number = 0
    usedPct: number = 0
}

/** speed 计量：本轮生成速度。 */
export class AgentStateSpeed {
    tokensPerSec: number = 0
    ttftMs: number = 0
}

/** turn 计量：本轮输入/输出 token。 */
export class AgentStateTurn {
    inputTokens: number = 0
    outputTokens: number = 0
    cacheHitTokens: number = 0
    durationMs: number = 0
}

/** usage 计量：会话累计 token 用量。 */
export class AgentStateUsage {
    promptTokens: number = 0
    outputTokens: number = 0
    cacheReadTokens: number = 0
    cacheWriteTokens: number = 0
    totalTokens: number = 0
}

export class AgentState {
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
    // 当前 Agent 会话 ID（回合开始时由插件写入；切目录/重置后为新会话 ID；旧数据/未设置时为空字符串）。
    // 用于与 type=2 统计的 sessionId 比对：不一致 = 旧会话残留统计，不展示
    sessionId: string = ''
}

/** Token/上下文计量（scope=31 type=2 独立通道，键 ..._2）：回合结束必推，独立于状态推送。 */
export class AgentMetrics {
    context: AgentStateContext | null = null
    cacheHitRatePct: number = 0
    speed: AgentStateSpeed | null = null
    turn: AgentStateTurn | null = null
    usage: AgentStateUsage | null = null
    // 统计生成时间戳（毫秒），用于排查/调试
    metricsAt: number = 0
    // 统计所属 Agent 会话 ID（插件回合结束必推）；与 type=1 状态（AgentState）sessionId
    // 不一致 = 切目录后旧会话残留统计，客户端不展示；旧数据/未设置时为空字符串
    sessionId: string = ''
}

const AGENT_STATE_TYPE = 1 // 1=状态（业务约定）
const AGENT_METRICS_TYPE = 2 // 2=Token 统计（独立通道，回合结束必推）
const AGENT_PANEL_TYPE = 3 // 3=AI 面板数据（207 query 组合查询结果，面板打开/更新后刷新）

/** scope=31 key 前缀：`<convType>-<line>-<target>_<type>_`（v2 服务端在其后追加机器人 uid）。 */
function agentSlotPrefix(conversation: Conversation, slot: number): string {
    return `${conversation.type}-${conversation.line}-${conversation.target}_${slot}_`
}

/** 按 key 前缀查询 scope=31 设置表（SDK getUserSettingsLike，native 只返回 key 以 prefix 开头的条目，避免拉全量再筛选）。 */
function settingEntriesByPrefix(prefix: string): UserSettingEntry[] {
    try {
        let entries = wfc.getUserSettingsLike(UserSettingScope.Conversation_User_Setting, prefix)
        if (!entries) {
            return []
        }
        return entries
    } catch (e) {
        // 忽略：底层不可用时按"无状态"处理
        return []
    }
}

/** 返回首个 key 以 prefix 开头的 value；无匹配返回空串。 */
function findSettingByPrefix(prefix: string): string {
    let entries = settingEntriesByPrefix(prefix)
    for (let i = 0; i < entries.length; i++) {
        let key = entries[i].key
        if (key && key.startsWith(prefix)) {
            return entries[i].value
        }
    }
    return ''
}

/**
 * AI/Agent 会话类型：'single'（line 2 单聊）/ 'group'（line 2 群聊）/ ''（非 AI 会话）。
 * 判断依据：会话 line === 2（AI 消息统一使用 line 2，普通消息 line 0，朋友圈 line 1）；
 * 不依赖 userInfo.type === 1（机器人），群 extra {"dsh":true} 标记已彻底移除、不再使用。
 */
export function agentConversationKind(conversation?: Conversation): string {
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
 * 是否 Agent 会话（判断依据：conversation.line === 2）。
 * 非 Agent 会话不查询/不展示 Agent 状态。
 */
export function isAgentConversation(conversation?: Conversation): boolean {
    return agentConversationKind(conversation) !== ''
}

/** 读取会话的 Agent 运行时状态，未设置/非法时返回 null。 */
export function getAgentState(conversation?: Conversation): AgentState | null {
    if (!conversation || !isAgentConversation(conversation)) {
        return null
    }
    try {
        let raw = findSettingByPrefix(agentSlotPrefix(conversation, AGENT_STATE_TYPE))
        if (!raw) {
            return null
        }
        let parsed = JSON.parse(raw) as AgentState
        return parsed && parsed.state ? parsed : null
    } catch (e) {
        return null
    }
}

/** 读取会话的 Agent Token 统计（scope=31 type=2 计量），未设置/非法时返回 null。 */
export function getAgentMetrics(conversation?: Conversation): AgentMetrics | null {
    if (!conversation || !isAgentConversation(conversation)) {
        return null
    }
    try {
        let raw = findSettingByPrefix(agentSlotPrefix(conversation, AGENT_METRICS_TYPE))
        if (!raw) {
            return null
        }
        let parsed = JSON.parse(raw) as AgentMetrics
        // 至少含一个计量子对象才视为有效统计（容错：解析为 null/空对象/非对象时返回 null）
        return parsed && (parsed.context || parsed.speed || parsed.turn || parsed.usage) ? parsed : null
    } catch (e) {
        return null
    }
}

/** 面板模型可选项：{value: "provider/id", label: "provider/id（名）"}。 */
export class AgentPanelModelOption {
    value: string = ''
    label: string = ''
}

/** 面板模型段：当前值 + 可选目录。 */
export class AgentPanelModel {
    current: string = ''
    options: AgentPanelModelOption[] = []
}

/** 面板推理等级段：当前值 + 可选项（如 ["low","medium","high"]）。 */
export class AgentPanelEffort {
    current: string = ''
    options: string[] = []
}

/** 面板沙箱段：当前值 + 可选项（如 ["read-only","workspace-write","danger-full-access"]）。 */
export class AgentPanelSandbox {
    current: string = ''
    options: string[] = []
}

/** 面板计划模式段。 */
export class AgentPanelPlan {
    on: boolean = false
}

/**
 * AI 面板数据（scope=31 type=3，键 ..._3）：207 AGENT_Command query 组合查询结果。
 * 结构：model/effort/sandbox/plan/cwd/sessionId/dirs（dirs 已废弃，仅兼容老插件）。
 */
export class AgentPanelData {
    model: AgentPanelModel | null = null
    effort: AgentPanelEffort | null = null
    sandbox: AgentPanelSandbox | null = null
    plan: AgentPanelPlan | null = null
    cwd: string = ''
    sessionId: string = ''
    // 项目根目录子目录（cwd 切换候选）。新插件已从 type=3 移除 dirs（改走 207 op=dirs +
    // 209 AGENT_COMMAND_RESULT 按需应答，见 INTERACTION_DESIGN.md §10）；此字段仅用于
    // 兼容老插件（仍内联 dirs 时直接用），新插件下通常为空
    dirs: string[] = []
}

/**
 * 读取会话的 AI 面板数据（scope=31 type=3，键 ..._3），未设置/非法时返回 null。
 * 面板打开时先读已有数据渲染，再发 207 query 让插件刷新；面板监听设置更新事件重读。
 */
export function getAgentPanelData(conversation?: Conversation): AgentPanelData | null {
    if (!conversation || !isAgentConversation(conversation)) {
        return null
    }
    try {
        let raw = findSettingByPrefix(agentSlotPrefix(conversation, AGENT_PANEL_TYPE))
        if (!raw) {
            return null
        }
        return parseAgentPanelRaw(raw)
    } catch (e) {
        return null
    }
}

/** type=3 原始 JSON → AgentPanelData（解析失败返回 null）。 */
function parseAgentPanelRaw(raw: string): AgentPanelData | null {
    if (!raw) {
        return null
    }
    try {
        let parsed = JSON.parse(raw) as Record<string, Object>
        if (!parsed) {
            return null
        }
        let data = new AgentPanelData()
        let model = parsed['model'] as Record<string, Object>
        if (model) {
            let m = new AgentPanelModel()
            m.current = model['current'] as string || ''
            let options = model['options'] as Record<string, Object>[]
            if (options) {
                for (const opt of options) {
                    let o = new AgentPanelModelOption()
                    o.value = opt['value'] as string || ''
                    o.label = opt['label'] as string || o.value
                    m.options.push(o)
                }
            }
            data.model = m
        }
        let effort = parsed['effort'] as Record<string, Object>
        if (effort) {
            let e = new AgentPanelEffort()
            e.current = effort['current'] as string || ''
            e.options = (effort['options'] as string[]) || []
            data.effort = e
        }
        let sandbox = parsed['sandbox'] as Record<string, Object>
        if (sandbox) {
            let s = new AgentPanelSandbox()
            s.current = sandbox['current'] as string || ''
            s.options = (sandbox['options'] as string[]) || []
            data.sandbox = s
        }
        let plan = parsed['plan'] as Record<string, Object>
        if (plan) {
            let p = new AgentPanelPlan()
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
export function agentStateText(state: AgentState | null): string {
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
 * agentStatusHint（type=1 状态），不在此处。
 * 各段用 " · " 连接；返回 '' 表示没有可展示的统计（不占位）。
 * 数值均以 typeof === 'number' 判有，避免把字符串当数字；cacheHitRatePct 为 0 也要显示。
 */
export function agentMetricsText(metrics: AgentMetrics | null): string {
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
export function agentStatusHint(state: AgentState | null): string {
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
export function agentStateColor(state: string): ResourceColor {
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

// ===================== 多机器人（多 agent）会话支持 =====================
/**
 * 会话内单个机器人的（type=1 状态 + type=2 计量）分组。
 * 结构对齐 PC 端 getAgentRobotStates 的返回项 {uid, state, metrics}。
 */
export class AgentRobotStateRow {
    // 机器人完整 uid（robot_xxx_yyy，完整不截断）
    uid: string = ''
    // type=1 状态（无有效状态时 null，行不参与展示）
    state: AgentState | null = null
    // type=2 Token 统计（可能为 null）
    metrics: AgentMetrics | null = null
}

/** type=1 状态原始 JSON → AgentState（无有效状态返回 null，对齐 getAgentState 语义）。 */
function parseAgentStateRaw(raw: string): AgentState | null {
    if (!raw) {
        return null
    }
    try {
        let parsed = JSON.parse(raw) as AgentState
        return parsed && parsed.state ? parsed : null
    } catch (e) {
        return null
    }
}

/** type=2 计量原始 JSON → AgentMetrics（对齐 getAgentMetrics 语义：至少含一个计量子对象才有效）。 */
function parseAgentMetricsRaw(raw: string): AgentMetrics | null {
    if (!raw) {
        return null
    }
    try {
        let parsed = JSON.parse(raw) as AgentMetrics
        return parsed && (parsed.context || parsed.speed || parsed.turn || parsed.usage) ? parsed : null
    } catch (e) {
        return null
    }
}

/** 去重追加（保持插入序；ArkTS 禁 Set 泛型依赖时用数组线性去重，条目数很少）。 */
function addUnique(list: string[], value: string): void {
    if (value && list.indexOf(value) < 0) {
        list.push(value)
    }
}

/**
 * 机器人显示名：走用户信息接口/缓存（robot 是特殊用户）。
 * 取 userInfo.displayName/name；取不到时回退完整 uid —— 不截断 robot_xxx_yyy 的多段 id。
 */
export function agentRobotName(uid: string): string {
    if (!uid) {
        return ''
    }
    try {
        let u = wfc.getUserInfo(uid, false)
        let n = u && (u.displayName || u.name)
        if (n) {
            return n
        }
    } catch (e) {
        // 忽略：按回退处理
    }
    return uid
}

/**
 * 列出会话内“有状态推送”的机器人 uid 列表（按 scope=31 type=1 条目键后缀，完整 uid）。
 * 说明：机器人首次在该会话活动（推送状态）后才会出现；
 * 兜底：群聊中按“机器人成员”（memberId 以 robot_ / robot- 开头）补齐——让尚未推送
 * 过状态、但已在本群的机器人也能出现在选择列表（对齐 PC 端 listAgentRobotUids）。
 */
export function listAgentRobotUids(conversation?: Conversation): string[] {
    if (!conversation || !conversation.target) {
        return []
    }
    const prefix = agentSlotPrefix(conversation, AGENT_STATE_TYPE)
    const uids: string[] = []
    for (const e of settingEntriesByPrefix(prefix)) {
        if (e.key && e.key.startsWith(prefix)) {
            addUnique(uids, e.key.slice(prefix.length))
        }
    }
    if (conversation.type === ConversationType.Group) {
        try {
            let members = wfc.getGroupMembers(conversation.target, false)
            for (const m of members) {
                let id = m ? m.memberId : ''
                if (id && (id.startsWith('robot_') || id.startsWith('robot-'))) {
                    addUnique(uids, id)
                }
            }
        } catch (e) {
            // 群成员读取失败忽略（已有 scope=31 条目的机器人仍可列出）
        }
    }
    uids.sort((a: string, b: string): number => (a < b ? -1 : 1))
    return uids
}

/**
 * 读取会话内每个机器人的（type=1 状态 + type=2 计量），按机器人分组。
 * 返回 [{uid, state, metrics}]（按 uid 排序；无条目/非 AI 会话返回空数组；
 * 只有有效状态（state.state 非空）的机器人计入，对齐 PC 端 getAgentRobotStates）。
 */
export function getAgentRobotStates(conversation?: Conversation): AgentRobotStateRow[] {
    if (!conversation || !conversation.target || !isAgentConversation(conversation)) {
        return []
    }
    const stateRaw: Map<string, string> = new Map()
    const metricsRaw: Map<string, string> = new Map()
    const keys: string[] = []
    const p1 = agentSlotPrefix(conversation, AGENT_STATE_TYPE)
    const p2 = agentSlotPrefix(conversation, AGENT_METRICS_TYPE)
    // type=1 状态 / type=2 计量分别按前缀查询（native 已过滤，避免拉全量再筛选）
    for (const e of settingEntriesByPrefix(p1)) {
        if (!e.key || !e.key.startsWith(p1)) {
            continue
        }
        let uid = e.key.slice(p1.length)
        if (uid) {
            addUnique(keys, uid)
            stateRaw.set(uid, e.value)
        }
    }
    for (const e of settingEntriesByPrefix(p2)) {
        if (!e.key || !e.key.startsWith(p2)) {
            continue
        }
        let uid = e.key.slice(p2.length)
        if (uid) {
            addUnique(keys, uid)
            metricsRaw.set(uid, e.value)
        }
    }
    const out: AgentRobotStateRow[] = []
    for (const uid of keys) {
        let state = parseAgentStateRaw(stateRaw.get(uid) as string)
        // 只统计有有效状态的机器人（无状态的 uid 不展示）
        if (!state || !state.state) {
            continue
        }
        let row = new AgentRobotStateRow()
        row.uid = uid
        row.state = state
        row.metrics = parseAgentMetricsRaw(metricsRaw.get(uid) as string)
        out.push(row)
    }
    out.sort((a: AgentRobotStateRow, b: AgentRobotStateRow): number => (a.uid < b.uid ? -1 : 1))
    return out
}

/**
 * 读取指定机器人的 type=3 面板数据（键 `<前缀>_3_<robotUid>`）。
 * robotUid 为空时取会话默认（键前缀扫描第一条），对齐 PC 端 getAgentPanelDataFor。
 */
export function getAgentPanelDataFor(conversation?: Conversation, robotUid: string = ''): AgentPanelData | null {
    if (!conversation || !conversation.target) {
        return null
    }
    const prefix = agentSlotPrefix(conversation, AGENT_PANEL_TYPE)
    if (robotUid) {
        // 精确匹配：单键查询，避免全量读取再筛选
        try {
            let raw = wfc.getUserSetting(UserSettingScope.Conversation_User_Setting, prefix + robotUid)
            return raw ? parseAgentPanelRaw(raw) : null
        } catch (e) {
            return null
        }
    }
    try {
        let raw = findSettingByPrefix(prefix)
        return raw ? parseAgentPanelRaw(raw) : null
    } catch (e) {
        return null
    }
}

/**
 * 多机器人标题逐列展示的机器人状态文案（对齐 PC 端 ConversationView robotStatusRows 的 textMap）：
 * running→运行中 / waiting_user→等待确认 / thinking→思考中 / done·idle→空闲；reason=error→错误。
 * 未知/缺省状态兜底返回“空闲”。
 */
export function agentRobotStatusText(state: AgentState | null): string {
    if (!state) {
        return '空闲'
    }
    if (state.reason === 'error') {
        return '错误'
    }
    const map: Record<string, string> = {
        'running': '运行中',
        'waiting_user': '等待确认',
        'thinking': '思考中',
        'done': '空闲',
        'idle': '空闲'
    }
    return map[state.state] || '空闲'
}
