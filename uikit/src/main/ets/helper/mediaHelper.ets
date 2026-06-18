//https://blog.csdn.net/q919233914/article/details/134665775

/**
 * 多媒体辅助类
 */
import common from '@ohos.app.ability.common';
import picker from '@ohos.file.picker';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import cameraPicker from '@ohos.multimedia.cameraPicker';
import camera from '@ohos.multimedia.camera';
import { BusinessError } from '@ohos.base';
import { dataSharePredicates } from '@kit.ArkData';
import { compressImage, packing } from './imageVideoHelper';
import Config from '@wfc/client/src/main/ets/config'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { fileIo } from '@kit.CoreFileKit';
import { showToast } from '../common/utils/Toast';
import { request } from '@kit.BasicServicesKit';
import Long from '@wfc/client/src/main/ets/wfc/util/long';
import { stringValue } from '@wfc/client/src/main/ets/wfc/util/longUtil';
import { getImageSizeByOrgSizeToWeChat } from '../util/wechatImageUtil';
import ImageMessageContent from '@wfc/client/src/main/ets/wfc/messages/imageMessageContent';
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import { copyFileUri } from '../common/utils/FileUtil';

export interface MediaResult {
    type: number // 1 image, 2 video
    uri: string
    width: number
    height: number
    duration: number
    thumbnail: string
}

const TAG = "MediaHelper"

/**
 * 将一个 MediaResult 作为图片/视频消息发送到会话。
 * 通过 request 包上传时只能使用 applicationContext.cacheDir 目录下的文件，
 * 因此先把 uri 拷贝到 cacheDir 再构建消息内容。
 */
export function sendMediaResult(context: Context, conversation: Conversation, result: MediaResult) {
    if (result.type === 2) {
        let filePath = context.getApplicationContext().cacheDir + '/' + new Date().getTime() + '.mp4'
        copyFileUri(result.uri, filePath);
        let content = new VideoMessageContent(filePath, '', result.thumbnail, result.duration)
        wfc.sendConversationMessage(conversation, content, [], null, null, null, null, null);
    } else {
        let filePath = context.getApplicationContext().cacheDir + '/' + new Date().getTime() + '.jpg'
        copyFileUri(result.uri, filePath);
        let content = new ImageMessageContent(filePath, '', result.thumbnail)
        content.imageWidth = result.width;
        content.imageHeight = result.height;
        wfc.sendConversationMessage(conversation, content, [], null, null, null, null, null);
    }
}

/**
 * 选择图片
 */
export function selectImageAndVideo(maxSelectCount: number = 1): Promise<string[]> {
    return _selectMedia(photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE, maxSelectCount);
}

export function selectImage(maxSelectCount: number = 1): Promise<string[]> {
    return _selectMedia(photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectCount);
}

export function selectVideo(maxSelectCount: number = 1): Promise<string[]> {
    return _selectMedia(photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE, maxSelectCount);
}

export async function selectMedia(context: Context, mimeType: photoAccessHelper.PhotoViewMIMETypes = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE, maxSelectCount: number = 9): Promise<MediaResult[]> {
    try {
        let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
        photoSelectOptions.MIMEType = mimeType;
        photoSelectOptions.maxSelectNumber = maxSelectCount;
        let photoPicker = new photoAccessHelper.PhotoViewPicker();
        let photoUris = (await photoPicker.select(photoSelectOptions)).photoUris

        let results: MediaResult[] = await uri2MediaResult(context, photoUris)

        return results
    } catch (err) {
        console.error(TAG, 'PhotoViewPicker failed with err: ' + err);
        return Promise.reject(err);
    }
}

/**
 * 选择文件
 */
export function selectFile(): Promise<string> {
    try {
        let documentSelectOptions = new picker.DocumentSelectOptions();
        let documentPicker = new picker.DocumentViewPicker();
        return documentPicker.select(documentSelectOptions)
            .then((documentSelectResult) => {
                console.info(TAG, 'DocumentViewPicker.select successfully, DocumentSelectResult uri: ' + JSON.stringify(documentSelectResult));

                if (documentSelectResult && documentSelectResult.length > 0) {
                    let filePath = documentSelectResult[0];
                    console.info(TAG, 'DocumentViewPicker.select successfully, DocumentSelectResult uri: ' + filePath);
                    return filePath;
                } else {
                    return ''
                }

            })
        // .catch((err: Error) => {
        //     console.error(this.TAG, 'PhotoViewPicker.select failed with err: ' + err);
        //     return ''
        // });
    } catch (err) {
        console.error(TAG, 'PhotoViewPicker failed with err: ' + err);
        return Promise.reject(err);
    }
}

/**
 * 拍照
 */
export async function takePhoto(context: common.UIAbilityContext): Promise<MediaResult[]> {
    try {
        let pickerProfile: cameraPicker.PickerProfile = {
            cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
            videoDuration: 60
        };
        let pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(context,
            [cameraPicker.PickerMediaType.PHOTO, cameraPicker.PickerMediaType.VIDEO], pickerProfile);
        console.log("the pick pickerResult is:" + JSON.stringify(pickerResult));

        if (pickerResult.resultCode === 0) {
            return await uri2MediaResult(context, [pickerResult.resultUri])
        } else {
            return []
        }

    } catch (error) {
        let err = error as BusinessError;
        console.error(`the pick call failed. error code: ${err.code}`);
    }
    return []
}

