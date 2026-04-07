import Message from "@wfc/client/src/main/ets/wfc/messages/message";
import StreamingTextGeneratingMessageContent from "@wfc/client/src/main/ets/wfc/messages/streamingTextGeneratingMessageContent";
import StreamingTextGeneratedMessageContent from "@wfc/client/src/main/ets/wfc/messages/streamingTextGeneratedMessageContent";

@Component
export default struct StreamingTextMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message

    streamingMessageContent() {
        if (this.message.messageContent instanceof StreamingTextGeneratingMessageContent) {
            return (this.message.messageContent as StreamingTextGeneratingMessageContent).text
        } else if (this.message.messageContent instanceof StreamingTextGeneratedMessageContent) {
            return (this.message.messageContent as StreamingTextGeneratedMessageContent).text
        }
        return ''
    }

    isGenerated() {
        return this.message.messageContent instanceof StreamingTextGeneratedMessageContent;
    }

    build() {
        Column() {
            Text(this.streamingMessageContent())
                .constraintSize({ minHeight: 40 })
                .padding(10)
                .enableDataDetector(true)
                .dataDetectorConfig({
                    types: [TextDataDetectorType.URL, TextDataDetectorType.PHONE_NUMBER, TextDataDetectorType.EMAIL]
                })
            if (!this.isGenerated()) {
                LoadingProgress().width(20).height(20)
            } else {
                Text('本内容由 AI 生成')
                    .fontSize(12)
                    .fontColor(Color.Gray)
                    .padding({left: 10, top: 5, bottom: 5})
            }
        }
        .borderRadius(4)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .alignItems(HorizontalAlign.Start)
    }
}