/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from './messageContent';
import MessageContentType from './messageContentType';
import PersistFlag from './persistFlag';
import MessagePayload from './messagePayload';
import wfc from '../client/wfc';
import Message from './message';

/**
 * 投票消息内容类型
 * <p>
 * 用于表示群聊中的投票创建消息。
 * 消息类型: 18
 * </p>
 */
export default class PollMessageContent extends MessageContent {
    pollId = '';
    groupId = '';
    creatorId = '';
    title = '';
    desc = '';
    visibility = 1;      // 1=仅群内, 2=公开
    pollType = 1;        // 1=单选, 2=多选
    anonymous = 0;       // 0=实名, 1=匿名
    status = 0;          // 0=进行中, 1=已结束
    endTime = 0;
    totalVotes = 0;

    constructor() {
        super(MessageContentType.Poll);
    }

    encode(): MessagePayload {
        let payload = super.encode();
        payload.searchableContent = this.title;

        let obj = {
            pollId: this.pollId || '',
            groupId: this.groupId || '',
            creatorId: this.creatorId || '',
            title: this.title || '',
            desc: this.desc || '',
            visibility: this.visibility,
            type: this.pollType,
            anonymous: this.anonymous,
            status: this.status,
            endTime: this.endTime,
            totalVotes: this.totalVotes
        } as PollData;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload): void {
        super.decode(payload);
        if (payload.binaryContent) {
            let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as PollData;
            this.pollId = obj.pollId || '';
            this.groupId = obj.groupId || '';
            this.creatorId = obj.creatorId || '';
            this.title = obj.title || '';
            this.desc = obj.desc || '';
            this.visibility = obj.visibility || 1;
            this.pollType = obj.type || 1;
            this.anonymous = obj.anonymous || 0;
            this.status = obj.status || 0;
            this.endTime = obj.endTime || 0;
            this.totalVotes = obj.totalVotes || 0;
        }
    }

    digest(message?: Message): string {
        return '[投票] ' + (this.title || '');
    }
}

class PollData {
    pollId = '';
    groupId = '';
    creatorId = '';
    title = '';
    desc = '';
    visibility = 1;
    type = 1;
    anonymous = 0;
    status = 0;
    endTime = 0;
    totalVotes = 0;
}
