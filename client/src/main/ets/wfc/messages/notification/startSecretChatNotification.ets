/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import NotificationMessageContent from './notificationMessageContent'
import MessageContentType from "../messageContentType";
import wfc from "../../client/wfc";
import SecretChatState from "../../model/secretChatState";
import Message from '../message';
import MessagePayload from '../messagePayload';

export default class StartSecretChatNotification extends NotificationMessageContent {
    constructor() {
        super(MessageContentType.StartSecretChat_Notification);
    }

    formatNotification(message: Message) {
        let state: number = wfc.getSecretChatInfo(message.conversation.target)!.state;
        if (state === SecretChatState.Starting) {
            return "等待对方响应";
        } else if (state === SecretChatState.Accepting) {
            return "密聊会话建立中";
        } else if (state === SecretChatState.Established) {
            return "密聊会话已建立";
        } else if (state === SecretChatState.Canceled) {
            return "密聊会话已取消";
        } else {
            return "密聊会话不可用";
        }
    }

    encode(): MessagePayload {
        return super.encode();
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
    }
}
