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
import image from '@ohos.multimedia.image';
import { compressImage, packing } from './imageVideoHelper';
import wfc from '../wfc/client/wfc';

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
 * 选择图片
 */
export function selectImageAndVideo(maxSelectCount: number = 1): Promise<string[]> {
    return selectMedia(photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE, maxSelectCount);
}

export function selectImage(maxSelectCount: number = 1): Promise<string[]> {
    return selectMedia(photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectCount);
}

export function selectVideo(maxSelectCount: number = 1): Promise<string[]> {
    return selectMedia(photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE, maxSelectCount);
}

function selectMedia(mimeType: photoAccessHelper.PhotoViewMIMETypes, maxSelectCount: number = 1): Promise<string[]> {
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

export async function selectMedia2(context: Context, mimeType: photoAccessHelper.PhotoViewMIMETypes = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE, maxSelectCount: number = 9, thumbnailWH: Size = { width: 200, height: 200 }, maxThumbnailSize: number = 20): Promise<MediaResult[]> {
    try {
        let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
        photoSelectOptions.MIMEType = mimeType;
        photoSelectOptions.maxSelectNumber = maxSelectCount;
        let photoPicker = new photoAccessHelper.PhotoViewPicker();
        let photoUris = (await photoPicker.select(photoSelectOptions)).photoUris

        let results: MediaResult[] = await _uri2MediaResult(context, photoUris, thumbnailWH, maxThumbnailSize)

        return results
    } catch (err) {
        console.error(TAG, 'PhotoViewPicker failed with err: ' + err);
        return Promise.reject(err);
    }
}

async function _uri2MediaResult(context: Context, photoUris: string[], thumbnailWH: Size = { width: 200, height: 200 }, maxThumbnailSize: number = 20) {
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
        asset.photoType

        let base64Data = ''
        let pixelMap = await asset.getThumbnail(thumbnailWH)
        if (pixelMap) {
            if (maxThumbnailSize > 0) {
                let compressedImageData = await compressImage(pixelMap!, maxThumbnailSize)
                base64Data = wfc.arrayBuffer_to_b64(compressedImageData)
            } else {
                let imageData = await packing(pixelMap, 50)
                base64Data = wfc.arrayBuffer_to_b64(imageData)
            }
        }
        console.info('asset width: ', asset.get(photoAccessHelper.PhotoKeys.WIDTH));
        console.info('asset height: ', asset.get(photoAccessHelper.PhotoKeys.HEIGHT));

        results.push({
            type: asset.photoType,
            uri: asset.uri,
            width: asset.get(photoAccessHelper.PhotoKeys.WIDTH) as number,
            height: asset.get(photoAccessHelper.PhotoKeys.HEIGHT) as number,
            duration: asset.photoType === 2 ? asset.get(photoAccessHelper.PhotoKeys.DURATION) as number : 0,
            thumbnail: base64Data
        })
    }
    return results
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
            return await _uri2MediaResult(context, [pickerResult.resultUri])
        } else {
            return []
        }

    } catch (error) {
        let err = error as BusinessError;
        console.error(`the pick call failed. error code: ${err.code}`);
    }
    return []
}
