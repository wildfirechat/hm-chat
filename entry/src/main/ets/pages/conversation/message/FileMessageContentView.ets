import { showToast } from '../../../common/utils/Toast'
import { getFiletypeIcon, humanSize } from '../../../util/helper'
import FileMessageContent from '../../../wfc/messages/fileMessageContent'
import Message from '../../../wfc/messages/message'

@Component
export default struct FileMessageContentView {
    @Link message: Message

    fileMessageContent() {
        return this.message.messageContent as FileMessageContent
    }

    build() {
        Row() {
            Image(getFiletypeIcon(this.fileMessageContent().name))
                .width(50)
                .height(50)
                .margin(10)
            Column() {
                Text(this.fileMessageContent().name)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: 160 })
                    .fontSize(18)
                    .maxLines(1)
                Text(humanSize(this.fileMessageContent().size))
                    .fontSize(14)
                    .maxLines(1)
            }
            .padding({ right: 10 })
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(HorizontalAlign.Start)
        }
        .backgroundColor(Color.White)
        .borderRadius(4)
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
            showToast('TODO 预览文件')
        })
    }
}