/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import Message from './message';

import MessagePayload from "./messagePayload";

export default class MessageContent {
    type: number;
    //0 普通消息, 1 部分提醒, 2 提醒全部
    mentionedType: number = 0;
    //提醒对象，mentionedType 1时有效
    mentionedTargets: number[] = [];
    extra: string;
    pushContent: string;

    constructor(type: number, mentionedType: number = 0, mentionedTargets: number[] = []) {
        this.type = type;
        this.mentionedType = mentionedType;
        this.mentionedTargets = mentionedTargets;
    }

    digest(message?: Message): string {
        return '...digest...';
    }

    /**
     * return MessagePayload in json format
     */
    encode(): MessagePayload {
        let payload = new MessagePayload();
        payload.type = this.type;
        payload.mentionedType = this.mentionedType;
        payload.mentionedTargets = this.mentionedTargets;
        payload.extra = this.extra;
        return payload;
    }

    /**
     *
     * @param {object} payload object json.parse from message#content
     */
    decode(payload: MessagePayload) {
        this.type = payload.type;
        this.mentionedType = payload.mentionedType;
        if (payload.hasOwnProperty('mentionedTarget')) {
            // web
            // this.mentionedTargets = payload.mentionedTarget;
        } else {
            // pc
            this.mentionedTargets = payload.mentionedTargets;
        }
        this.extra = payload.extra;
        this.pushContent = payload.pushContent;
    }
}
