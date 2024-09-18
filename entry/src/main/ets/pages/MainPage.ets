import ConversationListTab from './ConversationListTab'
import ContactListTab from './ContactListTab'
import DiscoveryTab from './DiscoveryTab'
import MeTab from './MeTab'
import AbilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { showToast } from '../common/utils/Toast'
import PickContactModal from './picker/PickContactModal'
import UserInfo from '../wfc/model/userInfo'
import wfc from '../wfc/client/wfc'
import GroupType from '../wfc/model/groupType'
import Conversation from '../wfc/model/conversation'
import ConversationType from '../wfc/model/conversationType'

import notificationManager from '@ohos.notificationManager'
import Base, { BusinessError } from '@ohos.base'
import WorkSpaceTab from './WorkSpaceTab'
import Config from '../config'
import { checkPermissions, requestPermissions } from '../helper/permissionHelper'
import { navigationDestinations, PagesMap } from './navigationConfig'
import orgServer from '../api/orgServer'
import GroupInfo from '../wfc/model/groupInfo'
import { url } from '@kit.ArkTS'
import WfcScheme from '../wfcScheme'
import Message from '../wfc/messages/message'
import MessageContentType from '../wfc/messages/messageContentType'
import EventType from '../wfc/client/wfcEvent'
import PCLoginRequestMessageContent from '../wfc/messages/pcLoginRequestMessageContent'

const TAG = 'Main';

const permissions: Array<Permissions> = [
    'ohos.permission.INTERNET',
    'ohos.permission.READ_MEDIA',
    'ohos.permission.WRITE_MEDIA',
    'ohos.permission.MICROPHONE',
    'ohos.permission.READ_IMAGEVIDEO',
    'ohos.permission.SYSTEM_FLOAT_WINDOW',
    'ohos.permission.KEEP_BACKGROUND_RUNNING'
];

let storage = LocalStorage.getShared()


@Entry(storage)
@Component
struct MainPage {
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
    @Provide('mainNavPathStack') mainNavPathStack: NavPathStack = new NavPathStack()
    @LocalStorageProp('targetConversation') @Watch('onTargetConversation') targetConversation?: Conversation = undefined

