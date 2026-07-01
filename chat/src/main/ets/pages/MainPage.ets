import ConversationListTab from '@wfc/uikit/src/main/ets/pages/ConversationListTab'
import ContactListTab from '@wfc/uikit/src/main/ets/pages/ContactListTab'
import DiscoveryTab from './DiscoveryTab'
import MeTab from './MeTab'
import AbilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { bundleManager, ConfigurationConstant } from '@kit.AbilityKit';
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
import { ShareItem } from '@wfc/uikit/src/main/ets/common/Types'
import { MainPageMap, appNavigationDestinations } from './mainNavigationConfig'
import orgServer from '@wfc/uikit/src/main/ets/api/orgServer'
import appServer from '@wfc/uikit/src/main/ets/api/appServer'
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
import CallState from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callState'
import pipHelper from '@wfc/uikit/src/main/ets/pages/voip/pipHelper'
import window from '@ohos.window'
import { FontSize, scaledSize } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import { deviceInfo } from '@kit.BasicServicesKit'
import { WidthBreakpoint } from '@wfc/uikit/src/main/ets/util/windowSizeManager'
import { tabNavRegistry, TabKey } from '@wfc/uikit/src/main/ets/util/tabNavRegistry'
import { pushOrReplaceDetail } from '@wfc/uikit/src/main/ets/util/navUtil'
import SplitTabPane from './SplitTabPane'

const TAG = 'Main';

const permissions: Array<Permissions> = [
    'ohos.permission.INTERNET'
];

let storage = LocalStorage.getShared()

@Entry(storage)
@Component
struct MainPage {
    @StorageProp('fontScale') fontScale: number = 1.0;
    private tabsController: TabsController = new TabsController()
    private tabTitles: string[] = ['野火', '通讯录', '工作台', '发现', '我的']
    @State message: string = 'Hello World'
    @State title: string = '野火'
    @State currentIndex: number = 0
    @State @Watch('onUnreadCountUpdated') conversationListTabUnreadCount: number = 0
    @State @Watch('onUnreadCountUpdated') contactTabUnreadCount: number = 0
    @State @Watch('onUnreadCountUpdated') discoveryTabUnreadCount: number = 0
    @State meTabUnreadCount: number = 0
    @State showPickContactModal: boolean = false
    @State isMeTab: boolean = false
    // 外层导航栈：Stack 模式，承载全屏覆盖页（通话/分享/通知打开），并提供 id 给 PiP。
    // allowOverride 让分栏 pane 可用同名 @Provide 遮蔽本栈，实现「每 tab 独立栈」。
    @Provide({ allowOverride: 'mainNavPathStack' }) mainNavPathStack: NavPathStack = uikit.mainNavPathStack
    // Pad/宽屏：断点 ≥ md（600vp）视为宽屏，驱动 手机(单栏) / 平板(每 tab 分栏) 分支
    @StorageProp('widthBreakpoint') @Watch('onWidthBreakpointChange') widthBreakpoint: WidthBreakpoint = 'sm'
    @LocalStorageProp('wantParams') @Watch('onWantParams') wantParams?: Record<string, Object> = undefined
    @LocalStorageProp('shareParams') @Watch('onShareParams') shareParams?: ShareItem[] = undefined
    @StorageProp('currentColorMode') @Watch('onCurrentColorModeChange') currentColorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

