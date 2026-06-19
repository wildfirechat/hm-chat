import { showToast } from '../../../common/utils/Toast'
import { getFiletypeIcon, humanSize } from '../../../util/helper'
import Config from '@wfc/client/src/main/ets/config'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { filePreview } from '@kit.PreviewKit';
import { downloadMedia } from '../../../helper/mediaHelper';
import { fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
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
            let ext = this.fileMessageContent().name.substring(this.fileMessageContent().name.lastIndexOf('.') + 1).toLowerCase()
            if (Config.DISABLED_RECEIVE_FILE_TYPES.includes(ext)) {
                showToast('禁止打开此类型')
                return
            }
            let context = getContext(this)
            downloadMedia(context, this.message.messageUid, this.fileMessageContent().remotePath)
                .then(async filePath => {
                    let canPreview = await filePreview.canPreview(context, fileUri.getUriFromPath(filePath))
                    if (canPreview) {
                        let title = this.fileMessageContent().name
                        let uri = fileUri.getUriFromPath(filePath)
                        let typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(filePath.substring(filePath.lastIndexOf('.')));
                        let typeObj = uniformTypeDescriptor.getTypeDescriptor(typeId);
                        let mimeTypes = typeObj.mimeTypes;
                        filePreview.openPreview(context, {
                            title: title,
                            uri: uri,
                            mimeType: mimeTypes[0],
                        })
                    }
                })
        })
    }
}