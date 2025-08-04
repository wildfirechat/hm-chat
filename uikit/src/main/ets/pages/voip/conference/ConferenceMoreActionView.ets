import { showToast } from "../../../common/utils/Toast"

@Component
export default struct ConferenceMoreActionView {
    build() {
        Grid() {
            this.actionItem($r('app.media.av_conference_invite'), '邀请', () => {
                showToast('邀请 TODO')
            })
            this.actionItem($r('app.media.av_conference_chat'), '聊天', () => {
                showToast('聊天 TODO')
            })
            this.actionItem($r('app.media.av_conference_handup'), '举手', () => {
                showToast('举手 TODO')
            })
            this.actionItem($r('app.media.av_conference_minimize'), '悬浮', () => {
                showToast('悬浮 TODO')
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