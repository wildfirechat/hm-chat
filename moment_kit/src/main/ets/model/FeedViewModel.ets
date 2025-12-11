/**
 * 朋友圈 UI 数据模型
 * 基于 moment_client 的模型，扩展 UI 相关的状态
 */

import { Feed, FeedEntry, Comment, Profile, FeedCommentType } from '@wfc/moment_client';

/**
 * UI 层的朋友圈数据模型
 */
export class FeedViewModel {
    // 基础数据
    feed: Feed;
    // UI 状态
    isLiking: boolean = false; // 是否正在点赞
    isCommenting: boolean = false; // 是否正在评论
    isExpanded: boolean = false; // 文本是否展开（长文本折叠）
    showAllComments: boolean = false; // 是否显示所有评论

    constructor(feed: Feed) {
        this.feed = feed;
    }

    /**
     * 获取显示的评论列表
     */
    getDisplayComments(): Comment[] {
        if (!this.feed.comments || this.feed.comments.length === 0) {
            return [];
        }

        // 如果评论数量少于等于3条，全部显示
        if (this.feed.comments.length <= 3) {
            return this.feed.comments;
        }

        // 否则根据展开状态决定显示数量
        return this.showAllComments ? this.feed.comments : this.feed.comments.slice(0, 3);
    }

    /**
     * 是否有更多评论
     */
    hasMoreComments(): boolean {
        return !this.showAllComments && this.feed.comments && this.feed.comments.length > 3;
    }

    /**
     * 获取点赞列表
     */
    getLikesList(): Comment[] {
        if (!this.feed.comments) {
            return [];
        }
        return this.feed.comments.filter(comment => comment.type === 1); // FeedCommentType.Comment_Thumbup_Type
    }

    /**
     * 获取评论列表（排除点赞）
     */
    getCommentsList(): Comment[] {
        if (!this.feed.comments) {
            return [];
        }
        return this.feed.comments.filter(comment => comment.type === 0); // FeedCommentType.Comment_Comment_Type
    }

    /**
     * 是否已点赞
     */
    isLiked(currentUserId: string): boolean {
        const likes = this.getLikesList();
        return likes.some(like => like.sender === currentUserId);
    }

    /**
     * 获取显示文本
     */
    getDisplayText(): string {
        if (!this.feed.text) {
            return '';
        }

        const maxLength = 120; // 最大显示长度
        if (this.feed.text.length <= maxLength || this.isExpanded) {
            return this.feed.text;
        }

        return this.feed.text.substring(0, maxLength) + '...';
    }

    getImages(){
        return this.feed.medias
    }

    /**
     * 是否需要展开按钮
     */
    needsExpansion(): boolean {
        return this.feed.text.length > 120;
    }

    hasLikes() {
        return this.feed.comments.filter(c => c.type === FeedCommentType.Comment_Thumbup_Type).length > 0
    }

    hasComments() {
        return this.feed.comments.filter(c => c.type !== FeedCommentType.Comment_Thumbup_Type).length > 0
    }
}

/**
 * 朋友圈列表状态
 */
export interface FeedListState {
    feeds: FeedViewModel[];
    isLoading: boolean;
    isRefreshing: boolean;
    isLoadingMore: boolean;
    hasMore: boolean;
    error?: string;
}

/**
 * 朋友圈交互事件
 */
export interface FeedInteractionEvents {
    onLike: (feed: FeedViewModel) => void;
    onComment: (feed: FeedViewModel, commentText: string, replyTo?: string) => void;
    onDelete: (feed: FeedViewModel) => void;
    onUserClick: (userId: string) => void;
    onImageClick: (images: FeedEntry[], index: number) => void;
    onMoreComments: (feed: FeedViewModel) => void;
}

/**
 * 评论输入状态
 */
export interface CommentInputState {
    isVisible: boolean;
    feedId?: bigint;
    replyTo?: string;
    replyToName?: string;
    placeholder: string;
}