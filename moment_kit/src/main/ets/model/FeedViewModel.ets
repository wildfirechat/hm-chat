/**
 * 朋友圈 UI 数据模型
 * 基于 moment_client 的模型，扩展 UI 相关的状态
 */

import { Feed, FeedEntry, Comment, FeedCommentType } from '@wfc/moment_client';

/**
 * UI 层的朋友圈数据模型
 */
@Observed
export class FeedViewModel {
    // 基础数据
    feed: Feed;
    // UI 状态
    isLiking: boolean = false; // 是否正在点赞
    isCommenting: boolean = false; // 是否正在评论
    showAllComments: boolean = false; // 是否显示所有评论
    updateTime: number = Date.now(); // 互动后递增，驱动 @ObjectLink 局部刷新

    constructor(feed: Feed) {
        this.feed = feed;
        this.updateTime = Date.now();
    }

    /**
     * 标记数据已变更，递增版本号以触发依赖该 view model 的列表项重建/刷新
     */
    markDirty() {
        this.updateTime = this.updateTime + 1;
    }

    /**
     * 获取点赞列表
     */
    getLikesList(): Comment[] {
        if (!this.feed.comments) {
            return [];
        }
        return this.feed.comments.filter(comment => comment.type === FeedCommentType.Comment_Thumbup_Type);
    }

    /**
     * 获取评论列表（排除点赞）
     */
    getCommentsList(): Comment[] {
        if (!this.feed.comments) {
            return [];
        }
        return this.feed.comments.filter(comment => comment.type === FeedCommentType.Comment_Comment_Type);
    }

    /**
     * 是否已点赞
     */
    isLiked(currentUserId: string): boolean {
        const likes = this.getLikesList();
        return likes.some(like => like.sender === currentUserId);
    }

    getImages(): FeedEntry[] {
        return this.feed.medias || [];
    }

    hasLikes(): boolean {
        return (this.feed.comments || []).some(c => c.type === FeedCommentType.Comment_Thumbup_Type);
    }

    hasComments(): boolean {
        return (this.feed.comments || []).some(c => c.type !== FeedCommentType.Comment_Thumbup_Type);
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
    onVideoClick: (videoUrl: string, thumbUrl: string) => void;
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