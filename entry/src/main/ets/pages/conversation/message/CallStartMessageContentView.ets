import { showToast } from '../../../common/utils/Toast';
// import avengineKit from '../../../wfc/av/internal/avenginekitImpl';
import CallStartMessageContent from '../../../wfc/av/messages/callStartMessageContent';
import Message from '../../../wfc/messages/message'
import ConversationType from '../../../wfc/model/conversationType';

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
            let duration = Math.ceil((content.endTime - content.connectTime) / 1000);
            // if (duration > 3600) {
            //     text = ``
            // }else{
            //     text = `通话时长`
            // }
            // TODO
            text = `通话时长${duration}`
        } else {

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
            showToast('TODO')
            // if (this.message.conversation.type === ConversationType.Single) {
            //     let content = this.message.messageContent as CallStartMessageContent;
            //     avengineKit.startCall(this.message.conversation, [this.message.conversation.target], content.audioOnly)
            // } else {
            //     showToast(' TODO')
            // }
        })
    }
}