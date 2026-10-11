import { FeedViewModel, FeedInteractionEvents } from '../model/FeedViewModel';
import { Comment, FeedContentType, FeedEntry } from '../model/MomentModel';
import { MomentConstants, TimeFormatter } from '../utils/MomentConstants';
import { NineGridView } from './NineGridView';
import { CommentWidget } from './CommentWidget';
import wfc from '@wfc/client';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import { display } from '@kit.ArkUI';
import { FontSize } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import { trustedMediaSrc } from '@wfc/uikit/src/main/ets/util/trustedMedia'

@Component
export struct FeedItemComponent {
    @ObjectLink feedViewModel: FeedViewModel;
    @Prop currentUserId: string;
    // 回调对象包含闭包，不能用 @Prop（深拷贝会破坏闭包），用普通成员一次性赋值
    events: FeedInteractionEvents = {
        onLike: () => {},
        onComment: () => {},
        onDelete: () => {},
        onDeleteComment: () => {},
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

    build() {
        Column() {
            Row() {
                // 左侧头像
                Image(trustedMediaSrc(this.getUserInfo(this.feedViewModel.feed.sender).portrait) || $r('app.media.icon'))
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
                    if (this.feedViewModel.feed.medias && this.feedViewModel.feed.medias.length > 0) {
                        this.buildMediaContent()
                    }

                    // 时间和操作按钮行
                    this.buildTimeAndActions()

                    // 点赞 + 评论区
                    if (this.feedViewModel.feed.comments && this.feedViewModel.feed.comments.length > 0) {
                        CommentWidget({
                            feedViewModel: this.feedViewModel,
                            currentUserId: this.currentUserId,
                            onUserClick: (userId: string) => this.events.onUserClick(userId),
                            onReplyComment: (comment: Comment) => {
                                this.onCommentClick(comment.sender, this.getUserInfo(comment.sender).displayName);
                            },
                            onDeleteComment: (comment: Comment) => this.events.onDeleteComment(this.feedViewModel, comment),
                            onMoreComments: (feed: FeedViewModel) => this.events.onMoreComments(feed)
                        })
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
        NineGridView({
            medias: this.feedViewModel.feed.medias!,
            isVideo: this.feedViewModel.feed.type === FeedContentType.Video,
            contentWidth: this.contentWidth,
            onItemClick: (index: number) => {
                const medias = this.feedViewModel.feed.medias!;
                if (this.feedViewModel.feed.type === FeedContentType.Video) {
                    const entry = medias[0];
                    if (entry?.mediaUrl) {
                        this.events.onVideoClick(entry.mediaUrl, entry.thumbUrl || '');
                    }
                } else {
                    this.events.onImageClick(medias, index);
                }
            }
        })
            .margin({ bottom: 8 })
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
                .color($r('app.color.menu_divider'))
                .height(16)
                .strokeWidth(0.5)

            // 评论
            Row({ space: 4 }) {
                SymbolGlyph($r('sys.symbol.ellipsis_bubble'))
                    .fontSize(FontSize.sm)
                    .fontColor([Color.White])
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
                    .color($r('app.color.menu_divider'))
                    .height(16)
                    .strokeWidth(0.5)

                Row({ space: 4 }) {
                    SymbolGlyph($r('sys.symbol.trash'))
                        .fontSize(FontSize.sm)
                        .fontColor([$r('app.color.like_active')])
                    Text('删除')
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.like_active'))
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
        .shadow({ radius: 12, color: $r('app.color.shadow_color'), offsetX: 0, offsetY: 4 })
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
}
