import { momentClient } from '../client/MomentClient';
import { MomentConstants, TimeFormatter } from '../utils/MomentConstants';
import { momentNavigationDestinations } from './momentNavigationConfig';
import wfc from '@wfc/client';
import { MomentFeedMessageContent, MomentCommentMessageContent } from '@wfc/client';
import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import { FontSize, Radius } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import { trustedMediaSrc } from '@wfc/uikit/src/main/ets/util/trustedMedia'

const PAGE_COUNT = 100;

/**
 * 朋友圈消息列表页（收到的评论/点赞/提醒）。
 * 进入后清除未读并记录最后阅读时间；滚动到底加载更早。
 */
@Component
export struct FeedMessagesPage {
    @State items: MessageItemData[] = [];
    @State isLoading: boolean = false;
    @State hasMore: boolean = false;

    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        this.loadMessages(true);
    }

    private async loadMessages(refresh: boolean) {
        if (this.isLoading) return;
        this.isLoading = true;
        try {
            if (refresh) {
                // 未读 + 历史，按 messageUid 去重合并（时间倒序）
                let newMessages = await momentClient.getFeedMessages(0, true);
                let history = await momentClient.getFeedMessages(0, false);
                let merged: Message[] = [];
                let seen = new Set<string>();
                [...newMessages, ...history].forEach(message => {
                    let key = message.messageUid.toString();
                    if (!seen.has(key)) {
                        seen.add(key);
                        merged.push(message);
                    }
                });
                merged.sort((a, b) => b.timestamp - a.timestamp);
                this.items = merged.map(message => this.messageItem(message));
                this.hasMore = history.length >= PAGE_COUNT;
                // 进入后清除未读并记录最后阅读时间
                momentClient.clearUnreadStatus();
                momentClient.updateLastReadTimestamp();
                AppStorage.setOrCreate<number>('momentUnreadCount', 0);
            } else {
                const fromIndex = this.items.length > 0 ? this.items[this.items.length - 1].messageId : 0;
                let loaded = await momentClient.getFeedMessages(fromIndex, false);
                this.items = [...this.items, ...loaded.map(message => this.messageItem(message))];
                this.hasMore = loaded.length >= PAGE_COUNT;
            }
        } catch (e) {
            console.error(`FeedMessagesPage load failed: ${JSON.stringify(e)}`);
        }
        this.isLoading = false;
    }

    // 渲染一行的展示数据
    private messageItem(message: Message): MessageItemData {
        let item = new MessageItemData();
        item.messageId = message.messageId;
        let content = message.messageContent;
        if (content instanceof MomentCommentMessageContent) {
            item.sender = content.sender || message.from;
            item.feedId = content.feedId;
            item.isPraise = content.commentType === 1;
            item.text = item.isPraise ? '' : (content.text || '');
            item.feedPreview = content.feedText || '';
            if (content.feedMedias && content.feedMedias.length > 0) {
                let media = content.feedMedias[0];
                item.feedThumb = (media.thumbUrl && media.thumbUrl.length > 0) ? media.thumbUrl : media.mediaUrl;
            }
        } else if (content instanceof MomentFeedMessageContent) {
            item.sender = content.sender || message.from;
            item.feedId = content.feedId;
            item.isMention = true;
            item.feedPreview = content.text || '';
            if (content.medias && content.medias.length > 0) {
                let media = content.medias[0];
                item.feedThumb = (media.thumbUrl && media.thumbUrl.length > 0) ? media.thumbUrl : media.mediaUrl;
            }
        } else {
            item.sender = message.from;
        }
        item.timeText = TimeFormatter.formatFeedTime(message.timestamp);
        return item;
    }

    build() {
        NavDestination() {
            List() {
                ForEach(this.items, (item: MessageItemData) => {
                    ListItem() {
                        this.buildMessageItem(item)
                    }
                }, (item: MessageItemData, index: number) => `msg_${item.messageId}_${index}`)

                if (this.isLoading) {
                    ListItem() {
                        Row() {
                            LoadingProgress()
                                .width(20)
                                .height(20)
                                .color(MomentConstants.TEXT_SECONDARY_COLOR)
                        }
                        .width('100%')
                        .padding({ top: 16, bottom: 16 })
                        .justifyContent(FlexAlign.Center)
                    }
                } else if (this.items.length === 0) {
                    ListItem() {
                        Column() {
                            Text('暂无消息')
                                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                        }
                        .width('100%')
                        .padding({ top: 120 })
                        .justifyContent(FlexAlign.Center)
                    }
                }
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .onReachEnd(() => {
                if (this.hasMore && !this.isLoading) {
                    this.loadMessages(false);
                }
            })
        }
        .title('消息')
        .backgroundColor(MomentConstants.BACKGROUND_COLOR)
    }

    @Builder
    private buildMessageItem(item: MessageItemData) {
        Row({ space: 10 }) {
            // 头像
            Image(trustedMediaSrc(wfc.getUserInfo(item.sender).portrait) || $r('app.media.icon'))
                .width(46)
                .height(46)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)

            Column({ space: 3 }) {
                Text(wfc.getUserInfo(item.sender).displayName)
                    .fontSize(FontSize.sm)
                    .fontColor(MomentConstants.LINK_COLOR)

                Text(item.isPraise
                    ? '赞了你的朋友圈'
                    : item.isMention
                        ? '在评论中提到了你'
                        : item.text)
                    .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                    .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(item.timeText)
                    .fontSize(MomentConstants.FONT_SIZE_CAPTION)
                    .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // 右侧 feed 摘要（图或文本）
            this.buildFeedPreview(item)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .alignItems(VerticalAlign.Top)
        .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
        .onClick(() => {
            if (item.feedId.length > 0) {
                this.mainNavPathStack.pushPathByName(momentNavigationDestinations.FeedDetailPage, {
                    'feedId': item.feedId
                } as Record<string, Object>);
            }
        })
    }

    @Builder
    private buildFeedPreview(item: MessageItemData) {
        if (item.feedThumb.length > 0) {
            Image(trustedMediaSrc(item.feedThumb))
                .width(56)
                .height(56)
                .objectFit(ImageFit.Cover)
                .borderRadius(Radius.xs)
                .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)
        } else {
            Column() {
                Text(item.feedPreview)
                    .fontSize(11)
                    .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width(56)
            .height(56)
            .padding(4)
            .borderRadius(Radius.xs)
            .backgroundColor(MomentConstants.INTERACTIONS_BACKGROUND_COLOR)
        }
    }
}

@Observed
class MessageItemData {
    messageId: number = 0;
    sender: string = '';
    // int64 feedId，用字符串承载避免精度丢失
    feedId: string = '';
    isPraise: boolean = false;
    isMention: boolean = false;
    text: string = '';
    feedPreview: string = '';
    feedThumb: string = '';
    timeText: string = '';
}
