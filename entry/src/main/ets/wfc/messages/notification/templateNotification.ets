/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import MessagePayload from '../messagePayload';

import NotificationMessageContent from './notificationMessageContent'

export default class TemplateNotification extends NotificationMessageContent {
    tip = '';

    constructor(type: number) {
        super(type)
        this.tip = '';
    }

    formatNotification() {
        return this.tip;
    }

    digest() {
        return this.tip;
    }

    encode() {
        let payload = super.encode();
        payload.content = this.tip;
        return payload;
    };

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.tip = payload.content;
    }
}
