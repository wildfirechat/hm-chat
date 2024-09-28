/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MediaMessageContent from './mediaMessageContent'
import MessageContentMediaType from './messageContentMediaType';
import MessageContentType from './messageContentType';
import MessagePayload from './messagePayload';

export default class SoundMessageContent extends MediaMessageContent {
    duration = 0;

    constructor(fileOrLocalPath: string = '', remotePath: string = '', duration = 0) {
        super(MessageContentType.Voice, MessageContentMediaType.Voice, fileOrLocalPath, remotePath);
        this.duration = duration;
    }

    digest() {
        return '[语音]';
    }

    encode() {
        let payload = super.encode();
        payload.mediaType = MessageContentMediaType.Voice;
        let obj = {
            duration: this.duration,
        } as Data;
        payload.content = JSON.stringify(obj);
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let obj = JSON.parse(payload.content) as Data;
        this.duration = obj.duration;
    }
}

class Data {
    duration = 0;
}
