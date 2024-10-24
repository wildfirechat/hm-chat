/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import Message from "../message";
import MessagePayload from "../messagePayload";
import NotificationMessageContent from "./notificationMessageContent";

export default class ChatRoomWelcomeNotificationContent extends NotificationMessageContent {
    welcome = '';

    formatNotification(message?: Message): string {
        return this.welcome;
    }

    encode(): MessagePayload {
        return super.encode();
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
    }
}
