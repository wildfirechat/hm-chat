/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from './messageContent'
import MessageContentType from './messageContentType';
import wfc from '../client/wfc'
import Long from '../util/long'
import Message from './message';
import MessagePayload from './messagePayload';

// 本消息由调用server api删除消息触发，请勿直接发送本消息
export default class DeleteMessageContent extends MessageContent {
    operatorId = '';
    messageUid = Long.ZERO;

    constructor(operatorId: string = '', messageUid: Long = Long.ZERO) {
        super(MessageContentType.DeleteMessage_Notification);
        this.operatorId = operatorId;
        this.messageUid = messageUid;
    }

    formatNotification(message: Message) {
        return "消息已删除";
    }

    encode() {
        let payload = super.encode();
        payload.content = this.operatorId;
        payload.binaryContent = wfc.utf8_to_b64(this.messageUid.toString());
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.operatorId = payload.content;
        this.messageUid = Long.fromString(wfc.b64_to_utf8(payload.binaryContent));
    }
}
