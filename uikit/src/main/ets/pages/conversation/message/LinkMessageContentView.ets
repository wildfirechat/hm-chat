import LinkMessageContent from "@wfc/client/src/main/ets/wfc/messages/linkMessageContent";
import Message from "@wfc/client/src/main/ets/wfc/messages/message";
import { uikitNavigationDestinations } from "../../uikitNavigationConfig";

@Component
export default struct LinkMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message

    linkMessageContent() {
        return this.message.messageContent as LinkMessageContent
    }

    build() {
        Row() {
            Column() {
                Text(this.linkMessageContent().title)
                    .constraintSize({ maxWidth: 150 })
                    .maxLines(1)
                    .fontSize(18)
                Text(this.linkMessageContent().contentDigest)
                    .margin({ top: 10 })
                    .constraintSize({ maxWidth: 150 })
                    .maxLines(3)
                    .fontColor('#c8969696')
            }
            .padding(10)

            Image(this.linkMessageContent().thumbnail)
                .width(60)
                .height(60)
                .objectFit(ImageFit.CENTER)
                .borderRadius(4)
        }
        .backgroundColor(Color.White)
        .borderRadius(4)
        .onClick(() => {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                'url': this.linkMessageContent().url,
                'title': this.linkMessageContent().title
            } as Record<string, Object>)
        })
    }
}