/**
 * 记录会话界面中图片/视频消息缩略图在窗口中的位置（单位：vp）。
 * 图片预览拖拽返回时，预览图需要缩放并消失到对应消息缩略图的位置，
 * 由于预览弹窗与消息气泡是相互独立的组件，这里用一个全局表来共享位置信息。
 */
export interface MediaThumbRect {
    x: number
    y: number
    width: number
    height: number
}

class MediaMessagePositionRegistry {
    private rects: Map<string, MediaThumbRect> = new Map()

    update(uid: string, rect: MediaThumbRect): void {
        if (!uid) {
            return
        }
        this.rects.set(uid, rect)
    }

    get(uid: string): MediaThumbRect | undefined {
        if (!uid) {
            return undefined
        }
        return this.rects.get(uid)
    }

    remove(uid: string): void {
        if (!uid) {
            return
        }
        this.rects.delete(uid)
    }
}

export const mediaMessagePositionRegistry = new MediaMessagePositionRegistry()
