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
 * 宽屏（分栏）下，右栏是一个「详情位」：无论右栏当前是什么（会话页/设备页等），
 * 打开会话都收敛到唯一一份会话页——栈中已有会话页则 popToName 收敛到它（同会话忽略、异会话替换），
 * 没有则回到空态基座再压入，避免「会话-设备页-会话」这类叠栈。手机窄屏始终压入。
 */
export function openConversation(stack: NavPathStack, conversation: Conversation): void {
    let params: Record<string, Object> = { 'conversation': conversation }
    if (!isWideScreen()) {
        // 手机窄屏：始终压入（全屏打开）
        stack.pushPathByName(uikitNavigationDestinations.ConversationPage, params)
        return
    }
    // 宽屏分栏：先收敛到栈中已有的会话页（若有）
    let index = stack.popToName(uikitNavigationDestinations.ConversationPage)
    if (index >= 0) {
        let names = stack.getAllPathName()
        let topName = names.length > 0 ? names[names.length - 1] : ''
        if (topName === uikitNavigationDestinations.ConversationPage) {
            // 栈顶已是会话页：同一会话点击不做任何操作——避免重复 replace 重建会话页导致的崩溃/闪动
            let topParam = stack.getParamByIndex(stack.size() - 1) as Record<string, Object> | undefined
            let topConv = topParam?.['conversation'] as Conversation | undefined
            if (topConv && topConv.type === conversation.type && topConv.target === conversation.target
                && topConv.line === conversation.line) {
                return
            }
            stack.replacePathByName(uikitNavigationDestinations.ConversationPage, params)
        } else {
            // 收敛后栈顶不是会话页（异常态），直接替换
            stack.replacePathByName(uikitNavigationDestinations.ConversationPage, params)
        }
    } else {
        // 栈中无会话页：回到空态基座（若有）再压入，保证右栏只有一份会话页
        stack.popToName(uikitNavigationDestinations.WelcomePage)
        stack.pushPathByName(uikitNavigationDestinations.ConversationPage, params)
    }
}

/**
 * 详情页参数浅比较（引用相等/值相等）：用于判断「栈顶已是同一目标页」。
 * 同一对象/同一基础值重复点击视为相同，避免无意义的重建（闪动）。
 */
function sameDetailParams(a: Record<string, Object> | undefined, b: Record<string, Object>): boolean {
    if (!a) {
        return false
    }
    let keysA = Object.keys(a)
    let keysB = Object.keys(b)
    if (keysA.length !== keysB.length) {
        return false
    }
    for (let key of keysA) {
        if (a[key] !== b[key]) {
            return false
        }
    }
    return true
}

/**
 * 打开详情页：宽屏（分栏）下右栏是「详情位」——
 * 栈顶已是目标页：参数相同则忽略（避免重复重建闪动），参数不同则替换刷新数据；
 * 栈顶是其他页：替换；空态/窄屏：压入。手机窄屏保持原行为（始终压入）。
 */
export function pushOrReplaceDetail(stack: NavPathStack, pageName: string, params: Record<string, Object> = {}): void {
    if (!isWideScreen()) {
        // 手机窄屏：始终压入（原行为）
        stack.pushPathByName(pageName, params)
        return
    }
    let names = stack.getAllPathName()
    let topName = names.length > 0 ? names[names.length - 1] : ''
    if (topName === pageName) {
        // 目标页已在栈顶：同一目标（参数相同）忽略，不同目标替换
        let topParam = stack.getParamByIndex(stack.size() - 1) as Record<string, Object> | undefined
        if (sameDetailParams(topParam, params)) {
            return
        }
        stack.replacePathByName(pageName, params)
    } else if (stack.size() > 1) {
        stack.replacePathByName(pageName, params)
    } else {
        stack.pushPathByName(pageName, params)
    }
}

/**
 * 打开详情页且保证栈中只有一份：
 * 目标页已在栈顶 → 直接忽略（不重建，避免页面闪动）；
 * 目标页在栈中但非栈顶 → 收敛（popToName）到它并替换参数；
 * 不在栈中 → 压入新页。
 */
export function pushUniqueDetail(stack: NavPathStack, pageName: string, params: Record<string, Object> = {}): void {
    let names = stack.getAllPathName()
    if (names.length > 0 && names[names.length - 1] === pageName) {
        // 目标页已在栈顶：不重建，避免闪烁
        return
    }
    let index = stack.popToName(pageName)
    if (index >= 0) {
        stack.replacePathByName(pageName, params)
    } else {
        stack.pushPathByName(pageName, params)
    }
}
