/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import MessagePayload from './messagePayload';

export default class UnknownMessageContent extends MessageContent {
    originalPayload?: MessagePayload;

    constructor(originalPayload?: MessagePayload) {
        super(MessageContentType.Unknown);
        this.originalPayload = originalPayload;
    }

    encode() {
        return this.originalPayload!;
    }

    decode(paylaod: MessagePayload) {
        this.originalPayload = paylaod;
    }

    digest() {
        return '未知类型消息';
    }
}