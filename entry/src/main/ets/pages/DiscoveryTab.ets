import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import router from '@ohos.router'
import { showToast } from '../common/utils/Toast'

@Preview
@Component
export default struct DiscoveryTab {
    @State unreadMomentCount: number = 10
    @Link discoveryTabUnreadCount: number

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
                            showToast('TODO')
                            // router.pushUrl({
                            //     url: 'pages/contact/FriendRequestListPage'
                            // })
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
                            Image($r('app.media.ic_chatroom'))
                                .width(20)
                                .height(20)
                                .objectFit(ImageFit.Contain)
                            Text('聊天室')
                                .padding({ left: 10 })
                        }
                        .onClick(() => {
                            showToast('TODO: 聊天室')
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
                            showToast('TODO: 机器人')
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
                            router.pushUrl({
                                url: 'pages/misc/WebViewPage', params: {
                                    url: 'https://docs.wildfirechat.cn',
                                    title: '开发手册'
                                }
                            }, router.RouterMode.Standard)
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
                    strokeWidth: 1,
                    startMargin: 40

                })
            }
            .width('100%')
            .height('100%')
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ top: 5 })
    }
}
