/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from './messageContent'
import MessageContentType from "./messageContentType";
import MessagePayload from './messagePayload';

export default class LocationMessageContent extends MessageContent {
    title = '';
    // base64 encoded, 不包含头部:data:image/png;base64,
    thumbnail = '';
    lat = 0;
    long = 0;

    constructor() {
        super(MessageContentType.Location);
    }

    digest() {
        return '位置'
    }

    encode() {
        let payload = super.encode();
        payload.searchableContent = this.title;
        payload.binaryContent = this.thumbnail;
        let location = {
            lat: this.lat,
            long: this.long
        } as Data;
        payload.content = JSON.stringify(location);
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.title = payload.searchableContent;
        this.thumbnail = payload.binaryContent;
        let location = JSON.parse(payload.content) as Data;
        this.lat = location.lat;
        this.long = location.long;
    }
}

class Data {
    lat = 0;
    long = 0;
}
