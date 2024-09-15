import wfc from '../wfc/client/wfc'
import EventType from '../wfc/client/wfcEvent'
import ConnectionStatus from '../wfc/client/connectionStatus'
import { UIUserInfo } from '../common/Types'
import BasicDataSource from '../common/BasicDataSource'
import { loadAndGroupContactUserInfos } from '../helper/asyncTaskHelper'
import { navigationDestinations } from './navigationConfig'
import orgServer from '../api/orgServer'
import Config from '../config'
import UserInfo from '../wfc/model/userInfo'
import { showToast } from '../common/utils/Toast'

interface ContactListHeader {
    title: string,
    icon: ResourceStr
    // badgeValue 优先级更高
    badgeCount: number,
    badgeValue: string,
    action: () => void
}

@Component
export default struct ContactListTab {
    private contactDataSource: ContactDataSource = new ContactDataSource()
    @Link contactTabUnreadCount: number
    private contactCategories = [
        '↑', '☆', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
        'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
        'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#'
    ]
    private scroller: Scroller = new Scroller()
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State contactListHeaders: ContactListHeader[] = [
        {
            title: '新的朋友',
            icon: $r('app.media.ic_new_friend'),
            badgeCount: 0,
            badgeValue: '',
            action: () => {
                wfc.clearUnreadFriendRequestStatus()
                this.contactTabUnreadCount = 0
                this.contactListHeaders[0].badgeCount = 0
                this.mainNavPathStack.pushPathByName(navigationDestinations.FriendRequestListPage, {} as Record<string, Object>)
            }
        },
        {
            title: '群组(保存到通讯录的群组)',
            icon: $r('app.media.ic_group_chat'),
            badgeCount: 0,
            badgeValue: '',
            action: () => {
                this.mainNavPathStack.pushPathByName(navigationDestinations.FavGroupListPage, {} as Record<string, Object>)
            }
        },
        {
            title: '频道',
            icon: $r('app.media.ic_channel_1'),
            badgeCount: 0,
            badgeValue: '',
            action: () => {
                this.mainNavPathStack.pushPathByName(navigationDestinations.ChannelListPage, {} as Record<string, Object>)
            }
        },
    ]

    aboutToAppear() {
        let unreadFriendRequestCount = wfc.getUnreadFriendRequestCount()
        this.contactTabUnreadCount = unreadFriendRequestCount
        this.contactListHeaders[0].badgeCount = unreadFriendRequestCount


        this.loadContact()
        this.loadMyOrganization()
        wfc.eventEmitter!.on(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
        wfc.eventEmitter!.on(EventType.UserOnlineEvent, this.onUserOnlineState)
        wfc.eventEmitter?.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
    }

    aboutToDisappear() {
        wfc.eventEmitter!.off(EventType.ConnectionStatusChanged, this.onConnectionStatusChange)
        wfc.eventEmitter!.off(EventType.UserOnlineEvent, this.onUserOnlineState)
        wfc.eventEmitter?.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)
    }

    onConnectionStatusChange = (status: number) => {
        if (status === ConnectionStatus.ConnectionStatusConnected) {
            this.loadContact()
        }
    }
    onUserInfosUpdate = (infos: UserInfo[]) => {
        this.loadContact()
    }
    onUserOnlineState = (status: number) => {
        let userOnlineStateMap = wfc.getUserOnlineStateMap();

        let groupedContactUserInfos = this.contactDataSource.groupedContactUserInfos.map(uiUserinfo => {
            uiUserinfo.onlineState = userOnlineStateMap.get(uiUserinfo.userInfo.uid)
            return uiUserinfo
        })
        this.contactDataSource.setContactInfos(groupedContactUserInfos)
    }

    loadContact() {
        loadAndGroupContactUserInfos(true).then(groupedUserInfos => {
            let userOnlineStateMap = wfc.getUserOnlineStateMap();
            let groupedContactUserInfos = groupedUserInfos.map(uiUserinfo => {
                uiUserinfo.onlineState = userOnlineStateMap.get(uiUserinfo.userInfo.uid)
                return uiUserinfo
            })
            this.contactDataSource.setContactInfos(groupedContactUserInfos)
        })
    }

