import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MeetingMinutesMessageContent from '@wfc/client/src/main/ets/wfc/messages/meetingMinutesMessageContent'
import Config from '@wfc/client/src/main/ets/config'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'
import { FontSize, Radius } from '../../../common/design/Tokens'

@Component
export default struct MeetingMinutesMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message

    content(): MeetingMinutesMessageContent {
        return this.message.messageContent as MeetingMinutesMessageContent
    }

    build() {
        Column() {
            if (this.content().title && this.content().title.length > 0) {
                Text(this.content().title)
                    .fontSize(FontSize.sm)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#303133')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ bottom: 4 })
            }
            if (this.content().text && this.content().text.length > 0) {
                Text(this.content().text)
                    .fontSize(FontSize.sm)
                    .fontColor('#606266')
                    .maxLines(5)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
        }
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor('#f5f7fa')
        .borderRadius(Radius.sm)
        .width('100%')
        .onClick(() => {
            let meetingId = this.content().meetingId;
            let isFromMinutesRobot = this.message.conversation.target === Config.AI_MINUTES_ROBOT_ID
                || this.message.from === Config.AI_MINUTES_ROBOT_ID;
            if (Config.AI_MINUTES_ROBOT_ID && Config.AI_MINUTES_ROBOT_ID.length > 0
                && isFromMinutesRobot
                && meetingId && meetingId.length > 0) {
                let encodedConferenceId = encodeURIComponent(meetingId);
                let url = `${Config.MINUTES_URL}?conferenceId=${encodedConferenceId}`;
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                    'url': url,
                    'title': this.content().title || '会议纪要'
                } as Record<string, Object>)
            }
        })
    }
}
