import { showToast } from '../../../common/utils/Toast';
import avenginekit from '@wfc/avenginekit'
import CallStartMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/callStartMessageContent';
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import { timestampFormat } from '../../../util/helper';

@Component
export default struct CallStartMessageContentView {
    @Link message: Message

    icon(): ResourceStr {
        let content = this.message.messageContent as CallStartMessageContent;
        return content.audioOnly ? $r('app.media.ic_msg_cell_voice_call') : $r('app.media.ic_msg_cell_video_call')
    }

    desc() {
        let content = this.message.messageContent as CallStartMessageContent;
        let text = '未接通'
        if (content.connectTime > 0 && content.endTime > 0) {
            let duration = Math.ceil(content.endTime - content.connectTime);
            text = `通话时长 ${timestampFormat(duration)}`
        }
        return text;
    }

    build() {
        Row() {
            Image(this.icon())
                .width(20)
                .height(20)
            Text(this.desc())
                .constraintSize({ minHeight: 40 })
                .padding({ left: 10 })
        }
        .padding({ left: 10, right: 10 })
        .backgroundColor(Color.White)
        .align(Alignment.Center)
        .borderRadius(4)
        .onClick(() => {
            if (this.message.conversation.type === ConversationType.Single) {
                let content = this.message.messageContent as CallStartMessageContent;
                avenginekit.startCall(this.message.conversation, [this.message.conversation.target], content.audioOnly)
            } else {
                showToast(' TODO')
            }
        })
    }
}