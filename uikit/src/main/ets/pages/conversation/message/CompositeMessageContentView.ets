import CompositeMessageContent from '@wfc/client/src/main/ets/wfc/messages/compositeMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'

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
                    .fontColor($r('app.color.wf_primary_text'))
                Text(this.compositeMessageContent?.compositeDigest())
                    .fontSize(14)
                    .margin({ top: 5, bottom: 5 })
                    .fontColor($r('app.color.wf_tertiary_text'))
            }
            .borderWidth({ bottom: '1px' })
            .borderColor($r('app.color.wf_divider'))
            .alignItems(HorizontalAlign.Start)
            .constraintSize({minWidth: 200})

            Text('聊天记录')
                .fontSize(12)
                .margin({ top: 5 })
                .fontColor($r('app.color.wf_tertiary_text'))
        }
        .margin({ top: 4 })
        .alignItems(HorizontalAlign.Start)
        .padding(10)
        .borderRadius(4)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .onClick(() => {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.CompositeMessagePreviewPage, {
                'message': this.message
            } as Record<string, Object>)
        })
    }
}