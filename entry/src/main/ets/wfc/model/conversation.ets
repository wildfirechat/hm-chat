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
    type: number = ConversationType.Single;
    // 这行是为了做一个兼容处理
    conversationType = this.type;
    target = '';
    line = 0;

    constructor(type: number, target: string, line = 0) {
        this.type = type;
        this.conversationType = type;
        this.target = target;
        this.line = line;
    }

    static equal(conv1: Conversation, conv2: Conversation): boolean {
        if (!conv1 || !conv2) {
            return false;
        }
        return conv1.type === conv2.type
            && conv1.target === conv2.target
            && conv1.line === conv2.line;
    }
}
