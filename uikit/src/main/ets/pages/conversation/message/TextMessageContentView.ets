import wfc from '@wfc/client';
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import { showToast } from '../../../common/utils/Toast';
import { navigationDestinations } from '../../navigationConfig';

@Component
export default struct TextMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message
    @Prop textPadding: Length | Padding = 10

    quoteInfoDesc() {
        let quoteInfo = (this.message.messageContent as TextMessageContent).quoteInfo
        return `${quoteInfo?.userDisplayName}: ${quoteInfo?.messageDigest}`
    }

    showQuoteMessage() {
        let quoteInfo = (this.message.messageContent as TextMessageContent).quoteInfo
        let messageUid = quoteInfo!.messageUid
        let msg = wfc.getMessageByUid(messageUid)
        if (msg) {
            this.mainNavPathStack.pushPathByName(navigationDestinations.TextMessagePreviewPage, {
                'message': msg
            } as Record<string, object>)
        } else {
            showToast('引用的消息本地不存在')
        }
    }

    build() {
        if ((this.message.messageContent as TextMessageContent).quoteInfo) {
            Column() {
                Text(this.message.messageContent.digest(this.message))
                    .padding(this.textPadding)
                    .constraintSize({ minHeight: 40 })
                    .backgroundColor(Color.White)
                    .borderRadius(4)
                    .enableDataDetector(true)
                    .dataDetectorConfig({
                        types: [TextDataDetectorType.URL, TextDataDetectorType.PHONE_NUMBER, TextDataDetectorType.EMAIL]
                    })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(navigationDestinations.TextMessagePreviewPage, {
                            'message': this.message
                        } as Record<string, object>)
                    })

                Text(this.quoteInfoDesc())
                    .padding(this.textPadding)
                    .margin({ top: 8 })
                    .constraintSize({ minHeight: 40 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .backgroundColor('#E7E7E7')
                    .borderRadius(4)
                    .onClick(() => {
                        this.showQuoteMessage()
                    })
            }
            // 0 out
            .alignItems(this.message.direction === 0 ? HorizontalAlign.End : HorizontalAlign.Start)

        } else {
            Text(this.message.messageContent.digest(this.message))
                .padding(this.textPadding)
                .constraintSize({ minHeight: 40 })
                .backgroundColor(Color.White)
                .borderRadius(4)
                .enableDataDetector(true)
                .dataDetectorConfig({
                    types: [TextDataDetectorType.URL, TextDataDetectorType.PHONE_NUMBER, TextDataDetectorType.EMAIL]
                })
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.TextMessagePreviewPage, {
                        'message': this.message
                    } as Record<string, object>)
                })
        }
    }
}