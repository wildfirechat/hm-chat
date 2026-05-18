import ConversationListTab from '@wfc/uikit/src/main/ets/pages/ConversationListTab'
import ContactListTab from '@wfc/uikit/src/main/ets/pages/ContactListTab'
import DiscoveryTab from './DiscoveryTab'
import MeTab from './MeTab'
import AbilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import PickMultiContactModal from '@wfc/uikit/src/main/ets/pages/picker/PickMultiContactModal'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupType from '@wfc/client/src/main/ets/wfc/model/groupType'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'

import notificationManager from '@ohos.notificationManager'
import Base, { BusinessError } from '@ohos.base'
import WorkSpaceTab from '@wfc/uikit/src/main/ets/pages/WorkSpaceTab'
import Config from '@wfc/client/src/main/ets/config'
import { checkPermissions, requestPermissions } from '@wfc/uikit/src/main/ets/helper/permissionHelper'
import { uikitNavigationDestinations } from '@wfc/uikit/src/main/ets/pages/uikitNavigationConfig'
import { MainPageMap } from './mainNavigationConfig'
import orgServer from '@wfc/uikit/src/main/ets/api/orgServer'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { url } from '@kit.ArkTS'
import WfcScheme from '@wfc/uikit/src/main/ets/wfcScheme'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import PCLoginRequestMessageContent from '@wfc/client/src/main/ets/wfc/messages/pcLoginRequestMessageContent'
import uikit from '@wfc/uikit'
import { common } from '@kit.AbilityKit'
import avengineKit from '@wfc/avenginekit'
import PCWelcomePage from './PCWelcomePage'
import pipHelper from '@wfc/uikit/src/main/ets/pages/voip/pipHelper'

const TAG = 'Main';

const permissions: Array<Permissions> = [
    'ohos.permission.INTERNET'
];

let storage = LocalStorage.getShared()

@Entry(storage)
@Component
struct MainPage {
    private tabTitles: string[] = ['消息', '通讯录', '工作台', '发现', '我的']
    @State currentIndex: number = 0
    @State @Watch('onUnreadCountUpdated') conversationListTabUnreadCount: number = 0
    @State @Watch('onUnreadCountUpdated') contactTabUnreadCount: number = 0
    @State @Watch('onUnreadCountUpdated') discoveryTabUnreadCount: number = 0
    @State meTabUnreadCount: number = 0
    @State showPickContactModal: boolean = false
    // ── 每 Tab 独立导航栈 ─────────────────────────────────────────────────
    // switchTab() 切换 @Provide mainNavPathStack 指向，使所有 @Consume 页面
    // 自动拿到正确的栈，彻底解决多 Tab 场景下 getParamByIndex crash 问题。
    private conversationNavStack: NavPathStack = uikit.mainNavPathStack
    private contactNavStack: NavPathStack = new NavPathStack()
    // 其余 Tab（发现、我的）暂时复用会话栈（可按需扩展）
    private otherNavStack: NavPathStack = new NavPathStack()
    @Provide('mainNavPathStack') mainNavPathStack: NavPathStack = uikit.mainNavPathStack
    @LocalStorageProp('wantParams') @Watch('onWantParams') wantParams?: Record<string, Object> = undefined

    private showWorkSpaceTab(): boolean {
        return !!Config.OPEN_PLATFORM_WORK_SPACE_URL
    }

    private isWorkSpaceActive(): boolean {
        return this.showWorkSpaceTab() && this.currentIndex === 2
    }

    private shouldShowThirdColumn(): boolean {
        return !this.isWorkSpaceActive()
    }

    /**
     * 切换 Tab：同步更新 currentIndex 并将 @Provide mainNavPathStack 指向该 Tab
     * 专属的 NavPathStack，让所有 @Consume('mainNavPathStack') 页面自动获得
     * 正确的栈（getParamByIndex 不再读到错误栈）。
     */
    private switchTab(index: number) {
        this.currentIndex = index
        switch (index) {
            case 0:
                this.mainNavPathStack = this.conversationNavStack
                break
            case 1:
                this.mainNavPathStack = this.contactNavStack
                break
            default:
                this.mainNavPathStack = this.otherNavStack
                break
        }
    }

