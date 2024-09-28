/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import Message from '../message';

import MessageContent from "../messageContent";

export default class NotificationMessageContent extends MessageContent {
    // message#protoMessageToMessage时设置
    fromSelf = false;

    constructor(type: number) {
        super(type);
    }

    digest(message?: Message) {
        let desc = '';
        try {
            desc = this.formatNotification(message);
        } catch (error) {
            console.log('disgest', error);
        }
        return desc;
    }

    formatNotification(message?: Message) {
        return '..nofication..';
    }
}
