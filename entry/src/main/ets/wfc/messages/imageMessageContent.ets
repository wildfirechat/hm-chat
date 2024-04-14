/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MediaMessageContent from './mediaMessageContent';
import MessageContentMediaType from './messageContentMediaType';
import MessageContentType from './messageContentType';
import MessagePayload from './messagePayload';

export default class ImageMessageContent extends MediaMessageContent {
    // base64 encoded, 不包含头部:data:image/png;base64,
    thumbnail: string;
    imageWidth: number = 0;
    imageHeight: number = 0;

    constructor(fileOrLocalPath: string = '', remotePath: string = '', thumbnail: string = '') {
        super(MessageContentType.Image, MessageContentMediaType.Image, fileOrLocalPath, remotePath);
        this.thumbnail = thumbnail;
    }

    digest() {
        return '[图片]';
    }

    encode() {
        let payload = super.encode();
        payload.mediaType = MessageContentMediaType.Image;
        payload.binaryContent = this.thumbnail;
        if (this.imageWidth) {
            let obj = {
                w: this.imageWidth,
                h: this.imageHeight
            } as ImageSize
            payload.content = JSON.stringify(obj)
        }
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.thumbnail = payload.binaryContent;
        if (payload.content) {
            let obj = JSON.parse(payload.content) as ImageSize
            this.imageWidth = obj.w;
            this.imageHeight = obj.h;
        }
    }
}

class ImageSize {
    w = 0;
    h = 0;
}
