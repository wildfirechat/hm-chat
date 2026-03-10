import { momentClient, Feed, Comment, Profile, FeedEntry } from '@wfc/moment_client';
import { FeedViewModel, FeedListState, FeedInteractionEvents, CommentInputState } from '../model/FeedViewModel';
import { MomentConstants, TimeFormatter } from '../utils/MomentConstants';
import { FeedItemComponent } from '../components/FeedItemComponent';
import { FeedHeaderComponent } from '../components/FeedHeaderComponent';
import { FeedImagePreviewDialog } from '../components/FeedImagePreviewDialog';
import wfc from '@wfc/client';
import { momentNavigationDestinations } from '../../../../Index';
import { uikitNavigationDestinations } from '@wfc/uikit/src/main/ets/pages/uikitNavigationConfig';
import { promptAction } from '@kit.ArkUI';

@Component
export struct FeedListPage {
    // 状态管理
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

    // 当前用户ID
    private currentUserId: string = '';

    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        // 获取当前用户ID
        this.currentUserId = wfc.getUserId()
        this.loadInitialFeeds();
        this.loadUserProfile();
        this.loadUnreadCount();
    }

    private loadUserProfile() {
        momentClient.getUserProfile(this.currentUserId, (profile: Profile) => {
            this.userProfile = profile;
        }, (err) => {
            console.error('Load user profile failed:', err);
        });
    }

    private loadUnreadCount() {
        // 鸿蒙 momentClient 似乎没直接暴露 getUnreadCount，
        // 参考 MomentClientImpl.ets 的 getFeedMessages(fromIndex, isNew)
        const newMsgs = momentClient.getFeedMessages(BigInt(0), true);
        this.unreadCount = newMsgs?.length || 0;
    }

    /**
     * 加载初始朋友圈数据
     */
    private loadInitialFeeds() {
        this.feedListState.isLoading = true;

        momentClient.getFeeds(
            BigInt(0), // 从最新开始
            20, // 获取20条
            null, // 获取所有用户的朋友圈
            (feeds: Feed[]) => {
                this.feedListState.feeds = feeds.map(feed => new FeedViewModel(feed));
                this.feedListState.isLoading = false;
                this.feedListState.error = undefined;
            },
            (errorCode: number) => {
                this.feedListState.isLoading = false;
                this.feedListState.error = `加载失败: ${errorCode}`;
                console.error('Load feeds failed:', errorCode);
            }
        );
    }

    /**
     * 下拉刷新
     */
    private onRefresh() {
        this.feedListState.isRefreshing = true;

        momentClient.getFeeds(
            BigInt(0),
            20,
            null,
            (feeds: Feed[]) => {
                this.feedListState.feeds = feeds.map(feed => new FeedViewModel(feed));
                this.feedListState.isRefreshing = false;
                this.feedListState.error = undefined;
            },
            (errorCode: number) => {
                this.feedListState.isRefreshing = false;
                this.feedListState.error = `刷新失败: ${errorCode}`;
            }
        );
    }

    /**
     * 加载更多
     */
    private onLoadMore() {
        if (this.feedListState.isLoadingMore || !this.feedListState.hasMore) {
            return;
        }

        this.feedListState.isLoadingMore = true;

        const lastFeed = this.feedListState.feeds[this.feedListState.feeds.length - 1];
        const fromIndex = lastFeed?.feed.feedId || BigInt(0);

        momentClient.getFeeds(
            fromIndex,
            20,
            null,
            (feeds: Feed[]) => {
                if (feeds.length === 0) {
                    this.feedListState.hasMore = false;
                } else {
                    this.feedListState.feeds.push(...feeds.map(feed => new FeedViewModel(feed)));
                }
                this.feedListState.isLoadingMore = false;
            },
            (errorCode: number) => {
                this.feedListState.isLoadingMore = false;
                console.error('Load more feeds failed:', errorCode);
            }
        );
    }

    /**
     * 交互事件处理
     */
    private interactionEvents: FeedInteractionEvents = {
        onLike: (feed: FeedViewModel) => {
            if (feed.isLiking) {
                return;
            }

            feed.isLiking = true;
            const isLiked = feed.isLiked(this.currentUserId);

            if (isLiked) {
                // 取消点赞 - 需要找到对应的点赞评论并删除
                const likeComment = feed.getLikesList().find(like => like.sender === this.currentUserId);
                if (likeComment && likeComment.commentId && feed.feed.feedId) {
                    momentClient.deleteComment(
                        likeComment.commentId,
                        feed.feed.feedId,
                        () => {
                            // 从本地移除点赞
                            if (feed.feed.comments) {
                                const index = feed.feed.comments.findIndex(c => c.commentId === likeComment.commentId);
                                if (index !== -1) {
                                    feed.feed.comments.splice(index, 1);
                                }
                            }
                            feed.isLiking = false;
                        },
                        (errorCode: number) => {
                            feed.isLiking = false;
                            console.error('Unlike failed:', errorCode);
                        }
                    );
                }
            } else {
                // 点赞
                if (feed.feed.feedId) {
                    momentClient.postComment(
                        1, // FeedCommentType.Comment_Thumbup_Type
                        feed.feed.feedId,
                        '',
                        '',
                        '',
                        (commentId: bigint, timestamp: number) => {
                            // 添加到本地点赞列表
                            const newLike = {
                                'commendId': commentId,
                                'feedId': feed.feed.feedId,
                                'sender': this.currentUserId,
                                'type': 1,
                                'text': '',
                                'replyTo': '',
                                'serverTime': timestamp,
                                'extra': ''
                            } as Record<string, Object>;

                            if (!feed.feed.comments) {
                                feed.feed.comments = [];
                            }
                            let comment = new Comment()
                            comment.fromJsonObject(newLike);
                            feed.feed.comments.push(comment);
                            feed.isLiking = false;
                        },
                        (errorCode: number) => {
                            feed.isLiking = false;
                            console.error('Like failed:', errorCode);
                        }
                    );
                }
            }
        },

        onComment: (feed: FeedViewModel, commentText: string, replyTo?: string) => {
            if (feed.isCommenting || !commentText.trim()) {
                return;
            }

            feed.isCommenting = true;

            if (feed.feed.feedId) {
                momentClient.postComment(
                    0, // FeedCommentType.Comment_Comment_Type
                    feed.feed.feedId,
                    commentText.trim(),
                    replyTo || '',
                    '',
                    (commentId: bigint, timestamp: number) => {
                        // 添加到本地评论列表
                        const newComment = {
                            'commentId': commentId,
                            'feedId': feed.feed.feedId,
                            'sender': this.currentUserId,
                            'type': 0,
                            'text': commentText.trim(),
                            'replyTo': replyTo || '',
                            'serverTime': timestamp,
                            'extra': ''
                        } as Record<string, Object>;

                        if (!feed.feed.comments) {
                            feed.feed.comments = [];
                        }
                        let comment = new Comment()
                        comment.fromJsonObject(newComment)
                        feed.feed.comments.push(comment);
                        feed.isCommenting = false;

                        // 隐藏评论输入框
                        this.commentInputState.isVisible = false;
                        this.commentText = '';
                    },
                    (errorCode: number) => {
                        feed.isCommenting = false;
                        console.error('Comment failed:', errorCode);
                    }
                );
            }
        },

        onDelete: (feed: FeedViewModel) => {
            promptAction.showDialog({
                title: '提示',
                message: '确定删除这条朋友圈吗？',
                buttons: [
                    { text: '取消', color: '#000000' },
                    { text: '删除', color: '#FF0000' }
                ]
            }).then(data => {
                if (data.index === 1) {
                    if (feed.feed.feedId) {
                        momentClient.deleteFeed(
                            feed.feed.feedId,
                            () => {
                                // 从列表中移除
                                const index = this.feedListState.feeds.findIndex(f => f.feed.feedId === feed.feed.feedId);
                                if (index !== -1) {
                                    this.feedListState.feeds.splice(index, 1);
                                }
                            },
                            (errorCode: number) => {
                                console.error('Delete feed failed:', errorCode);
                            }
                        );
                    }
                }
            })
        },

        onUserClick: (userId: string) => {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                'userId': userId
            } as Record<string, Object>)
        },

        onImageClick: (images: FeedEntry[], index: number) => {
            this.previewImages = images;
            this.previewIndex = index;
            this.previewDialogController.open();
        },

        onMoreComments: (feed: FeedViewModel) => {
            feed.showAllComments = true;
        }
    };

    /**
     * 显示评论输入框
     */
    private showCommentInput(feed: FeedViewModel, replyTo?: string, replyToName?: string) {
        this.commentInputState = {
            isVisible: true,
            feedId: feed.feed.feedId,
            replyTo,
            replyToName,
            placeholder: replyTo ? `回复 ${replyToName || replyTo}:` : '写评论...'
        };
    }

    build() {
        NavDestination() {
            Stack({ alignContent: Alignment.Top }) {
                Column() {
                    // 主内容区域
                    if (this.feedListState.isLoading && this.feedListState.feeds.length === 0) {
                        // 初始加载状态
                        this.buildLoadingView()
                    } else if (this.feedListState.error && this.feedListState.feeds.length === 0) {
                        // 错误状态
                        this.buildErrorView()
                    } else {
                        // 朋友圈列表
                        this.buildFeedList()
                    }
                }
                .width('100%')
                .height('100%')
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

                // 评论输入框
                if (this.commentInputState.isVisible) {
                    this.buildCommentInput()
                }

                // 自定义标题栏
                this.buildCustomTitleBar()
            }
            .width('100%')
            .height('100%')
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
        .hideTitleBar(true)
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    }

    @Builder
    private buildCustomTitleBar() {
        Row() {
            SymbolGlyph($r('sys.symbol.chevron_backward'))
                .fontSize(28)
                .fontColor([this.titleBarOpacity > 0.5 ? Color.Black : Color.White])
                .onClick(() => {
                    this.mainNavPathStack.pop();
                })

            Blank()
            
            if (this.titleBarOpacity > 0) {
                Text('朋友圈')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.Black)
                    .opacity(this.titleBarOpacity)
            }

            Blank()

            SymbolGlyph($r('sys.symbol.camera'))
                .fontSize(28)
                .fontColor([this.titleBarOpacity > 0.5 ? Color.Black : Color.White])
                .onClick(() => {
                    promptAction.showActionMenu({
                        title: '',
                        buttons: [
                            { text: '拍摄', color: '#000000' },
                            { text: '从相册选择', color: '#000000' }
                        ]
                    }).then(data => {
                        if (data.index === 0 || data.index === 1) {
                            this.mainNavPathStack.pushPathByName(momentNavigationDestinations.PostFeedPage, {} as Record<string, Object>)
                        }
                    })
                })
        }
        .width('100%')
        .height(48 + px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0))
        .padding({ left: 16, right: 16, top: px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0) })
        .backgroundColor(`rgba(237, 237, 237, ${this.titleBarOpacity})`)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    }

    @Builder
    private buildLoadingView() {
        Column() {
            LoadingProgress()
                .width(40)
                .height(40)
                .color(MomentConstants.PRIMARY_COLOR)

            Text('加载中...')
                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }

    @Builder
    private buildErrorView() {
        Column() {
            Text('😞')
                .fontSize(48)
                .margin({ bottom: 16 })

            Text(this.feedListState.error || '加载失败')
                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                .margin({ bottom: 16 })

            Button('重试')
                .backgroundColor(MomentConstants.PRIMARY_COLOR)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .onClick(() => {
                    this.loadInitialFeeds();
                })
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
                ListItem() {
                    FeedHeaderComponent({ profile: this.userProfile, userId: this.currentUserId })
                }

                if (this.unreadCount > 0) {
                    ListItem() {
                        this.buildUnreadCountHint()
                    }
                }

                ForEach(this.feedListState.feeds, (feedItem: FeedViewModel, index: number) => {
                    ListItem() {
                        FeedItemComponent({
                            feedViewModel: feedItem,
                            currentUserId: this.currentUserId,
                            events: this.interactionEvents,
                            onCommentClick: (replyTo?: string, replyToName?: string) => {
                                this.showCommentInput(feedItem, replyTo, replyToName);
                            }
                        })
                    }
                    .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
                }, (feedItem: FeedViewModel, index: number) => `${feedItem.feed.feedId}_${index}`)

                // 加载更多指示器
                if (this.feedListState.hasMore) {
                    ListItem() {
                        this.buildLoadMoreView()
                    }
                    .onAppear(() => {
                        this.onLoadMore();
                    })
                } else if (this.feedListState.feeds.length > 0) {
                    ListItem() {
                        Text('没有更多了')
                            .fontSize(MomentConstants.FONT_SIZE_SMALL)
                            .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                            .textAlign(TextAlign.Center)
                            .padding(16)
                    }
                }
            }
            .listDirection(Axis.Vertical)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.None)
            .onDidScroll(() => {
                const offset = this.listScroller.currentOffset().yOffset;
                // Fade starts after scrolling 100vp, fully solid after 200vp
                let opacity = (offset - 100) / 100;
                if (opacity < 0) opacity = 0;
                if (opacity > 1) opacity = 1;
                this.titleBarOpacity = opacity;

                AppStorage.setOrCreate('closeFeedMenuTime', Date.now());
            })
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
        .onRefreshing(() => {
            this.onRefresh();
        })
        .layoutWeight(1)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }

    @Builder
    private buildUnreadCountHint() {
        Row() {
            Image(wfc.getUserInfo(this.currentUserId).portrait || $r('app.media.icon'))
                .width(30)
                .height(30)
                .borderRadius(4)
                .margin({ right: 10 })

            Text(`${this.unreadCount}条新消息`)
                .fontSize(14)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)

            Image($r('app.media.icon')) // TODO: 使用右箭头图标
                .width(12)
                .height(12)
                .fillColor(Color.White)
                .margin({ left: 10 })
        }
        .width(180)
        .height(40)
        .backgroundColor('#4C4C4C')
        .borderRadius(4)
        .padding({ left: 8, right: 8 })
        .alignSelf(ItemAlign.Center)
        .justifyContent(FlexAlign.Center)
        .margin({ top: 10, bottom: 10 })
        .onClick(() => {
            // 跳转到消息列表
            // this.mainNavPathStack.pushPathByName(momentNavigationDestinations.FeedMessagePage, {} as Record<string, Object>)
            this.unreadCount = 0;
            momentClient.clearUnreadStatus();
        })
    }

    @Builder
    private buildLoadMoreView() {
        Row() {
            if (this.feedListState.isLoadingMore) {
                LoadingProgress()
                    .width(20)
                    .height(20)
                    .color(MomentConstants.PRIMARY_COLOR)
                    .margin({ right: 8 })

                Text('加载中...')
                    .fontSize(MomentConstants.FONT_SIZE_SMALL)
                    .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
            }
        }
        .width('100%')
        .height(50)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }

    @Builder
    private buildCommentInput() {
        Column() {
            // 遮罩层
            Row()
                .width('100%')
                .layoutWeight(1)
                .backgroundColor('rgba(0,0,0,0.3)')
                .onClick(() => {
                    this.commentInputState.isVisible = false;
                    this.commentText = '';
                })

            // 输入框区域
            Row() {
                TextInput({ placeholder: this.commentInputState.placeholder, text: this.commentText })
                    .layoutWeight(1)
                    .height(40)
                    .backgroundColor('#FFFFFF')
                    .borderRadius(20)
                    .padding({ left: 16, right: 16 })
                    .onChange((value: string) => {
                        this.commentText = value;
                    })

                Button('发送')
                    .height(40)
                    .backgroundColor(this.commentText.trim() ? MomentConstants.PRIMARY_COLOR : '#CCCCCC')
                    .borderRadius(20)
                    .margin({ left: 8 })
                    .enabled(!!this.commentText.trim())
                    .onClick(() => {
                        const targetFeed = this.feedListState.feeds.find(f => f.feed.feedId === this.commentInputState.feedId);
                        if (targetFeed) {
                            this.interactionEvents.onComment(targetFeed, this.commentText, this.commentInputState.replyTo);
                        }
                    })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(999)
    }

}