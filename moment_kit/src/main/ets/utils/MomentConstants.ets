/**
 * 朋友圈常量定义
 */

export class MomentConstants {
    static calculateImageGridHeight(imageCount: number): Length {
        // throw new Error('Method not implemented.');
        return 120;
    }
    // 颜色常量
    static readonly PRIMARY_COLOR: string = '#07C160'; // 微信绿
    static readonly BACKGROUND_COLOR: string = '#F7F7F7'; // 背景色
    static readonly CARD_BACKGROUND_COLOR: string = '#FFFFFF'; // 卡片背景色
    static readonly TEXT_PRIMARY_COLOR: string = '#191919'; // 主要文字色
    static readonly TEXT_SECONDARY_COLOR: string = '#888888'; // 次要文字色
    static readonly LINK_COLOR: string = '#576B95'; // 链接色（微信蓝）
    static readonly LIKE_COLOR: string = '#F56565'; // 点赞色
    static readonly DIVIDER_COLOR: string = '#E5E5E5'; // 分割线色
    static readonly INTERACTIONS_BACKGROUND_COLOR: string = '#F5F5F5'; // 互动区背景色
    static readonly ERROR_COLOR: string = '#F56565'; // 错误提示色
    static readonly COMMENT_BACKGROUND_COLOR = '#F0F0F0';

    // 尺寸定义
    static readonly AVATAR_SIZE = 40;
    static readonly AVATAR_SIZE_SMALL = 20;
    static readonly IMAGE_SIZE = 80;
    static readonly IMAGE_SIZE_LARGE = 120;
    static readonly CARD_PADDING = 16;
    static readonly ITEM_SPACING = 8;
    static readonly BORDER_RADIUS = 4;
    static readonly IMAGE_GRID_GAP = 4;
    static readonly IMAGE_GRID_WIDTH = 120;
    static readonly BORDER_RADIUS_SMALL = 4;

    static readonly IMAGE_SINGLE_WIDTH = 120;
    static readonly IMAGE_SINGLE_HEIGHT = 120;

    // 字体大小
    static readonly FONT_SIZE_LARGE = 16;
    static readonly FONT_SIZE_MEDIUM = 14;
    static readonly FONT_SIZE_SMALL = 12;
    static readonly FONT_SIZE_CAPTION = 10;
    static readonly FONT_SIZE_CONTENT = 10;

    // 布局常量
    static readonly MAX_IMAGES_PER_ROW = 3;
    static readonly MAX_TEXT_LINES = 6;
    static readonly TEXT_COLLAPSE_LENGTH = 120;
    static readonly INITIAL_COMMENTS_COUNT = 3;

    // 动画时长
    static readonly ANIMATION_DURATION = 200;
    static readonly REFRESH_DURATION = 1000;
}

/**
 * 朋友圈图片布局计算
 */
export class ImageLayoutCalculator {
    /**
     * 计算图片网格布局
     */
    static calculateImageLayout(imageCount: number, containerWidth: number): ImageLayoutInfo {
        const spacing = MomentConstants.ITEM_SPACING;
        const padding = MomentConstants.CARD_PADDING;
        const availableWidth = containerWidth - padding * 2;

        if (imageCount === 0) {
            return { columns: 0, imageSize: 0, totalHeight: 0 };
        }

        if (imageCount === 1) {
            // 单张图片，使用较大尺寸
            const imageSize = Math.min(MomentConstants.IMAGE_SIZE_LARGE, availableWidth * 0.6);
            return { columns: 1, imageSize, totalHeight: imageSize };
        }

        if (imageCount === 2) {
            // 两张图片，横向排列
            const imageSize = (availableWidth - spacing) / 2;
            return { columns: 2, imageSize, totalHeight: imageSize };
        }

        if (imageCount === 4) {
            // 四张图片，2x2 排列
            const imageSize = (availableWidth - spacing) / 2;
            const totalHeight = imageSize * 2 + spacing;
            return { columns: 2, imageSize, totalHeight };
        }

        // 其他情况，3列布局
        const columns = Math.min(imageCount, MomentConstants.MAX_IMAGES_PER_ROW);
        const imageSize = (availableWidth - spacing * (columns - 1)) / columns;
        const rows = Math.ceil(imageCount / columns);
        const totalHeight = imageSize * rows + spacing * (rows - 1);

        return { columns, imageSize, totalHeight };
    }
}

export interface ImageLayoutInfo {
    columns: number;
    imageSize: number;
    totalHeight: number;
}

/**
 * 时间格式化工具
 */
export class TimeFormatter {
    /**
     * 格式化朋友圈时间显示
     */
    static formatFeedTime(timestamp: number): string {
        const now = Date.now();
        const time = Number(timestamp);
        const diff = now - time;

        const minute = 60 * 1000;
        const hour = 60 * minute;
        const day = 24 * hour;
        const week = 7 * day;
        const month = 30 * day;
        const year = 365 * day;

        if (diff < minute) {
            return '刚刚';
        } else if (diff < hour) {
            return `${Math.floor(diff / minute)}分钟前`;
        } else if (diff < day) {
            return `${Math.floor(diff / hour)}小时前`;
        } else if (diff < week) {
            return `${Math.floor(diff / day)}天前`;
        } else if (diff < month) {
            return `${Math.floor(diff / week)}周前`;
        } else if (diff < year) {
            return `${Math.floor(diff / month)}个月前`;
        } else {
            return `${Math.floor(diff / year)}年前`;
        }
    }

    /**
     * 格式化详细时间
     */
    static formatDetailTime(timestamp: bigint): string {
        const date = new Date(Number(timestamp));
        const now = new Date();

        const isToday = date.toDateString() === now.toDateString();
        const isThisYear = date.getFullYear() === now.getFullYear();

        if (isToday) {
            return `今天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
        }

        if (isThisYear) {
            return `${date.getMonth() + 1}月${date.getDate()}日 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
        }

        return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
}