import { FeedViewModel, FeedInteractionEvents } from '../model/FeedViewModel';
import { Comment, FeedCommentType, FeedContentType, FeedEntry } from '@wfc/moment_client';
import { MomentConstants, TimeFormatter } from '../utils/MomentConstants';
import wfc from '@wfc/client';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import { display, promptAction } from '@kit.ArkUI';
import pasteboard from '@ohos.pasteboard';
import { FontSize, Radius } from '@wfc/uikit/src/main/ets/common/design/Tokens'

@Component
export struct FeedItemComponent {
    @ObjectLink feedViewModel: FeedViewModel;
    @Prop currentUserId: string;
    // 回调对象包含闭包，不能用 @Prop（深拷贝会破坏闭包），用普通成员一次性赋值
    events: FeedInteractionEvents = {
        onLike: () => {},
        onComment: () => {},
        onDelete: () => {},
        onUserClick: () => {},
        onImageClick: () => {},
        onVideoClick: () => {},
        onMoreComments: () => {}
    };
    onCommentClick: (replyTo?: string, replyToName?: string) => void = () => {};

    @State private expandedText: boolean = false;
    @State private showMenu: boolean = false;
    @State private contentWidth: number = 260;

    @StorageProp('closeFeedMenuTime') @Watch('onCloseFeedMenu') closeFeedMenuTime: number = 0;

    onCloseFeedMenu() {
        if (this.showMenu) {
            animateTo({ duration: MomentConstants.ANIMATION_DURATION }, () => {
                this.showMenu = false;
            });
        }
    }

    aboutToAppear() {
        // 动态计算内容区宽度
        const d = display.getDefaultDisplaySync();
        const screenVp = px2vp(d.width);
        // 左 padding + 头像 + 头像右间距 + 右 padding
        this.contentWidth = screenVp - MomentConstants.CARD_PADDING - MomentConstants.AVATAR_SIZE - 10 - MomentConstants.CARD_PADDING;

        // 预加载相关用户信息
        const userIds = new Set<string>();
        userIds.add(this.feedViewModel.feed.sender);
        if (this.feedViewModel.feed.comments) {
            this.feedViewModel.feed.comments.forEach(c => {
                userIds.add(c.sender);
                if (c.replyTo) userIds.add(c.replyTo);
            });
        }
        wfc.getUserInfos(Array.from(userIds));
    }

    private getUserInfo(userId: string): UserInfo {
        return wfc.getUserInfo(userId);
    }

    // 图片网格：每项正方形尺寸
    private imageItemSize(): number {
        const cols = this.images().length === 4 ? 2 : 3;
        return (this.contentWidth - (cols - 1) * MomentConstants.IMAGE_GRID_GAP) / cols;
    }

    private gridHeight(): number {
        const count = this.images().length;
        if (count === 0) return 0;
        if (count === 1) return Math.min(this.contentWidth * 0.75, 240);
        const cols = count === 4 ? 2 : 3;
        const rows = Math.ceil(count / cols);
        const size = this.imageItemSize();
        return rows * size + (rows - 1) * MomentConstants.IMAGE_GRID_GAP;
    }

    images(): FeedEntry[] {
        return this.feedViewModel.getImages();
    }

