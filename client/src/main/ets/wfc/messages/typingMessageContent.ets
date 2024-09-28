/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import MessagePayload from './messagePayload';

export default class TypingMessageContent extends MessageContent {
    static TYPING_TEXT = 0;
    static TYPING_VOICE = 1;
    static TYPING_CAMERA = 2;
    static TYPING_LOCATION = 3;
    static TYPING_FILE = 4;
    typingType = TypingMessageContent.TYPING_TEXT;

    constructor(type: number = 0) {
        super(MessageContentType.Typing);
        this.typingType = type;
    }

    digest() {
        return '';
    }

    encode() {
        let payload = super.encode();
        payload.content = this.typingType + '';
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.typingType = parseInt(payload.content);
    }
}