    onTargetConversation() {
        let conversation = this.targetConversation
        if (conversation) {
            storage.delete('targetConversation')
            wfc.clearConversationUnreadStatus(conversation!)
            // TODO
            // FIXME
            // https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-arkui-observer-V5?catalogVersion=V5
            //  会话页面，监听 observer.on('navDestinationUpdate')
            let index = this.mainNavPathStack.popToName(navigationDestinations.ConversationPage)
            if (index >= 0) {
                this.mainNavPathStack.replacePathByName(navigationDestinations.ConversationPage, {
                    'conversation': conversation
                } as Record<string, Object>)
            } else {
                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                    'conversation': conversation
                } as Record<string, Object>)
            }
        }
    }

    onPageShow() {
        notificationManager.cancelAll()
    }

    createConversation(users: UserInfo[]) {
        if (users.length === 1) {
            this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
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
            wfc.createGroup('', GroupType.Normal, groupName, '', '', memberIds, '', [0], null, (groupId) => {
                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
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
                notificationManager.requestEnableNotification().then(() => {
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

    onReceiveMessage = (msg: Message) => {
        if (msg.content?.type === MessageContentType.PC_Login_Request) {
            let pcLoginRequest = msg.messageContent as PCLoginRequestMessageContent
            this.showPCLoginPage(pcLoginRequest.sessionId, true, pcLoginRequest.platform)

        } else {
            // DO NOTHING
        }
    }

    async aboutToAppear() {
        this.enableNotification();
        let ungrantedPermissions = await checkPermissions(getContext(this), permissions)
        if (ungrantedPermissions.length > 0) {
            await requestPermissions(getContext(this), ungrantedPermissions)
            ungrantedPermissions = await checkPermissions(getContext(this), permissions)
            if (ungrantedPermissions.length > 0) {
                showToast(`请授予相关权限，否则不能正常工作 ${ungrantedPermissions[0]}`)
            }
        }

        if (Config.ORGANIZATION_SERVER) {
            orgServer.login()
        }

        wfc.eventEmitter?.on(EventType.ReceiveMessage, this.onReceiveMessage)
    }

    aboutToDisappear(): void {
        wfc.eventEmitter?.off(EventType.ReceiveMessage)
    }

    showPCLoginPage(token: string, isConfirmPCLogin = false, platform = 0) {
        this.mainNavPathStack.pushPathByName(navigationDestinations.PCLoginPage, {
            'token': token,
            'isConfirmPCLogin': isConfirmPCLogin,
            'platform': platform
        } as Record<string, Object>)
    }

    showUser(userId: string) {
        let userInfo = wfc.getUserInfo(userId)
        this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, {
            'userInfo': userInfo
        } as Record<string, Object>)
    }

    showGroup(groupId: string) {
        this.mainNavPathStack.pushPathByName(navigationDestinations.GroupInfoPage, {
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

    @Builder
    TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
        Column() {
            Badge({
                count: this.tabUnreadCount(targetIndex),
                maxCount: 99,
                position: BadgePosition.RightTop,
                style: { badgeSize: 14, badgeColor: '#FA2A2D' }
            }) {
                Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
                    .size({ width: 20 })
                    .objectFit(ImageFit.ScaleDown)
            }

            Text(title)
                .fontColor(this.currentIndex === targetIndex ? '#3066EC' : '#6B6B6B')
                .fontSize(14)
                .padding({ top: 5, bottom: 5 })
        }
        .width('100%')
        .height(60)
        .backgroundColor('#F7F7F7')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
            this.currentIndex = targetIndex
            this.tabsController.changeIndex(this.currentIndex)
        })
    }

    @Builder
    pickContactModal() {
        PickContactModal({
            showPickContactModal: $showPickContactModal,
            onCheckUser: (users: UserInfo[]) => {
                this.createConversation(users)
            },
            onCheckFavGroup: (groupInfo: GroupInfo) => {
                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                    'conversation': new Conversation(ConversationType.Group, groupInfo.target, 0)
                } as Record<string, Object>)
            }
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
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
                    this.mainNavPathStack.pushPathByName(navigationDestinations.SearchUserPage, {} as Record<string, Object>)
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
                        let prefix = qrcode.substring(0, qrcode.lastIndexOf('/') + 1)
                        let value = qrcode.substring(qrcode.lastIndexOf('/') + 1)
                        try {
                            let _url = url.URL.parseURL(qrcode)
                        } catch (e) {
                        }

                        switch (prefix) {
                            case WfcScheme.QR_CODE_PREFIX_PC_SESSION:
                                this.showPCLoginPage(value)
                                break
                            case WfcScheme.QR_CODE_PREFIX_USER:
                                this.showUser(value)
                                break
                            case WfcScheme.QR_CODE_PREFIX_GROUP:
                                this.showGroup(value)
                                break
                                break
                        // case WfcScheme.QR_CODE_PREFIX_CHANNEL:
                        //     break
                        // case WfcScheme.QR_CODE_PREFIX_CONFERENCE:
                        //     break
                            default:
                                showToast('qrcode: ' + qrcode);
                                break
                        }

                    }).catch((error: BusinessError) => {
                        // TODO
                    });

                })
        }
    }

    @Builder
    NavigationMenus() {
        Row() {
            Image($r('app.media.ic_search'))
                .width(30)
                .height(30)
                .padding(6)
                .onClick(() => {
                    let xx = this.mainNavPathStack.getAllPathName();
                    this.mainNavPathStack.pushPathByName(navigationDestinations.SearchPortalPage, {
                        'keyword': '1'
                    } as Record<string, Object>, true)
                })

            Image($r('app.media.ic_add'))
                .width(30)
                .height(30)
                .padding(6)
                .margin({ left: 12 })
                .bindMenu(this.SubMoreMenus())
                .bindContentCover($$this.showPickContactModal, this.pickContactModal(), {
                    modalTransition: ModalTransition.DEFAULT,
                    onAppear: () => {
                    },
                })
        }
        .margin({ right: 18 })
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
    }

    build() {
        Navigation(this.mainNavPathStack) {
            Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
                TabContent() {
                    ConversationListTab({ conversationListTabUnreadCount: $conversationListTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[0], 0, $r('app.media.message_press'), $r('app.media.message_normal')))

                TabContent() {
                    ContactListTab({ contactTabUnreadCount: $contactTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[1], 1, $r('app.media.contacts_press'), $r('app.media.contacts_normal')))

                if (Config.OPEN_PLATFORM_WORK_SPACE_URL) {
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
            .onChange(index => {
                this.currentIndex = index
                this.title = this.tabTitles[index]
            })
        }
        .title(this.title)
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(true)
        .menus(this.NavigationMenus())
        .mode(NavigationMode.Stack)
        .navDestination(PagesMap)
    }
}