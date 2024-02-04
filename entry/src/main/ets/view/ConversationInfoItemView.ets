import Utils from '../common/Utils';
import helper from '../util/helper';
import wfc from '../wfc/client/wfc';
import ChannelInfo from '../wfc/model/channelInfo';
import ChatRoomInfo from '../wfc/model/chatRoomInfo';
import ConversationInfo from '../wfc/model/conversationInfo';
import ConversationType from '../wfc/model/conversationType';
import GroupInfo from '../wfc/model/groupInfo';

@Component
@Preview
export default struct ConversationInfoItemView {
    @State conversationInfo: ConversationInfo = null
    @State conversationItemPortrait: string = ''
    @State conversationItemName: string = ''
    /**
     * 仅显示头像和名称
     */
    private basicMode: boolean = false

    aboutToAppear() {
        Utils.computeConversationItemPortraitAndName(this.conversationInfo.conversation)
            .then(value => {
                this.conversationItemPortrait = value.portrait
                this.conversationItemName = value.name
            })

    }

    conversationUnreadCount() {
        return this.conversationInfo.unreadCount ? (this.conversationInfo.unreadCount.unreadMention + this.conversationInfo.unreadCount.unread + this.conversationInfo.unreadCount.unreadMentionAll) : 0
    }

    build() {
        Column() {
            Row() {
                Row() {
                    if (this.basicMode) {
                        Image(this.conversationItemPortrait)
                            .alt($r('app.media.avatar_def'))
                            .height(44)
                            .width(44)
                            .padding(2)
                            .borderRadius(4)
                    } else if (this.conversationInfo.isSilent && this.conversationUnreadCount() > 0) {
                        Badge({
                            // count: this.conversationInfo.unreadCount ? (this.conversationInfo.unreadCount.unreadMention + this.conversationInfo.unreadCount.unread + this.conversationInfo.unreadCount.unreadMentionAll) : 0,
                            // maxCount: 99,
                            value: '',
                            position: BadgePosition.RightTop,
                            style: { badgeSize: 8, badgeColor: '#FA2A2D' }
                        }) {
                            Image(this.conversationItemPortrait)
                                .alt($r('app.media.avatar_def'))
                                .height(44)
                                .width(44)
                                .padding(2)
                                .borderRadius(4)
                        }
                        .backgroundColor(Color.Green)
                    } else {
                        Badge({
                            count: this.conversationUnreadCount(),
                            maxCount: 99,
                            position: BadgePosition.RightTop,
                            style: { badgeSize: 14, badgeColor: '#FA2A2D' }
                        }) {
                            Image(this.conversationItemPortrait)
                                .alt($r('app.media.avatar_def'))
                                .height(44)
                                .width(44)
                                .padding(2)
                                .borderRadius(4)
                        }
                    }
                }
                .width(64)
                .height(64)
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)

                Column() {
                    Row() {
                        Text(this.conversationItemName)
                            .fontColor('#1d1d1d')
                            .fontSize(16)
                            .maxLines(1)
                            .layoutWeight(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        if (!this.basicMode) {
                            Text(helper.timeFormat(this.conversationInfo.timestamp))
                                .fontSize(12)
                                .fontColor('#b3b3b3')
                        }
                    }

                    if (!this.basicMode) {
                        Row() {
                            Text(`${this.conversationInfo.lastMessage ? this.conversationInfo.lastMessage.messageContent.digest(this.conversationInfo.lastMessage) : ''}`)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .fontSize(13)
                                .fontColor('#b3b3b3')
                                .margin({ right: 10 })
                                .maxLines(1)
                                .layoutWeight(1)
                            if (this.conversationInfo.isSilent) {
                                Image($r('app.media.block_notification'))
                                    .width(14)
                                    .height(14)
                                    .alt('')
                            }
                        }
                        .width('100%')
                    }
                }
                .height('100%')
                .layoutWeight(1)
                .padding({ right: 10, top: 7, bottom: 7 })
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.SpaceAround)
            }
            .height(72)
            .width('100%')
            .padding({ top: 7, bottom: 7 })

            Divider()
                .margin({ left: 60 })
                .color(!this.basicMode && this.conversationInfo.top ? '#E5E5E5' : '#F7F7F7')
        }
        .width('100%')
        .backgroundColor(!this.basicMode && this.conversationInfo.top ? 0xEBEBEB : '')
    }
}