    async loadMyOrganization() {
        if (!Config.ORGANIZATION_SERVER) {
            return
        }
        let rootOrgs = await orgServer.getRootOrganization()
        rootOrgs.forEach(org => {
            this.contactListHeaders.push({
                title: org.name,
                icon: $r('app.media.ic_organization'),
                badgeCount: 0,
                badgeValue: '',
                action: () => {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.OrganizationTreePage, { 'organization': org } as Record<string, Object>)
                }
            })
        })

        let myOrgRelations = await orgServer.getRelationShip(wfc.getUserId())
        let orgIds = myOrgRelations.map(rs => rs.organizationId)
        let myOrgs = await orgServer.getOrganizations(orgIds)
        myOrgs.forEach(org => {
            this.contactListHeaders.push({
                title: org.name,
                icon: $r('app.media.ic_organization_expended'),
                badgeCount: 0,
                badgeValue: '',
                action: () => {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.OrganizationTreePage, { 'organization': org } as Record<string, Object>)
                }
            })

        })
    }

    onPageShow() {
    }

    scrollContactListToCategory(category: string) {
        let listIndex = 0
        if (category === '↑') {
            listIndex = 0
        } else if (category === '☆') {
            listIndex = this.contactListHeaders.length
        } else {
            listIndex = -1
            for (let i = 0; i < this.contactDataSource.groupedContactUserInfos.length; i++) {
                let gu = this.contactDataSource.groupedContactUserInfos[i]
                if (gu.category === category) {
                    listIndex = this.contactListHeaders.length + i
                    break
                }
            }
        }
        if (listIndex !== -1) {
            this.scroller.scrollToIndex(listIndex)
        }
    }

    build() {
        Stack() {
            Column() {
                Text('联系人列表加载中...')
            }
            .justifyContent(FlexAlign.Center)
            .align(Alignment.Center)
            .width('100%')
            .height('100%')

            Column() {
                List({ scroller: this.scroller }) {
                    // TODO lazyForEach https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/ui-ts-performance-improvement-recommendation-0000001477981001-V2
                    // header
                    ForEach(this.contactListHeaders,
                        (header: ContactListHeader) => {
                            ListItem() {
                                Row() {
                                    Image(header.icon)
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    if (header.badgeValue) {
                                        Badge({
                                            position: BadgePosition.Right,
                                            value: header.badgeValue,
                                            style: { badgeSize: 14, badgeColor: '#FA2A2D' }
                                        }) {
                                            Text(header.title)
                                                .padding({ left: 10 })
                                        }
                                        .padding({ left: 20 })
                                    } else {
                                        Badge({
                                            position: BadgePosition.Right,
                                            maxCount: 99,
                                            count: header.badgeCount,
                                            style: { badgeSize: 14, badgeColor: '#FA2A2D' }
                                        }) {
                                            Text(header.title)
                                                .padding({ left: 10 })
                                        }
                                        .padding({ left: 20 })
                                    }
                                }
                                .onClick(() => {
                                    header.action()
                                })
                                .padding({ left: 10, right: 10 })
                                .width('100%')
                                .height(60)
                            }
                            .stateStyles({
                                pressed: {
                                    .backgroundColor('#E5E5E5')
                                },
                                normal: {
                                    .backgroundColor(Color.White)
                                }
                            })
                        },
                        (header: ContactListHeader) => header.title + '-' + header.badgeCount + '-' + header.badgeValue
                    )

                    // fav contact && contact
                    LazyForEach(this.contactDataSource, (groupedUserInfo: UIUserInfo) => {
                        ListItem() {
                            Column() {
                                if (groupedUserInfo.showCategory) {
                                    Row() {
                                        Text(groupedUserInfo.category)
                                            .width('100%')
                                            .fontSize(13)
                                            .fontColor('#828282')
                                    }
                                    .height(30)
                                    .padding({ left: 10 })
                                    .alignItems(VerticalAlign.Center)
                                    .backgroundColor('#EDEDED')
                                }
                                Row() {
                                    Image(groupedUserInfo.userInfo.portrait)
                                        .alt($r('app.media.avatar_def'))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Column() {
                                        Text(groupedUserInfo.userInfo.displayName)
                                            .maxLines(1)
                                            .padding({ left: 10 })
                                        if (groupedUserInfo.onlineState) {
                                            Text(groupedUserInfo.onlineState.desc())
                                                .maxLines(1)
                                                .padding({ left: 10, top: 4 })
                                                .fontSize(11)
                                        }
                                    }
                                    .alignItems(HorizontalAlign.Start)
                                }
                                .height(60)
                                .width('100%')
                                .padding({ left: 10, right: 10 })
                                .onClick(() => {
                                    this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, {
                                        'userInfo': groupedUserInfo.userInfo
                                    } as Record<string, Object>)
                                })
                            }
                            .alignItems(HorizontalAlign.Start)
                            .width('100%')
                        }
                        .stateStyles({
                            pressed: {
                                .backgroundColor('#E5E5E5')
                            },
                            normal: {
                                .backgroundColor(Color.White)
                            }
                        })
                    }, (info: UIUserInfo) => info.category + '-' + info.userInfo.uid + '-' + info.userInfo.updateDt)
                }
                .divider({
                    strokeWidth: 1,
                    startMargin: 60,
                })
                .scrollBar(BarState.Off)
                .width('100%')
                .height('100%')
            }
            .height('100%')
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .backgroundColor(Color.White)
            .padding({ top: 5 })

            AlphabetIndexer({ arrayValue: this.contactCategories, selected: 0 })
                .selectedColor(0xFFFFFF)// 选中项文本颜色
                .popupColor(Color.Black)// 弹出框文本颜色
                .selectedBackgroundColor(0xCCCCCC)// 选中项背景颜色
                .popupBackground(0xD2B48C)// 弹出框背景颜色
                .usingPopup(true)// 是否显示弹出框
                .selectedFont({ size: 16, weight: FontWeight.Bolder })// 选中项字体样式
                .popupFont({ size: 30, weight: FontWeight.Bolder })// 弹出框内容的字体样式
                .itemSize(28)// 每一项的尺寸大小
                .alignStyle(IndexerAlign.Left)// 弹出框在索引条右侧弹出
                .onSelect((index: number) => {
                    let alphabet = this.contactCategories[index];
                    this.scrollContactListToCategory(alphabet)
                })
                .popupPosition({ x: -100, y: 100 })
                .onRequestPopupData((index: number) => {
                    // if (this.alphabetIndex[index] == 'A') {
                    //     return this.arrayA // 当选中A时，弹出框里面的提示文本列表显示A对应的列表arrayA，选中B、C、L时也同样
                    // } else if (this.value[index] == 'B') {
                    //     return this.arrayB
                    // } else if (this.value[index] == 'C') {
                    //     return this.arrayC
                    // } else if (this.value[index] == 'L') {
                    //     return this.arrayL
                    // } else {
                    //     return [] // 选中其余子母项时，提示文本列表为空
                    // }
                    let alphabet = this.contactCategories[index];
                    this.scrollContactListToCategory(alphabet)
                    return []
                })
                .onPopupSelect((index: number) => {
                    console.info('onPopupSelected:' + index)
                })
        }
        .alignContent(Alignment.End)
        .width('100%')
        .height('100%')
    }
}

class ContactDataSource extends BasicDataSource<UIUserInfo> {
    groupedContactUserInfos: UIUserInfo[] = []

    setContactInfos(userInfos: UIUserInfo[]): void {
        this.groupedContactUserInfos = userInfos
        this.notifyDataReload()
    }

    setFavContactInfos(userInfos: UIUserInfo[]): void {
        this.notifyDataReload()
    }

    public totalCount(): number {
        return this.groupedContactUserInfos.length
    }

    public getData(index: number): UIUserInfo {
        return this.groupedContactUserInfos[index]
    }
}