    onWantParams() {
        let conversation = this.wantParams?.conversation as Conversation
        if (conversation) {
            storage.delete('targetConversation')
            wfc.clearConversationUnreadStatus(conversation!)
            // TODO
            // FIXME
            // https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-arkui-observer-V5?catalogVersion=V5
            //  会话页面，监听 observer.on('navDestinationUpdate')
            // 收到通知跳转会话时，先切换到会话 Tab（同步切换导航栈）
            this.switchTab(0)
            let index = this.mainNavPathStack.popToName(uikitNavigationDestinations.ConversationPage)
            if (index >= 0) {
                this.mainNavPathStack.replacePathByName(uikitNavigationDestinations.ConversationPage, {
                    'conversation': conversation
                } as Record<string, Object>)
            } else {
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                    'conversation': conversation
                } as Record<string, Object>)
            }
        }
        let voip = this.wantParams?.continuousTaskLabel as string
        if (voip) {
            let callSession = avengineKit.getCurrentSession();
            if (!callSession) {
                return
            }
            pipHelper.stopCurrentPiP()
            // let params: Record<string, Object> = {}
            // if (callSession.conference) {
            //     this.mainNavPathStack.pushPathByName(navigationDestinations.ConferencePage, params)
            // } else if (callSession.singleCall) {
            //     this.mainNavPathStack.pushPathByName(callSession.audioOnly ? navigationDestinations.SingleAudioCallPage : navigationDestinations.SingleVideoCallPage, params)
            // } else {
            //     this.mainNavPathStack.pushPathByName(callSession.audioOnly ? navigationDestinations.MultiAudioCallPage : navigationDestinations.MultiVideoCallPage, params)
            // }
        }
    }

    onPageShow() {
        notificationManager.cancelAll()
    }

    createConversation(users: UserInfo[]) {
        this.mainNavPathStack.clear()
        if (users.length === 1) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                'conversation': new Conversation(ConversationType.Single, users[0].uid, 0)
            } as Record<string, Object>)
        } else {
            let memberIds: string[] = users.map(userInfo => userInfo.uid)
            let first5Members = users.slice(0, 5)
            let groupName = ''
            first5Members.forEach(userInfo => {
                groupName += userInfo.displayName
                groupName += '、'
            })
            groupName = groupName.substring(0, groupName.length - 1)
            wfc.createGroup('', GroupType.Restricted, groupName, '', '', memberIds, '', [0], null, (groupId) => {
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                    'conversation': new Conversation(ConversationType.Group, groupId, 0)
                } as Record<string, Object>)
            }, err => {

            })
        }
    }

    onUnreadCountUpdated() {
        let badgeNumber = this.conversationListTabUnreadCount + this.contactTabUnreadCount + this.discoveryTabUnreadCount;
        notificationManager.setBadgeNumber(badgeNumber, null)
    }

    async enableNotification() {
        notificationManager.isNotificationEnabled().then((data: boolean) => {
            console.info("isNotificationEnabled success, data: " + JSON.stringify(data));
            if (!data) {
                notificationManager.requestEnableNotification(getContext(this) as common.UIAbilityContext).then(() => {
                    console.info(`[ANS] requestEnableNotification success`);
                }).catch((err: Base.BusinessError) => {
                    if (1600004 == err.code) {
                        console.info(`[ANS] requestEnableNotification refused`);
                    } else {
                        console.error(`[ANS] requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
                    }
                });
            }
        }).catch((err: Base.BusinessError) => {
            console.error(`isNotificationEnabled fail: ${JSON.stringify(err)}`);
        });

    }

    onReceiveMessage = (msgs: Message[], hasMore: boolean) => {
        for (const msg of msgs) {
            if (msg.content?.type === MessageContentType.PC_Login_Request) {
                let pcLoginRequest = msg.messageContent as PCLoginRequestMessageContent
                this.showPCLoginPage(pcLoginRequest.sessionId, true, pcLoginRequest.platform)
            } else {
                // DO NOTHING
            }
        }
    }
    onFriendRequestUpdate = (ids: string[]) => {
        this.contactTabUnreadCount = wfc.getUnreadFriendRequestCount()
    }

    async aboutToAppear() {
        this.enableNotification();
        let ungrantedPermissions = await checkPermissions(getContext(this), permissions)
        if (ungrantedPermissions.length > 0) {
            showToast(`请授予相关权限，否则不能正常工作 ${ungrantedPermissions[0]}`)
        }

        if (Config.ORGANIZATION_SERVER) {
            orgServer.login()
        }

        this.contactTabUnreadCount = wfc.getUnreadFriendRequestCount()
        wfc.eventEmitter?.on(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter?.on(EventType.FriendRequestUpdate, this.onFriendRequestUpdate)
    }

    aboutToDisappear(): void {
        wfc.eventEmitter?.off(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter?.off(EventType.FriendRequestUpdate, this.onFriendRequestUpdate)
    }

    showPCLoginPage(token: string, isConfirmPCLogin = false, platform = 0) {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PCLoginPage, {
            'token': token,
            'isConfirmPCLogin': isConfirmPCLogin,
            'platform': platform
        } as Record<string, Object>)
    }

    showUser(userId: string) {
        let userInfo = wfc.getUserInfo(userId)
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
            'userInfo': userInfo
        } as Record<string, Object>)
    }

    showGroup(groupId: string) {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.GroupInfoPage, {
            'groupId': groupId
        } as Record<string, Object>)
    }

    tabUnreadCount(tabIndex: number) {
        let unreadCount: number = 0
        switch (tabIndex) {
            case 0:
                unreadCount = this.conversationListTabUnreadCount
                break
            case 1:
                unreadCount = this.contactTabUnreadCount
                break
            case 2:
                unreadCount = this.discoveryTabUnreadCount
            case 3:
                unreadCount = this.meTabUnreadCount
                break
            default:
        }
        return unreadCount
    }

    // ──────────────────────────── PC 布局 Builder ────────────────────────────

    /** 左侧边栏：单个导航图标项（80px 宽点击区 + 48px 高亮图标框） */
    @Builder
    SidebarItem(targetIndex: number, selectedImg: Resource, normalImg: Resource, unreadCount: number) {
        // 外层：全宽点击区，80 × 68（48 图标 + 20 间距）
        Column() {
            // 内层：48 × 48 高亮框
            Column() {
                Badge({
                    count: unreadCount,
                    maxCount: 99,
                    position: BadgePosition.RightTop,
                    style: { badgeSize: 12, badgeColor: $r('app.color.wf_badge_color') }
                }) {
                    Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
                        .size({ width: 24, height: 24 })
                        .objectFit(ImageFit.ScaleDown)
                }
            }
            .width(48)
            .height(48)
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.currentIndex === targetIndex
                ? $r('app.color.wf_item_pressed')
                : Color.Transparent)
        }
        .width(80)
        .height(68)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
            this.switchTab(targetIndex)
        })
    }

    /** Tab0 的 tabBar：应用图标 + 消息图标 */

    @Builder
    Tab0Bar() {
        Column() {
            Image($r('app.media.app_icon'))
                .width(36)
                .height(36)
                .borderRadius(8)
                .margin({ top: 24, bottom: 12 })
            this.SidebarItem(0, $r('app.media.message_press'), $r('app.media.message_normal'),
                this.conversationListTabUnreadCount)
        }
        .width(80)
        .alignItems(HorizontalAlign.Center)
    }

    /** 工作台 tabBar（无工作台时渲染空容器，保持索引稳定） */
    @Builder
    WorkspaceTabBar() {
        if (this.showWorkSpaceTab()) {
            this.SidebarItem(2, $r('app.media.work_press'), $r('app.media.work'), 0)
        }
    }

    /** 空占位 tabBar（用于"我的"Tab：图标单独置于侧边栏底部，内容仍由 Tabs 缓存） */
    @Builder
    EmptyTabBar() {
        Column()
            .width(0)
            .height(0)
    }

    /** 中间列表区顶部的 "+" 下拉菜单 */
    @Builder
    SubMoreMenus() {
        Menu() {
            MenuItem({ startIcon: $r('app.media.faqiqunliao_iconfont'), content: "创建群聊" })
                .onClick(() => {
                    this.showPickContactModal = true
                })
            MenuItem({ startIcon: $r('app.media.faqiqunliao_iconfont'), content: "发起密聊" })
                .enabled(false)
            MenuItem({ startIcon: $r('app.media.tianjiapengyou_iconfont'), content: "添加朋友" })
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.SearchUserPage, {} as Record<string, Object>)
                })
            MenuItem({ startIcon: $r('app.media.saoyisao1_iconfont'), content: "扫一扫" })
                .onClick(() => {
                    let options: scanBarcode.ScanOptions = {
                        scanTypes: [scanCore.ScanType.QR_CODE],
                        enableMultiMode: true,
                        enableAlbum: true
                    };
                    scanBarcode.startScanForResult(getContext(this), options)
                        .then((result: scanBarcode.ScanResult) => {
                            WfcScheme.handleQRCodeResult(this.mainNavPathStack, result.originalValue);
                        })
                        .catch((_error: BusinessError) => {
                            showToast('扫码失败')
                        });
                })
        }
    }

    /** 选择联系人全屏弹层 */
    @Builder
    pickMultiContactModal() {
        PickMultiContactModal({
            showPickContactModal: $showPickContactModal,
            onCheckUser: (users: UserInfo[]) => {
                this.createConversation(users)
            },
            onCheckFavGroup: (groupInfo: GroupInfo) => {
                this.mainNavPathStack.clear()
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                    'conversation': new Conversation(ConversationType.Group, groupInfo.target, 0)
                } as Record<string, Object>)
            }
        })
            .height('100%')
            .width('100%')
            .backgroundColor($r('app.color.wf_background'))
    }

    // ──────────────────────────── PC 主布局 ────────────────────────────

    build() {
        Row() {
            // ── 第一列：图标侧边栏（普通 Column，Blank() 将"我的"推到底部）──
            Column() {
                Image($r('app.media.app_icon'))
                    .width(36)
                    .height(36)
                    .borderRadius(8)
                    .margin({ top: 24, bottom: 16 })

                this.SidebarItem(0, $r('app.media.message_press'), $r('app.media.message_normal'),
                    this.conversationListTabUnreadCount)
                this.SidebarItem(1, $r('app.media.contacts_press'), $r('app.media.contacts_normal'),
                    this.contactTabUnreadCount)
                if (this.showWorkSpaceTab()) {
                    this.SidebarItem(2, $r('app.media.work_press'), $r('app.media.work'), 0)
                }
                this.SidebarItem(3, $r('app.media.discovery_press'), $r('app.media.discovery_normal'),
                    this.discoveryTabUnreadCount)

                Blank()

                this.SidebarItem(4, $r('app.media.me_press'), $r('app.media.me_normal'), 0)
            }
            .width(80)
            .height('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ bottom: 20 })
            .backgroundColor($r('app.color.wf_primary_background_color'))

            Divider()
                .vertical(true)
                .height('100%')
                .strokeWidth(0.5)
                .color($r('app.color.wf_divider'))

            // ── 第二列：Tabs 仅做状态缓存（barWidth/barHeight=0 隐藏系统 tabBar）──
            Tabs({ index: this.currentIndex }) {
                // Tab 0：消息列表
                TabContent() {
                    Column() {
                        Row() {
                            Text(this.tabTitles[0])
                                .fontSize(18)
                                .fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.wf_primary_text'))
                                .layoutWeight(1)

                            SymbolGlyph($r('sys.symbol.magnifyingglass'))
                                .fontSize(20)
                                .fontColor([$r('app.color.wf_icon_color')])
                                .onClick(() => {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.SearchPortalPage, {
                                        'keyword': '1'
                                    } as Record<string, Object>, true)
                                })

                            SymbolGlyph($r('sys.symbol.plus_circle'))
                                .fontSize(20)
                                .fontColor([$r('app.color.wf_icon_color')])
                                .margin({ left: 12 })
                                .bindMenu(this.SubMoreMenus())
                        }
                        .width('100%')
                        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

                        Divider().color($r('app.color.wf_divider'))

                        ConversationListTab({ conversationListTabUnreadCount: $conversationListTabUnreadCount })
                    }
                    .width('100%')
                    .height('100%')
                    .backgroundColor($r('app.color.wf_background'))
                }
                .tabBar('')

                // Tab 1：通讯录（将 contactNavStack 直接传入 ContactListTab，实现独立第三列导航）
                TabContent() {
                    Column() {
                        Row() {
                            Text('通讯录')
                                .fontSize(18)
                                .fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.wf_primary_text'))
                                .layoutWeight(1)
                        }
                        .width('100%')
                        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

                        Divider().color($r('app.color.wf_divider'))

                        ContactListTab({
                            contactTabUnreadCount: $contactTabUnreadCount,
                        })
                    }
                    .width('100%')
                    .height('100%')
                    .backgroundColor($r('app.color.wf_background'))
                }
                .tabBar('')

                // Tab 2：工作台（始终保留槽位以保持索引稳定）
                TabContent() {
                    WorkSpaceTab()
                }
                .tabBar('')

                // Tab 3：发现
                TabContent() {
                    Column() {
                        Row() {
                            Text(this.tabTitles[3])
                                .fontSize(18)
                                .fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.wf_primary_text'))
                                .layoutWeight(1)
                        }
                        .width('100%')
                        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

                        Divider().color($r('app.color.wf_divider'))

                        DiscoveryTab({ discoveryTabUnreadCount: $discoveryTabUnreadCount })
                    }
                    .width('100%')
                    .height('100%')
                    .backgroundColor($r('app.color.wf_background'))
                }
                .tabBar('')

                // Tab 4：我的
                TabContent() {
                    Column() {
                        Row() {
                            Text(this.tabTitles[4])
                                .fontSize(18)
                                .fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.wf_primary_text'))
                                .layoutWeight(1)
                        }
                        .width('100%')
                        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

                        Divider().color($r('app.color.wf_divider'))

                        MeTab({ meTabUnreadCount: $meTabUnreadCount })
                    }
                    .width('100%')
                    .height('100%')
                    .backgroundColor($r('app.color.wf_background'))
                }
                .tabBar('')
            }
            .barWidth(0)
            .barHeight(0)
            .animationDuration(0)
            .scrollable(false)
            .onChange((index: number) => {
                this.switchTab(index)
            })
            .width(280)
            .layoutWeight(this.isWorkSpaceActive() ? 1 : 0)
            .height('100%')

            if (this.shouldShowThirdColumn()) {
                Divider()
                    .vertical(true)
                    .height('100%')
                    .strokeWidth(0.5)
                    .color($r('app.color.wf_divider'))

                // ── 第三列：单一 Navigation，mainNavPathStack 随 Tab 切换 ──────────
                // 每个 Tab 各自的 NavPathStack 对象持久存在于 MainPage，
                // Navigation 只是「视图」，栈切换后自动从 NavPathStack 恢复页面。
                // 所有 @Consume('mainNavPathStack') 的子页面自动获得正确的栈，
                // getParamByIndex(size-1) 始终命中正确条目，不再 crash。
                Navigation(this.mainNavPathStack) {
                    if (this.currentIndex === 1) {
                        // 联系人 Tab：未选中联系人时显示空白
                        Column()
                            .width('100%')
                            .height('100%')
                            .backgroundColor($r('app.color.wf_background'))
                    } else {
                        PCWelcomePage()
                    }
                }
                .mode(NavigationMode.Stack)
                .navDestination(MainPageMap)
                .hideTitleBar(true)
                .hideBackButton(true)
                // 要和 pipController 里面配置的 navigationId 一致
                .id(uikit.bundleName)
                .layoutWeight(1)
            }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.wf_primary_background_color'))
        // 选择联系人全屏弹层
        .bindContentCover($$this.showPickContactModal, this.pickMultiContactModal(), {
            modalTransition: ModalTransition.DEFAULT
        })
    }
}
