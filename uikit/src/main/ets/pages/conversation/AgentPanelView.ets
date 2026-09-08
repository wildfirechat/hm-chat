/*
 * AgentPanelView.ets — AI 会话设置面板（第一层 Agent 可改属性，统一交互风格）。
 * 交互对齐 vue-pc-chat 的 AgentPanel.vue：
 *   模型/推理等级 = 下拉选择（Select）；沙箱模式 = 水平单选（Radio）；
 *   工作目录 = 「切换」弹出独立目录选择界面（bindSheet 二级弹窗）；计划模式 = 开关（Toggle）。
 * 展示方式：父组件以 Stack 内联覆盖呈现（遮罩 + 居中卡片），本面板为居中卡片（窗口样式）。
 * 静默通道：打开面板发 AGENT_Command(207) query（组合查询）→ 插件聚合面板数据写
 * scope=31 type=3 → 本面板读 type=3 渲染（模型/推理等级/沙箱/计划/cwd）。
 * 所有操作发 AGENT_Command(207) set（cmd=命令文本），插件执行后写 type=1 lastChange
 * （标题栏变更可见）+ 刷新 type=3；本面板监听 SettingUpdate 设置更新事件重读 type=3。
 * 目录列表按需获取（INTERACTION_DESIGN.md §10）：type=3 不再带 dirs；点「切换」时发 207
 * {op:"dirs",seq,robotId}，插件用 209 AGENT_COMMAND_RESULT（透明消息）回传 dirs，本面板按
 * seq 匹配 pending（超时 5s 重试 1 次，仍失败提示重试 + 手动输入路径兜底；老插件无应答时
 * 回退读 type=3 的 dirs）。
 * 207/209 均为透明消息：不落库、不显示在消息流（digest 为空）。
 */
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import AgentCommandMessageContent from '@wfc/client/src/main/ets/wfc/messages/agentCommandMessageContent'
import AgentCommandResultMessageContent from '@wfc/client/src/main/ets/wfc/messages/agentCommandResultMessageContent'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import { AgentPanelData, agentRobotName, getAgentPanelDataFor } from '../../util/agentState'
import { FontSize, Radius } from '../../common/design/Tokens'

// 目录列表缓存 TTL（同一面板实例内；过期或目标机器人变化后重新请求 207 op=dirs）
const DIRS_CACHE_TTL: number = 60 * 1000
// 207 op=dirs 应答等待超时（5s 超时重试 1 次）
const DIRS_TIMEOUT: number = 5000
// 目录请求最大尝试次数（首次 + 重试 1 次）
const DIRS_MAX_ATTEMPTS: number = 2

// 单选可选项（模型/推理等级）
interface AgentOption {
    value: string
    label: string
}

// 沙箱模式固定三项（type=3 sandbox.options 为空时的兜底，与插件 SANDBOX_MODES 一致）
const SANDBOX_MODES: AgentOption[] = [
    { value: 'read-only', label: '只读' },
    { value: 'workspace-write', label: '仅写工作区' },
    { value: 'danger-full-access', label: '完全放开' }
]

// 沙箱可选项 value → 中文展示（无映射时直接显示 value）
function sandboxLabel(value: string): string {
    for (const m of SANDBOX_MODES) {
        if (m.value === value) {
            return m.label
        }
    }
    return value
}

// AgentOption[] → Select 下拉选项（SelectOption 为接口，用对象字面量构造）
function toSelectOptions(options: AgentOption[]): SelectOption[] {
    let result: SelectOption[] = []
    for (const o of options) {
        let opt: SelectOption = { value: o.label }
        result.push(opt)
    }
    return result
}

@Component
export default struct AgentPanelView {
    // 面板所属会话（由父组件传入；默认值仅满足 ArkTS 必初始化约束）
    conversation: Conversation = new Conversation(ConversationType.Single, '', 0)
    // 目标机器人（多机器人会话寻址；空 = 会话默认机器人）。面板数据按该机器人读取、
    // 207 指令带 robotId；父组件切换目标时（@Watch）重读 type=3 并补发 query 刷新
    @Prop @Watch('onRobotUidChanged') robotUid: string = ''
    // 关闭面板的回调（父组件 Stack 移除本组件，这里用于面板内「×」按钮与遮罩点击）
    dismiss?: () => void
    // type=3 面板数据（模型/推理等级/沙箱/计划/cwd/目录列表），赋值即触发重建
    @State panelData: AgentPanelData | null = null
    @State applying: boolean = false
    // 目录选择弹窗（bindSheet 二级弹窗）是否打开
    @State showCwdPicker: boolean = false
    private flashTimer: number = -1
    // 207 请求序号（防重/排查用，自增）
    private seq: number = 0

