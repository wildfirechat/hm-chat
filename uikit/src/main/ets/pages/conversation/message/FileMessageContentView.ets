import common from '@ohos.app.ability.common'
import { getFiletypeIcon, humanSize } from '../../../util/helper'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { openFile } from '../../../helper/fileOpenHelper'
import { FontSize, Radius } from '../../../common/design/Tokens'

@Component
export default struct FileMessageContentView {
    @Link message: Message

    fileMessageContent() {
        return this.message.messageContent as FileMessageContent
    }

    build() {
        Row() {
            Image(getFiletypeIcon(this.fileMessageContent().name))
                .width(52)
                .height(52)
                .margin(12)
            Column() {
                Text(this.fileMessageContent().name)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: 160 })
                    .fontSize(FontSize.lg)
                    .maxLines(1)
                    .fontColor($r('app.color.wf_primary_text'))
                Text(humanSize(this.fileMessageContent().size))
                    .fontSize(FontSize.sm)
                    .maxLines(1)
                    .fontColor($r('app.color.wf_tertiary_text'))
            }
            .padding({ right: 12 })
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(HorizontalAlign.Start)
        }
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .borderRadius(Radius.sm)
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
            let content = this.fileMessageContent()
            openFile(getContext(this) as common.UIAbilityContext, this.message.messageUid, content.remotePath, content.name)
        })
    }
}