/**
 * 文件打开辅助：会话里的文件消息、设置里的文件记录（所有文件 / 我的文件 / 会话文件）、收藏里的文件，
 * 统一走「先下载，再交给系统文件预览打开」这一套，行为保持一致。
 */
import common from '@ohos.app.ability.common';
import { filePreview } from '@kit.PreviewKit';
import { fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import Config from '@wfc/client/src/main/ets/config';
import Long from '@wfc/client/src/main/ets/wfc/util/long';
import { showToast } from '../common/utils/Toast';
import { downloadMedia } from './mediaHelper';

/**
 * 打开一个文件（文件消息 / 文件记录 / 收藏里的文件）
 * @param context UIAbilityContext
 * @param messageUid 消息 uid，作为本地缓存文件名
 * @param remoteUrl 文件的远端地址（消息里的 remotePath，文件记录里的 url）
 * @param name 文件名，用于后缀校验和预览标题
 */
export function openFile(context: common.UIAbilityContext, messageUid: Long, remoteUrl: string, name: string): void {
    if (!remoteUrl) {
        showToast('文件地址为空，无法打开');
        return;
    }
    let ext = name.substring(name.lastIndexOf('.') + 1).toLowerCase();
    if (Config.DISABLED_RECEIVE_FILE_TYPES.includes(ext)) {
        showToast('禁止打开此类型');
        return;
    }
    downloadMedia(context, messageUid, remoteUrl)
        .then(async (filePath: string) => {
            let uri = fileUri.getUriFromPath(filePath);
            let canPreview = await filePreview.canPreview(context, uri);
            if (!canPreview) {
                showToast('暂不支持预览该文件');
                return;
            }
            let typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(filePath.substring(filePath.lastIndexOf('.')));
            let typeObj = uniformTypeDescriptor.getTypeDescriptor(typeId);
            let mimeTypes = typeObj.mimeTypes;
            filePreview.openPreview(context, {
                title: name,
                uri: uri,
                mimeType: mimeTypes[0],
            })
        })
        .catch((e: Error) => {
            console.error('open file failed', e);
            showToast('文件预览失败');
        })
}