    // ─── type=3 派生值：ArkTS getter 不响应 @State，改为 @State 字段由 refreshPanelData 填充 ───
    @State currentModel: string = ''
    @State modelOptions: AgentOption[] = []
    @State modelSelectOptions: SelectOption[] = []
    @State currentEffort: string = ''
    @State effortOptions: AgentOption[] = []
    @State effortSelectOptions: SelectOption[] = []
    @State currentCwd: string = ''
    @State currentSandbox: string = ''
    @State sandboxOptions: AgentOption[] = SANDBOX_MODES
    @State planOn: boolean = false
    @State cwdCandidates: string[] = []
    // 目录列表加载态（207 op=dirs 已发出、等待 209 应答）
    @State cwdLoading: boolean = false
    // 目录列表失败提示（超时重试后仍无应答且无 type=3 回退时展示）
    @State cwdError: string = ''
    // 手动输入路径兜底（点「确定」发 207 set /cwd <路径>）
    @State manualCwd: string = ''
    // 面板标题附注（多机器人时显示目标机器人名，如 "AI 会话设置 · 机器人名"）
    @State robotTitleNote: string = ''
    // 目录列表缓存（同一面板实例内 TTL 60s；按目标机器人区分）
    private dirsCache: string[] = []
    private dirsCacheAt: number = 0
    private dirsCacheRobot: string = ''
    // pending 请求表：seq → 发起时间戳（同一会话可多个 pending；未匹配/已超时的应答丢弃）
    private dirsPending: Map<number, number> = new Map<number, number>()
    // 目录请求令牌：重试/切换机器人后旧超时回调失效（避免误判当前请求超时）
    private dirsToken: number = 0
    private dirsTimer: number = -1

    aboutToAppear() {
        // 设置更新事件：插件执行更新/组合查询后写 type=3，重读刷新
        wfc.eventEmitter?.on(EventType.SettingUpdate, this.onSettingUpdate)
        // 209 应答（透明消息）：按 seq 匹配 pending 目录请求
        wfc.eventEmitter?.on(EventType.ReceiveMessage, this.onReceiveMessage)
        this.updateRobotTitleNote()
        // 先读已有面板数据（若有），再发组合查询刷新
        this.refreshPanelData()
        this.sendCommand('query')
    }

    aboutToDisappear() {
        wfc.eventEmitter?.off(EventType.SettingUpdate, this.onSettingUpdate)
        wfc.eventEmitter?.off(EventType.ReceiveMessage, this.onReceiveMessage)
        clearTimeout(this.flashTimer)
        // 清空 pending 与超时定时器，避免面板关闭后回调持有引用（内存泄漏）
        clearTimeout(this.dirsTimer)
        this.dirsTimer = -1
        this.dirsToken++
        this.dirsPending.clear()
    }

    /** 目标机器人（@Prop）变化：重读该机器人的 type=3 并补发组合查询（一般由父组件重新创建本面板触发）。 */
    onRobotUidChanged() {
        this.updateRobotTitleNote()
        // 目标机器人变了：目录缓存与在途请求全部作废（应答按 robotId 校验，不跨机器人复用）
        this.resetDirsState()
        this.refreshPanelData()
        this.sendCommand('query')
    }

    /** 清空目录缓存/在途请求/加载态（切换目标机器人或面板重建时）。 */
    resetDirsState() {
        clearTimeout(this.dirsTimer)
        this.dirsTimer = -1
        this.dirsToken++
        this.dirsPending.clear()
        this.dirsCache = []
        this.dirsCacheAt = 0
        this.dirsCacheRobot = ''
        this.cwdCandidates = []
        this.cwdLoading = false
        this.cwdError = ''
    }

    /** 面板标题附注：robotUid 非空时显示机器人显示名（名称缺失回退完整 uid，不截断）。 */
    updateRobotTitleNote() {
        this.robotTitleNote = this.robotUid ? agentRobotName(this.robotUid) : ''
    }

    /** 设置更新（scope=31 会话级用户设置变化，type=3 刷新即触发）：重读目标机器人的面板数据。 */
    onSettingUpdate = () => {
        this.refreshPanelData()
    }

