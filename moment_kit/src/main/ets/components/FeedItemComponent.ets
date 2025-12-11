import { FeedViewModel, FeedInteractionEvents} from '../model/FeedViewModel';
import { Comment, FeedCommentType, FeedContentType, FeedEntry } from '@wfc/moment_client';
import { MomentConstants, TimeFormatter } from '../utils/MomentConstants';
import wfc from '@wfc/client';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import { thirdPaymentService } from '@kit.PaymentKit';

@Component
export struct FeedItemComponent {
    @Prop feedViewModel: FeedViewModel;
    @Prop currentUserId: string;
    @Prop events: FeedInteractionEvents;
    onCommentClick: (replyTo?: string, replyToName?: string) => void = () => {
    };
    // 内部状态
    @State expandedText: boolean = false;

    aboutToAppear() {
        // 预加载相关用户信息
        const userIds = new Set<string>();
        userIds.add(this.feedViewModel.feed.sender);

        // 添加评论中的用户ID
        if (this.feedViewModel.feed.comments) {
            this.feedViewModel.feed.comments.forEach(comment => {
                userIds.add(comment.sender);
                if (comment.replyTo) {
                    userIds.add(comment.replyTo);
                }
            });
        }

        wfc.getUserInfos(Array.from(userIds))
    }

    /**
     * 获取用户显示信息
     */
    private getUserDisplayInfo(userId: string): UserInfo {
        return wfc.getUserInfo(userId);
    }

    build() {
        Column() {
            // 用户信息行
            this.buildUserInfoRow()

            // 文本内容
            if (this.feedViewModel.feed.text && this.feedViewModel.feed.text.trim()) {
                this.buildTextContent()
            }

            // 媒体内容（图片/视频）
            if (this.feedViewModel.feed.medias?.length > 0) {
                this.buildMediaContent()
            }

            // 时间和操作按钮
            this.buildTimeAndActions()

            // 点赞和评论区域
            if (this.feedViewModel.feed.comments?.length > 0) {
                this.buildInteractionsArea()
            }

            // 分割线
            Divider()
                .color(MomentConstants.DIVIDER_COLOR)
                .strokeWidth(0.5)
                .margin({ top: 12 })
        }
        .width('100%')
        .padding(MomentConstants.CARD_PADDING)
        .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    private buildUserInfoRow() {
        Row() {
            // 头像
            Image(wfc.getUserInfo(this.feedViewModel.feed.sender).portrait || $r("app.media.icon"))
                .width(MomentConstants.AVATAR_SIZE)
                .height(MomentConstants.AVATAR_SIZE)
                .borderRadius(MomentConstants.AVATAR_SIZE / 2)
                .backgroundColor('#F0F0F0')
                .onClick(() => {
                    this.events.onUserClick(this.feedViewModel.feed.sender);
                })

            // 用户名
            Text(this.getUserDisplayInfo(this.feedViewModel.feed.sender).displayName)
                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                .fontWeight(FontWeight.Medium)
                .margin({ left: 12 })
                .layoutWeight(1)
                .onClick(() => {
                    this.events.onUserClick(this.feedViewModel.feed.sender);
                })

            // 删除按钮（只有自己的朋友圈才显示）
            if (this.feedViewModel.feed.sender === this.currentUserId) {
                Image($r('app.media.icon')) // TODO: 使用删除图标
                    .width(16)
                    .height(16)
                    .fillColor(MomentConstants.TEXT_SECONDARY_COLOR)
                    .onClick(() => {
                        this.events.onDelete(this.feedViewModel);
                    })
            }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 8 })
    }

