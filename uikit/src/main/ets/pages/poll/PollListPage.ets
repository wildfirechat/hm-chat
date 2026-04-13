/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import { showToast } from '../../common/utils/Toast';
import pollService, { OnPollCallback } from '../../api/pollService';
import Poll from './model/poll';
import { uikitNavigationDestinations } from '../uikitNavigationConfig';

interface PollsCallback {
    onSuccess: (result: Poll[]) => void;
    onError: (errorCode: number, message: string) => void;
}

interface VoidCallback {
    onSuccess: () => void;
    onError: (errorCode: number, message: string) => void;
}

@Component
export default struct PollListPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    private groupId: string = '';
    @State pollList: Poll[] = [];
    @State isLoading: boolean = false;
    @State isRefreshing: boolean = false;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByName(uikitNavigationDestinations.PollListPage) as Record<string, Object>[];
        if (params && params.length > 0) {
            this.groupId = params[0]['groupId'] as string || '';
        }
        this.loadPolls();
    }

    private loadPolls() {
        if (!pollService.baseUrl) {
            showToast('投票服务未配置');
            this.isRefreshing = false;
            return;
        }

        this.isLoading = true;
        pollService.getMyPolls(this.groupId, {
            onSuccess: (result: Poll[]): void => {
                this.pollList = result || [];
                this.isLoading = false;
                this.isRefreshing = false;
            },
            onError: (errorCode: number, message: string): void => {
                this.isLoading = false;
                this.isRefreshing = false;
                showToast('加载失败: ' + message);
            }
        } as PollsCallback);
    }

    private onRefresh() {
        this.isRefreshing = true;
        this.loadPolls();
    }

    private closePoll(poll: Poll) {
        AlertDialog.show({
            title: '确认结束投票',
            message: '结束后将无法继续投票，是否确认？',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            primaryButton: {
                value: '取消',
                action: () => {
                }
            },
            secondaryButton: {
                value: '结束',
                action: () => {
                    this.doClosePoll(poll);
                }
            }
        });
    }

    private doClosePoll(poll: Poll) {
        if (!pollService.baseUrl) return;

        pollService.closePoll(poll.pollId, {
            onSuccess: (): void => {
                showToast('投票已结束');
                this.loadPolls();
            },
            onError: (errorCode: number, message: string): void => {
                showToast('操作失败: ' + message);
            }
        } as VoidCallback);
    }

    private deletePoll(poll: Poll) {
        AlertDialog.show({
            title: '确认删除投票',
            message: '删除后无法恢复，是否确认？',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            primaryButton: {
                value: '取消',
                action: () => {
                }
            },
            secondaryButton: {
                value: '删除',
                fontColor: $r('app.color.wf_danger'),
                action: () => {
                    this.doDeletePoll(poll);
                }
            }
        });
    }

    private doDeletePoll(poll: Poll) {
        if (!pollService.baseUrl) return;

        pollService.deletePoll(poll.pollId, {
            onSuccess: (): void => {
                showToast('投票已删除');
                this.loadPolls();
            },
            onError: (errorCode: number, message: string): void => {
                showToast('操作失败: ' + message);
            }
        } as VoidCallback);
    }

    private navigateToPollDetail(poll: Poll) {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PollDetailPage, {
            'pollId': poll.pollId,
            'groupId': poll.groupId
        } as Record<string, Object>);
    }

    private formatTime(time: number): string {
        if (time <= 0) return '';
        let date = new Date(time);
        return `${date.getMonth() + 1}-${date.getDate()} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }

    private getStatusText(poll: Poll): string {
        if (poll.status === 1 || poll.isExpired()) {
            return '已结束';
        }
        return '进行中';
    }

    private getStatusColor(poll: Poll): Resource {
        if (poll.status === 1 || poll.isExpired()) {
            return $r('app.color.wf_tertiary_text');
        }
        return $r('app.color.wf_warning');
    }

    private getStatusBgColor(poll: Poll): Resource {
        if (poll.status === 1 || poll.isExpired()) {
            return $r('app.color.wf_primary_background_color');
        }
        return $r('app.color.wf_secondary_background');
    }

    private isPollEnded(poll: Poll): boolean {
        return poll.status === 1 || poll.isExpired();
    }

    @Builder
    PollItemBuilder(poll: Poll) {
        ListItem() {
            Row({ space: 12 }) {
                // 类型图标
                Stack() {
                    Circle()
                        .width(40)
                        .height(40)
                        .fill($r('app.color.wf_secondary_background'))

                    Text(poll.pollType === 1 ? '单' : '多')
                        .fontSize(14)
                        .fontColor($r('app.color.wf_primary'))
                        .fontWeight(FontWeight.Bold)
                }

                // 内容区域
                Column({ space: 4 }) {
                    Row({ space: 8 }) {
                        Text(poll.title)
                            .fontSize(16)
                            .fontColor($r('app.color.wf_primary_text'))
                            .fontWeight(FontWeight.Medium)
                            .layoutWeight(1)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                        Text(this.getStatusText(poll))
                            .fontSize(11)
                            .fontColor(this.getStatusColor(poll))
                            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                            .backgroundColor(this.getStatusBgColor(poll))
                            .borderRadius(4)
                    }
                    .width('100%')

                    Row({ space: 8 }) {
                        Text(`${poll.voterCount}人参与`)
                            .fontSize(13)
                            .fontColor($r('app.color.wf_tertiary_text'))

                        Text(this.formatTime(poll.createdAt))
                            .fontSize(13)
                            .fontColor($r('app.color.wf_tertiary_text'))
                    }
                    .width('100%')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.wf_background'))
        }
        .onClick(() => {
            this.navigateToPollDetail(poll);
        })
        .swipeAction({
            end: poll.isCreator ? this.ItemEndBuilder(poll) : undefined
        })
    }

    @Builder
    ItemEndBuilder(poll: Poll) {
        Row({ space: 8 }) {
            if (!this.isPollEnded(poll)) {
                Button('结束')
                    .fontSize(14)
                    .fontColor($r('app.color.wf_background'))
                    .backgroundColor($r('app.color.wf_warning'))
                    .width(60)
                    .height(40)
                    .onClick(() => {
                        this.closePoll(poll);
                    })
            }

            Button('删除')
                .fontSize(14)
                .fontColor($r('app.color.wf_background'))
                .backgroundColor($r('app.color.wf_danger'))
                .width(60)
                .height(40)
                .onClick(() => {
                    this.deletePoll(poll);
                })
        }
        .padding({ right: 16 })
    }

    build() {
        NavDestination() {
            Refresh({ refreshing: $$this.isRefreshing }) {
                if (this.pollList.length === 0 && !this.isLoading) {
                    Column() {
                        Text('暂无投票')
                            .fontSize(16)
                            .fontColor($r('app.color.wf_tertiary_text'))
                    }
                    .width('100%')
                    .height('100%')
                    .justifyContent(FlexAlign.Center)
                } else {
                    List() {
                        ForEach(this.pollList, (poll: Poll) => {
                            this.PollItemBuilder(poll);
                        }, (poll: Poll) => poll.pollId.toString())
                    }
                    .width('100%')
                    .height('100%')
                    .divider({ strokeWidth: 0.5, color: $r('app.color.wf_divider') })
                    .backgroundColor($r('app.color.wf_primary_background_color'))
                }
            }
            .onRefreshing(() => {
                this.onRefresh();
            })
        }
        .title('我的投票')
        .backgroundColor($r('app.color.wf_primary_background_color'))
        .hideBackButton(false)
    }
}