    /**
     * 收到消息：挑出本会话的 209 AGENT_COMMAND_RESULT（透明消息）作为目录请求的应答。
     * 只接受 op=dirs 且 seq 命中 pending 的应答；未匹配/已超时的应答丢弃；
     * 应答带 robotId 且与当前面板目标机器人不一致时丢弃（多机器人会话串答保护）。
     */
    onReceiveMessage = (messages: Message[]) => {
        if (!messages || messages.length === 0) {
            return
        }
        for (const message of messages) {
            if (!message || !message.messageContent) {
                continue
            }
            if (message.messageContent.type !== MessageContentType.AGENT_COMMAND_RESULT) {
                continue
            }
            if (!Conversation.equal(message.conversation, this.conversation)) {
                continue
            }
            let content = message.messageContent as AgentCommandResultMessageContent
            if (content.op !== 'dirs') {
                continue
            }
            if (!this.dirsPending.has(content.seq)) {
                continue
            }
            if (content.robotId && this.robotUid && content.robotId !== this.robotUid) {
                continue
            }
            this.dirsPending.delete(content.seq)
            this.onDirsResult(content.dirs)
        }
    }

    /** 209 应答命中 pending：渲染目录候选并写入缓存（TTL 60s，按目标机器人区分）。 */
    onDirsResult(dirs: string[]) {
        let list: string[] = dirs ? dirs : []
        this.cwdCandidates = list
        this.dirsCache = list
        this.dirsCacheAt = Date.now()
        this.dirsCacheRobot = this.robotUid
        this.cwdLoading = false
        this.cwdError = ''
        clearTimeout(this.dirsTimer)
        this.dirsTimer = -1
    }

    /**
     * 请求目录列表：发 207 {op:"dirs", seq, robotId}（透明消息），等 209 应答。
     * attempt=1 为首次请求；超时 5s 仍无匹配应答则重试一次（attempt=2）；仍失败走 onDirsTimeout。
     */
    requestDirs(attempt: number) {
        if (attempt <= 1) {
            // 新的一轮目录请求：作废旧的在途请求（避免 pending 表堆积 / 旧应答串入）
            this.dirsPending.clear()
            this.cwdLoading = true
            this.cwdError = ''
        }
        let seq = this.nextSeq()
        this.dirsToken++
        let token = this.dirsToken
        this.dirsPending.set(seq, Date.now())
        wfc.sendConversationMessage(this.conversation,
            new AgentCommandMessageContent('dirs', '', seq, this.robotUid))
        clearTimeout(this.dirsTimer)
        this.dirsTimer = setTimeout(() => {
            // 令牌不匹配 = 已被新请求/关闭/切换机器人作废，丢弃本次超时回调
            if (token !== this.dirsToken) {
                return
            }
            this.dirsPending.delete(seq)
            if (attempt < DIRS_MAX_ATTEMPTS) {
                this.requestDirs(attempt + 1)
                return
            }
            this.onDirsTimeout()
        }, DIRS_TIMEOUT)
    }

    /** 超时重试后仍无应答：回退读 type=3 的 dirs（老插件），为空则提示失败（保留手动输入路径兜底）。 */
    onDirsTimeout() {
        this.dirsTimer = -1
        this.cwdLoading = false
        this.dirsPending.clear()
        let fallback = this.dirsFromType3()
        if (fallback.length > 0) {
            this.cwdCandidates = fallback
            this.dirsCache = fallback
            this.dirsCacheAt = Date.now()
            this.dirsCacheRobot = this.robotUid
            this.cwdError = ''
            return
        }
        this.cwdCandidates = []
        this.cwdError = '获取目录失败，请重试'
    }

    /** 兼容老插件：读 type=3 面板数据里可能仍内联的 dirs（新插件已移除，返回空列表）。 */
    dirsFromType3(): string[] {
        let data = getAgentPanelDataFor(this.conversation, this.robotUid)
        if (data && data.dirs && data.dirs.length > 0) {
            return data.dirs
        }
        return []
    }

    /** 「重新获取」：作废缓存与在途请求，重新发 207 op=dirs。 */
    retryDirs() {
        clearTimeout(this.dirsTimer)
        this.dirsTimer = -1
        this.dirsToken++
        this.dirsPending.clear()
        this.dirsCache = []
        this.dirsCacheAt = 0
        this.cwdError = ''
        this.requestDirs(1)
    }

