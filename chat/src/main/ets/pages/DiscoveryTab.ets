import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import { uikitNavigationDestinations } from '@wfc/uikit/src/main/ets/pages/uikitNavigationConfig'
import BuildProfile from 'BuildProfile'
import uikit from '@wfc/uikit'

// 如果需要支持朋友圈时，请取消注释
import { momentNavigationDestinations } from '@wfc/momentkit'

@Preview
@Component
export default struct DiscoveryTab {
    @State unreadMomentCount: number = 10
    @Link discoveryTabUnreadCount: number
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
    }

    aboutToDisappear() {
    }

    onPageShow() {
    }

    build() {
        Column() {
            List() {
                // TODO lazyForEach https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/ui-ts-performance-improvement-recommendation-0000001477981001-V2
                ListItemGroup() {
                    if (BuildProfile.DEBUG) {
                        ListItem() {
                            Row() {
                                Image($r('app.media.ic_moment'))
                                    .width(20)
                                    .height(20)
                                    .objectFit(ImageFit.Contain)
                                Badge({
                                    position: BadgePosition.Right,
                                    maxCount: 99,
                                    count: this.unreadMomentCount,
                                    style: { badgeSize: 14, badgeColor: '#FA2A2D' }
                                }) {
                                    Text('朋友圈')
                                        .padding({ left: 10 })
                                }
                                .padding({ left: 20 })
                            }
                            .onClick(() => {
                                showToast('当前版本不支持朋友圈功能')
                                // 如果需要支持朋友圈时，请取消注释
                                this.mainNavPathStack.pushPathByName(momentNavigationDestinations.FeedListPage, {} as Record<string, Object>)
                            })
                            .padding({ left: 10, right: 10 })
                            .width('100%')
                            .height(56)
                        }
                        .stateStyles({
                            pressed: {
                                .backgroundColor('#E5E5E5')
                            },
                            normal: {
                                .backgroundColor(Color.White)
                            }
                        })
                    }

                    ListItem() {
                        Row() {
                            Image($r('app.media.ic_chatroom'))
                                .width(20)
                                .height(20)
                                .objectFit(ImageFit.Contain)
                            Text('聊天室')
                                .padding({ left: 10 })
                        }
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ChatroomListPage, {} as Record<string, Object>)
                        })
                        .padding({ left: 10, right: 10 })
                        .width('100%')
                        .height(56)
                    }
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })

                    ListItem() {
                        Row() {
                            Image($r('app.media.ic_robot'))
                                .width(20)
                                .height(20)
                                .objectFit(ImageFit.Contain)
                            Text('机器人')
                                .padding({ left: 10 })
                        }
                        .onClick(() => {
                            let conversation = new Conversation(ConversationType.Single, 'FireRobot', 0)
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                                'conversation': conversation
                            } as Record<string, Object>)
                        })
                        .padding({ left: 10, right: 10 })
                        .width('100%')
                        .height(56)
                    }
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })

                    ListItem() {
                        Row() {
                            Image($r('app.media.ic_conference'))
                                .width(20)
                                .height(20)
                                .objectFit(ImageFit.Contain)
                            Text('会议')
                                .padding({ left: 10 })
                        }
                        .onClick(() => {
                            if (uikit.isSupportConference()) {
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConferencePortalPage, {} as Record<string, Object>)
                            } else {
                                showToast('多人版音视频 SDK，不支持会议功能')
                            }
                        })
                        .padding({ left: 10, right: 10 })
                        .width('100%')
                        .height(56)
                    }
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })

                    ListItem() {
                        Row() {
                            Image($r('app.media.ic_dev_docs'))
                                .width(20)
                                .height(20)
                            Text('开发手册')
                                .padding({ left: 10 })
                        }
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                                'url': 'https://docs.wildfirechat.cn',
                                'title': '野火IM 开发文档'
                            } as Record<string, Object>)
                        })
                        .padding({ left: 10, right: 10 })
                        .width('100%')
                        .height(56)
                    }
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })
                }
                .divider({
                    strokeWidth: 0.6,
                    color: '#EDEDED',
                    startMargin: 40
                })
            }
            .width('100%')
            .height('100%')
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .backgroundColor('#EDEDED')
    }
}
