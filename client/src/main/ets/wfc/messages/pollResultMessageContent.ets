/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from './messageContent';
import MessageContentType from './messageContentType';
import MessagePayload from './messagePayload';
import wfc from '../client/wfc';
import Message from './message';

/**
 * 投票结果消息内容类型
 * <p>
 * 用于表示投票结束时的结果通知消息。
 * 消息类型: 19
 * </p>
 */
export default class PollResultMessageContent extends MessageContent {
    pollId = '';
    groupId = '';
    creatorId = '';
    title = '';
    totalVotes = 0;
    voterCount = 0;
    winningOptionIds: string[] = [];
    winningOptionTexts: string[] = [];
    endedAt = 0;

    constructor() {
        super(MessageContentType.Poll_Result);
    }

    encode(): MessagePayload {
        let payload = super.encode();
        payload.searchableContent = '投票结果: ' + this.title;

        let obj = {
            pollId: this.pollId || '',
            groupId: this.groupId || '',
            creatorId: this.creatorId || '',
            title: this.title || '',
            totalVotes: this.totalVotes,
            voterCount: this.voterCount,
            winningOptionIds: this.winningOptionIds,
            winningOptionTexts: this.winningOptionTexts,
            endedAt: this.endedAt
        } as PollResultData;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload): void {
        super.decode(payload);
        if (payload.binaryContent) {
            let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as PollResultData;
            this.pollId = obj.pollId || '';
            this.groupId = obj.groupId || '';
            this.creatorId = obj.creatorId || '';
            this.title = obj.title || '';
            this.totalVotes = obj.totalVotes || 0;
            this.voterCount = obj.voterCount || 0;
            this.winningOptionIds = obj.winningOptionIds || [];
            this.winningOptionTexts = obj.winningOptionTexts || [];
            this.endedAt = obj.endedAt || 0;
        }
    }

    digest(message?: Message): string {
        return '[投票结果] ' + (this.title || '');
    }
}

class PollResultData {
    pollId = '';
    groupId = '';
    creatorId = '';
    title = '';
    totalVotes = 0;
    voterCount = 0;
    winningOptionIds: string[] = [];
    winningOptionTexts: string[] = [];
    endedAt = 0;
}
