/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MediaMessageContent from './mediaMessageContent'
import MessageContentMediaType from './messageContentMediaType';
import MessageContentType from './messageContentType';
import MessagePayload from './messagePayload';

export default class VideoMessageContent extends MediaMessageContent {
    // base64 encoded
    thumbnail: string;
    duration: number;

    constructor(fileOrLocalPath: string = '', remotePath: string = '', thumbnail: string = '', duration = 0) {
        super(MessageContentType.Video, MessageContentMediaType.Video, fileOrLocalPath, remotePath);
        this.thumbnail = thumbnail;
        this.duration = duration;
    }

    digest() {
        return '[视频]';
    }

    encode() {
        let payload = super.encode();
        payload.binaryContent = this.thumbnail;
        let obj = {
            d: this.duration,
            duration: this.duration
        } as Data;
        payload.content = JSON.stringify(obj);
        payload.mediaType = MessageContentMediaType.Video;
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.thumbnail = payload.binaryContent;
        if (payload.content) {
            let obj = JSON.parse(payload.content) as Data
            this.duration = obj.d;
            if (this.duration === undefined) {
                this.duration = obj.duration;
            }
        }
    }
}

class Data {
    d = 0;
    duration = 0;
}
