import { MMMediaEntry } from '../common/Types'
import { exist } from '../common/utils/FileUtil'
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent'

export function mediaEntry(message: Message): MMMediaEntry {
    if (message.messageContent.type === MessageContentType.Image) {
        let imageMessageContent = message.messageContent as ImageMessageContent
        return {
            message: message,
            type: 'image',
            url: imageMessageContent.localPath && exist(imageMessageContent.localPath) ? 'file://' + imageMessageContent.localPath : imageMessageContent.remotePath,
            thumbnail: 'data:image/jpeg;base64,' + imageMessageContent.thumbnail
        } as MMMediaEntry

    } else if (message.messageContent.type === MessageContentType.Video) {
        let videoMessageContent = message.messageContent as VideoMessageContent
        return {
            message: message,
            type: 'video',
            url: videoMessageContent.localPath && exist(videoMessageContent.localPath) ? 'file://' + videoMessageContent.localPath : videoMessageContent.remotePath,
            thumbnail: 'data:image/jpeg;base64,' + videoMessageContent.thumbnail,
            videoController: new VideoController()
        } as MMMediaEntry
    } else {
        throw new Error('message must be imageMessage or videoMessage')
    }
}
