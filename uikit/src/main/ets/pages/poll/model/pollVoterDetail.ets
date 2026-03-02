/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

/**
 * 投票人详情
 */
export default class PollVoterDetail {
    optionId = 0;
    optionText = '';
    userId = '';
    userName = '';
    createdAt = 0;

    static fromJson(json: Record<string, Object> | null): PollVoterDetail | null {
        if (!json) {
            return null;
        }
        let detail = new PollVoterDetail();
        detail.optionId = json['optionId'] as number || 0;
        detail.optionText = json['optionText'] as string || '';
        detail.userId = json['userId'] as string || '';
        detail.userName = json['userName'] as string || '';
        detail.createdAt = json['createdAt'] as number || 0;
        return detail;
    }
}
