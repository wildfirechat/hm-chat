import { showToast } from '../../../common/utils/Toast'
import { getFiletypeIcon, humanSize } from '../../../util/helper'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { filePreview } from '@kit.PreviewKit';
import { downloadMedia } from '../../../helper/mediaHelper';
import { fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor } from '@kit.ArkData';

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