    refreshPanelData() {
        let data = getAgentPanelDataFor(this.conversation, this.robotUid)
        if (!data) {
            return
        }
        this.currentModel = data.model ? data.model.current : ''
        let mopts: AgentOption[] = []
        if (data.model && data.model.options && data.model.options.length > 0) {
            for (const o of data.model.options) {
                mopts.push({ value: o.value, label: o.label || o.value })
            }
            // 当前模型不在候选时补入（保证可选中/显示）
            if (this.currentModel && !mopts.some(x => x.value === this.currentModel)) {
                mopts.unshift({ value: this.currentModel, label: this.currentModel + '（当前）' })
            }
        }
        this.modelOptions = mopts
        this.modelSelectOptions = toSelectOptions(mopts)
        this.currentEffort = data.effort ? data.effort.current : ''
        let eopts: AgentOption[] = []
        if (data.effort && data.effort.options && data.effort.options.length > 0) {
            for (const v of data.effort.options) {
                eopts.push({ value: v, label: v })
            }
            // 当前推理等级不在候选时补入（保证可选中/显示）
            if (this.currentEffort && !eopts.some(x => x.value === this.currentEffort)) {
                eopts.unshift({ value: this.currentEffort, label: this.currentEffort + '（当前）' })
            }
        }
        this.effortOptions = eopts
        this.effortSelectOptions = toSelectOptions(eopts)
        this.currentCwd = data.cwd ? data.cwd : ''
        this.currentSandbox = data.sandbox ? data.sandbox.current : ''
        let sopts: AgentOption[] = []
        if (data.sandbox && data.sandbox.options && data.sandbox.options.length > 0) {
            for (const v of data.sandbox.options) {
                sopts.push({ value: v, label: sandboxLabel(v) })
            }
        }
        this.sandboxOptions = sopts.length > 0 ? sopts : SANDBOX_MODES
        this.planOn = data.plan ? !!data.plan.on : false
        // 目录列表：type=3 已不再内联 dirs（改走 207 op=dirs / 209 应答，见 §10）；
        // 兼容老插件（仍带 dirs）直接使用并写入缓存，且不覆盖已拿到的 209 结果
        let dirs = data.dirs ? data.dirs : []
        if (dirs.length > 0) {
            this.cwdCandidates = dirs
            this.dirsCache = dirs
            this.dirsCacheAt = Date.now()
            this.dirsCacheRobot = this.robotUid
        }
    }

    /** 207 请求序号（自增；防重/排查，并用于 209 应答关联）。 */
    nextSeq(): number {
        this.seq = (this.seq + 1) % 100000
        return this.seq
    }

    /** 发送 207 面板指令（透明消息，不显示在消息流）；带目标机器人 robotId（多机器人寻址）。 */
    sendCommand(op: string, cmd: string = '') {
        wfc.sendConversationMessage(this.conversation,
            new AgentCommandMessageContent(op, cmd, this.nextSeq(), this.robotUid))
    }

    // ─── 操作：207 set（cmd=命令文本，插件执行后写 lastChange + 刷新 type=3） ───
    selectModel(value: string) {
        if (!value || this.applying) {
            return
        }
        this.sendCommand('set', `/model ${value}`)
        this.flash()
    }

    selectEffort(value: string) {
        if (!value || this.applying) {
            return
        }
        this.sendCommand('set', `/effort ${value}`)
        this.flash()
    }

    selectSandbox(value: string) {
        if (!value || this.applying || value === this.currentSandbox) {
            return
        }
        this.sendCommand('set', `/sandbox ${value}`)
        this.flash()
    }

    togglePlan(on: boolean) {
        if (this.applying) {
            return
        }
        this.sendCommand('set', `/plan ${on ? 'on' : 'off'}`)
        this.flash()
    }

    /** 点击「切换」：弹出独立目录选择界面。缓存命中（同一面板实例、同一目标机器人、TTL 60s 内）
     *  直接用；否则发 207 op=dirs 并显示加载态，等 209 应答。 */
    openCwdPicker() {
        if (this.applying) {
            return
        }
        this.showCwdPicker = true
        this.cwdError = ''
        if (this.dirsCache.length > 0 && this.dirsCacheRobot === this.robotUid
            && Date.now() - this.dirsCacheAt < DIRS_CACHE_TTL) {
            this.cwdCandidates = this.dirsCache
            this.cwdLoading = false
            return
        }
        this.requestDirs(1)
    }

