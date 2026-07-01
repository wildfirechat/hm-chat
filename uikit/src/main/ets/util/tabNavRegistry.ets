/**
 * Pad/宽屏「每 tab 独立导航栈」注册表。
 * 平板分栏下，每个 list 类 tab 各自持有一个 NavPathStack（见 SplitTabPane）。
 * pane 挂载时把自己的栈按 tabKey 注册进来，供 MainPage 的全局跳转
 *（点通知、新建聊天等，发生在 tab 子树之外）定位并压入目标 tab 的栈。
 */
export class TabKey {
    static readonly Conversation = 'conversation'
    static readonly Contact = 'contact'
    static readonly Discovery = 'discovery'
    static readonly Me = 'me'
}

class TabNavRegistry {
    private stacks: Map<string, NavPathStack> = new Map()

    register(tabKey: string, stack: NavPathStack): void {
        this.stacks.set(tabKey, stack)
    }

    unregister(tabKey: string): void {
        this.stacks.delete(tabKey)
    }

    get(tabKey: string): NavPathStack | undefined {
        return this.stacks.get(tabKey)
    }
}

export const tabNavRegistry: TabNavRegistry = new TabNavRegistry()
