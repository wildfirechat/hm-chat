/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import ConversationType from "./conversationType";

/**
 *
 "conversation":{
 "conversationType": 0,
 "target": "UZUWUWuu",
 "line": 0,
 }
 */
export default class Conversation {
    type: ConversationType = ConversationType.Single;
    conversationType = this.type; // 这行是为了做一个兼容处理
    target = '';
    line = 0;

    constructor(type: ConversationType, target: string, line = 0) {
        this.type = type;
        this.conversationType = type;
        this.target = target;
        this.line = line;
    }

    equal(conversation: Conversation) {
        if (!conversation) {
            return false;
        }
        return this.type === conversation.type
        && this.target === conversation.target
        && this.line === conversation.line;
    }
}