    /** 点击候选目录：发 207 set /cwd 目录名，关闭弹窗；当前值随后由 type=3 刷新。 */
    switchCwd(dir: string) {
        if (!dir || this.applying) {
            return
        }
        this.sendCommand('set', `/cwd ${dir}`)
        this.showCwdPicker = false
        this.flash()
    }

    /** 手动输入路径兜底：发 207 set /cwd <路径>（相对路径由插件按项目根解析）。 */
    switchCwdManual() {
        let path = this.manualCwd ? this.manualCwd.trim() : ''
        if (!path || this.applying) {
            return
        }
        this.sendCommand('set', `/cwd ${path}`)
        this.manualCwd = ''
        this.showCwdPicker = false
        this.flash()
    }

    compact() {
        if (this.applying) {
            return
        }
        AlertDialog.show({
            message: '压缩会话上下文（折叠历史，减少 token 占用），继续？',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            primaryButton: {
                value: '取消',
                action: () => {
                }
            },
            secondaryButton: {
                value: '确定',
                fontColor: $r('app.color.wf_primary'),
                action: () => {
                    this.sendCommand('set', '/compact')
                    this.flash()
                }
            }
        })
    }

    resetSession() {
        if (this.applying) {
            return
        }
        AlertDialog.show({
            message: '重置会话将清空全部上下文（工作目录保留），继续？',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            primaryButton: {
                value: '取消',
                action: () => {
                }
            },
            secondaryButton: {
                value: '确定',
                fontColor: $r('app.color.wf_danger'),
                action: () => {
                    this.sendCommand('set', '/reset')
                    this.flash()
                }
            }
        })
    }

    /** 销毁会话：毁灭性操作（解散群组 + 销毁会话 + 删除工作区目录 + 清注册），
     *  单次强警告确认（确认后才发 207 set /destroy）；不随操作冷却禁用，始终可点。 */
    destroySession() {
        AlertDialog.show({
            message: '⚠️ 销毁会话将解散本群、删除工作区目录及全部会话数据，且不可恢复！\n\n请确认是否销毁？',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            primaryButton: {
                value: '取消',
                action: () => {
                }
            },
            secondaryButton: {
                value: '确定',
                fontColor: $r('app.color.wf_danger'),
                action: () => {
                    this.sendCommand('set', '/destroy')
                    this.flash()
                }
            }
        })
    }

    // 发送后短暂禁用（防连点），1.5s 后恢复
    flash() {
        this.applying = true
        clearTimeout(this.flashTimer)
        this.flashTimer = setTimeout(() => {
            this.applying = false
        }, 1500)
    }

    // ─── Select 辅助：当前值在候选中的索引 / 展示文案 ───
    modelSelectedIndex(): number {
        for (let i = 0; i < this.modelOptions.length; i++) {
            if (this.modelOptions[i].value === this.currentModel) {
                return i
            }
        }
        return 0
    }

    modelCurrentLabel(): string {
        for (const o of this.modelOptions) {
            if (o.value === this.currentModel) {
                return o.label
            }
        }
        return this.currentModel || '未获取到模型'
    }

    effortSelectedIndex(): number {
        for (let i = 0; i < this.effortOptions.length; i++) {
            if (this.effortOptions[i].value === this.currentEffort) {
                return i
            }
        }
        return 0
    }

    effortCurrentLabel(): string {
        for (const o of this.effortOptions) {
            if (o.value === this.currentEffort) {
                return o.label
            }
        }
        return this.currentEffort || '未获取到推理等级'
    }

