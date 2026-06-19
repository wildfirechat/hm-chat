import ConferenceInviteMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/conferenceInviteMessageContent'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'
import { FontSize, Radius } from '../../../common/design/Tokens'

@Component
export default struct ConferenceInviteMessageContentView {
    @Link message: Message
    @State hostPortrait: string = ''
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear(): void {
        let content = this.message.messageContent as ConferenceInviteMessageContent
        wfc.getUserInfoEx(content.host, false, (info) => {
            this.hostPortrait = info.portrait
        }, err => {

        })
    }

    conferenceInviteMessageContent() {
        return this.message.messageContent as ConferenceInviteMessageContent
    }

    build() {
        Column() {
            Row() {
                Image(this.hostPortrait)
                    .width(52)
                    .height(52)
                    .margin(12)
                Column() {
                    Text(this.conferenceInviteMessageContent().title)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width(120)
                        .fontSize(FontSize.sm)
                        .maxLines(1)
                    Text(this.conferenceInviteMessageContent().desc)
                        .fontSize(FontSize.xs)
                        .maxLines(1)
                }
                .padding({ right: 12 })
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(HorizontalAlign.Start)
            }
            .justifyContent(FlexAlign.Start)

            Divider()
                .margin({ left: 12, right: 12, bottom: 12 })
            Text('会议邀请')
                .maxLines(1)
                .fontSize(FontSize.xs)
                .margin({ left: 12, bottom: 12 })
        }
        .onClick(() => {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConferenceInfoPage, {
                'conferenceId': this.conferenceInviteMessageContent().callId,
                'password': this.conferenceInviteMessageContent().password
            } as Record<string, string>)
        })
        .width(200)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .borderRadius(Radius.sm)
    }
}
