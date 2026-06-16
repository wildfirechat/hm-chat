import { momentClient, Feed, Comment, Profile, FeedEntry } from '@wfc/moment_client';
import { FeedViewModel, FeedListState, FeedInteractionEvents, CommentInputState } from '../model/FeedViewModel';
import { MomentConstants, TimeFormatter } from '../utils/MomentConstants';
import { FeedItemComponent } from '../components/FeedItemComponent';
import { FeedHeaderComponent } from '../components/FeedHeaderComponent';
import { FeedImagePreviewDialog } from '../components/FeedImagePreviewDialog';
import wfc from '@wfc/client';
import { momentNavigationDestinations } from '../../../../Index';
import { uikitNavigationDestinations } from '@wfc/uikit/src/main/ets/pages/uikitNavigationConfig';
import { promptAction, window, KeyboardAvoidMode } from '@kit.ArkUI';

@Component
export struct FeedListPage {
    @State feedListState: FeedListState = {
        feeds: [],
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: true,
        error: undefined
    };
    @State commentInputState: CommentInputState = {
        isVisible: false,
        feedId: undefined,
        replyTo: undefined,
        replyToName: undefined,
        placeholder: '写评论...'
    };
    @State commentText: string = '';
    @State unreadCount: number = 0;
    @State userProfile: Profile | undefined = undefined;

    @State titleBarOpacity: number = 0;
    private listScroller: Scroller = new Scroller();

    @State previewImages: FeedEntry[] = [];
    @State previewIndex: number = 0;
    previewDialogController: CustomDialogController = new CustomDialogController({
        builder: FeedImagePreviewDialog({
            images: this.$previewImages,
            index: this.$previewIndex,
        }),
        customStyle: true,
        autoCancel: true,
        alignment: DialogAlignment.Center
    });

