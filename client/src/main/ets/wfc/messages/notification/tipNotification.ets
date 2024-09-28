/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import NotificationMessageContent from './notificationMessageContent'
import MessageContentType from '../messageContentType';
import MessagePayload from '../messagePayload';

export default class TipNotificationMessageContent extends NotificationMessageContent {
    tip = '';

    constructor(tip: string = '') {
        super(MessageContentType.Tip_Notification);
        this.tip = tip;
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
