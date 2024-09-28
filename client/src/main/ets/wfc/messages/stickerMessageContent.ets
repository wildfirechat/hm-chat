/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContentMediaType from "./messageContentMediaType";
import MediaMessageContent from "./mediaMessageContent";
import MessageContentType from "./messageContentType";

import wfc from "../client/wfc"
import MessagePayload from './messagePayload';


export default class StickerMessageContent extends MediaMessageContent {
    width = 200;
    height = 200;

    constructor(filerOrLocalPath: string = '', remotePath: string = '', width: number = 0, height: number = 0) {
        super(MessageContentType.Sticker, MessageContentMediaType.Sticker, filerOrLocalPath, remotePath);
        this.width = width;
        this.height = height;
    }

    digest() {
        return '[表情]';
    }

    encode() {
        let payload = super.encode();
        payload.mediaType = MessageContentMediaType.File;
        let obj = {
            x: this.width,
            y: this.height,
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as Data;
        this.width = obj.x;
        this.height = obj.y;
    }
}

class Data {
    x = 0;
    y = 0;
}
