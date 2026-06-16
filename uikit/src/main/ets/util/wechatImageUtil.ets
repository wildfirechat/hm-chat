/**
 * 获取类似微信的缩放后的宽高
 *
 * @param imgOrgWidth
 * @param imgOrgHeight
 * @return
 */
export function getImageSizeByOrgSizeToWeChat(imgOrgWidth: number, imgOrgHeight: number): Size {
    const maxWidth = 540;
    const maxHeight = 540;
    const minWidth = 160;
    const minHeight = 160;

    if (imgOrgWidth <= 0 || imgOrgHeight <= 0) {
        return {
            width: 300,
            height: 300
        }
    }

    const ratio = imgOrgWidth / imgOrgHeight;
    let width: number;
    let height: number;

    if (ratio >= 1.0) { // 宽图或正方形
        width = maxWidth;
        height = Math.floor(width / ratio);
        if (height < minHeight) {
            height = minHeight;
            // 对于超宽图，宽度保持最大，高度拉伸到最小高度，由裁剪组件处理
        }
    } else { // 长图
        height = maxHeight;
        width = Math.floor(height * ratio);
        if (width < minWidth) {
            width = minWidth;
            // 对于超长图，高度保持最大，宽度拉伸到最小宽度，由裁剪组件处理
        }
    }

    // 最终返回结果，配合 CENTER_CROP 使用效果最佳
    return {
        width: Math.min(width, maxWidth),
        height: Math.min(height, maxHeight)
    }
}

