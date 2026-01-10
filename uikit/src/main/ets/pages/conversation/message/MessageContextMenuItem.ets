/**
 * 消息上下文菜单项接口
 */
export interface MessageContextMenuItem {
    title: string
    tag: string
    icon: ResourceStr
    action: () => void
    // 返回 false 时，将不会被包含在最终的长按菜单列表里面
    filter?: () => boolean
}