    // 目录候选行：点选后发送 /cwd
    @Builder
    cwdRow(dir: string) {
        Row() {
            Text('📂')
                .fontSize(FontSize.sm)
            Text(dir)
                .fontSize(FontSize.sm)
                .fontColor($r('app.color.wf_primary_text'))
                .margin({ left: 8 })
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .constraintSize({ minHeight: 44 })
        .padding({ left: 12, right: 12 })
        .borderRadius(Radius.md)
        .stateStyles({
            pressed: {
                .backgroundColor($r('app.color.wf_item_pressed'))
            },
            normal: {
                .backgroundColor($r('app.color.wf_background'))
            }
        })
        .onClick(() => {
            this.switchCwd(dir)
        })
        .margin({ top: 4 })
    }

    // 分组标题
    @Builder
    sectionTitle(title: string) {
        Text(title)
            .fontSize(FontSize.sm)
            .fontColor($r('app.color.wf_tertiary_text'))
            .width('100%')
            .margin({ top: 12, bottom: 4 })
    }

    // ─── 工作目录选择弹窗（bindSheet 二级弹窗，独立目录选择界面） ───
    @Builder
    cwdPickerBuilder() {
        Column() {
            Row() {
                Text('📁 选择工作目录')
                    .fontSize(FontSize.md)
                    .fontColor($r('app.color.wf_primary_text'))
                    .layoutWeight(1)
                // 重新获取：作废缓存，重发 207 op=dirs
                Text('↻')
                    .fontSize(FontSize.md)
                    .fontColor($r('app.color.wf_primary'))
                    .padding({ left: 8, right: 8 })
                    .enabled(!this.cwdLoading)
                    .onClick(() => {
                        this.retryDirs()
                    })
                Text('×')
                    .fontSize(FontSize.lg)
                    .fontColor($r('app.color.wf_secondary_text'))
                    .padding({ left: 8, right: 8 })
                    .onClick(() => {
                        this.showCwdPicker = false
                    })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 8 })

            Divider()
                .color($r('app.color.wf_divider'))
                .width('100%')

            Text('切换目录 = 新会话（上下文清空）')
                .fontSize(FontSize.xs)
                .fontColor($r('app.color.wf_tertiary_text'))
                .width('100%')
                .padding({ left: 16, right: 16, top: 10 })

            Scroll() {
                Column() {
                    if (this.cwdLoading) {
                        // 加载态：207 op=dirs 已发出，等待 209 应答
                        Column() {
                            LoadingProgress()
                                .width(32)
                                .height(32)
                                .color($r('app.color.wf_primary'))
                            Text('正在获取目录列表…')
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_tertiary_text'))
                                .margin({ top: 8 })
                        }
                        .width('100%')
                        .constraintSize({ minHeight: 120 })
                        .justifyContent(FlexAlign.Center)
                        .alignItems(HorizontalAlign.Center)
                    } else if ((this.cwdCandidates ?? []).length === 0) {
                        Column() {
                            Text(this.cwdError ? this.cwdError : '未获取到目录列表')
                                .fontSize(FontSize.sm)
                                .fontColor(this.cwdError ? $r('app.color.wf_danger') : $r('app.color.wf_tertiary_text'))
                                .margin({ bottom: 4 })
                            Text('可点右上角 ↻ 重试，或在下方手动输入路径')
                                .fontSize(FontSize.xs)
                                .fontColor($r('app.color.wf_tertiary_text'))
                        }
                        .width('100%')
                        .constraintSize({ minHeight: 120 })
                        .justifyContent(FlexAlign.Center)
                        .alignItems(HorizontalAlign.Center)
                    } else {
                        ForEach(this.cwdCandidates ?? [], (dir: string) => {
                            this.cwdRow(dir)
                        }, (dir: string) => dir)
                    }
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 4, bottom: 16 })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)

            // 手动输入路径兜底（207 set /cwd <路径>；相对路径由插件按项目根解析）
            Divider()
                .color($r('app.color.wf_divider'))
                .width('100%')
            Row() {
                TextInput({ text: this.manualCwd, placeholder: '手动输入目录路径' })
                    .layoutWeight(1)
                    .height(40)
                    .fontSize(FontSize.sm)
                    .backgroundColor($r('app.color.wf_background'))
                    .borderRadius(Radius.sm)
                    .enabled(!this.applying)
                    .onChange((value: string) => {
                        this.manualCwd = value
                    })
                Button('确定')
                    .type(ButtonType.Normal)
                    .height(40)
                    .margin({ left: 8 })
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_primary'))
                    .backgroundColor($r('app.color.wf_background'))
                    .border({ width: 1, color: $r('app.color.wf_primary') })
                    .borderRadius(Radius.sm)
                    .enabled(!this.applying)
                    .onClick(() => {
                        this.switchCwdManual()
                    })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.wf_background'))
    }

    build() {
        // 全屏覆盖：Stack 内联渲染（不依赖 bindContentCover），遮罩 + 居中卡片
        Stack({ alignContent: Alignment.Center }) {
            // 半透明遮罩，点击关闭
            Column()
                .width('100%')
                .height('100%')
                .backgroundColor('#66000000')
                .onClick(() => {
                    this.dismiss?.()
                })

            // 居中卡片
            Column() {
                // 头部：标题（多机器人时附目标机器人名）+ 关闭按钮
                Row() {
                    Text(this.robotTitleNote ? `🤖 AI 设置 · ${this.robotTitleNote}` : '🤖 AI 设置')
                        .fontSize(FontSize.md)
                        .fontColor($r('app.color.wf_primary_text'))
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text('×')
                        .fontSize(FontSize.lg)
                        .fontColor($r('app.color.wf_secondary_text'))
                        .padding({ left: 8, right: 8 })
                        .onClick(() => {
                            this.dismiss?.()
                        })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 8 })

                Divider()
                    .color($r('app.color.wf_divider'))
                    .width('100%')

                Scroll() {
                    Column() {
                        // 1. 模型（下拉选择）
                        this.sectionTitle('模型')
                        if ((this.modelOptions ?? []).length === 0) {
                            Text('未获取到模型目录，可稍后重试')
                                .fontSize(FontSize.xs)
                                .fontColor($r('app.color.wf_tertiary_text'))
                                .margin({ top: 4, left: 12 })
                        } else {
                            Select(this.modelSelectOptions)
                                .selected(this.modelSelectedIndex())
                                .value(this.modelCurrentLabel())
                                .font({ size: FontSize.sm })
                                .fontColor($r('app.color.wf_primary_text'))
                                .selectedOptionFont({ size: FontSize.sm, weight: FontWeight.Medium })
                                .selectedOptionFontColor($r('app.color.wf_primary'))
                                .optionFont({ size: FontSize.sm })
                                .optionFontColor($r('app.color.wf_primary_text'))
                                .backgroundColor($r('app.color.wf_background'))
                                .borderRadius(Radius.md)
                                .width('100%')
                                .height(44)
                                .margin({ top: 4 })
                                .enabled(!this.applying)
                                .onSelect((index: number) => {
                                    let opt = this.modelOptions[index]
                                    if (opt) {
                                        this.selectModel(opt.value)
                                    }
                                })
                        }

                        // 2. 推理等级（下拉选择）
                        if ((this.effortOptions ?? []).length > 0) {
                            this.sectionTitle('推理等级')
                            Select(this.effortSelectOptions)
                                .selected(this.effortSelectedIndex())
                                .value(this.effortCurrentLabel())
                                .font({ size: FontSize.sm })
                                .fontColor($r('app.color.wf_primary_text'))
                                .selectedOptionFont({ size: FontSize.sm, weight: FontWeight.Medium })
                                .selectedOptionFontColor($r('app.color.wf_primary'))
                                .optionFont({ size: FontSize.sm })
                                .optionFontColor($r('app.color.wf_primary_text'))
                                .backgroundColor($r('app.color.wf_background'))
                                .borderRadius(Radius.md)
                                .width('100%')
                                .height(44)
                                .margin({ top: 4 })
                                .enabled(!this.applying)
                                .onSelect((index: number) => {
                                    let opt = this.effortOptions[index]
                                    if (opt) {
                                        this.selectEffort(opt.value)
                                    }
                                })
                        }

                        // 3. 工作目录（显示当前值 + 「切换」按钮 → 弹出目录选择界面）
                        this.sectionTitle('工作目录')
                        Row() {
                            Text(this.currentCwd || '未设置')
                                .fontSize(FontSize.sm)
                                .fontColor(this.currentCwd ? $r('app.color.wf_primary_text') : $r('app.color.wf_tertiary_text'))
                                .layoutWeight(1)
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                            Button('切换')
                                .type(ButtonType.Normal)
                                .height(36)
                                .margin({ left: 8 })
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_primary'))
                                .backgroundColor($r('app.color.wf_background'))
                                .border({ width: 1, color: $r('app.color.wf_primary') })
                                .borderRadius(Radius.sm)
                                .enabled(!this.applying)
                                .onClick(() => {
                                    this.openCwdPicker()
                                })
                        }
                        .width('100%')
                        .constraintSize({ minHeight: 40 })
                        .padding({ left: 12, right: 12 })
                        Text('切换目录 = 新会话（上下文清空）')
                            .fontSize(FontSize.xs)
                            .fontColor($r('app.color.wf_tertiary_text'))
                            .margin({ left: 12, top: 4 })

                        // 4. 沙箱模式（水平单选）
                        this.sectionTitle('沙箱模式')
                        Row() {
                            ForEach(this.sandboxOptions, (mode: AgentOption) => {
                                Row() {
                                    Radio({ value: mode.value, group: 'agentSandboxGroup' })
                                        .checked(this.currentSandbox === mode.value)
                                        .onChange((isChecked: boolean) => {
                                            if (isChecked) {
                                                this.selectSandbox(mode.value)
                                            }
                                        })
                                    Text(mode.label)
                                        .fontSize(FontSize.sm)
                                        .fontColor(this.currentSandbox === mode.value ?
                                            $r('app.color.wf_primary') : $r('app.color.wf_primary_text'))
                                        .margin({ left: 4 })
                                        .maxLines(1)
                                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                                }
                                .layoutWeight(1)
                                .constraintSize({ minHeight: 44 })
                                .justifyContent(FlexAlign.Start)
                                .padding({ left: 4 })
                                .onClick(() => {
                                    this.selectSandbox(mode.value)
                                })
                            }, (mode: AgentOption) => mode.value)
                        }
                        .width('100%')
                        .padding({ left: 8, right: 8 })

                        // 5. 计划模式（开关）
                        this.sectionTitle('计划模式')
                        Row() {
                            Text(this.planOn ? '已开启（先审后做）' : '已关闭')
                                .fontSize(FontSize.sm)
                                .fontColor(this.planOn ? $r('app.color.wf_primary') : $r('app.color.wf_primary_text'))
                                .layoutWeight(1)
                            Toggle({ type: ToggleType.Switch, isOn: this.planOn })
                                .enabled(!this.applying)
                                .onChange(isOn => {
                                    this.togglePlan(isOn)
                                })
                        }
                        .width('100%')
                        .constraintSize({ minHeight: 40 })
                        .padding({ left: 12, right: 12 })
                        .borderRadius(Radius.md)
                        .stateStyles({
                            pressed: {
                                .backgroundColor($r('app.color.wf_item_pressed'))
                            },
                            normal: {
                                .backgroundColor($r('app.color.wf_background'))
                            }
                        })
                        .onClick(() => {
                            this.togglePlan(!this.planOn)
                        })

                        // 6. 操作按钮
                        Row() {
                            Button('压缩上下文')
                                .type(ButtonType.Normal)
                                .layoutWeight(1)
                                .height(40)
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_primary_text'))
                                .backgroundColor($r('app.color.wf_background'))
                                .border({ width: 1, color: $r('app.color.wf_divider') })
                                .borderRadius(Radius.sm)
                                .enabled(!this.applying)
                                .onClick(() => {
                                    this.compact()
                                })
                            Button('重置会话')
                                .type(ButtonType.Normal)
                                .layoutWeight(1)
                                .height(40)
                                .margin({ left: 12 })
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_danger'))
                                .backgroundColor($r('app.color.wf_background'))
                                .border({ width: 1, color: $r('app.color.wf_danger') })
                                .borderRadius(Radius.sm)
                                .enabled(!this.applying)
                                .onClick(() => {
                                    this.resetSession()
                                })
                            // 销毁会话：红色实底、危险操作不随冷却禁用（确认后才发送）
                            Button('销毁会话')
                                .type(ButtonType.Normal)
                                .layoutWeight(1)
                                .height(40)
                                .margin({ left: 12 })
                                .fontSize(FontSize.sm)
                                .fontColor(Color.White)
                                .backgroundColor($r('app.color.wf_danger'))
                                .borderRadius(Radius.sm)
                                .onClick(() => {
                                    this.destroySession()
                                })
                        }
                        .width('100%')
                        .padding({ left: 12, right: 12, top: 16, bottom: 24 })
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .layoutWeight(1)
                .scrollBar(BarState.Off)

                if (this.applying) {
                    Text('指令已发送…')
                        .fontSize(FontSize.xs)
                        .fontColor($r('app.color.wf_primary'))
                        .width('100%')
                        .padding({ left: 16, bottom: 8 })
                }
            }
            .width('92%')
            // 高度按内容自适应（最高 86% 屏高）：原来固定 86% 会撑出大片上下留白；
            // 内容超长时由内部 Scroll 滚动（与「选择机器人」卡片同一套约束写法）
            .constraintSize({ maxWidth: 480, maxHeight: '86%' })
            .borderRadius(Radius.xl)
            .backgroundColor($r('app.color.wf_background'))
            .shadow({ radius: 24, color: '#33000000', offsetY: 8 })
            .clip(true)
            // 工作目录选择：二级弹窗
            .bindSheet(this.showCwdPicker, this.cwdPickerBuilder(), {
                height: '60%',
                dragBar: true,
                showClose: false,
                onDisappear: () => {
                    this.showCwdPicker = false
                }
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.wf_record_view_background_color'))
    }
}
