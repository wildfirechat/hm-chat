/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import PollOption from './pollOption';
import PollVoterDetail from './pollVoterDetail';

/**
 * 投票数据模型
 */
export default class Poll {
    pollId = 0;
    groupId = '';
    creatorId = '';
    title = '';
    desc = '';
    visibility = 1;      // 1=仅群内, 2=公开
    pollType = 1;        // 1=单选, 2=多选
    maxSelect = 1;       // 多选时最多选几项
    anonymous = 0;       // 0=实名, 1=匿名
    status = 0;          // 0=进行中, 1=已结束
    endTime = 0;
    showResult = 0;      // 0=投票前隐藏, 1=始终显示
    createdAt = 0;
    updatedAt = 0;

    // 当前用户相关
    hasVoted = false;
    isCreator = false;
    myOptionIds: number[] = [];

    // 状态标记
    deleted = false;

    // 统计
    totalVotes = 0;     // 总票数（多选时可能大于人数）
    voterCount = 0;     // 投票人数（去重后的用户数）

    // 选项列表
    options: PollOption[] = [];

    // 投票人详情（仅实名投票且是发起者）
    voterDetails: PollVoterDetail[] = [];

    /**
     * 是否显示结果
     * 与iOS端保持一致：投票已结束或已投票者可见
     */
    shouldShowResult(): boolean {
        // 投票已结束，所有人可见
        if (this.status === 1) return true;
        // 已投票者可见
        if (this.hasVoted) return true;
        return false;
    }

    /**
     * 是否已过期
     */
    isExpired(): boolean {
        if (this.endTime > 0) {
            return this.endTime < new Date().getTime();
        }
        return false;
    }

    /**
     * 获取剩余时间文本
     */
    getRemainingTimeText(): string | null {
        // 投票已结束（手动关闭）
        if (this.status === 1) {
            return '已结束';
        }

        if (this.endTime <= 0) return null;

        let now = new Date().getTime();
        let remaining = this.endTime - now;

        if (remaining <= 0) {
            return '已过期';
        }

        let minutes = Math.floor(remaining / 60000);
        let hours = Math.floor(minutes / 60);
        let days = Math.floor(hours / 24);

        if (days > 0) {
            return `还剩${days}天`;
        } else if (hours > 0) {
            return `还剩${hours}小时`;
        } else {
            return `还剩${minutes}分钟`;
        }
    }

    static fromJson(json: Record<string, Object> | null): Poll | null {
        if (!json) {
            return null;
        }
        let poll = new Poll();
        poll.pollId = json['id'] as number || 0;
        poll.groupId = json['groupId'] as string || '';
        poll.creatorId = json['creatorId'] as string || '';
        poll.title = json['title'] as string || '';
        poll.desc = json['description'] as string || '';
        poll.visibility = json['visibility'] as number || 1;
        poll.pollType = json['type'] as number || 1;
        poll.maxSelect = json['maxSelect'] as number || 1;
        poll.anonymous = json['anonymous'] as number || 0;
        poll.status = json['status'] as number || 0;
        poll.endTime = json['endTime'] as number || 0;
        poll.showResult = json['showResult'] as number || 0;
        poll.createdAt = json['createdAt'] as number || 0;
        poll.updatedAt = json['updatedAt'] as number || 0;
        poll.hasVoted = json['hasVoted'] as boolean || false;
        poll.isCreator = json['isCreator'] as boolean || false;
        poll.totalVotes = json['totalVotes'] as number || 0;
        poll.voterCount = json['voterCount'] as number || 0;
        poll.deleted = json['deleted'] as boolean || false;

        // 解析选项
        let optionsArray = json['options'] as Record<string, Object>[];
        if (optionsArray) {
            poll.options = optionsArray.map(opt => PollOption.fromJson(opt)).filter(opt => opt !== null) as PollOption[];
        }

        // 解析我选的选项
        let myOptionIdsArray = json['myOptionIds'] as number[];
        if (myOptionIdsArray) {
            poll.myOptionIds = myOptionIdsArray;
        }

        // 解析投票人详情
        let voterDetailsArray = json['voterDetails'] as Record<string, Object>[];
        if (voterDetailsArray) {
            poll.voterDetails = voterDetailsArray.map(detail => PollVoterDetail.fromJson(detail)).filter(detail => detail !== null) as PollVoterDetail[];
        }

        return poll;
    }
}
