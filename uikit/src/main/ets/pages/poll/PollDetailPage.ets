/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import { showToast } from '../../common/utils/Toast';
import pollService from '../../api/pollService';
import Poll from './model/poll';
import PollOption from './model/pollOption';
import PollVoterDetail from './model/pollVoterDetail';
import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import PollMessageContent from '@wfc/client/src/main/ets/wfc/messages/pollMessageContent';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import { uikitNavigationDestinations } from '../uikitNavigationConfig';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';

interface PollCallback {
    onSuccess: (poll: Poll) => void;
    onError: (errorCode: number, message: string) => void;
}

interface VoidCallback {
    onSuccess: () => void;
    onError: (errorCode: number, message: string) => void;
}

interface ExportCallback {
    onSuccess: (details: PollVoterDetail[]) => void;
    onError: (errorCode: number, message: string) => void;
}

@Component
export default struct PollDetailPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private pollId: number = 0;
    private groupId: string = '';
    private message: Message | null = null;
    @State poll: Poll | null = null;
    @State selectedOptions: Set<number> = new Set();
    @State isLoading: boolean = true;
    @State currentUserId: string = '';
    @State creatorInfo: UserInfo | null = null;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByName(uikitNavigationDestinations.PollDetailPage) as Record<string, Object>[];
        if (params && params.length > 0) {
            this.pollId = params[0]['pollId'] as number || 0;
            this.groupId = params[0]['groupId'] as string || '';
            this.message = params[0]['message'] as Message || null;
        }
        this.currentUserId = wfc.getUserId();
        this.loadPollDetail();
    }

    private loadPollDetail() {
        if (!pollService.baseUrl) {
            showToast('投票服务未配置');
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        pollService.getPoll(this.pollId, {
            onSuccess: (poll: Poll): void => {
                this.poll = poll;
                this.isLoading = false;
                // 加载创建者信息
                if (poll.creatorId) {
                    this.loadCreatorInfo(poll.creatorId);
                }
                this.updateLocalMessageIfNeeded();
            },
            onError: (errorCode: number, message: string): void => {
                this.isLoading = false;
                showToast('加载失败: ' + message);
            }
        } as PollCallback);
    }

    private loadCreatorInfo(creatorId: string) {
        let userInfo = wfc.getUserInfo(creatorId, false);
        if (userInfo) {
            this.creatorInfo = userInfo;
        }
    }

    private updateLocalMessageIfNeeded() {
        if (!this.message || !(this.message.messageContent instanceof PollMessageContent)) {
            return;
        }

        let content = this.message.messageContent as PollMessageContent;
        let needUpdate = false;

        // 检查状态是否有变化
        if (this.poll && this.poll.status !== content.status) {
            content.status = this.poll.status;
            needUpdate = true;
        }

        // 检查总票数是否有变化
        if (this.poll && this.poll.totalVotes !== content.totalVotes) {
            content.totalVotes = this.poll.totalVotes;
            needUpdate = true;
        }

        // 检查是否已过期
        let now = new Date().getTime();
        if (this.poll && this.poll.endTime > 0 && this.poll.endTime < now && content.endTime >= now) {
            content.status = 1;
            needUpdate = true;
        }

        // 如果有变化，更新本地消息
        if (needUpdate) {
            wfc.updateMessageContent(this.message.messageId, content);
        }
    }

    private isManagerMode(): boolean {
        return this.poll !== null && this.poll.isCreator && this.message === null;
    }

    private canVote(): boolean {
        if (!this.poll) {
            return false;
        }
        if (this.isManagerMode()) {
            return false;
        }
        if (this.poll.hasVoted) {
            return false;
        }
        if (this.poll.status === 1) {
            return false;
        }
        if (this.poll.isExpired()) {
            return false;
        }
        return true;
    }

    private toggleOption(optionId: number) {
        if (!this.canVote()) {
            return;
        }

        let newSelected = new Set(this.selectedOptions);
        if (this.poll?.pollType === 1) {
            // 单选：清除之前的选择，只选中当前项
            if (newSelected.has(optionId)) {
                newSelected.delete(optionId);
            } else {
                newSelected.clear();
                newSelected.add(optionId);
            }
        } else {
            // 多选
            if (newSelected.has(optionId)) {
                newSelected.delete(optionId);
            } else {
                let maxSelect = this.poll?.maxSelect || this.poll?.options.length || 1;
                if (newSelected.size < maxSelect) {
                    newSelected.add(optionId);
                } else {
                    showToast(`最多选择${maxSelect}项`);
                }
            }
        }
        // 重新赋值触发更新
        this.selectedOptions = newSelected;
    }

    private submitVote() {
        if (this.selectedOptions.size === 0) {
            showToast('请选择选项');
            return;
        }

        if (!pollService.baseUrl) { return; }

        let optionIds = Array.from(this.selectedOptions);
        pollService.vote(this.pollId, optionIds, {
            onSuccess: (): void => {
                showToast('投票成功');
                this.loadPollDetail();
            },
            onError: (errorCode: number, message: string): void => {
                showToast('投票失败: ' + message);
            }
        } as VoidCallback);
    }

    private closePoll() {
        AlertDialog.show({
            title: '确认结束投票',
            message: '结束后将无法继续投票，是否确认？',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            primaryButton: {
                value: '取消',
                action: () => {}
            },
            secondaryButton: {
                value: '结束',
                action: () => { this.doClosePoll(); }
            }
        });
    }

    private doClosePoll() {
        if (!pollService.baseUrl) { return; }

        pollService.closePoll(this.pollId, {
            onSuccess: (): void => {
                showToast('投票已结束');
                this.loadPollDetail();
            },
            onError: (errorCode: number, message: string): void => {
                showToast('操作失败: ' + message);
            }
        } as VoidCallback);
    }

    private deletePoll() {
        AlertDialog.show({
            title: '确认删除投票',
            message: '删除后无法恢复，是否确认？',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            primaryButton: {
                value: '取消',
                action: () => {}
            },
            secondaryButton: {
                value: '删除',
                fontColor: '#FF3B30',
                action: () => { this.doDeletePoll(); }
            }
        });
    }

    private doDeletePoll() {
        if (!pollService.baseUrl) { return; }

        pollService.deletePoll(this.pollId, {
            onSuccess: (): void => {
                showToast('投票已删除');
                this.mainNavPathStack.pop();
            },
            onError: (errorCode: number, message: string): void => {
                showToast('操作失败: ' + message);
            }
        } as VoidCallback);
    }

    private getStatusText(): string {
        if (!this.poll) return '';
        let remainingTime = this.poll.getRemainingTimeText();
        if (remainingTime) return remainingTime;
        if (this.poll.status === 1) return '已结束';
        return '';
    }

    private getStatusColor(): string {
        if (!this.poll) return '#999999';
        if (this.poll.status === 1 || this.poll.isExpired()) return '#999999';
        return '#FF9500';
    }

    private getCreatorName(): string {
        if (this.creatorInfo) {
            return this.creatorInfo.displayName || this.creatorInfo.name || this.poll?.creatorId || '';
        }
        return this.poll?.creatorId || '';
    }

    private formatRemainingTime(): string {
        if (!this.poll) return '';
        if (this.poll.status === 1 || this.poll.isExpired()) return '';
        if (this.poll.endTime <= 0) return '无截止时间';

        let now = new Date().getTime();
        let remaining = this.poll.endTime - now;
        if (remaining <= 0) return '';

        let minutes = Math.floor(remaining / 60000);
        let hours = Math.floor(minutes / 60);
        let days = Math.floor(hours / 24);

        if (days > 0) return `还剩${days}天`;
        if (hours > 0) return `还剩${hours}小时`;
        if (minutes > 0) return `还剩${minutes}分钟`;
        return '还剩不到1分钟';
    }

    private getFooterStatusText(): string {
        if (!this.poll) return '';
        let parts: string[] = [];

        // 投票类型
        parts.push(this.poll.anonymous === 1 ? '匿名投票' : '实名投票');

        // 参与人数
        parts.push(`${this.poll.voterCount}人参与`);

        // 剩余时间
        let remainingTime = this.formatRemainingTime();
        if (remainingTime && remainingTime !== '无截止时间') {
            parts.push(remainingTime);
        }

        // 状态
        if (this.poll.status === 1) {
            parts.push('已结束');
        } else if (this.poll.isExpired()) {
            parts.push('已过期');
        } else if (this.poll.hasVoted) {
            parts.push('已投票');
        }

        return parts.join(' · ');
    }

    private isOptionSelected(optionId: number): boolean {
        return this.selectedOptions.has(optionId);
    }

    private isMyVoteOption(optionId: number): boolean {
        return this.poll?.myOptionIds?.includes(optionId) ?? false;
    }

    private getOptionFontColor(optionId: number): string {
        let isMyVote = this.isMyVoteOption(optionId);
        let isSelected = this.isOptionSelected(optionId);
        let hasVoted = !this.canVote();

        // 已投票选项：显示蓝色
        if (isMyVote) return '#007AFF';
        // 投票前选中：显示蓝色
        if (isSelected && !hasVoted) return '#007AFF';
        // 其他情况：黑色
        return '#333333';
    }

    @Builder
    OptionItemBuilder(option: PollOption, index: number) {
        Row() {
            // 左侧选择框（仅在非管理场景显示）
            if (!this.isManagerMode()) {
                if (this.isMyVoteOption(option.optionId) || (this.isOptionSelected(option.optionId) && this.canVote())) {
                    // 选中状态
                    Stack() {
                        Circle()
                            .width(20)
                            .height(20)
                            .fill('#007AFF')
                        Text('✓')
                            .fontSize(12)
                            .fontColor(Color.White)
                    }
                    .width(32)
                } else {
                    // 未选中状态
                    Circle()
                        .width(20)
                        .height(20)
                        .fill(Color.Transparent)
                        .stroke('#CCCCCC')
                        .strokeWidth(2)
                        .width(32)
                }
            }

            // 中间选项文字和进度条
            Column({ space: 6 }) {
                Row() {
                    Text(option.optionText)
                        .fontSize(14)
                        .fontColor(this.getOptionFontColor(option.optionId))
                        .layoutWeight(1)

                    // 百分比（显示结果时）
                    if (this.poll?.shouldShowResult()) {
                        Text(`${option.votePercent}% (${option.voteCount}票)`)
                            .fontSize(12)
                            .fontColor('#666666')
                            .margin({ left: 8 })
                    }
                }
                .width('100%')

                // 进度条（显示结果时）
                if (this.poll?.shouldShowResult()) {
                    Stack({ alignContent: Alignment.Start }) {
                        // 背景条
                        Row()
                            .width('100%')
                            .height(4)
                            .backgroundColor('#E5E5E5')
                            .borderRadius(2)

                        // 进度条
                        Row()
                            .width(`${option.votePercent}%`)
                            .height(4)
                            .backgroundColor('#007AFF')
                            .borderRadius(2)
                    }
                    .width('100%')
                }
            }
            .layoutWeight(1)
            .margin({ left: this.isManagerMode() ? 0 : 8 })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12, left: this.isManagerMode() ? 16 : 12, right: 12 })
        .backgroundColor(this.isMyVoteOption(option.optionId) || (this.isOptionSelected(option.optionId) && this.canVote()) ? '#F0F8FF' : Color.White)
        .onClick(() => {
            this.toggleOption(option.optionId);
        })
    }

    build() {
        NavDestination() {
            if (this.isLoading) {
                Column() {
                    LoadingProgress()
                        .width(40)
                        .height(40)
                        .color('#007AFF')
                    Text('加载中...')
                        .fontSize(14)
                        .fontColor('#999999')
                        .margin({ top: 8 })
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
            } else if (!this.poll) {
                Column() {
                    Text('加载失败')
                        .fontSize(16)
                        .fontColor('#999999')
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
            } else {
                Column() {
                    Scroll() {
                        Column({ space: 16 }) {
                            // 头部信息
                            Column({ space: 12 }) {
                                // 创建者信息
                                Row({ space: 8 }) {
                                    Image(this.creatorInfo?.portrait || $r('app.media.avatar_def'))
                                        .width(24)
                                        .height(24)
                                        .borderRadius(12)
                                    
                                    Text(`发起者：${this.getCreatorName()}`)
                                        .fontSize(12)
                                        .fontColor('#666666')
                                    
                                    // 状态标签
                                    Text(this.getStatusText())
                                        .fontSize(11)
                                        .fontColor(this.getStatusColor())
                                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                                        .backgroundColor('#FFF5E6')
                                        .borderRadius(4)
                                        .visibility(this.getStatusText() ? Visibility.Visible : Visibility.None)
                                }
                                .width('100%')

                                // 标题
                                Text(this.poll.title)
                                    .fontSize(18)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor('#333333')
                                    .width('100%')

                                // 描述
                                if (this.poll.desc) {
                                    Text(this.poll.desc)
                                        .fontSize(14)
                                        .fontColor('#666666')
                                        .width('100%')
                                }

                                // 类型标签
                                Row({ space: 8 }) {
                                    Text(this.poll.pollType === 1 ? '单选' : '多选')
                                        .fontSize(12)
                                        .fontColor('#007AFF')
                                        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                                        .backgroundColor('#F0F8FF')
                                        .borderRadius(4)
                                }
                                .width('100%')
                            }
                            .width('100%')
                            .padding(16)
                            .backgroundColor(Color.White)
                            .borderRadius(12)

                            // 选项列表标题
                            Text('选项')
                                .fontSize(14)
                                .fontColor('#666666')
                                .fontWeight(FontWeight.Medium)
                                .width('100%')
                                .padding({ left: 4 })

                            // 选项列表
                            Column({ space: 0 }) {
                                ForEach(this.poll.options, (option: PollOption, index: number) => {
                                    Column() {
                                        this.OptionItemBuilder(option, index);
                                        if (index < this.poll!.options.length - 1) {
                                            Divider()
                                                .strokeWidth(0.5)
                                                .color('#E5E5E5')
                                                .margin({ left: 16, right: 16 })
                                        }
                                    }
                                }, (option: PollOption) => option.optionId.toString())
                            }
                            .width('100%')
                            .backgroundColor(Color.White)
                            .borderRadius(12)
                            .clip(true)

                            // 底部状态
                            Text(this.getFooterStatusText())
                                .fontSize(12)
                                .fontColor('#999999')
                                .width('100%')
                                .textAlign(TextAlign.Center)
                                .padding(16)
                        }
                        .width('100%')
                        .padding(16)
                    }
                    .align(Alignment.TopStart)
                    .width('100%')
                    .layoutWeight(1)

                    // 底部操作栏
                    if (this.canVote()) {
                        Row({ space: 16 }) {
                            Button('提交投票')
                                .width('100%')
                                .height(44)
                                .fontSize(16)
                                .fontColor(Color.White)
                                .backgroundColor(this.selectedOptions.size > 0 ? '#007AFF' : '#CCCCCC')
                                .borderRadius(8)
                                .enabled(this.selectedOptions.size > 0)
                                .onClick(() => { this.submitVote(); })
                        }
                        .width('100%')
                        .padding(16)
                        .backgroundColor(Color.White)
                        .shadow({ radius: 4, color: '#00000010' })
                    } else if (this.isManagerMode()) {
                        Row({ space: 16 }) {
                            // 实名投票显示导出按钮
                            if (this.poll.anonymous === 0) {
                                Button('导出明细')
                                    .layoutWeight(1)
                                    .height(44)
                                    .fontSize(14)
                                    .fontColor(Color.White)
                                    .backgroundColor('#007AFF')
                                    .borderRadius(8)
                                    .onClick(() => { this.exportPollDetails(); })
                            }

                            // 结束/删除按钮
                            if (this.poll.status === 1 || this.poll.isExpired()) {
                                Button('删除投票')
                                    .layoutWeight(this.poll.anonymous === 0 ? 1 : 2)
                                    .height(44)
                                    .fontSize(14)
                                    .fontColor(Color.White)
                                    .backgroundColor('#FF3B30')
                                    .borderRadius(8)
                                    .onClick(() => { this.deletePoll(); })
                            } else {
                                Button('结束投票')
                                    .layoutWeight(this.poll.anonymous === 0 ? 1 : 2)
                                    .height(44)
                                    .fontSize(14)
                                    .fontColor(Color.White)
                                    .backgroundColor('#FF9500')
                                    .borderRadius(8)
                                    .onClick(() => { this.closePoll(); })
                            }
                        }
                        .width('100%')
                        .padding(16)
                        .backgroundColor(Color.White)
                        .shadow({ radius: 4, color: '#00000010' })
                    }
                }
                .width('100%')
                .height('100%')
            }
        }
        .title('投票详情')
        .backgroundColor('#F2F2F7')
        .hideBackButton(false)
    }

    private exportPollDetails() {
        if (!pollService.baseUrl) { return; }

        pollService.exportPollDetails(this.pollId, {
            onSuccess: (details: PollVoterDetail[]): void => {
                showToast('导出成功');
            },
            onError: (errorCode: number, message: string): void => {
                showToast('导出失败: ' + message);
            }
        } as ExportCallback);
    }
}
