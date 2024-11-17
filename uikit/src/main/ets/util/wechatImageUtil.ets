import { Size } from "@kit.ArkUI";

/**
 * 获取类似微信的缩放后的宽高
 *
 * @param imgOrgWidth
 * @param imgOrgHeight
 * @return
 */
export function getImageSizeByOrgSizeToWeChat(imgOrgWidth: number, imgOrgHeight: number): Size {
    let imageWidth = 300;
    let imageHeight = 300;
    const maxWidth = 400;
    const maxHeight = 400;
    const minWidth = 300;
    const minHeight = 250;

    if (imgOrgWidth === 0 && imgOrgHeight === 0) {
        return {
            width: imageWidth,
            height: imageHeight
        }
    }

    if (imgOrgWidth / maxWidth > imgOrgHeight / maxHeight) {
        if (imgOrgWidth >= maxWidth) {
            imageWidth = maxWidth;
            imageHeight = (imgOrgHeight * maxWidth) / imgOrgWidth;
        } else {
            imageWidth = imgOrgWidth;
            imageHeight = imgOrgHeight;
        }
        if (imgOrgHeight < minHeight) {
            imageHeight = minHeight;
            const width = (imgOrgWidth * minHeight) / imgOrgHeight;
            imageWidth = width > maxWidth ? maxWidth : width;
        }
    } else {
        if (imgOrgHeight >= maxHeight) {
            imageHeight = maxHeight;
            imageWidth = imgOrgHeight / maxHeight > 10 ? (imgOrgWidth * 5 * maxHeight) / imgOrgHeight : (imgOrgWidth * maxHeight) / imgOrgHeight;
        } else {
            imageHeight = imgOrgHeight;
            imageWidth = imgOrgWidth;
        }
        if (imgOrgWidth < minWidth) {
            imageWidth = minWidth;
            const height = (imgOrgHeight * minWidth) / imgOrgWidth;
            imageHeight = height > maxHeight ? maxHeight : height;
        }
    }

    return {
        width: imageWidth,
        height: imageHeight
    }
}