export function downloadMedia(context: Context, messageUid: Long, url: string, progressCB?: (receivedSize: number, totalSize: number) => void): Promise<string> {
    return new Promise<string>(async (resolve, reject) => {
        let suffix = url.substring(url.lastIndexOf('.'))
        let fileName = url.substring(url.lastIndexOf('/') + 1)
        let ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        if (Config.DISABLED_RECEIVE_FILE_TYPES.includes(ext)) {
            showToast('不能接收该类型文件')
            reject('file type not allowed')
            return
        }
        let filePath = context.cacheDir + '/' + messageUid.toString() + suffix
        if (await fileIo.access(filePath)) {
            resolve(filePath)
            return
        }
        request.downloadFile(context, { url: url, filePath: filePath })
            .then((data: request.DownloadTask) => {
                let downloadTask: request.DownloadTask = data;
                downloadTask.on('complete', async () => {
                    let downloadInfo = await downloadTask.getTaskInfo()
                    resolve(downloadInfo.filePath)
                });
                downloadTask.on('fail', (data) => {
                    reject(new Error('download error: ' + data))
                })
                downloadTask.on('progress', (receivedSize: number, totalSize: number) => {
                    progressCB?.(receivedSize, totalSize)
                })
            })
            .catch((e: BusinessError) => {
                reject(e.message)
            })
    })
}

export function saveMedia(context: Context, messageUid: Long, url: string, type: 'image' | 'video') {
    downloadMedia(context, messageUid, url)
        .then(async filePath => {
            let helper = photoAccessHelper.getPhotoAccessHelper(context)
            let uri: string
            let extension = url.substring(url.lastIndexOf('.') + 1)
            if (type === 'image') {
                uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, extension)
            } else {
                uri = await helper.createAsset(photoAccessHelper.PhotoType.VIDEO, extension)
            }
            let sourceFile = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY)
            let targetFile = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
            fileIo.copyFileSync(sourceFile.fd, targetFile.fd);
            await fileIo.close(targetFile.fd)
            await fileIo.close(sourceFile.fd)
            await fileIo.unlink(sourceFile.path)
            showToast('保存成功')
        })
        .catch((e: Error) => {
            showToast('保存媒体失败' + e.message);
        })
}

export async function uri2MediaResult(context: Context, photoUris: string[], maxThumbnailSize: number = 20) {
    let results: MediaResult[] = []
    for (const uri of photoUris) {
        let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
        let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
        // 配置查询条件，使用PhotoViewPicker选择图片返回的uri进行查询
        predicates.equalTo('uri', uri);
        let fetchOption: photoAccessHelper.FetchOptions = {
            fetchColumns: [photoAccessHelper.PhotoKeys.WIDTH, photoAccessHelper.PhotoKeys.HEIGHT, photoAccessHelper.PhotoKeys.TITLE, photoAccessHelper.PhotoKeys.DURATION],
            predicates: predicates
        };
        let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> = await phAccessHelper.getAssets(fetchOption);
        // 得到uri对应的PhotoAsset对象，读取文件的部分信息
        const asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();

        // 6.1 developer beta 系统好像有 bug，视频时，width 和 height 是反的
        let orgWidth = asset.get(photoAccessHelper.PhotoKeys.WIDTH) as number
        let orgHeight = asset.get(photoAccessHelper.PhotoKeys.HEIGHT) as number

        let base64Data = ''
        // 根据原始宽高，按微信展示尺寸算法计算缩略图解码尺寸
        let thumbnailSize = getImageSizeByOrgSizeToWeChat(orgWidth, orgHeight)
        let pixelMap = await asset.getThumbnail({ width: thumbnailSize.width, height: thumbnailSize.height })
        if (pixelMap) {
            if (maxThumbnailSize > 0) {
                let compressedImageData = await compressImage(pixelMap!, maxThumbnailSize)
                base64Data = wfc.arrayBuffer_to_b64(compressedImageData)
            } else {
                let imageData = await packing(pixelMap, 50)
                base64Data = wfc.arrayBuffer_to_b64(imageData)
            }
        }
        console.info('asset width: ', orgWidth, thumbnailSize.width);
        console.info('asset height: ', orgHeight, thumbnailSize.height);

        results.push({
            type: asset.photoType,
            uri: asset.uri,
            width: orgWidth,
            height: orgHeight,
            duration: asset.photoType === 2 ? asset.get(photoAccessHelper.PhotoKeys.DURATION) as number : 0,
            thumbnail: base64Data
        })
    }
    return results
}

function _selectMedia(mimeType: photoAccessHelper.PhotoViewMIMETypes, maxSelectCount: number = 1): Promise<string[]> {
    try {
        let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
        photoSelectOptions.MIMEType = mimeType;
        photoSelectOptions.maxSelectNumber = maxSelectCount;
        let photoPicker = new photoAccessHelper.PhotoViewPicker();
        return photoPicker.select(photoSelectOptions)
            .then((photoSelectResult) => {
                console.info(TAG, 'PhotoViewPicker.select successfully, PhotoSelectResult uri: ' + JSON.stringify(photoSelectResult));

                if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
                    return photoSelectResult.photoUris;
                } else {
                    return []
                }

            })
        // .catch((err: Error) => {
        //     console.error(this.TAG, 'PhotoViewPicker.select failed with err: ' + err);
        //     return [];
        // });
    } catch (err) {
        console.error(TAG, 'PhotoViewPicker failed with err: ' + err);
        return Promise.reject(err);
    }
}
