import ConversationListTab from './ConversationListTab'
import ContactListTab from './ContactListTab'
import DiscoveryTab from './DiscoveryTab'
import MeTab from './MeTab'
import AbilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import Logger from '../common/utils/Logger'
import promptAction from '@ohos.promptAction';
import bundleManager from '@ohos.bundle.bundleManager';
import common from '@ohos.app.ability.common'
import { showToast } from '../common/utils/Toast'
import router from '@ohos.router'
import PickContactPage from './picker/PickContactPage'
import UserInfo from '../wfc/model/userInfo'
import wfc from '../wfc/client/wfc'
import GroupType from '../wfc/model/groupType'
import Conversation from '../wfc/model/conversation'
import ConversationType from '../wfc/model/conversationType'
import { ChannelInfoPage } from './channel/ChannelInfoPage'

const TAG = 'Main';

const permissions: Array<Permissions> = [
    'ohos.permission.INTERNET',
    'ohos.permission.READ_MEDIA',
    'ohos.permission.WRITE_MEDIA',
    'ohos.permission.MICROPHONE',
    'ohos.permission.READ_IMAGEVIDEO'
];

@Entry
@Component
struct MainPage {
    private tabsController: TabsController = new TabsController()
    private tabTitles: string[] = ['野火', '通讯录', '发现', '我的']
    @State message: string = 'Hello World'
    @State title: string = '野火'
    @State currentIndex: number = 0
    @State conversationListTabUnreadCount: number = 0
    @State contactTabUnreadCount: number = 0
    @State discoveryTabUnreadCount: number = 0
    @State meTabUnreadCount: number = 0
    // TODO router.getParams() 一直返回 router.back 时设置的参数
    private isNewPickContact = false

    onPageShow() {
        let params = router.getParams() as Record<string, Object>
        console.log('main Index Show', params)
        if (params) {
            const tag: string = params['tag'] as string
            if (tag === PickContactPage.TAG) {
                if (!this.isNewPickContact) {
                    return
                }
                this.isNewPickContact = false
                let result: UserInfo[] = params['result'] as UserInfo[]
                if (result.length === 1) {
                    router.pushUrl({
                        url: "pages/conversation/ConversationPage",
                        params: {
                            conversation: new Conversation(ConversationType.Single, result[0].uid, 0)
                        }
                    }, router.RouterMode.Standard)
                } else {
                    let memberIds: string[] = result.map(userInfo => userInfo.uid)
                    let first5Members = result.slice(0, 5)
                    let groupName = ''
                    first5Members.forEach(userInfo => {
                        groupName += userInfo.displayName
                        groupName += '、'
                    })
                    groupName = groupName.substring(0, groupName.length - 1)
                    wfc.createGroup('', GroupType.Normal, groupName, '', '', memberIds, '', [0], null, (groupId) => {
                        router.pushUrl({
                            url: "pages/conversation/ConversationPage",
                            params: {
                                conversation: new Conversation(ConversationType.Group, groupId, 0)
                            }
                        }, router.RouterMode.Standard)
                    }, err => {

                    })
                }
            }
        }
    }

    async requestPermissions() {
        let atManager = AbilityAccessCtrl.createAtManager();
        let context = getContext(this);
        await atManager.requestPermissionsFromUser(context, permissions).then((data) => {
            Logger.info(TAG, `Request permissions succeed, data is: ${data}`);
        }).catch((error: Error) => {
            Logger.error(TAG, `Request permissions failed, error is: ${error}`);
        });
    }

    async checkAccessToken(permission: Permissions) {
        let atManager = AbilityAccessCtrl.createAtManager();
        let grantStatus: AbilityAccessCtrl.GrantStatus;
        let tokenID: number;
        try {
            let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
            let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
            tokenID = appInfo.accessTokenId;
        } catch (err) {
            console.error(`getBundleInfoForSelf failed, error: ${err}`);
        }

        try {
            grantStatus = await atManager.checkAccessToken(tokenID!, permission);
        } catch (err) {
            console.error(`checkAccessToken failed, error: ${err}`);
        }
        return grantStatus!;
    }

    async checkPermissions(): Promise<void> {
        for (let i = 0; i < permissions.length; i++) {
            let grantStatus: AbilityAccessCtrl.GrantStatus = await this.checkAccessToken(permissions[i]);
            if (grantStatus !== AbilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
                let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
                promptAction.showDialog({
                    title: '警告',
                    message: '没有权限，请自行去<设置>添加权限'
                })
                setTimeout(() => context.terminateSelf(), 1000);
            }
        }
    }

    async aboutToAppear() {
        await this.requestPermissions();
        await this.checkPermissions();
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
    SubMoreMenus() {
        Menu() {
            MenuItem({ startIcon: $r('app.media.faqiqunliao_iconfont'), content: "创建群聊" })
                .onClick(() => {
                    this.isNewPickContact = true
                    router.pushUrl({
                        url: "pages/picker/PickContactPage",
                    }, router.RouterMode.Standard).then(() => {
                    })
                })
            MenuItem({ startIcon: $r('app.media.faqiqunliao_iconfont'), content: "发起密聊" })
                .enabled(false)
                .onClick(() => {
                    showToast('发起密聊')
                })
            MenuItem({ startIcon: $r('app.media.tianjiapengyou_iconfont'), content: "添加朋友" })
                .onClick(() => {
                    router.pushUrl({
                        url: "pages/search/SearchUserPage",
                    }, router.RouterMode.Standard).then(() => {
                    })
                })
            MenuItem({ startIcon: $r('app.media.saoyisao1_iconfont'), content: "扫一扫" })
                .onClick(() => {
                    showToast('扫一扫')
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
                    router.pushUrl({
                        url: 'pages/search/SearchPortalPage'
                    })
                })

            Image($r('app.media.ic_add'))
                .width(30)
                .height(30)
                .padding(6)
                .margin({ left: 12 })
                .bindMenu(this.SubMoreMenus())
        }
        .margin({ right: 18 })
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
    }

    build() {
        Navigation() {
            Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
                TabContent() {
                    ConversationListTab({ conversationListTabUnreadCount: $conversationListTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[0], 0, $r('app.media.message_press'), $r('app.media.message_normal')))

                TabContent() {
                    ContactListTab({ contactTabUnreadCount: $contactTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[1], 1, $r('app.media.contacts_press'), $r('app.media.contacts_normal')))

                TabContent() {
                    DiscoveryTab({ discoveryTabUnreadCount: $discoveryTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[2], 2, $r('app.media.discovery_press'), $r('app.media.discovery_normal')))

                TabContent() {
                    MeTab({ meTabUnreadCount: $meTabUnreadCount })
                }
                .tabBar(this.TabBuilder(this.tabTitles[3], 3, $r('app.media.me_press'), $r('app.media.me_normal')))
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

        // .menus([
        //     { value: "", icon: "common/image/ic_search.png", action: () => {
        //         showToast('TODO search')
        //     } },
        //     { value: "", icon: "common/image/ic_add.png", action: () => {
        //         showToast('TODO add')
        //     } },
        // ])
    }
}