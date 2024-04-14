/*
 * Copyright (c) 2022 WildFireChat. All rights reserved.
 */

import NotificationMessageContent from "./notificationMessageContent";
import MessageContentType from "../messageContentType";
import Message from '../message';

export default class FriendGreetingNotification extends NotificationMessageContent {
    constructor() {
        super(MessageContentType.Friend_Greeting);
    }

    formatNotification(message: Message) {
        return "以上是打招呼的内容";
    }
}
