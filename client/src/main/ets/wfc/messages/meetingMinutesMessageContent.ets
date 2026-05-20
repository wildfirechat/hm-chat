/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from './messageContent'
import MessageContentType from './messageContentType';
import MessagePayload from './messagePayload';
import wfc from '../client/wfc';

class MeetingIdData {
    meetingId = '';
}

export default class MeetingMinutesMessageContent extends MessageContent {
    text = '';
    title = '';
    meetingId = '';

    constructor(title: string = '', text: string = '', meetingId: string = '') {
        super(MessageContentType.Meeting_Minutes);
        this.title = title;
        this.text = text;
        this.meetingId = meetingId;
    }

    digest() {
        return this.title || this.text;
    }

    encode() {
        let payload = super.encode();
        payload.content = this.text;
        payload.searchableContent = this.title;
        if (this.meetingId && this.meetingId.length > 0) {
            let obj: MeetingIdData = { meetingId: this.meetingId };
            payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        }
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.text = payload.content || '';
        this.title = payload.searchableContent || '';
        if (payload.binaryContent && payload.binaryContent.length > 0) {
            try {
                let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as MeetingIdData;
                if (obj) {
                    this.meetingId = obj.meetingId || '';
                }
            } catch (e) {
                console.error('parse meetingMinutesMessageContent error', e);
            }
        }
    }
}
