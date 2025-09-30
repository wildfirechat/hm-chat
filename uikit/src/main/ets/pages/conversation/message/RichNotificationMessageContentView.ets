import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import RichNotificationMessageContent, { NData } from '@wfc/client/src/main/ets/wfc/messages/notification/richNotificationMessageContent'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig';

@Component
export default struct RichNotificationMessageContentView {
    @Prop message: Message
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    richNotificationMessageContent() {
        return this.message.messageContent as RichNotificationMessageContent
    }

    build() {
        Column() {
            Text(this.richNotificationMessageContent().title)
                .maxLines(1)
                .fontSize(15)
            Text(this.richNotificationMessageContent().desc)
                .maxLines(2)
                .fontSize(14)
                .padding({ top: 5, bottom: 5 })
            ForEach(this.richNotificationMessageContent().datas, (item: NData, index) => {
                Row() {
                    Text(item.key)
                        .width(100)
                        .fontSize(14)
                    Text(item.value)
                        .fontSize(14)
                }
            }, (item: NData, index) => index + '')
            Divider()
                .margin({ top: 10, bottom: 10 })
            Text(this.richNotificationMessageContent().exName)
        }
        .padding(10)
        .margin({ top: 10, bottom: 10 })
        .backgroundColor(Color.White)
        .alignItems(HorizontalAlign.Start)
        .constraintSize({ maxWidth: 300 })
        .borderRadius(4)
        .onClick(() => {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                'url': this.richNotificationMessageContent().exUrl,
                'title': this.richNotificationMessageContent().title
            } as Record<string, Object>)
        })
    }
}