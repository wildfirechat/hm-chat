import { showToast } from "../../../common/utils/Toast"
import ConferencePage from "./ConferencePage"
import { BusinessError } from "@kit.BasicServicesKit"
import { uikitNavigationDestinations} from "../../uikitNavigationConfig";
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'

@Component
export default struct ConferenceMoreActionView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    conferencePage?: ConferencePage

    build() {
        Grid() {
            this.actionItem($r('app.media.av_conference_invite'), '邀请', () => {
                this.conferencePage?.inviteNewParticipant()
            })
            this.actionItem($r('app.media.av_conference_chat'), '聊天', () => {
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                    'conversation': new Conversation(ConversationType.ChatRoom, '', 0)
                } as Record<string, Object>)
            })
            this.actionItem($r('app.media.av_conference_handup'), '举手', () => {
                showToast('举手 TODO')
            })
            this.actionItem($r('app.media.av_conference_minimize'), '悬浮', () => {
                this.conferencePage?.minimize()
            })
            this.actionItem($r('app.media.av_conference_record'), '录制', () => {
                showToast('录制 TODO')
            })
            this.actionItem($r('app.media.av_conference_setting'), '设置', () => {
                showToast('设置 TODO')
            })
        }
        .rowsTemplate('1fr 1fr 1fr 1fr')
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .width('100%')
        .height('100%')
    }

    @Builder
    actionItem(src: ResourceStr, title: string, cb: () => void) {
        GridItem() {

            Column() {
                Image(src)
                    .draggable(false)
                    .width(30)
                    .height(30)
                Text(title)
                    .margin({ top: 10 })
                    .fontSize(13)
            }
            .onClick(cb)
        }
    }
}
