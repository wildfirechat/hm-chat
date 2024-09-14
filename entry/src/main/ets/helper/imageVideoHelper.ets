import { Size } from '@kit.ArkUI';
import { dataSharePredicates } from '@kit.ArkData';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import image from '@ohos.multimedia.image';
import wfc from '../wfc/client/wfc';
import fs from '@ohos.file.fs';
import { Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 *
 * @param context
 * @param uri 视频文件原始 uri
 * @param imageWH 压缩的目标宽高
 * @param maxImageSize 压缩后的图片大小，单位是 K，默认 20，<=0 时，不进行图片大小压缩
 * @returns
 */
export async function videoThumbnail(context: Context, uri: string, imageWH: Size, maxImageSize = 20): Promise<string> {

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
    let pixelMap = await asset.getThumbnail(imageWH)
    if (pixelMap) {
        if (maxImageSize > 0) {
            let compressedImageData = await compressImage(pixelMap!, maxImageSize)
            base64Data = wfc.arrayBuffer_to_b64(compressedImageData)
        } else {
            let imageData = await packing(pixelMap, 50)
            base64Data = wfc.arrayBuffer_to_b64(imageData)
        }
    }
    return base64Data;
}

/**
 *
 * @param context
 * @param uri 图片文件原始 uri
 * @param imageWH 压缩的目标宽高
 * @param maxImageSize 压缩后的图片大小，单位是 K，默认 20，<=0 时，不进行图片大小压缩
 * @returns
 */
export async function imageThumbnail(context: Context, uri: string, imageWH: Size, maxImageSize = 20): Promise<string> {
    let base64Data = ''
    let pixelMap = await _imageThumbnail(context, uri, imageWH)
    if (pixelMap) {
        if (maxImageSize > 0) {
            let compressedImageData = await compressImage(pixelMap!, maxImageSize)
            base64Data = wfc.arrayBuffer_to_b64(compressedImageData)
        } else {
            let imageData = await packing(pixelMap, 50)
            base64Data = wfc.arrayBuffer_to_b64(imageData)
        }
    }
    return base64Data;
}

export async function imageThumbnailFile(context: Context, uri: string, wh: Size): Promise<string> {
    let pixelMap = await _imageThumbnail(context, uri, wh)
    if (pixelMap) {
        try {
            let path = context.cacheDir + '/' + new Date().getTime() + '.jpg'
            let file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
            let packOpts: image.PackingOption = { format: "image/jpeg", quality: 50 };
            const imagePackerApi = image.createImagePacker();
            await imagePackerApi.packToFile(pixelMap, file.fd, packOpts)
            console.log('xxxxxx', fs.statSync(file.fd).size)
            fs.closeSync(file)
            return path;
        } catch (e) {
            console.error(e)
        }
    }

    return ''
}

async function _imageThumbnail(context: Context, uri: string, size: Size): Promise<image.PixelMap | null> {
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(photoAccessHelper.PhotoKeys.URI, uri.toString());
    let fetchOptions: photoAccessHelper.FetchOptions = {
        fetchColumns: [],
        predicates: predicates
    };

    try {
        let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> = await phAccessHelper.getAssets(fetchOptions);
        let photoAsset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
        console.info('getAssets photoAsset.uri : ' + photoAsset.uri);
        let pixelMap: image.PixelMap = await photoAsset.getThumbnail(size);
        fetchResult.close()
        return pixelMap
    } catch (err) {
        console.error('getAssets failed with err: ' + err);
        return null
    }
}

export async function imageSize(uri: string): Promise<Size> {
    let file = await fs.open(uri, fs.OpenMode.READ_ONLY)
    const imageSource: image.ImageSource = image.createImageSource(file.fd);
    let decodingOptions: image.DecodingOptions = {
        editable: true,
        desiredSize: { width: 0, height: 0 }
    }
    let pixelMap: PixelMap = await imageSource.createPixelMap(decodingOptions)
    let imageInfo = await pixelMap.getImageInfo()
    pixelMap.release()
    fs.close(file)

    return imageInfo.size
}


// 参考自：https://gitee.com/harmonyos-cases/cases/blob/master/CommonAppDevelopment/feature/imagecompression/src/main/ets/view/ImageCompression.ets
/**
 * 图片压缩
 * @param sourcePixelMap：原始待压缩图片的PixelMap对象
 * @param maxCompressedImageSize：指定图片的压缩目标大小，单位kb
 * @returns compressedImageInfo：返回最终压缩后的图片信息
 */
export async function compressImage(sourcePixelMap: image.PixelMap, maxCompressedImageSize: number): Promise<ArrayBuffer> {
    // 创建图像编码ImagePacker对象
    const imagePackerApi = image.createImagePacker();
    // 定义图片质量参数
    const IMAGE_QUALITY = 0;
    // 设置编码输出流和编码参数。图片质量参数quality范围0-100。
    const packOpts: image.PackingOption = { format: "image/jpeg", quality: IMAGE_QUALITY };
    // 通过PixelMap进行编码。compressedImageData为打包获取到的图片文件流。
    let compressedImageData: ArrayBuffer = await imagePackerApi.packing(sourcePixelMap, packOpts);
    // 压缩目标图像字节长度
    const maxCompressedImageByte = maxCompressedImageSize * 1024;
    // TODO 知识点：图片压缩。先判断设置图片质量参数quality为0时，packing能压缩到的图片最小字节大小是否满足指定的图片压缩大小。如果满足，则使用packing方式二分查找最接近指定图片压缩目标大小的quality来压缩图片。如果不满足，则使用scale对图片先进行缩放，采用while循环每次递减0.4倍缩放图片，再用packing（图片质量参数quality设置0）获取压缩图片大小，最终查找到最接近指定图片压缩目标大小的缩放倍数的图片压缩数据。
    if (maxCompressedImageByte > compressedImageData.byteLength) {
        // 使用packing二分压缩获取图片文件流
        compressedImageData = await packingImage(compressedImageData, sourcePixelMap, IMAGE_QUALITY, maxCompressedImageByte);
    } else {
        // 使用scale对图片先进行缩放，采用while循环每次递减0.4倍缩放图片，再用packing（图片质量参数quality设置0）获取压缩图片大小，最终查找到最接近指定图片压缩目标大小的缩放倍数的图片压缩数据
        let imageScale = 1; // 定义图片宽高的缩放倍数，1表示原比例。
        const REDUCE_SCALE = 0.4; // 图片缩小倍数
        // 判断压缩后的图片大小是否大于指定图片的压缩目标大小，如果大于，继续降低缩放倍数压缩。
        while (compressedImageData.byteLength > maxCompressedImageByte) {
            if (imageScale > 0) {
                // 性能知识点: 由于scale会直接修改图片PixelMap数据，所以不适用二分查找scale缩放倍数。这里采用循环递减0.4倍缩放图片，来查找确定最适
                // 合的缩放倍数。如果对图片压缩质量要求不高，建议调高每次递减的缩放倍数reduceScale，减少循环，提升scale压缩性能。
                imageScale = imageScale - REDUCE_SCALE; // 每次缩放倍数减0.4
                // 使用scale对图片进行缩放
                await sourcePixelMap.scale(imageScale, imageScale);
                // packing压缩
                compressedImageData = await packing(sourcePixelMap, IMAGE_QUALITY);
            } else {
                // imageScale缩放小于等于0时，没有意义，结束压缩。这里不考虑图片缩放倍数小于reduceScale的情况。
                break;
            }
        }
    }

    return compressedImageData;
}

/**
 * packing压缩
 * @param sourcePixelMap：原始待压缩图片的PixelMap
 * @param imageQuality：图片质量参数
 * @returns data：返回压缩后的图片数据
 */
export async function packing(sourcePixelMap: image.PixelMap, imageQuality: number): Promise<ArrayBuffer> {
    const imagePackerApi = image.createImagePacker();
    const packOpts: image.PackingOption = { format: "image/jpeg", quality: imageQuality };
    const data: ArrayBuffer = await imagePackerApi.packing(sourcePixelMap, packOpts);
    return data;
}

/**
 * packing二分方式循环压缩
 * @param compressedImageData：图片压缩的ArrayBuffer
 * @param sourcePixelMap：原始待压缩图片的PixelMap
 * @param imageQuality：图片质量参数
 * @param maxCompressedImageByte：压缩目标图像字节长度
 * @returns compressedImageData：返回二分packing压缩后的图片数据
 */
async function packingImage(compressedImageData: ArrayBuffer, sourcePixelMap: image.PixelMap, imageQuality: number, maxCompressedImageByte: number): Promise<ArrayBuffer> {
    // 图片质量参数范围为0-100，这里以10为最小二分单位创建用于packing二分图片质量参数的数组。
    const packingArray: number[] = [];
    const DICHOTOMY_ACCURACY = 10;
    // 性能知识点: 如果对图片压缩质量要求不高，建议调高最小二分单位dichotomyAccuracy，减少循环，提升packing压缩性能。
    for (let i = 0; i <= 100; i += DICHOTOMY_ACCURACY) {
        packingArray.push(i);
    }
    let left = 0; // 定义二分搜索范围的左边界
    let right = packingArray.length - 1; // 定义二分搜索范围的右边界
    // 二分压缩图片
    while (left <= right) {
        const mid = Math.floor((left + right) / 2); // 定义二分搜索范围的中间位置
        imageQuality = packingArray[mid]; // 获取二分中间位置的图片质量值
        // 根据传入的图片质量参数进行packing压缩，返回压缩后的图片文件流数据。
        compressedImageData = await packing(sourcePixelMap, imageQuality);
        // 判断查找一个尽可能接近但不超过压缩目标的压缩大小
        if (compressedImageData.byteLength <= maxCompressedImageByte) {
            // 二分目标值在右半边，继续在更高的图片质量参数（即mid + 1）中搜索
            left = mid + 1;
            // 判断mid是否已经二分到最后，如果二分完了，退出
            if (mid === packingArray.length - 1) {
                break;
            }
            // 获取下一次二分的图片质量参数（mid+1）压缩的图片文件流数据
            compressedImageData = await packing(sourcePixelMap, packingArray[mid + 1]);
            // 判断用下一次图片质量参数（mid+1）压缩的图片大小是否大于指定图片的压缩目标大小。如果大于，说明当前图片质量参数（mid）压缩出来的
            // 图片大小最接近指定图片的压缩目标大小。传入当前图片质量参数mid，得到最终目标图片压缩数据。
            if (compressedImageData.byteLength > maxCompressedImageByte) {
                compressedImageData = await packing(sourcePixelMap, packingArray[mid]);
                break;
            }
        } else {
            // 目标值不在当前范围的右半部分，将搜索范围的右边界向左移动，以缩小搜索范围并继续在下一次迭代中查找左半部分。
            right = mid - 1;
        }
    }
    return compressedImageData;
}