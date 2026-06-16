/**
 * 朋友圈常量定义
 */

export class MomentConstants {
    /**
     * 计算图片网格高度，传入内容区实际宽度
     */
    static calculateImageGridHeight(imageCount: number, contentWidth: number = 240): number {
        if (imageCount === 0) return 0;
        if (imageCount === 1) return MomentConstants.IMAGE_SINGLE_HEIGHT;

        const columns = imageCount === 4 ? 2 : 3;
        const rows = Math.ceil(imageCount / columns);
        const itemSize = (contentWidth - (columns - 1) * MomentConstants.IMAGE_GRID_GAP) / columns;
        return rows * itemSize + (rows - 1) * MomentConstants.IMAGE_GRID_GAP;
    }

    // 颜色常量
    static readonly PRIMARY_COLOR: Resource = $r('app.color.primary');
    static readonly BACKGROUND_COLOR: Resource = $r('app.color.background');
    static readonly CARD_BACKGROUND_COLOR: Resource = $r('app.color.card_background');
    static readonly TEXT_PRIMARY_COLOR: Resource = $r('app.color.text_primary');
    static readonly TEXT_SECONDARY_COLOR: Resource = $r('app.color.text_secondary');
    static readonly LINK_COLOR: Resource = $r('app.color.link');
    static readonly LIKE_COLOR: Resource = $r('app.color.like');
    static readonly LIKE_ACTIVE_COLOR: Resource = $r('app.color.like_active');
    static readonly DIVIDER_COLOR: Resource = $r('app.color.divider');
    static readonly INTERACTIONS_BACKGROUND_COLOR: Resource = $r('app.color.interactions_background');
    static readonly ERROR_COLOR: Resource = $r('app.color.error');
    static readonly COMMENT_BACKGROUND_COLOR: Resource = $r('app.color.comment_background');
    static readonly ACTION_MENU_BG_COLOR: Resource = $r('app.color.action_menu_background');

    // 头像尺寸
    static readonly AVATAR_SIZE = 44;
    static readonly AVATAR_SIZE_LARGE = 68;
    static readonly AVATAR_SIZE_SMALL = 20;

    // 图片相关
    static readonly IMAGE_SINGLE_WIDTH = 200;
    static readonly IMAGE_SINGLE_HEIGHT = 200;
    static readonly IMAGE_GRID_GAP = 4;

    // 布局
    static readonly CARD_PADDING = 16;
    static readonly FEED_LEFT_OFFSET = 54; // avatar(44) + margin(10)
    static readonly BORDER_RADIUS = 6;
    static readonly BORDER_RADIUS_SMALL = 3;
    static readonly BORDER_RADIUS_LARGE = 8;
    static readonly ITEM_SPACING = 10;

    // Header
    static readonly COVER_HEIGHT = 260;

    // 字体大小
    static readonly FONT_SIZE_TITLE = 18;
    static readonly FONT_SIZE_USERNAME = 16;
    static readonly FONT_SIZE_CONTENT = 15;
    static readonly FONT_SIZE_LARGE = 15;
    static readonly FONT_SIZE_MEDIUM = 14;
    static readonly FONT_SIZE_SMALL = 13;
    static readonly FONT_SIZE_CAPTION = 11;

    // 布局常量
    static readonly MAX_IMAGES_PER_ROW = 3;
    static readonly MAX_TEXT_LINES = 5;
    static readonly TEXT_COLLAPSE_LENGTH = 140;
    static readonly INITIAL_COMMENTS_COUNT = 3;

    // 动画时长
    static readonly ANIMATION_DURATION = 200;
    static readonly REFRESH_DURATION = 800;
}

/**
 * 时间格式化工具
 */
export class TimeFormatter {
    static formatFeedTime(timestamp: number): string {
        const now = Date.now();
        const time = Number(timestamp) * (Number(timestamp) < 1e10 ? 1000 : 1); // 兼容秒/毫秒时间戳
        const diff = now - time;

        const minute = 60 * 1000;
        const hour = 60 * minute;
        const day = 24 * hour;
        const week = 7 * day;

        if (diff < minute) {
            return '刚刚';
        } else if (diff < hour) {
            return `${Math.floor(diff / minute)}分钟前`;
        } else if (diff < day) {
            return `${Math.floor(diff / hour)}小时前`;
        } else if (diff < 2 * day) {
            return '昨天';
        } else if (diff < week) {
            return `${Math.floor(diff / day)}天前`;
        } else {
            const date = new Date(time);
            const now = new Date();
            const isThisYear = date.getFullYear() === now.getFullYear();
            const month = (date.getMonth() + 1).toString().padStart(2, '0');
            const day2 = date.getDate().toString().padStart(2, '0');
            const hh = date.getHours().toString().padStart(2, '0');
            const mm = date.getMinutes().toString().padStart(2, '0');
            if (isThisYear) {
                return `${month}-${day2} ${hh}:${mm}`;
            }
            return `${date.getFullYear()}-${month}-${day2}`;
        }
    }
}