    build() {
        Column() {
            Row() {
                // 左侧头像
                Image(this.getUserInfo(this.feedViewModel.feed.sender).portrait || $r('app.media.icon'))
                    .width(MomentConstants.AVATAR_SIZE)
                    .height(MomentConstants.AVATAR_SIZE)
                    .borderRadius(MomentConstants.BORDER_RADIUS)
                    .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)
                    .margin({ right: 12 })
                    .onClick(() => this.events.onUserClick(this.feedViewModel.feed.sender))

                // 右侧内容列
                Column() {
                    // 用户名
                    Text(this.getUserInfo(this.feedViewModel.feed.sender).displayName)
                        .fontSize(MomentConstants.FONT_SIZE_USERNAME)
                        .fontColor(MomentConstants.LINK_COLOR)
                        .fontWeight(FontWeight.Medium)
                        .margin({ bottom: 8 })
                        .onClick(() => this.events.onUserClick(this.feedViewModel.feed.sender))

                    // 文本内容
                    if (this.feedViewModel.feed.text && this.feedViewModel.feed.text.trim()) {
                        this.buildTextContent()
                    }

                    // 图片/视频
                    if (this.feedViewModel.feed.medias?.length > 0) {
                        this.buildMediaContent()
                    }

                    // 时间和操作按钮行
                    this.buildTimeAndActions()

                    // 点赞 + 评论区
                    if (this.feedViewModel.feed.comments?.length > 0) {
                        this.buildInteractionsArea()
                    }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: MomentConstants.CARD_PADDING, right: MomentConstants.CARD_PADDING, top: 16, bottom: 0 })
            .alignItems(VerticalAlign.Top)

            // 分割线
            Divider()
                .color(MomentConstants.DIVIDER_COLOR)
                .strokeWidth(0.5)
                .margin({ top: 16, left: MomentConstants.CARD_PADDING + MomentConstants.AVATAR_SIZE + 10 })
        }
        .width('100%')
        .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
        .alignItems(HorizontalAlign.Start)
        .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
                AppStorage.setOrCreate('closeFeedMenuTime', Date.now());
            }
        })
    }

    @Builder
    private buildTextContent() {
        Column() {
            Text(this.feedViewModel.feed.text!)
                .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                .lineHeight(MomentConstants.FONT_SIZE_CONTENT * 1.6)
                .maxLines(this.expandedText ? undefined : MomentConstants.MAX_TEXT_LINES)
                .textOverflow({ overflow: this.expandedText ? TextOverflow.None : TextOverflow.Ellipsis })
                .width('100%')

            if (!this.expandedText && this.feedViewModel.feed.text!.length > MomentConstants.TEXT_COLLAPSE_LENGTH) {
                Text('全文')
                    .fontSize(MomentConstants.FONT_SIZE_SMALL)
                    .fontColor(MomentConstants.LINK_COLOR)
                    .margin({ top: 2 })
                    .onClick(() => { this.expandedText = true; })
            } else if (this.expandedText && this.feedViewModel.feed.text!.length > MomentConstants.TEXT_COLLAPSE_LENGTH) {
                Text('收起')
                    .fontSize(MomentConstants.FONT_SIZE_SMALL)
                    .fontColor(MomentConstants.LINK_COLOR)
                    .margin({ top: 2 })
                    .onClick(() => { this.expandedText = false; })
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
            this.buildVideoThumbnail()
        }
    }

    @Builder
    private buildImageGrid() {
        if (this.images().length === 1) {
            // 单张图片：自适应比例，限制最大宽度
            Image(this.images()[0].mediaUrl)
                .alt(this.images()[0].thumbUrl)
                .width(Math.min(this.contentWidth * 0.75, 220))
                .aspectRatio(1)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .objectFit(ImageFit.Cover)
                .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)
                .onClick(() => this.events.onImageClick(this.images(), 0))
                .margin({ bottom: 8 })
        } else {
            Grid() {
                ForEach(this.images().slice(0, 9), (entry: FeedEntry, index: number) => {
                    GridItem() {
                        Image(entry.mediaUrl)
                            .alt(entry.thumbUrl)
                            .width('100%')
                            .height('100%')
                            .borderRadius(MomentConstants.BORDER_RADIUS_SMALL)
                            .objectFit(ImageFit.Cover)
                            .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)
                            .onClick(() => this.events.onImageClick(this.images(), index))
                    }
                }, (entry: FeedEntry, index: number) => `img_${index}_${entry.mediaUrl}`)
            }
            .columnsTemplate(this.images().length === 4 ? '1fr 1fr' : '1fr 1fr 1fr')
            .columnsGap(MomentConstants.IMAGE_GRID_GAP)
            .rowsGap(MomentConstants.IMAGE_GRID_GAP)
            .width('100%')
            .height(this.gridHeight())
            .margin({ bottom: 8 })
        }
    }

    @Builder
    private buildVideoThumbnail() {
        Stack({ alignContent: Alignment.Center }) {
            // 视频封面
            Image(this.images()[0]?.thumbUrl || this.images()[0]?.mediaUrl)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)

            // 半透明遮罩
            Column()
                .width('100%')
                .height('100%')
                .backgroundColor($r('app.color.video_overlay'))

            // 播放按钮
            Column() {
                SymbolGlyph($r('sys.symbol.play_fill'))
                    .fontSize(FontSize.d3)
                    .fontColor([Color.White])
            }
            .width(60)
            .height(60)
            .borderRadius(Radius.full)
            .backgroundColor('rgba(0,0,0,0.35)')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
        }
        .width(Math.min(this.contentWidth * 0.75, 220))
        .height(Math.min(this.contentWidth * 0.75, 220) * 0.56)
        .borderRadius(MomentConstants.BORDER_RADIUS)
        .clip(true)
        .margin({ bottom: 8 })
        .onClick(() => {
            const entry = this.images()[0];
            if (entry?.mediaUrl) {
                this.events.onVideoClick(entry.mediaUrl, entry.thumbUrl || '');
            }
        })
    }

    @Builder
    private buildTimeAndActions() {
        Row() {
            // 时间
            Text(TimeFormatter.formatFeedTime(this.feedViewModel.feed.serverTime))
                .fontSize(MomentConstants.FONT_SIZE_CAPTION)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)

            Blank()

            // 操作菜单触发按钮（三点图标）
            Stack({ alignContent: Alignment.TopEnd}) {
                if (this.showMenu) {
                    this.buildInteractionMenu()
                }

                Button() {
                    Row({ space: 4 }) {
                        Circle({ width: 3.5, height: 3.5 }).fill(MomentConstants.TEXT_SECONDARY_COLOR)
                        Circle({ width: 3.5, height: 3.5 }).fill(MomentConstants.TEXT_SECONDARY_COLOR)
                        Circle({ width: 3.5, height: 3.5 }).fill(MomentConstants.TEXT_SECONDARY_COLOR)
                    }
                    .padding({ left: 8, right: 8 })
                }
                .height(28)
                .type(ButtonType.Normal)
                .backgroundColor(MomentConstants.INTERACTIONS_BACKGROUND_COLOR)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .onTouch((event: TouchEvent) => {
                    if (event.type === TouchType.Down) event.stopPropagation();
                })
                .onClick(() => {
                    animateTo({ duration: MomentConstants.ANIMATION_DURATION }, () => {
                        this.showMenu = !this.showMenu;
                    });
                })
            }
            .clip(false)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 8, bottom: 8 })
    }

    @Builder
    private buildInteractionMenu() {
        Row() {
            // 点赞 / 取消赞
            Row({ space: 4 }) {
                if (this.feedViewModel.isLiked(this.currentUserId)) {
                    SymbolGlyph($r('sys.symbol.heart_fill'))
                        .fontSize(FontSize.sm)
                        .fontColor([$r('app.color.like_active')])
                    Text('取消')
                        .fontSize(FontSize.sm)
                        .fontColor(Color.White)
                } else {
                    SymbolGlyph($r('sys.symbol.heart'))
                        .fontSize(FontSize.sm)
                        .fontColor([Color.White])
                    Text('赞')
                        .fontSize(FontSize.sm)
                        .fontColor(Color.White)
                }
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
                animateTo({ duration: MomentConstants.ANIMATION_DURATION }, () => {
                    this.showMenu = false;
                });
                this.events.onLike(this.feedViewModel);
            })

            // 竖分割线
            Divider()
                .vertical(true)
                .color('rgba(255,255,255,0.25)')
                .height(16)
                .strokeWidth(0.5)

            // 评论
            Row({ space: 4 }) {
                Text('💬')
                    .fontSize(FontSize.sm)
                Text('评论')
                    .fontSize(FontSize.sm)
                    .fontColor(Color.White)
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
                animateTo({ duration: MomentConstants.ANIMATION_DURATION }, () => {
                    this.showMenu = false;
                });
                this.onCommentClick();
            })

            // 自己的动态显示删除
            if (this.feedViewModel.feed.sender === this.currentUserId) {
                Divider()
                    .vertical(true)
                    .color('rgba(255,255,255,0.25)')
                    .height(16)
                    .strokeWidth(0.5)

                Row({ space: 4 }) {
                    SymbolGlyph($r('sys.symbol.trash'))
                        .fontSize(FontSize.sm)
                        .fontColor(['#FF6B6B'])
                    Text('删除')
                        .fontSize(FontSize.sm)
                        .fontColor('#FF6B6B')
                }
                .layoutWeight(1)
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                    animateTo({ duration: MomentConstants.ANIMATION_DURATION }, () => {
                        this.showMenu = false;
                    });
                    this.events.onDelete(this.feedViewModel);
                })
            }
        }
        .height(40)
        .backgroundColor(MomentConstants.ACTION_MENU_BG_COLOR)
        .borderRadius(MomentConstants.BORDER_RADIUS)
        .shadow({ radius: 12, color: '#30000000', offsetX: 0, offsetY: 4 })
        .position({ right: 34, top: -12 })
        .width(this.feedViewModel.feed.sender === this.currentUserId ? 225 : 152)
        .transition({
            type: TransitionType.All,
            opacity: 0,
            scale: { x: 0.92, y: 0.92, centerX: '100%', centerY: '0%' }
        })
        .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) event.stopPropagation();
        })
    }

    @Builder
    private buildInteractionsArea() {
        Column({ space: 0 }) {
            // 点赞区
            if (this.feedViewModel.hasLikes()) {
                this.buildLikesArea()
            }

            if (this.feedViewModel.hasLikes() && this.feedViewModel.hasComments()) {
                Divider()
                    .color(MomentConstants.DIVIDER_COLOR)
                    .strokeWidth(0.5)
                    .margin({ top: 8, bottom: 8 })
            }

            // 评论区
            if (this.feedViewModel.hasComments()) {
                this.buildCommentsArea()
            }
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 8 })
        .backgroundColor(MomentConstants.INTERACTIONS_BACKGROUND_COLOR)
        .borderRadius(MomentConstants.BORDER_RADIUS_SMALL)
        .margin({ top: 8 })
    }

    @Builder
    private buildLikesArea() {
        Row({ space: 0 }) {
            // 爱心图标
            SymbolGlyph($r('sys.symbol.heart_fill'))
                .fontSize(FontSize.sm)
                .fontColor([MomentConstants.LINK_COLOR])
                .margin({ right: 8, top: 2 })

            // 点赞用户名列表（Flex 换行，每个名字可点击）
            Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.feedViewModel.getLikesList(), (like: Comment, idx: number) => {
                    Text(`${idx > 0 ? '、' : ''}${this.getUserInfo(like.sender).displayName}`)
                        .fontSize(MomentConstants.FONT_SIZE_SMALL)
                        .fontColor(MomentConstants.LINK_COLOR)
                        .onClick(() => this.events.onUserClick(like.sender))
                }, (like: Comment) => `like_${like.commentId}`)
            }
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
    }

    private getDisplayComments(): Array<Comment> {
        const comments = this.feedViewModel.getCommentsList();
        return this.feedViewModel.showAllComments ? comments : comments.slice(0, MomentConstants.INITIAL_COMMENTS_COUNT);
    }

    @Builder
    private buildCommentsArea() {
        Column({ space: 4 }) {
            ForEach(this.getDisplayComments(), (comment: Comment, index: number) => {
                this.buildCommentItem(comment)
            }, (comment: Comment, index: number) => `comment_${comment.commentId}_${index}`)

            if (!this.feedViewModel.showAllComments && this.feedViewModel.getCommentsList().length > MomentConstants.INITIAL_COMMENTS_COUNT) {
                Row({ space: 4 }) {
                    Text(`展开${this.feedViewModel.getCommentsList().length - MomentConstants.INITIAL_COMMENTS_COUNT}条评论`)
                        .fontSize(MomentConstants.FONT_SIZE_SMALL)
                        .fontColor(MomentConstants.LINK_COLOR)
                    SymbolGlyph($r('sys.symbol.chevron_down'))
                        .fontSize(FontSize.xs)
                        .fontColor([MomentConstants.LINK_COLOR])
                }
                .onClick(() => this.events.onMoreComments(this.feedViewModel))
            }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    private buildCommentItem(comment: Comment) {
        Text() {
            Span(this.getUserInfo(comment.sender).displayName)
                .fontColor(MomentConstants.LINK_COLOR)
                .fontWeight(FontWeight.Medium)
                .onClick(() => this.events.onUserClick(comment.sender))

            if (comment.replyTo && comment.replyTo !== comment.sender) {
                Span(' 回复 ')
                    .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                Span(this.getUserInfo(comment.replyTo).displayName)
                    .fontColor(MomentConstants.LINK_COLOR)
                    .fontWeight(FontWeight.Medium)
                    .onClick(() => this.events.onUserClick(comment.replyTo))
            }

            Span('：')
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)

            Span(comment.text)
                .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
        }
        .fontSize(MomentConstants.FONT_SIZE_SMALL)
        .lineHeight(MomentConstants.FONT_SIZE_SMALL * 1.65)
        .width('100%')
        .onClick(() => {
            this.onCommentClick(comment.sender, this.getUserInfo(comment.sender).displayName);
        })
        .gesture(
            LongPressGesture()
                .onAction(() => {
                    promptAction.showActionMenu({
                        title: '',
                        buttons: [
                            { text: '复制', color: $r('app.color.text_primary') }
                        ]
                    }).then(result => {
                        if (result.index === 0) {
                            this.copyText(comment.text);
                        }
                    }).catch(() => {});
                })
        )
    }

    private copyText(text: string) {
        if (!text) return;
        const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
        pasteboard.getSystemPasteboard().setData(data).then(() => {
            promptAction.showToast({ message: '已复制' });
        }).catch(() => {});
    }
}
