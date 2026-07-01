import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig'
import { STORAGE_KEY_WIDTH_BREAKPOINT, WidthBreakpoint } from './windowSizeManager'

/**
 * 是否为宽屏（平板/大屏）布局：断点 ≥ md（600vp）。
 * 由 windowSizeManager 实时写入 AppStorage['widthBreakpoint']。
 */
export function isWideScreen(): boolean {
    let bp = AppStorage.get<WidthBreakpoint>(STORAGE_KEY_WIDTH_BREAKPOINT) ?? 'sm'
    return bp !== 'sm'
}

// 分栏下右栏当前展示的会话标识，供会话列表高亮当前会话。
// 由 ConversationPage 在 setup/销毁 时写入/清除，会话列表读取比对。
export const STORAGE_KEY_ACTIVE_CONVERSATION = 'activeConversationKey'

/** 会话的稳定身份标识（type-target-line），用于比对「是否同一会话」。 */
export function conversationIdentity(conversation: Conversation): string {
    return `${conversation.type}-${conversation.target}-${conversation.line}`
}

/**
 * 在给定导航栈中打开会话页。
 * 宽屏（分栏）下，若栈顶已是会话页则「替换」而非「压入」——在会话列表间切换不叠栈
 *（类微信 Pad）；否则压入（含首次从占位基座页进入）。手机窄屏始终压入。
 */
export function openConversation(stack: NavPathStack, conversation: Conversation): void {
    let params: Record<string, Object> = { 'conversation': conversation }
    let names = stack.getAllPathName()
    let topIsConversation = names.length > 0 && names[names.length - 1] === uikitNavigationDestinations.ConversationPage
    if (isWideScreen() && topIsConversation) {
        // 栈顶已是同一个会话时，点击不做任何操作——避免重复 replace 重建会话页导致的崩溃/闪动
        let topParam = stack.getParamByIndex(stack.size() - 1) as Record<string, Object> | undefined
        let topConv = topParam?.['conversation'] as Conversation | undefined
        if (topConv && topConv.type === conversation.type && topConv.target === conversation.target
            && topConv.line === conversation.line) {
            return
        }
        stack.replacePathByName(uikitNavigationDestinations.ConversationPage, params)
    } else {
        stack.pushPathByName(uikitNavigationDestinations.ConversationPage, params)
    }
}

export function pushOrReplaceDetail(stack: NavPathStack, pageName: string, params: Record<string, Object> = {}): void {
    if (isWideScreen() && stack.size() > 1) {
        stack.replacePathByName(pageName, params)
    } else {
        stack.pushPathByName(pageName, params)
    }
}
