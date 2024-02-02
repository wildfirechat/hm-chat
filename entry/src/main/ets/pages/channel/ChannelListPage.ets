import router from '@ohos.router'
import { showToast } from '../../common/utils/Toast'
import wfc from '../../wfc/client/wfc'
import EventType from '../../wfc/client/wfcEvent'
import ChannelInfo from '../../wfc/model/channelInfo'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'

@Entry
@Component
struct FavGroupListPage {
    @State channelList: ChannelInfo[] = []

    aboutToAppear() {

        getContext(this).eventHub.on(EventType.ChannelInfosUpdate, this.onChannelInfosUpdate)
        wfc.getRemoteListenedChannels((channelIds: string[]) => {
            channelIds.forEach((channelId: string) => {
                this.channelList.push(wfc.getChannelInfo(channelId, false))
            })
        }, (err: number) => {
            showToast('获取频道列表失败')
        })
    }

    aboutToDisappear() {
        getContext(this).eventHub.off(EventType.ChannelInfosUpdate, this.onChannelInfosUpdate)
    }

    onChannelInfosUpdate = (channelInfos: ChannelInfo[]) => {
        let channelMap: Map<string, ChannelInfo> = new Map()
        channelInfos.forEach((info: ChannelInfo) => {
            channelMap.set(info.channelId, info)
        })

        for (let i = 0; i < this.channelList.length; i++) {
            let channelId = this.channelList[i].channelId
            let info = channelMap.get(channelId)
            if (info) {
                this.channelList[i] = info
            }
        }
    }

    build() {
        Navigation() {
            Text('我订阅的频道')
                .width('100%')
                .height(24)
                .fontSize(13)
                .fontColor('#989898')
                .padding({ left: 10 })
                .backgroundColor('#E5E5E5')

            List() {
                ForEach(this.channelList, (channelInfo: ChannelInfo) => {
                    ListItem() {
                        Row() {
                            Image(channelInfo.portrait)
                                .alt($r('app.media.ic_channel_1'))
                                .width(40)
                                .height(40)
                                .borderRadius(4)
                            Text(channelInfo.name)
                                .maxLines(1)
                                .padding({ left: 10 })
                        }
                        .height(60)
                        .width('100%')
                        .padding({ left: 10, right: 10 })
                        .onClick(() => {
                            router.replaceUrl({
                                url: 'pages/conversation/ConversationPage',
                                params: {
                                    conversation: new Conversation(ConversationType.Channel, channelInfo.channelId, 0)
                                }
                            }, router.RouterMode.Standard)
                        })
                    }
                }, (channelInfo: ChannelInfo) => channelInfo.channelId + '-' + channelInfo.updateDt)
            }
            .width('100%')
            .height('100%')
            .divider({
                strokeWidth: 1,
                startMargin: 60
            })
        }
        .title('频道列表')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
        .menus([
            {
                value: '',
                icon: "common/image/ic_add.png",
                action: () => {
                    router.pushUrl({
                        url: 'pages/search/SearchPortalPage',
                        params: {
                            channel: true
                        }
                    }, router.RouterMode.Standard)
                }
            }
        ])
    }
}
