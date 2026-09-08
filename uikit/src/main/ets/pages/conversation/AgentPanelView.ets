/*
 * AgentPanelView.ets — AI 会话设置面板（第一层 Agent 可改属性，统一交互风格）。
 * 交互对齐 vue-pc-chat 的 AgentPanel.vue：
 *   模型/推理等级 = 下拉选择（Select）；沙箱模式 = 水平单选（Radio）；
 *   工作目录 = 「切换」弹出独立目录选择界面（bindSheet 二级弹窗）；计划模式 = 开关（Toggle）。
 * 展示方式：父组件以 Stack 内联覆盖呈现（遮罩 + 居中卡片），本面板为居中卡片（窗口样式）。
 * 静默通道：打开面板发 AGENT_Command(207) query（组合查询）→ 插件聚合面板数据写
 * scope=31 type=3 → 本面板读 type=3 渲染（模型/推理等级/沙箱/计划/cwd/目录列表）。
 * 所有操作发 AGENT_Command(207) set（cmd=命令文本），插件执行后写 type=1 lastChange
 * （标题栏变更可见）+ 刷新 type=3；本面板监听 SettingUpdate 设置更新事件重读 type=3。
 * 207 为透明消息：不落库、不显示在消息流（digest 为空）。
 */
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import AgentCommandMessageContent from '@wfc/client/src/main/ets/wfc/messages/agentCommandMessageContent'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import { AgentPanelData, agentRobotName, getAgentPanelDataFor } from '../../util/agentState'
import { FontSize, Radius } from '../../common/design/Tokens'

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
    // 面板标题附注（多机器人时显示目标机器人名，如 "AI 会话设置 · 机器人名"）
    @State robotTitleNote: string = ''

    aboutToAppear() {
        // 设置更新事件：插件执行更新/组合查询后写 type=3，重读刷新
        wfc.eventEmitter?.on(EventType.SettingUpdate, this.onSettingUpdate)
        this.updateRobotTitleNote()
        // 先读已有面板数据（若有），再发组合查询刷新
        this.refreshPanelData()
        this.sendCommand('query')
    }

    aboutToDisappear() {
        wfc.eventEmitter?.off(EventType.SettingUpdate, this.onSettingUpdate)
        clearTimeout(this.flashTimer)
    }

    /** 目标机器人（@Prop）变化：重读该机器人的 type=3 并补发组合查询（一般由父组件重新创建本面板触发）。 */
    onRobotUidChanged() {
        this.updateRobotTitleNote()
        this.refreshPanelData()
        this.sendCommand('query')
    }

    /** 面板标题附注：robotUid 非空时显示机器人显示名（名称缺失回退完整 uid，不截断）。 */
    updateRobotTitleNote() {
        this.robotTitleNote = this.robotUid ? agentRobotName(this.robotUid) : ''
    }

    /** 设置更新（scope=31 会话级用户设置变化，type=3 刷新即触发）：重读目标机器人的面板数据。 */
    onSettingUpdate = () => {
        this.refreshPanelData()
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
        this.cwdCandidates = data.dirs ? data.dirs : []
    }

    /** 发送 207 面板指令（透明消息，不显示在消息流）；带目标机器人 robotId（多机器人寻址）。 */
    sendCommand(op: string, cmd: string = '') {
        this.seq = (this.seq + 1) % 100000
        wfc.sendConversationMessage(this.conversation,
            new AgentCommandMessageContent(op, cmd, this.seq, this.robotUid))
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

    /** 点击「切换」：弹出独立目录选择界面（候选来自 type=3 dirs；为空可再发一次 query 刷新）。 */
    openCwdPicker() {
        if (this.applying) {
            return
        }
        this.showCwdPicker = true
        if ((this.cwdCandidates ?? []).length === 0) {
            this.sendCommand('query')
        }
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
                    if ((this.cwdCandidates ?? []).length === 0) {
                        Column() {
                            Text('未获取到目录列表')
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_tertiary_text'))
                                .margin({ bottom: 4 })
                            Text('可稍后重试或再次打开')
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