    @Builder
    private buildTextContent() {
        Column() {
            Text(this.feedViewModel.feed.text!)
                .fontSize(16)
                .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                // .lineHeight(MomentConstants.FONT_SIZE_CONTENT * 1.4)
                .maxLines(this.expandedText ? undefined : 6)
                .textOverflow({ overflow: this.expandedText ? TextOverflow.None : TextOverflow.Ellipsis })
                .onClick(() => {
                    if (!this.expandedText && this.feedViewModel.feed.text!.length > 120) {
                        this.expandedText = true;
                    }
                })

            // 展开/收起按钮
            if (!this.expandedText && this.feedViewModel.feed.text!.length > 120) {
                Text('全文')
                    .fontSize(MomentConstants.FONT_SIZE_SMALL)
                    .fontColor(MomentConstants.LINK_COLOR)
                    .margin({ top: 4 })
                    .onClick(() => {
                        this.expandedText = true;
                    })
            } else if (this.expandedText && this.feedViewModel.feed.text!.length > 120) {
                Text('收起')
                    .fontSize(MomentConstants.FONT_SIZE_SMALL)
                    .fontColor(MomentConstants.LINK_COLOR)
                    .margin({ top: 4 })
                    .onClick(() => {
                        this.expandedText = false;
                    })
            }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 8 })
    }

    @Builder
    private buildMediaContent() {
        if (this.feedViewModel.feed.type === FeedContentType.Content_Image_Type) {
            this.buildImageGrid()
        } else if (this.feedViewModel.feed.type === FeedContentType.Content_Video_Type) {
            this.buildVideoPlayer()
        }
    }

    images(): FeedEntry[] {
        return this.feedViewModel.getImages();
    }

    @Builder
    private buildImageGrid() {
        // const images = this.feedViewModel.getImageUrls();
        // const imageCount = images.length;

        if (this.images().length === 1) {
            // 单张图片
            Image(this.images()[0].mediaUrl)
                .width(MomentConstants.IMAGE_SINGLE_WIDTH)
                .height(MomentConstants.IMAGE_SINGLE_HEIGHT)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .objectFit(ImageFit.Cover)
                .backgroundColor('#F0F0F0')
                .onClick(() => {
                    this.events.onImageClick(this.images(), 0);
                })
                .margin({ bottom: 8 })
        } else if (this.images().length> 1) {
            // 多张图片网格
            // const columns = imageCount === 4 ? 2 : 3;
            // const rows = Math.ceil(imageCount / columns);

            Grid() {
                ForEach(this.images().slice(0, 9), (imageUrl: string, index: number) => {
                    GridItem() {
                        Image(imageUrl)
                            .width('100%')
                            .height('100%')
                            .borderRadius(MomentConstants.BORDER_RADIUS_SMALL)
                            .objectFit(ImageFit.Cover)
                            .backgroundColor('#F0F0F0')
                            .onClick(() => {
                                this.events.onImageClick(this.images(), index);
                            })
                    }
                }, (imageUrl: string, index: number) => `image_${index}`)
            }
            .columnsTemplate(this.images().length === 4 ? '1fr 1fr' : '1fr 1fr 1fr')
            .rowsTemplate(new Array(Math.ceil(this.images().length / (this.images().length === 4 ? 2: 3))).fill('1fr').join(' '))
            .columnsGap(MomentConstants.IMAGE_GRID_GAP)
            .rowsGap(MomentConstants.IMAGE_GRID_GAP)
            .width(MomentConstants.IMAGE_GRID_WIDTH)
            .height(MomentConstants.calculateImageGridHeight(this.images().length))
            .margin({ bottom: 8 })
        }
    }

    @Builder
    private buildVideoPlayer() {
        // TODO: 实现视频播放器
        Row() {
            Image($r('app.media.icon')) // TODO: 使用播放图标
                .width(40)
                .height(40)
                .fillColor('#FFFFFF')

            Text('视频')
                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                .fontColor('#FFFFFF')
                .margin({ left: 8 })
        }
        .width(MomentConstants.IMAGE_SINGLE_WIDTH)
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#000000')
        .borderRadius(MomentConstants.BORDER_RADIUS)
        .margin({ bottom: 8 })
        .onClick(() => {
            // TODO: 播放视频
        })
    }

    @Builder
    private buildTimeAndActions() {
        Row() {
            // 时间
            Text(TimeFormatter.formatFeedTime(this.feedViewModel.feed.serverTime))
                .fontSize(MomentConstants.FONT_SIZE_SMALL)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                .layoutWeight(1)

            // 操作按钮
            Row({ space: 16 }) {
                // 评论按钮
                Row() {
                    Image($r('app.media.icon')) // TODO: 使用评论图标
                        .width(16)
                        .height(16)
                        .fillColor(MomentConstants.TEXT_SECONDARY_COLOR)

                    Text('评论')
                        .fontSize(MomentConstants.FONT_SIZE_SMALL)
                        .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                        .margin({ left: 4 })
                }
                .onClick(() => {
                    this.onCommentClick();
                })

                // 点赞按钮
                Row() {
                    Image($r('app.media.icon')) // TODO: 使用点赞图标
                        .width(16)
                        .height(16)
                        .fillColor(this.feedViewModel.isLiked(this.currentUserId) ?
                            MomentConstants.LIKE_COLOR : MomentConstants.TEXT_SECONDARY_COLOR)

                    Text(this.feedViewModel.isLiked(this.currentUserId) ? '已赞' : '赞')
                        .fontSize(MomentConstants.FONT_SIZE_SMALL)
                        .fontColor(this.feedViewModel.isLiked(this.currentUserId) ?
                            MomentConstants.LIKE_COLOR : MomentConstants.TEXT_SECONDARY_COLOR)
                        .margin({ left: 4 })
                }
                .opacity(this.feedViewModel.isLiking ? 0.5 : 1.0)
                .onClick(() => {
                    this.events.onLike(this.feedViewModel);
                })
            }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 8, bottom: 8 })
    }

    @Builder
    private buildInteractionsArea() {
        Column() {
            // 点赞列表
            if (this.feedViewModel.hasLikes()) {
                this.buildLikesArea()
            }

            // 评论列表
            if (this.feedViewModel.hasComments()) {
                this.buildCommentsArea()
            }
        }
        .width('100%')
        .padding(10)
        .backgroundColor(MomentConstants.INTERACTIONS_BACKGROUND_COLOR)
        .borderRadius(4)
        .margin({ top: 8 })
    }

    @Builder
    private buildLikesArea() {
        Row() {
            // 点赞图标
            Image($r('app.media.icon')) // TODO: 使用点赞图标
                .width(12)
                .height(12)
                .fillColor(MomentConstants.LIKE_COLOR)
                .margin({ right: 6 })

            // 点赞用户列表
            Text(this.buildLikesText())
                .fontSize(MomentConstants.FONT_SIZE_SMALL)
                .fontColor(MomentConstants.LINK_COLOR)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: this.feedViewModel.hasComments() ? 8 : 0 })
    }

    /**
     * 构建点赞文本
     */
    private buildLikesText(): string {
        const likes = this.feedViewModel.getLikesList();
        return likes.map(like => this.getUserDisplayInfo(like.sender).displayName).join('、');
    }

    private getDisplayComments(): Array<Comment> {
        const comments = this.feedViewModel.getCommentsList();
        const displayComments = this.feedViewModel.showAllComments ? comments : comments.slice(0, 3);
        return displayComments;
    }

    @Builder
    private buildCommentsArea() {
        Column({ space: 6 }) {

            ForEach(this.getDisplayComments(), (comment: Comment, index: number) => {
                this.buildCommentItem(comment)
            }, (comment: Comment, index: number) => `comment_${comment.commentId}_${index}`)

            // 查看更多评论
            if (!this.feedViewModel.showAllComments && this.feedViewModel.getCommentsList().length > 3) {
                Text(`查看全部${this.feedViewModel.getCommentsList().length}条评论`)
                    .fontSize(MomentConstants.FONT_SIZE_SMALL)
                    .fontColor(MomentConstants.LINK_COLOR)
                    .onClick(() => {
                        this.events.onMoreComments(this.feedViewModel);
                    })
            }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    private buildCommentItem(comment: Comment) {
        Row() {
            // 评论内容
            Text() {
                Span(this.getUserDisplayInfo(comment.sender).displayName)
                    .fontColor(MomentConstants.LINK_COLOR)
                    .onClick(() => {
                        this.events.onUserClick(comment.sender);
                    })

                if (comment.replyTo && comment.replyTo !== comment.sender) {
                    Span(' 回复 ')
                        .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)

                    Span(this.getUserDisplayInfo(comment.replyTo).displayName)
                        .fontColor(MomentConstants.LINK_COLOR)
                        .onClick(() => {
                            this.events.onUserClick(comment.replyTo);
                        })
                }

                Span(`: ${comment.text}`)
                    .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
            }
            .fontSize(MomentConstants.FONT_SIZE_SMALL)
            .lineHeight(MomentConstants.FONT_SIZE_SMALL * 1.4)
            .layoutWeight(1)
            .onClick(() => {
                // 点击评论可以回复
                this.onCommentClick(comment.sender, this.getUserDisplayInfo(comment.sender).displayName);
            })

            // 删除按钮（自己的评论或自己的朋友圈）
            if (comment.sender === this.currentUserId || this.feedViewModel.feed.sender === this.currentUserId) {
                Image($r('app.media.icon')) // TODO: 使用删除图标
                    .width(12)
                    .height(12)
                    .fillColor(MomentConstants.TEXT_SECONDARY_COLOR)
                    .margin({ left: 8 })
                    .onClick(() => {
                        // TODO: 删除评论
                        if (comment.commentId && this.feedViewModel.feed.feedId) {
                            // 调用删除评论API
                        }
                    })
            }
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
    }
}