    onWantParams() {
        let conversation = this.wantParams?.conversation as Conversation
        // 后台收到音视频来电时，avenginekit 已经把通话页面 push 到了导航栈顶（见
        // AVEngineCallbackImpl.onReceiveCall）。此时来电同时会弹出一条消息通知，
        // 点击该通知会唤起 App 并触发这里的会话跳转，从而把通话页面覆盖。
        // 因此当存在进行中的通话时，跳过会话跳转，保持通话页面在最上层。
        let activeCallSession = avengineKit.getCurrentSession()
        if (conversation && (!activeCallSession || activeCallSession.status === CallState.STATUS_IDLE)) {
            storage.delete('targetConversation')
            wfc.clearConversationUnreadStatus(conversation!)
            // 宽屏落到会话 tab 的独立栈，手机落外层栈全屏
            this.openConversationFromGlobal(conversation)
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

    onShareParams() {
        let items = this.shareParams
        if (items && items.length > 0) {
            // 仅在已登录（即当前展示 MainPage）时消费；未登录场景留存数据，
            // 不在此处导航，避免崩溃。消费后立即清除，防止重复触发。
            storage.delete('shareParams')
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ShareToConversationPage, {
                'shareItems': items
            } as Record<string, Object>)
        }
    }

    onPageShow() {
        notificationManager.cancelAll()
    }

    createConversation(users: UserInfo[]) {
        if (users.length === 1) {
            this.openConversationFromGlobal(new Conversation(ConversationType.Single, users[0].uid, 0))
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
                this.openConversationFromGlobal(new Conversation(ConversationType.Group, groupId, 0))
            }, err => {
                showToast('创建群组失败：' + err)
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

        if (Config.ORGANIZATION_SERVER || Config.ORGANIZATION_SERVER_BACKUP) {
            orgServer.login()
        }

        this.contactTabUnreadCount = wfc.getUnreadFriendRequestCount()
        wfc.eventEmitter?.on(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter?.on(EventType.FriendRequestUpdate, this.onFriendRequestUpdate)

        // 延迟3秒后检查版本更新
        setTimeout(() => {
            this.checkVersionUpdate()
        }, 3000)
    }

    aboutToDisappear(): void {
        wfc.eventEmitter?.off(EventType.ReceiveMessage, this.onReceiveMessage)
        wfc.eventEmitter?.off(EventType.FriendRequestUpdate, this.onFriendRequestUpdate)
    }

    // 宽屏(平板)：断点 ≥ md 视为宽屏，进入「每 tab 独立栈」的分栏布局
    isWide(): boolean {
        return this.widthBreakpoint !== 'sm'
    }

    onWidthBreakpointChange(): void {
        // 断点变化触发 build 重算（Tabs.vertical / 各 tab 分支），无需额外处理
    }

    // 全局打开会话（点通知、新建群聊等，发生在 tab 子树之外）：
    // 宽屏 → 切到会话 tab 并压入其独立栈；手机 → 压入外层栈全屏打开。
    // 若目标栈已有会话页则 popToName 收敛后 replace，避免叠栈。
    openConversationFromGlobal(conversation: Conversation): void {
        let stack = this.mainNavPathStack
        if (this.isWide()) {
            let tabStack = tabNavRegistry.get(TabKey.Conversation)
            if (tabStack) {
                this.currentIndex = 0
                this.tabsController.changeIndex(0)
                stack = tabStack
            }
        }
        let params: Record<string, Object> = { 'conversation': conversation }
        let index = stack.popToName(uikitNavigationDestinations.ConversationPage)
        if (index >= 0) {
            stack.replacePathByName(uikitNavigationDestinations.ConversationPage, params)
        } else {
            stack.pushPathByName(uikitNavigationDestinations.ConversationPage, params)
        }
    }

    onCurrentColorModeChange(): void {
        this.setStatusBarColor(this.isMeTab)
    }

    showPCLoginPage(token: string, isConfirmPCLogin = false, platform = 0) {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PCLoginPage, {
            'token': token,
            'isConfirmPCLogin': isConfirmPCLogin,
            'platform': platform
        } as Record<string, Object>)
    }

    async checkVersionUpdate() {
        try {
            let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
            let currentVersion = bundleInfo.versionName || ''
            let buildNumber = bundleInfo.versionCode || 0
            let versionInfo = await appServer.checkVersion(currentVersion, buildNumber)
            AppStorage.setOrCreate<Record<string, Object> | null>('versionInfo', versionInfo)
            if (!versionInfo) {
                return
            }
            let needUpdate = versionInfo['needUpdate'] as boolean
            if (!needUpdate) {
                return
            }
            let forceUpdate = versionInfo['forceUpdate'] as boolean
            let title = (versionInfo['title'] as string) || '发现新版本'
            let message = (versionInfo['message'] as string) || ''
            let url = (versionInfo['harmonyUrl'] as string) || ''

            let hasShown = AppStorage.get<boolean>('versionDialogShown') || false
            if (hasShown) {
                return
            }
            AppStorage.setOrCreate('versionDialogShown', true)

            if (forceUpdate) {
                AlertDialog.show({
                    title: title,
                    message: message,
                    autoCancel: false,
                    primaryButton: {
                        value: '立即更新',
                        action: () => {
                            if (url) {
                                let context = getContext(this) as common.UIAbilityContext
                                context.startAbility({ action: 'ohos.want.action.viewData', uri: url })
                            }
                        }
                    }
                })
            } else {
                AlertDialog.show({
                    title: title,
                    message: message,
                    primaryButton: {
                        value: '立即更新',
                        action: () => {
                            if (url) {
                                let context = getContext(this) as common.UIAbilityContext
                                context.startAbility({ action: 'ohos.want.action.viewData', uri: url })
                            }
                        }
                    },
                    secondaryButton: {
                        value: '以后再说',
                        action: () => {
                        }
                    }
                })
            }
        } catch (e) {
            console.error('checkVersionUpdate error', e)
        }
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

    private setStatusBarColor(isMe: boolean) {
        let colorMode = AppStorage.get<ConfigurationConstant.ColorMode>('currentColorMode')
        window.getLastWindow(this.getUIContext().getHostContext()).then(win => {
            win.setWindowSystemBarProperties({
                statusBarColor: isMe && colorMode == ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#111111' : '#00000000',
                statusBarContentColor: colorMode == ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#000000',
            }).catch((e: Error) => {
                console.error(TAG, 'setWindowSystemBarProperties failed', e)
            })
        }).catch((e: Error) => {
            console.error(TAG, 'getLastWindow failed', e)
        })
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

    @Builder
    TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
        Column() {
            Badge({
                count: this.tabUnreadCount(targetIndex),
                maxCount: 99,
                position: BadgePosition.RightTop,
                style: { badgeSize: scaledSize(14, this.fontScale), badgeColor: $r('app.color.wf_badge_color') }
            }) {
                Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
                    .size({ width: 20 })
                    .objectFit(ImageFit.ScaleDown)
            }

            Text(title)
                .fontColor(this.currentIndex === targetIndex ? $r('app.color.wf_tab_text_selected') : $r('app.color.wf_tab_text_normal'))
                .fontSize(FontSize.sm)
                // 底部 Tab 文字不跟随字体大小调节
                .minFontScale(1)
                .maxFontScale(1)
                .padding({ top: 4, bottom: 4 })
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
            this.currentIndex = targetIndex
            this.tabsController.changeIndex(this.currentIndex)
        })
    }

    // Pad/宽屏分栏：每个 tab 左栏底部的 Tab 栏单元（横向等分）
    @Builder
    PaneTabCell(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
        Column() {
            Badge({
                count: this.tabUnreadCount(targetIndex),
                maxCount: 99,
                position: BadgePosition.RightTop,
                style: { badgeSize: scaledSize(14, this.fontScale), badgeColor: $r('app.color.wf_badge_color') }
            }) {
                Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
                    .size({ width: 20 })
                    .objectFit(ImageFit.ScaleDown)
            }

            Text(title)
                .fontColor(this.currentIndex === targetIndex ? $r('app.color.wf_tab_text_selected') : $r('app.color.wf_tab_text_normal'))
                .fontSize(FontSize.sm)
                .minFontScale(1)
                .maxFontScale(1)
                .padding({ top: 4, bottom: 4 })
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
            this.currentIndex = targetIndex
            this.tabsController.changeIndex(this.currentIndex)
        })
    }

    // Pad/宽屏分栏：左栏底部的 Tab 栏（会话/联系人/[工作台]/发现/我的）
    @Builder
    PaneTabBar() {
        Row() {
            this.PaneTabCell(this.tabTitles[0], 0, $r('app.media.message_press'), $r('app.media.message_normal'))
            this.PaneTabCell(this.tabTitles[1], 1, $r('app.media.contacts_press'), $r('app.media.contacts_normal'))
            if (Config.getWorkspaceUrl()) {
                this.PaneTabCell(this.tabTitles[2], 2, $r('app.media.work_press'), $r('app.media.work'))
            }
            this.PaneTabCell(this.tabTitles[3], 3, $r('app.media.discovery_press'), $r('app.media.discovery_normal'))
            this.PaneTabCell(this.tabTitles[4], 4, $r('app.media.me_press'), $r('app.media.me_normal'))
        }
        .width('100%')
        .height(56)
        .backgroundColor($r('app.color.wf_tab_background'))
        .border({ width: { top: 0.5 }, color: $r('app.color.wf_divider') })
    }

    @Builder
    pickMultiContactModal() {
        PickMultiContactModal({
            showPickContactModal: $showPickContactModal,
            onCheckUser: (users: UserInfo[]) => {
                this.createConversation(users)
            },
            onCheckFavGroup: (groupInfo: GroupInfo) => {
                this.openConversationFromGlobal(new Conversation(ConversationType.Group, groupInfo.target, 0))
            }
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor($r('app.color.wf_background'))
    }

    @Builder
    SubMoreMenus() {
        Menu() {
            MenuItem({ startIcon: $r('app.media.faqiqunliao_iconfont'), content: "创建群聊" })
                .onClick(() => {
                    this.showPickContactModal = true
                })
            MenuItem({ startIcon: $r('app.media.faqiqunliao_iconfont'), content: "发起密聊" })
                .enabled(false)
                .onClick(() => {
                    showToast('发起密聊')
                })
            MenuItem({ startIcon: $r('app.media.tianjiapengyou_iconfont'), content: "添加朋友" })
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.SearchUserPage, {} as Record<string, Object>)
                })
            MenuItem({ startIcon: $r('app.media.saoyisao1_iconfont'), content: "扫一扫" })
                .onClick(() => {
                    showToast('扫一扫')
                    // 定义扫码参数options
                    let options: scanBarcode.ScanOptions = {
                        scanTypes: [scanCore.ScanType.QR_CODE],
                        enableMultiMode: true,
                        enableAlbum: true
                    };
                    // 可调用getContext接口获取当前页面关联的UIAbilityContext
                    scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                        // 解析码值结果跳转应用服务页

                        let qrcode = result.originalValue;
                        WfcScheme.handleQRCodeResult(this.mainNavPathStack, qrcode);

                    }).catch((error: BusinessError) => {
                        // TODO
                    });

                })
        }
    }

    @Builder
    TitleBuilder() {
        if (!this.isMeTab) {
            Column() {
                Text(this.title)
                    .padding({ left: 16 })
                    .fontSize(FontSize.xl)
                    // 标题栏不跟随字体大小调节
                    .minFontScale(1)
                    .maxFontScale(1)
                    .fontColor($r('app.color.wf_primary_text'))
                    .width('200')
            }
            .height('100%')
            .justifyContent(FlexAlign.Center)
        }
    }

    @Builder
    NavigationMenus() {
        if (!this.isMeTab) {
            Row() {
                if (deviceInfo.sdkApiVersion >= 18) {
                    SymbolGlyph($r('sys.symbol.magnifyingglass'))
                        .fontSize(FontSize.xxl)
                        .fontColor([$r('app.color.wf_icon_color')])
                        .minFontScale(1)
                        .maxFontScale(1)
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.SearchPortalPage, {
                                'keyword': '1'
                            } as Record<string, Object>, true)
                        })
                } else {
                    SymbolGlyph($r('sys.symbol.magnifyingglass'))
                        .fontSize(FontSize.xxl)
                        .fontColor([$r('app.color.wf_icon_color')])
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.SearchPortalPage, {
                                'keyword': '1'
                            } as Record<string, Object>, true)
                        })
                }

                if (deviceInfo.sdkApiVersion >= 18) {
                    SymbolGlyph($r('sys.symbol.plus_circle'))
                        .fontSize(FontSize.xxl)
                        .fontColor([$r('app.color.wf_icon_color')])
                        .minFontScale(1)
                        .maxFontScale(1)
                        .margin({ left: 12 })
                        .bindMenu(this.SubMoreMenus())
                        .bindContentCover($$this.showPickContactModal, this.pickMultiContactModal(), {
                            modalTransition: ModalTransition.DEFAULT,
                            onAppear: () => {
                            },
                        })
                } else {
                    SymbolGlyph($r('sys.symbol.plus_circle'))
                        .fontSize(FontSize.xxl)
                        .fontColor([$r('app.color.wf_icon_color')])
                        .margin({ left: 12 })
                        .bindMenu(this.SubMoreMenus())
                        .bindContentCover($$this.showPickContactModal, this.pickMultiContactModal(), {
                            modalTransition: ModalTransition.DEFAULT,
                            onAppear: () => {
                            },
                        })
                }
            }
            .margin({ right: 20 })
            .height('100%')
            .justifyContent(FlexAlign.Start)
            .alignItems(VerticalAlign.Center)
        }
    }

    @Builder
    PaneSubMoreMenus(tabKey: string) {
        Menu() {
            MenuItem({ startIcon: $r('app.media.faqiqunliao_iconfont'), content: "创建群聊" })
                .onClick(() => {
                    let stack = tabNavRegistry.get(tabKey)
                    if (stack) {
                        stack.pushPathByName(uikitNavigationDestinations.PickMultiContactPage, {
                            'onCheckUser': (users: UserInfo[]) => {
                                this.createConversation(users)
                            },
                            'onCheckFavGroup': (groupInfo: GroupInfo) => {
                                this.openConversationFromGlobal(new Conversation(ConversationType.Group, groupInfo.target, 0))
                            }
                        } as Record<string, Object>)
                    }
                })
            MenuItem({ startIcon: $r('app.media.faqiqunliao_iconfont'), content: "发起密聊" })
                .enabled(false)
                .onClick(() => {
                    showToast('发起密聊')
                })
            MenuItem({ startIcon: $r('app.media.tianjiapengyou_iconfont'), content: "添加朋友" })
                .onClick(() => {
                    let stack = tabNavRegistry.get(tabKey)
                    if (stack) {
                        stack.pushPathByName(uikitNavigationDestinations.SearchUserPage, {} as Record<string, Object>)
                    }
                })
            MenuItem({ startIcon: $r('app.media.saoyisao1_iconfont'), content: "扫一扫" })
                .onClick(() => {
                    showToast('扫一扫')
                    let options: scanBarcode.ScanOptions = {
                        scanTypes: [scanCore.ScanType.QR_CODE],
                        enableMultiMode: true,
                        enableAlbum: true
                    };
                    scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                        let qrcode = result.originalValue;
                        let stack = tabNavRegistry.get(tabKey)
                        if (stack) {
                            WfcScheme.handleQRCodeResult(stack, qrcode);
                        }
                    }).catch((error: BusinessError) => {
                        // TODO
                    });
                })
        }
    }

    @Builder
    TabHeaderBuilder(tabKey: string) {
        if (tabKey === TabKey.Me) {
            Row() {
                Text('我')
                    .padding({ left: 16 })
                    .fontSize(FontSize.xl)
                    .minFontScale(1)
                    .maxFontScale(1)
                    .fontColor($r('app.color.wf_primary_text'))
                    .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .height(56)
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.wf_primary_background_color'))
            .border({ width: { bottom: 0.5 }, color: $r('app.color.wf_divider') })
        } else {
            Row() {
                Text(tabKey === TabKey.Conversation ? '野火' : (tabKey === TabKey.Contact ? '通讯录' : (tabKey === 'workspace' ? '工作台' : '发现')))
                    .padding({ left: 16 })
                    .fontSize(FontSize.xl)
                    .minFontScale(1)
                    .maxFontScale(1)
                    .fontColor($r('app.color.wf_primary_text'))
                    .fontWeight(FontWeight.Bold)

                Blank()

                if(!this.isWide || ([TabKey.Conversation, TabKey.Contact].indexOf(tabKey) >= 0)){
                    Row() {
                        if (deviceInfo.sdkApiVersion >= 18) {
                            SymbolGlyph($r('sys.symbol.magnifyingglass'))
                                .fontSize(FontSize.xxl)
                                .fontColor([$r('app.color.wf_icon_color')])
                                .minFontScale(1)
                                .maxFontScale(1)
                                .onClick(() => {
                                    let stack = tabNavRegistry.get(tabKey) || this.mainNavPathStack
                                    // push 到 Welcome 基座之上，若右栏已有详情则 replace——保留 Welcome 占位基座
                                    pushOrReplaceDetail(stack, uikitNavigationDestinations.SearchPortalPage, {
                                        'keyword': '1'
                                    } as Record<string, Object>)
                                })
                        } else {
                            SymbolGlyph($r('sys.symbol.magnifyingglass'))
                                .fontSize(FontSize.xxl)
                                .fontColor([$r('app.color.wf_icon_color')])
                                .onClick(() => {
                                    let stack = tabNavRegistry.get(tabKey) || this.mainNavPathStack
                                    // push 到 Welcome 基座之上，若右栏已有详情则 replace——保留 Welcome 占位基座
                                    pushOrReplaceDetail(stack, uikitNavigationDestinations.SearchPortalPage, {
                                        'keyword': '1'
                                    } as Record<string, Object>)
                                })
                        }

                        if (deviceInfo.sdkApiVersion >= 18) {
                            SymbolGlyph($r('sys.symbol.plus_circle'))
                                .fontSize(FontSize.xxl)
                                .fontColor([$r('app.color.wf_icon_color')])
                                .minFontScale(1)
                                .maxFontScale(1)
                                .margin({ left: 16 })
                                .bindMenu(this.PaneSubMoreMenus(tabKey))
                        } else {
                            SymbolGlyph($r('sys.symbol.plus_circle'))
                                .fontSize(FontSize.xxl)
                                .fontColor([$r('app.color.wf_icon_color')])
                                .margin({ left: 16 })
                                .bindMenu(this.PaneSubMoreMenus(tabKey))
                        }
                    }
                    .margin({ right: 16 })
                }
            }
            .width('100%')
            .height(56)
            .alignItems(VerticalAlign.Center)
            .backgroundColor($r('app.color.wf_primary_background_color'))
            .border({ width: { bottom: 0.5 }, color: $r('app.color.wf_divider') })
        }
    }

    getGreeting(): string {
        let hour = new Date().getHours()
        if (hour < 6) {
            return '夜深了'
        }
        if (hour < 12) {
            return '早上好'
        }
        if (hour < 14) {
            return '中午好'
        }
        if (hour < 18) {
            return '下午好'
        }
        return '晚上好'
    }

    getFormattedDate(): string {
        let date = new Date()
        let year = date.getFullYear()
        let month = date.getMonth() + 1
        let day = date.getDate()
        let dayOfWeek = date.getDay()
        let weeks = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
        return `${year}年${month}月${day}日 ${weeks[dayOfWeek]}`
    }

    getMyName(): string {
        let uid = wfc.getUserId()
        let info = wfc.getUserInfo(uid, false)
        return info?.displayName || '用户'
    }

    getMyPortrait(): string {
        let uid = wfc.getUserId()
        let info = wfc.getUserInfo(uid, false)
        return info?.portrait || ''
    }

    @Builder
    ShortcutItem(title: string, symbol: Resource, action: () => void) {
        Row() {
            SymbolGlyph(symbol)
                .fontSize(20)
                .fontColor([$r('app.color.wf_primary')])
                .margin({ right: 8 })
                .minFontScale(1)
                .maxFontScale(1)
            Text(title)
                .fontSize(FontSize.sm)
                .fontColor($r('app.color.wf_primary_text'))
                .fontWeight(FontWeight.Medium)
                .minFontScale(1)
                .maxFontScale(1)
        }
        .width('100%')
        .height(44)
        .padding({ left: 10, right: 10 })
        .borderRadius(8)
        .backgroundColor($r('app.color.wf_primary_background_color'))
        .alignItems(VerticalAlign.Center)
        .onClick(action)
        .stateStyles({
            pressed: {
                .backgroundColor($r('app.color.wf_item_pressed'))
            },
            normal: {
                .backgroundColor($r('app.color.wf_primary_background_color'))
            }
        })
    }

    // 工作台：左栏(个人助理控制面板 + 底部 Tab 栏) | 右栏(网页)
    @Builder
    WorkspacePane() {
        Row() {
            Column() {
                // 1. Header (工作台)
                this.TabHeaderBuilder('workspace')

                // 2. Personal Assistant Dashboard
                Column() {

                    // Greeting（头像 + 问候语）
                    Row() {
                        Image(this.getMyPortrait())
                            .width(44)
                            .height(44)
                            .borderRadius(22)
                            .backgroundColor($r('app.color.wf_image_placeholder_bg'))
                            .margin({ right: 12 })

                        Column() {
                            Text(`${this.getGreeting()}，${this.getMyName()}`)
                                .fontSize(FontSize.lg)
                                .fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.wf_primary_text'))
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .minFontScale(1)
                                .maxFontScale(1)
                            Text('祝你有美好的一天')
                                .fontSize(FontSize.xs)
                                .fontColor($r('app.color.wf_tertiary_text'))
                                .margin({ top: 2 })
                                .minFontScale(1)
                                .maxFontScale(1)
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                    .margin({ bottom: 16 })

                    // Date Card
                    Column() {
                        Row() {
                            Column() {
                                Text(new Date().getDate().toString())
                                    .fontSize(36)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor($r('app.color.wf_primary'))
                                    .minFontScale(1)
                                    .maxFontScale(1)
                            }
                            .width(56)
                            .height(56)
                            .justifyContent(FlexAlign.Center)
                            .backgroundColor($r('app.color.wf_secondary_background'))
                            .borderRadius(12)
                            .margin({ right: 16 })

                            Column() {
                                Text(this.getFormattedDate())
                                    .fontSize(FontSize.sm)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor($r('app.color.wf_primary_text'))
                                    .minFontScale(1)
                                    .maxFontScale(1)
                                Text('探索今天的高效工作吧')
                                    .fontSize(FontSize.xs)
                                    .fontColor($r('app.color.wf_tertiary_text'))
                                    .margin({ top: 4 })
                                    .minFontScale(1)
                                    .maxFontScale(1)
                            }
                            .alignItems(HorizontalAlign.Start)
                            .layoutWeight(1)
                        }
                        .alignItems(VerticalAlign.Center)
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor($r('app.color.wf_background'))
                    .borderRadius(16)
                    .margin({ bottom: 16 })
                    .shadow({ radius: 8, color: '#0d000000', offsetX: 0, offsetY: 2 })

                    // Shortcut Tools Card
                }
                .layoutWeight(1)
                .width('100%')
                .padding(16)
                .backgroundColor($r('app.color.wf_secondary_background'))

                // 3. TabBar
                this.PaneTabBar()
            }
            .width(300)
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))

            Divider()
                .vertical(true)
                .height('100%')
                .strokeWidth(0.5)
                .color($r('app.color.wf_divider'))

            Column() {
                WorkSpaceTab()
            }
            .layoutWeight(1)
            .height('100%')
        }
        .width('100%')
        .height('100%')
    }

    // 手机：底部横排 Tab，每个 tab 整页列表，详情走外层栈全屏（与适配前一致）
    @Builder
    PhoneTabs() {
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabsController }) {
            TabContent() {
                ConversationListTab({ conversationListTabUnreadCount: $conversationListTabUnreadCount })
            }
            .tabBar(this.TabBuilder(this.tabTitles[0], 0, $r('app.media.message_press'), $r('app.media.message_normal')))

            TabContent() {
                ContactListTab({ contactTabUnreadCount: $contactTabUnreadCount })
            }
            .tabBar(this.TabBuilder(this.tabTitles[1], 1, $r('app.media.contacts_press'), $r('app.media.contacts_normal')))

            if (Config.getWorkspaceUrl()) {
                TabContent() {
                    WorkSpaceTab()
                }
                .tabBar(this.TabBuilder(this.tabTitles[2], 2, $r('app.media.work_press'), $r('app.media.work')))

                TabContent() {
                    DiscoveryTab({ discoveryTabUnreadCount: $discoveryTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[3], 3, $r('app.media.discovery_press'), $r('app.media.discovery_normal')))

                TabContent() {
                    MeTab({ meTabUnreadCount: $meTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[4], 4, $r('app.media.me_press'), $r('app.media.me_normal')))
            } else {
                TabContent() {
                    DiscoveryTab({ discoveryTabUnreadCount: $discoveryTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[3], 3, $r('app.media.discovery_press'), $r('app.media.discovery_normal')))

                TabContent() {
                    MeTab({ meTabUnreadCount: $meTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[4], 4, $r('app.media.me_press'), $r('app.media.me_normal')))
            }
        }
        .barOverlap(true)
        .barBackgroundBlurStyle(BlurStyle.COMPONENT_THICK)
        .barBackgroundColor($r('app.color.wf_tab_background'))
        .onChange(index => {
            this.currentIndex = index
            let titleIndex = index
            if (!Config.getWorkspaceUrl() && index >= 2) {
                titleIndex = index + 1
            }
            this.title = this.tabTitles[titleIndex]
            const isMe = index === (Config.getWorkspaceUrl() ? 4 : 3)
            this.isMeTab = isMe
            this.setStatusBarColor(isMe)
        })
        .onAnimationStart((index: number, targetIndex: number) => {
            const isMe = targetIndex === (Config.getWorkspaceUrl() ? 4 : 3)
            this.isMeTab = isMe
            this.setStatusBarColor(isMe)
        })
        .onAnimationEnd((index: number) => {
            const isMe = index === (Config.getWorkspaceUrl() ? 4 : 3)
            this.isMeTab = isMe
            this.setStatusBarColor(isMe)
        })
    }

    // 平板：一个 list tab 的分栏 pane（独立栈，左列表右详情），左栏底部挂 Tab 栏
    @Builder
    TabPane(tabKey: string) {
        SplitTabPane({
            tabKey: tabKey,
            conversationListTabUnreadCount: $conversationListTabUnreadCount,
            contactTabUnreadCount: $contactTabUnreadCount,
            discoveryTabUnreadCount: $discoveryTabUnreadCount,
            meTabUnreadCount: $meTabUnreadCount,
            headerBar: () => {
                this.TabHeaderBuilder(tabKey)
            },
            bottomBar: () => {
                this.PaneTabBar()
            }
        })
    }

    // 平板：默认 Tab 栏隐藏（barHeight 0），改由每个 pane 左栏底部自绘 Tab 栏；
    // 每个 list tab 用 SplitTabPane（独立栈）左列表右详情。Tabs 仅用于切换与保活。
    @Builder
    TabletTabs() {
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabsController }) {
            TabContent() {
                this.TabPane(TabKey.Conversation)
            }

            TabContent() {
                this.TabPane(TabKey.Contact)
            }

            if (Config.getWorkspaceUrl()) {
                TabContent() {
                    this.WorkspacePane()
                }

                TabContent() {
                    this.TabPane(TabKey.Discovery)
                }

                TabContent() {
                    this.TabPane(TabKey.Me)
                }
            } else {
                TabContent() {
                    this.TabPane(TabKey.Discovery)
                }

                TabContent() {
                    this.TabPane(TabKey.Me)
                }
            }
        }
        .barHeight(0)
        // 平板由自绘 Tab 栏切换，禁用横滑换 tab（避免会话/列表内横向手势误触）
        .scrollable(false)
        .animationDuration(0)
        .onChange(index => {
            this.currentIndex = index
            let titleIndex = index
            if (!Config.getWorkspaceUrl() && index >= 2) {
                titleIndex = index + 1
            }
            this.title = this.tabTitles[titleIndex]
            const isMe = index === (Config.getWorkspaceUrl() ? 4 : 3)
            this.isMeTab = isMe
            this.setStatusBarColor(isMe)
        })
        .onAnimationStart((index: number, targetIndex: number) => {
            const isMe = targetIndex === (Config.getWorkspaceUrl() ? 4 : 3)
            this.isMeTab = isMe
            this.setStatusBarColor(isMe)
        })
        .onAnimationEnd((index: number) => {
            const isMe = index === (Config.getWorkspaceUrl() ? 4 : 3)
            this.isMeTab = isMe
            this.setStatusBarColor(isMe)
        })
    }

    build() {
        Navigation(this.mainNavPathStack) {
            // 平板：每个 tab 左栏(列表+底部Tab栏) | 右栏(该 tab 独立详情栈)；手机：单栏底部 Tab。
            if (this.isWide()) {
                this.TabletTabs()
            } else {
                this.PhoneTabs()
            }
        }
        .title(this.TitleBuilder(), {
            backgroundColor: this.isMeTab ? $r('app.color.wf_background') : $r('app.color.wf_primary_background_color')
        })
        .titleMode(NavigationTitleMode.Mini)
        .hideTitleBar(this.isWide())
        .backgroundColor($r('app.color.wf_primary_background_color'))
        .hideBackButton(true)
        .menus(this.NavigationMenus())
        // 外层栈只承载全屏覆盖页（通话/会议/分享/通知打开）；分栏发生在每个 tab 内部
        .mode(NavigationMode.Stack)
        // 要和 pipController 里面配置的 navigationId 一致
        .id(uikit.bundleName)
        .navDestination(MainPageMap)
    }
}
