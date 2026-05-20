/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from './messageContent'
import MessageContentType from './messageContentType';
import MessagePayload from './messagePayload';

class TranscriptionData {
    id = 0;
    meetingId = '';
    userId = '';
    timestamp = 0;
    duration = 0;
    content = '';
}

export default class TranscriptionMessageContent extends MessageContent {
    transcriptionId = 0;
    meetingId = '';
    userId = '';
    timestamp = 0;
    duration = 0;
    content = '';

    constructor(transcriptionId: number = 0, meetingId: string = '', userId: string = '', timestamp: number = 0, duration: number = 0, content: string = '') {
        super(MessageContentType.Transcription);
        this.transcriptionId = transcriptionId;
        this.meetingId = meetingId;
        this.userId = userId;
        this.timestamp = timestamp;
        this.duration = duration;
        this.content = content;
    }

    digest() {
        return this.content;
    }

    encode() {
        let payload = super.encode();
        let obj: Record<string, Object> = {};
        if (this.transcriptionId > 0) {
            obj['id'] = this.transcriptionId;
        }
        if (this.meetingId && this.meetingId.length > 0) {
            obj['meetingId'] = this.meetingId;
        }
        if (this.userId && this.userId.length > 0) {
            obj['userId'] = this.userId;
        }
        if (this.timestamp) {
            obj['timestamp'] = this.timestamp;
        }
        if (this.duration) {
            obj['duration'] = this.duration;
        }
        if (this.content && this.content.length > 0) {
            obj['content'] = this.content;
        }
        payload.content = JSON.stringify(obj);
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        if (payload.content && payload.content.length > 0) {
            try {
                let obj = JSON.parse(payload.content) as TranscriptionData;
                if (obj) {
                    this.transcriptionId = obj.id || 0;
                    this.meetingId = obj.meetingId || '';
                    this.userId = obj.userId || '';
                    this.timestamp = obj.timestamp || 0;
                    this.duration = obj.duration || 0;
                    this.content = obj.content || '';
                }
            } catch (e) {
                console.error('parse transcriptionMessageContent error', e);
            }
        }
    }
}
