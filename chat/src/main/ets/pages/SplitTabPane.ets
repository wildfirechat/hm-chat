import { MainPageMap } from './mainNavigationConfig'
import { tabNavRegistry, TabKey } from '@wfc/uikit/src/main/ets/util/tabNavRegistry'
import { uikitNavigationDestinations } from '@wfc/uikit/src/main/ets/pages/uikitNavigationConfig'
import ConversationListTab from '@wfc/uikit/src/main/ets/pages/ConversationListTab'
import ContactListTab from '@wfc/uikit/src/main/ets/pages/ContactListTab'
import DiscoveryTab from './DiscoveryTab'
import MeTab from './MeTab'

/**
 * Pad/宽屏分栏容器：每个 list 类 tab 用它包裹，各自持有一个独立的 NavPathStack。
 * 内部是一个 Navigation（强制 Split）：navBar（左栏）= 该 tab 的「列表 + 底部 Tab 栏」，
 * content（右栏）= 该 tab 自己的详情栈。tab 栏落在左栏底部（类微信 Pad）。
 *
 * 关键：列表在本组件内**直接渲染**（ListContent），而不是从 MainPage 经 @BuilderParam 传入——
 * 这样列表的 @Consume('mainNavPathStack') 一定就近解析到本组件 @Provide 的 tabStack，
 * 从而本 tab 内任意跳转（如从联系人页打开会话）都进本 tab 的独立栈、显示在右栏，而非全屏。
 * 底部 Tab 栏不涉及本栈，仍由 MainPage 经 @BuilderParam 传入（复用其 currentIndex/未读等状态）。
 */
@Component
export default struct SplitTabPane {
    @Provide({ allowOverride: 'mainNavPathStack' }) tabStack: NavPathStack = new NavPathStack()
    tabKey: string = ''
    // 四个 tab 的未读数（透传给对应列表；只用到与 tabKey 匹配的那个）
    @Link conversationListTabUnreadCount: number
    @Link contactTabUnreadCount: number
    @Link discoveryTabUnreadCount: number
    @Link meTabUnreadCount: number
    // 左栏顶部的 Header 栏，由 MainPage 传入
    @BuilderParam headerBar: () => void = this.defaultHeaderBar
    // 左栏底部的 Tab 栏，由 MainPage 传入
    @BuilderParam bottomBar: () => void
    // 是否用 WelcomePage 作右栏空态基座
    showWelcomePlaceholder: boolean = true

    @Builder
    defaultHeaderBar() {}

    aboutToAppear(): void {
        tabNavRegistry.register(this.tabKey, this.tabStack)
        if (this.showWelcomePlaceholder && this.tabStack.size() === 0) {
            this.tabStack.pushPathByName(uikitNavigationDestinations.WelcomePage, {} as Record<string, Object>, false)
        }
    }

    aboutToDisappear(): void {
        tabNavRegistry.unregister(this.tabKey)
    }

    @Builder
    leftPane() {
        if (this.tabKey === TabKey.Conversation) {
            ConversationListTab({ conversationListTabUnreadCount: $conversationListTabUnreadCount })
        } else if (this.tabKey === TabKey.Contact) {
            ContactListTab({ contactTabUnreadCount: $contactTabUnreadCount })
        } else if (this.tabKey === TabKey.Discovery) {
            DiscoveryTab({ discoveryTabUnreadCount: $discoveryTabUnreadCount })
        } else if (this.tabKey === TabKey.Me) {
            MeTab({ meTabUnreadCount: $meTabUnreadCount })
        }
    }

    build() {
        Navigation(this.tabStack) {
            Column() {
                this.headerBar()

                Column() {
                    this.leftPane()
                }
                .layoutWeight(1)
                .width('100%')

                this.bottomBar()
            }
            .width('100%')
            .height('100%')
        }
        // 强制分栏：pane 只在宽屏(≥600vp)渲染。宽度取小值以保证 600vp 也放得下
        //（navBar 260 + content 300 = 560 < 600），避免 Auto 因放不下退化成整屏栈式。
        .mode(NavigationMode.Split)
        .navBarWidth(300)
        .navBarWidthRange(['260vp', '360vp'])
        .minContentWidth('300vp')
        .hideTitleBar(true)
        .navDestination(MainPageMap)
    }
}
