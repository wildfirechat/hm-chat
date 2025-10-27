import { showToast } from '../../../common/utils/Toast';
import avenginekit from '@wfc/avenginekit'
import CallStartMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/callStartMessageContent';
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import { timestampFormat } from '../../../util/helper';
import PickGroupMemberModal from '../../group/PickGroupMemberModal';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { checkAndRequestPermission } from '../../../helper/permissionHelper';

@Component
export default struct CallStartMessageContentView {
    @Link message: Message
    @State showPickGroupMemberToStartCallCoverModal: boolean = false

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
        .onClick(async () => {
            let content = this.message.messageContent as CallStartMessageContent;

            let cameraGranted = content.audioOnly ? true : await checkAndRequestPermission(this.getUIContext().getHostContext(), 'ohos.permission.CAMERA')
            let microphoneGranted = await checkAndRequestPermission(this.getUIContext().getHostContext(), 'ohos.permission.MICROPHONE')
            if (!cameraGranted || !microphoneGranted) {
                showToast('请授予摄像头和麦克风权限')
                return
            }
            if (this.message.conversation.type === ConversationType.Single) {
                avenginekit.startCall(this.message.conversation, [this.message.conversation.target], content.audioOnly)
            } else {
                this.showPickGroupMemberToStartCallCoverModal = true;
            }
        })
        .bindContentCover(this.showPickGroupMemberToStartCallCoverModal, this.pickGroupMemberToStartCallModal, {
            modalTransition: ModalTransition.DEFAULT,
            onAppear: () => {
            },

            onDisappear: () => {
                this.showPickGroupMemberToStartCallCoverModal = false
            }
        })
    }

    @Builder
    pickGroupMemberToStartCallModal() {
        PickGroupMemberModal({
            groupId: this.message.conversation.target,
            title: '选择群成员',
            initialCheckedUserIds: [wfc.getUserId()],
            uncheckableUserIds: [wfc.getUserId()],
            showPickGroupMemberModal: $showPickGroupMemberToStartCallCoverModal,
            onPickResult: (users: UserInfo[]) => {
                let content = this.message.messageContent as CallStartMessageContent;
                avenginekit.startCall(this.message.conversation, users.map(user => user.uid), content.audioOnly)
            }
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }
}
