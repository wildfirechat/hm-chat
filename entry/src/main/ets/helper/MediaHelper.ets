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


export class MediaHelper {
    private readonly TAG: string = 'MediaHelper';
    private mContext: common.Context;

    constructor(context: common.Context) {
        this.mContext = context;
    }

    /**
     * 选择图片
     */
    public selectImageAndVideo(maxSelectCount: number = 1): Promise<string[]> {
        return this.selectMedia(photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE, maxSelectCount);
    }

    public selectImage(maxSelectCount: number = 1): Promise<string[]> {
        return this.selectMedia(photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectCount);
    }

    public selectVideo(maxSelectCount: number = 1): Promise<string[]> {
        return this.selectMedia(photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE, maxSelectCount);
    }

    private selectMedia(mimeType: photoAccessHelper.PhotoViewMIMETypes, maxSelectCount: number = 1): Promise<string[]> {
        try {
            let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
            photoSelectOptions.MIMEType = mimeType;
            photoSelectOptions.maxSelectNumber = maxSelectCount;
            let photoPicker = new photoAccessHelper.PhotoViewPicker();
            return photoPicker.select(photoSelectOptions)
                .then((photoSelectResult) => {
                    console.info(this.TAG, 'PhotoViewPicker.select successfully, PhotoSelectResult uri: ' + JSON.stringify(photoSelectResult));

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
            console.error(this.TAG, 'PhotoViewPicker failed with err: ' + err);
            return Promise.reject(err);
        }
    }

    /**
     * 选择文件
     */
    public selectFile(): Promise<string> {
        try {
            let documentSelectOptions = new picker.DocumentSelectOptions();
            let documentPicker = new picker.DocumentViewPicker();
            return documentPicker.select(documentSelectOptions)
                .then((documentSelectResult) => {
                    console.info(this.TAG, 'DocumentViewPicker.select successfully, DocumentSelectResult uri: ' + JSON.stringify(documentSelectResult));

                    if (documentSelectResult && documentSelectResult.length > 0) {
                        let filePath = documentSelectResult[0];
                        console.info(this.TAG, 'DocumentViewPicker.select successfully, DocumentSelectResult uri: ' + filePath);
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
            console.error(this.TAG, 'PhotoViewPicker failed with err: ' + err);
            return Promise.reject(err);
        }
    }

    /**
     * 拍照
     */
    public async takePhoto(context: common.UIAbilityContext): Promise<cameraPicker.PickerResult | null> {
        // let want = {
        //     'uri': '',
        //     'action': wantConstant.Action.ACTION_IMAGE_CAPTURE,
        //     'parameters': {},
        // };
        // return context.startAbilityForResult(want)
        //     .then((result) => {
        //         console.info(this.TAG, `startAbility call back , ${JSON.stringify(result)}`);
        //         if (result.resultCode === 0 && result.want && !this.isNullOrEmpty(result.want.uri)) {
        //             //拍照成功
        //             console.info(this.TAG, 'takePhoto successfully, takePhotoResult uri: ' + result.want.uri);
        //             return result.want.uri;
        //         }
        //     }).catch((error) => {
        //         console.info(this.TAG, `startAbility error , ${JSON.stringify(error)}`);
        //         return error;
        //     });
        try {
            let pickerProfile: cameraPicker.PickerProfile = {
                cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
                videoDuration: 60
            };
            let pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(context,
                [cameraPicker.PickerMediaType.PHOTO, cameraPicker.PickerMediaType.VIDEO], pickerProfile);
            console.log("the pick pickerResult is:" + JSON.stringify(pickerResult));
            return pickerResult
        } catch (error) {
            let err = error as BusinessError;
            console.error(`the pick call failed. error code: ${err.code}`);
            return null
        }

        // let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
        // let fetchOptions: photoAccessHelper.FetchOptions = {
        //     fetchColumns: [],
        //     predicates: predicates
        // };
        // try {
        //     let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
        //     let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> = await phAccessHelper.getAssets(fetchOptions);
        //     if (fetchResult !== undefined) {
        //         console.info('fetchResult success');
        //         let photoAsset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
        //         if (photoAsset !== undefined) {
        //             console.info('photoAsset.displayName :' + photoAsset.displayName);
        //         }
        //     }
        // } catch (err) {
        //     console.error('getAssets failed, message = ', err);
        // }
        // return ""
    }

}
