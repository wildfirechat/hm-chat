import CompositeMessageContent from '../../../wfc/messages/compositeMessageContent'
import Message from '../../../wfc/messages/message'
import { navigationDestinations } from '../../navigationConfig'

@Component
export default struct CompositeMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message
    private compositeMessageContent?: CompositeMessageContent;

    aboutToAppear(): void {
        this.compositeMessageContent = this.message.messageContent as CompositeMessageContent
    }

    build() {
        Column() {
            Column() {
                Text(this.compositeMessageContent?.title)
                    .fontSize(16)
                Text(this.compositeMessageContent?.compositeDigest())
                    .fontSize(14)
                    .margin({ top: 5, bottom: 5 })
            }
            .borderWidth({ bottom: '1px' })
            .borderColor('#EDEDED')
            .alignItems(HorizontalAlign.Start)

            Text('聊天记录')
                .fontSize(12)
                .margin({ top: 5 })
        }
        .margin({ top: 4 })
        .alignItems(HorizontalAlign.Start)
        .padding(10)
        .borderRadius(4)
        .backgroundColor(Color.White)
        .onClick(() => {
            this.mainNavPathStack.pushPathByName(navigationDestinations.PreviewCompositeMessagePage, {
                'message': this.message
            } as Record<string, Object>)
        })
    }
}