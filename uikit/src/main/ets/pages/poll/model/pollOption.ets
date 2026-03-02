/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

/**
 * 投票选项
 */
export default class PollOption {
    optionId = 0;
    optionText = '';
    sortOrder = 0;
    voteCount = 0;
    votePercent = 0;

    static fromJson(json: Record<string, Object> | null): PollOption | null {
        if (!json) {
            return null;
        }
        let option = new PollOption();
        option.optionId = json['id'] as number || 0;
        option.optionText = json['optionText'] as string || '';
        option.sortOrder = json['sortOrder'] as number || 0;
        option.voteCount = json['voteCount'] as number || 0;
        option.votePercent = json['votePercent'] as number || 0;
        return option;
    }
}