    private currentUserId: string = '';

    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        this.currentUserId = wfc.getUserId();
        this.loadInitialFeeds();
        this.loadUserProfile();
        this.loadUnreadCount();
        try {
            this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
        } catch (e) {}
    }

    private loadUserProfile() {
        momentClient.getUserProfile(this.currentUserId, (profile: Profile) => {
            this.userProfile = profile;
        }, () => {});
    }

    private loadUnreadCount() {
        const newMsgs = momentClient.getFeedMessages(BigInt(0), true);
        this.unreadCount = newMsgs?.length || 0;
    }

    private loadInitialFeeds() {
        this.feedListState.isLoading = true;
        momentClient.getFeeds(BigInt(0), 20, null, (feeds: Feed[]) => {
            this.feedListState.feeds = feeds.map(f => new FeedViewModel(f));
            this.feedListState.isLoading = false;
            this.feedListState.error = undefined;
        }, (errorCode: number) => {
            this.feedListState.isLoading = false;
            this.feedListState.error = `加载失败 (${errorCode})`;
        });
    }

    private onRefresh() {
        this.feedListState.isRefreshing = true;
        momentClient.getFeeds(BigInt(0), 20, null, (feeds: Feed[]) => {
            this.feedListState.feeds = feeds.map(f => new FeedViewModel(f));
            this.feedListState.isRefreshing = false;
            this.feedListState.error = undefined;
            this.loadUnreadCount();
        }, () => {
            this.feedListState.isRefreshing = false;
        });
    }

    private onLoadMore() {
        if (this.feedListState.isLoadingMore || !this.feedListState.hasMore) return;
        this.feedListState.isLoadingMore = true;
        const lastFeed = this.feedListState.feeds[this.feedListState.feeds.length - 1];
        const fromIndex = lastFeed?.feed.feedId || BigInt(0);
        momentClient.getFeeds(fromIndex, 20, null, (feeds: Feed[]) => {
            if (feeds.length === 0) {
                this.feedListState.hasMore = false;
            } else {
                this.feedListState.feeds.push(...feeds.map(f => new FeedViewModel(f)));
            }
            this.feedListState.isLoadingMore = false;
        }, () => {
            this.feedListState.isLoadingMore = false;
        });
    }

    private interactionEvents: FeedInteractionEvents = {
        onLike: (feed: FeedViewModel) => {
            if (feed.isLiking) return;
            feed.isLiking = true;
            const isLiked = feed.isLiked(this.currentUserId);
            if (isLiked) {
                const likeComment = feed.getLikesList().find(like => like.sender === this.currentUserId);
                if (likeComment && likeComment.commentId !== undefined && feed.feed.feedId !== undefined) {
                    momentClient.deleteComment(likeComment.commentId, feed.feed.feedId, () => {
                        if (feed.feed.comments) {
                            const idx = feed.feed.comments.findIndex(c => c.commentId === likeComment.commentId);
                            if (idx !== -1) feed.feed.comments.splice(idx, 1);
                        }
                        feed.isLiking = false;
                        this.refreshFeedItem(feed);
                    }, () => { feed.isLiking = false; });
                } else {
                    feed.isLiking = false;
                }
            } else {
                if (feed.feed.feedId) {
                    momentClient.postComment(1, feed.feed.feedId, '', '', '', (commentId: bigint, timestamp: number) => {
                        const newLike = {
                            'commentId': commentId, 'feedId': feed.feed.feedId,
                            'sender': this.currentUserId, 'type': 1,
                            'text': '', 'replyTo': '', 'serverTime': timestamp, 'extra': ''
                        } as Record<string, Object>;
                        if (!feed.feed.comments) feed.feed.comments = [];
                        let comment = new Comment();
                        comment.fromJsonObject(newLike);
                        feed.feed.comments.push(comment);
                        feed.isLiking = false;
                        this.refreshFeedItem(feed);
                    }, () => { feed.isLiking = false; });
                }
            }
        },

        onComment: (feed: FeedViewModel, commentText: string, replyTo?: string) => {
            if (feed.isCommenting || !commentText.trim()) return;
            feed.isCommenting = true;
            if (feed.feed.feedId) {
                momentClient.postComment(0, feed.feed.feedId, commentText.trim(), replyTo || '', '', (commentId: bigint, timestamp: number) => {
                    const newComment = {
                        'commentId': commentId, 'feedId': feed.feed.feedId,
                        'sender': this.currentUserId, 'type': 0,
                        'text': commentText.trim(), 'replyTo': replyTo || '',
                        'serverTime': timestamp, 'extra': ''
                    } as Record<string, Object>;
                    if (!feed.feed.comments) feed.feed.comments = [];
                    let comment = new Comment();
                    comment.fromJsonObject(newComment);
                    feed.feed.comments.push(comment);
                    feed.isCommenting = false;
                    this.refreshFeedItem(feed);
                    this.commentInputState.isVisible = false;
                    this.commentText = '';
                }, () => { feed.isCommenting = false; });
            }
        },

        onDelete: (feed: FeedViewModel) => {
            promptAction.showDialog({
                title: '删除动态',
                message: '确定要删除这条朋友圈吗？',
                buttons: [
                    { text: '取消', color: $r('app.color.text_secondary') },
                    { text: '删除', color: $r('app.color.like_active') }
                ]
            }).then(data => {
                if (data.index === 1 && feed.feed.feedId) {
                    momentClient.deleteFeed(feed.feed.feedId, () => {
                        const idx = this.feedListState.feeds.findIndex(f => f.feed.feedId === feed.feed.feedId);
                        if (idx !== -1) {
                            const newFeeds = [...this.feedListState.feeds];
                            newFeeds.splice(idx, 1);
                            this.feedListState.feeds = newFeeds;
                        }
                    }, () => {});
                }
            }).catch(() => {});
        },

        onUserClick: (userId: string) => {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                'userId': userId
            } as Record<string, Object>);
        },

        onImageClick: (images: FeedEntry[], index: number) => {
            this.previewImages = images;
            this.previewIndex = index;
            this.previewDialogController.open();
        },

        onMoreComments: (feed: FeedViewModel) => {
            feed.showAllComments = true;
            this.refreshFeedItem(feed);
        }
    };

    private refreshFeedItem(feed: FeedViewModel) {
        const idx = this.feedListState.feeds.findIndex(f => f.feed.feedId === feed.feed.feedId);
        if (idx !== -1) {
            const newFeeds = [...this.feedListState.feeds];
            newFeeds[idx] = new FeedViewModel(feed.feed);
            newFeeds[idx].showAllComments = feed.showAllComments;
            this.feedListState.feeds = newFeeds;
        }
    }

    private showCommentInput(feed: FeedViewModel, listIndex: number, replyTo?: string, replyToName?: string) {
        this.commentInputState = {
            isVisible: true,
            feedId: feed.feed.feedId,
            replyTo,
            replyToName,
            placeholder: replyTo ? `回复 ${replyToName || replyTo}` : '写评论...'
        };
        setTimeout(() => {
            const targetIndex = listIndex + (this.unreadCount > 0 ? 2 : 1);
            this.listScroller.scrollToIndex(targetIndex, true, ScrollAlign.END);
        }, 300);
    }

    build() {
        NavDestination() {
            Stack({ alignContent: Alignment.Top }) {
                Stack({ alignContent: Alignment.Top }) {
                    Column() {
                        if (this.feedListState.isLoading && this.feedListState.feeds.length === 0) {
                            this.buildSkeletonView()
                        } else if (this.feedListState.error && this.feedListState.feeds.length === 0) {
                            this.buildErrorView()
                        } else {
                            this.buildFeedList()
                        }
                    }
                    .width('100%')
                    .height('100%')
                    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

                    if (this.commentInputState.isVisible) {
                        this.buildCommentInput()
                    }
                }
                .width('100%')
                .height('100%')
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

                // 自定义标题栏（绝对定位，不随键盘移动）
                this.buildCustomTitleBar()
            }
            .width('100%')
            .height('100%')
        }
        .hideTitleBar(true)
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
        .onShown(() => {
            try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE); } catch (e) {}
        })
        .onHidden(() => {
            try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET); } catch (e) {}
        })
    }

    @Builder
    private buildCustomTitleBar() {
        Stack({ alignContent: Alignment.Top }) {
            // 背景
            Row()
                .width('100%')
                .height(48 + px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0))
                .backgroundColor(MomentConstants.BACKGROUND_COLOR)
                .opacity(this.titleBarOpacity)
                .blur(this.titleBarOpacity > 0 ? 20 : 0)

            Row() {
                // 返回按钮
                Button() {
                    SymbolGlyph($r('sys.symbol.chevron_backward'))
                        .fontSize(22)
                        .fontColor([this.titleBarOpacity > 0.5 ? $r('app.color.text_primary') : Color.White])
                }
                .width(40)
                .height(40)
                .type(ButtonType.Circle)
                .backgroundColor(Color.Transparent)
                .onClick(() => this.mainNavPathStack.pop())

                Blank()

                if (this.titleBarOpacity > 0.3) {
                    Text('朋友圈')
                        .fontSize(MomentConstants.FONT_SIZE_TITLE)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.text_primary'))
                        .opacity(Math.min(this.titleBarOpacity * 2, 1))
                        .transition({ type: TransitionType.All, opacity: 0 })
                }

                Blank()

                // 相机按钮
                Button() {
                    SymbolGlyph($r('sys.symbol.camera'))
                        .fontSize(22)
                        .fontColor([this.titleBarOpacity > 0.5 ? $r('app.color.text_primary') : Color.White])
                }
                .width(40)
                .height(40)
                .type(ButtonType.Circle)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(momentNavigationDestinations.PostFeedPage, {} as Record<string, Object>);
                })
            }
            .width('100%')
            .height(48 + px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0))
            .padding({ left: 8, right: 8, top: px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0) })
            .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .position({ x: 0, y: 0 })
        .zIndex(100)
    }

    // 骨架屏
    @Builder
    private buildSkeletonView() {
        Column() {
            // 封面骨架
            Column()
                .width('100%')
                .height(MomentConstants.COVER_HEIGHT + px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0) + MomentConstants.AVATAR_SIZE_LARGE / 2)
                .backgroundColor($r('app.color.skeleton_base'))

            // Feed 条目骨架（3条）
            ForEach([0, 1, 2], (_: number) => {
                this.buildSkeletonItem()
            })
        }
        .width('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    }

    @Builder
    private buildSkeletonItem() {
        Row() {
            // 头像骨架
            Column()
                .width(MomentConstants.AVATAR_SIZE)
                .height(MomentConstants.AVATAR_SIZE)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .backgroundColor($r('app.color.skeleton_base'))
                .margin({ right: 10 })

            Column({ space: 8 }) {
                // 用户名骨架
                Column()
                    .width('40%')
                    .height(14)
                    .borderRadius(4)
                    .backgroundColor($r('app.color.skeleton_base'))
                // 文本骨架
                Column()
                    .width('90%')
                    .height(13)
                    .borderRadius(4)
                    .backgroundColor($r('app.color.skeleton_highlight'))
                Column()
                    .width('70%')
                    .height(13)
                    .borderRadius(4)
                    .backgroundColor($r('app.color.skeleton_highlight'))
                // 时间骨架
                Column()
                    .width('25%')
                    .height(11)
                    .borderRadius(4)
                    .backgroundColor($r('app.color.skeleton_highlight'))
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: MomentConstants.CARD_PADDING, right: MomentConstants.CARD_PADDING, top: 14, bottom: 14 })
        .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)

        Divider()
            .color(MomentConstants.DIVIDER_COLOR)
            .strokeWidth(0.5)
            .margin({ left: MomentConstants.CARD_PADDING + MomentConstants.AVATAR_SIZE + 10 })
    }

    @Builder
    private buildErrorView() {
        Column({ space: 16 }) {
            SymbolGlyph($r('sys.symbol.wifi_slash'))
                .fontSize(56)
                .fontColor([MomentConstants.TEXT_SECONDARY_COLOR])

            Text('加载失败')
                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)

            Button('重新加载')
                .backgroundColor(MomentConstants.PRIMARY_COLOR)
                .fontColor(Color.White)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .padding({ left: 24, right: 24 })
                .height(40)
                .onClick(() => this.loadInitialFeeds())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }

    @Builder
    private buildFeedList() {
        Refresh({ refreshing: $$this.feedListState.isRefreshing, offset: 64, friction: 100 }) {
            List({ space: 0, scroller: this.listScroller }) {
                // 顶部 Header
                ListItem() {
                    FeedHeaderComponent({ profile: this.userProfile, userId: this.currentUserId })
                }

                // 未读提示
                if (this.unreadCount > 0) {
                    ListItem() {
                        this.buildUnreadHint()
                    }
                }

                // Feed 列表
                ForEach(this.feedListState.feeds, (feedItem: FeedViewModel, index: number) => {
                    ListItem() {
                        FeedItemComponent({
                            feedViewModel: feedItem,
                            currentUserId: this.currentUserId,
                            events: this.interactionEvents,
                            onCommentClick: (replyTo?: string, replyToName?: string) => {
                                this.showCommentInput(feedItem, index, replyTo, replyToName);
                            }
                        })
                    }
                }, (feedItem: FeedViewModel, index: number) => `${feedItem.feed.feedId}_${index}_${feedItem.updateTime}`)

                // 加载更多 / 底部提示
                if (this.feedListState.feeds.length === 0 && !this.feedListState.isLoading) {
                    ListItem() { this.buildEmptyView() }
                } else if (this.feedListState.hasMore) {
                    ListItem() {
                        this.buildLoadMoreView()
                    }
                    .onAppear(() => this.onLoadMore())
                } else if (this.feedListState.feeds.length > 0) {
                    ListItem() {
                        Row({ space: 8 }) {
                            Divider().layoutWeight(1).color(MomentConstants.DIVIDER_COLOR).strokeWidth(0.5)
                            Text('以上是全部朋友圈')
                                .fontSize(MomentConstants.FONT_SIZE_CAPTION)
                                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                            Divider().layoutWeight(1).color(MomentConstants.DIVIDER_COLOR).strokeWidth(0.5)
                        }
                        .padding({ left: 20, right: 20, top: 20, bottom: 24 })
                        .alignItems(VerticalAlign.Center)
                    }
                }
            }
            .listDirection(Axis.Vertical)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.None)
            .onDidScroll(() => {
                const offset = this.listScroller.currentOffset().yOffset;
                let opacity = (offset - 120) / 80;
                this.titleBarOpacity = Math.max(0, Math.min(1, opacity));
                AppStorage.setOrCreate('closeFeedMenuTime', Date.now());
            })
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        }
        .onRefreshing(() => this.onRefresh())
        .layoutWeight(1)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    }

    @Builder
    private buildUnreadHint() {
        Row({ space: 8 }) {
            Image(wfc.getUserInfo(this.currentUserId).portrait || $r('app.media.icon'))
                .width(28)
                .height(28)
                .borderRadius(4)

            Text(`${this.unreadCount}条新动态`)
                .fontSize(13)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)

            SymbolGlyph($r('sys.symbol.chevron_up'))
                .fontSize(13)
                .fontColor([Color.White])
        }
        .height(44)
        .padding({ left: 14, right: 14 })
        .borderRadius(MomentConstants.BORDER_RADIUS)
        .backgroundColor($r('app.color.unread_hint_background'))
        .margin({ top: 10, bottom: 10, left: 16, right: 16 })
        .onClick(() => {
            this.listScroller.scrollToIndex(1, true, ScrollAlign.START);
            this.unreadCount = 0;
            momentClient.clearUnreadStatus();
        })
    }

    @Builder
    private buildEmptyView() {
        Column({ space: 16 }) {
            SymbolGlyph($r('sys.symbol.person_2'))
                .fontSize(64)
                .fontColor([MomentConstants.TEXT_SECONDARY_COLOR])

            Text('还没有朋友圈动态')
                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)

            Text('去分享你的精彩瞬间吧')
                .fontSize(MomentConstants.FONT_SIZE_SMALL)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
        }
        .width('100%')
        .padding({ top: 80, bottom: 40 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }

    @Builder
    private buildLoadMoreView() {
        Row({ space: 8 }) {
            if (this.feedListState.isLoadingMore) {
                LoadingProgress()
                    .width(18)
                    .height(18)
                    .color(MomentConstants.TEXT_SECONDARY_COLOR)
                Text('加载中...')
                    .fontSize(MomentConstants.FONT_SIZE_CAPTION)
                    .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
            }
        }
        .width('100%')
        .height(48)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }

    @Builder
    private buildCommentInput() {
        Column() {
            // 半透明遮罩
            Row()
                .width('100%')
                .layoutWeight(1)
                .backgroundColor('rgba(0,0,0,0.25)')
                .onClick(() => {
                    this.commentInputState.isVisible = false;
                    this.commentText = '';
                })

            // 输入框
            Row({ space: 10 }) {
                TextInput({
                    placeholder: this.commentInputState.placeholder,
                    text: this.commentText
                })
                    .id('comment_input')
                    .layoutWeight(1)
                    .height(40)
                    .backgroundColor(MomentConstants.BACKGROUND_COLOR)
                    .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                    .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                    .placeholderColor(MomentConstants.TEXT_SECONDARY_COLOR)
                    .borderRadius(20)
                    .padding({ left: 14, right: 14 })
                    .defaultFocus(true)
                    .onAppear(() => {
                        setTimeout(() => {
                            focusControl.requestFocus('comment_input');
                        }, 80);
                    })
                    .onChange((value: string) => {
                        this.commentText = value;
                    })
                    .onSubmit(() => {
                        const targetFeed = this.feedListState.feeds.find(f => f.feed.feedId === this.commentInputState.feedId);
                        if (targetFeed && this.commentText.trim()) {
                            this.interactionEvents.onComment(targetFeed, this.commentText, this.commentInputState.replyTo);
                        }
                    })

                Button('发送')
                    .height(40)
                    .padding({ left: 18, right: 18 })
                    .backgroundColor(this.commentText.trim() ? MomentConstants.PRIMARY_COLOR : $r('app.color.button_disabled'))
                    .fontColor(this.commentText.trim() ? Color.White : $r('app.color.text_disabled'))
                    .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                    .borderRadius(20)
                    .enabled(!!this.commentText.trim())
                    .onClick(() => {
                        const targetFeed = this.feedListState.feeds.find(f => f.feed.feedId === this.commentInputState.feedId);
                        if (targetFeed) {
                            this.interactionEvents.onComment(targetFeed, this.commentText, this.commentInputState.replyTo);
                        }
                    })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
        }
        .width('100%')
        .height('100%')
        .zIndex(999)
    }
}
