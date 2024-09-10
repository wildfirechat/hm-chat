import ConferenceInviteMessageContent from '../../../wfc/av/messages/conferenceInviteMessageContent'
import wfc from '../../../wfc/client/wfc'
import Message from '../../../wfc/messages/message'

@Component
export default struct ConferenceInviteMessageContentView {
    @Link message: Message
    @State hostPortrait: string = ''

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
                    .width(50)
                    .height(50)
                    .margin(10)
                Column() {
                    Text(this.conferenceInviteMessageContent().title)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .fontSize(18)
                        .maxLines(1)
                    Text(this.conferenceInviteMessageContent().desc)
                        .fontSize(12)
                        .maxLines(1)
                }
                .padding({ right: 10 })
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(HorizontalAlign.Start)
            }
            .justifyContent(FlexAlign.Start)

            Divider()
                .margin({ left: 10, right: 10, bottom: 10 })
            Text('会议邀请')
                .maxLines(1)
                .fontSize(12)
                .margin({ left: 10, bottom: 10 })
        }
        .width(200)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(4)
    }
}