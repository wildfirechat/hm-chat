/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import NotificationMessageContent from './notificationMessageContent'
import wfc from '../../client/wfc'
import MessageContentType from '../messageContentType';
import Long from '../../util/long';
import ConversationType from "../../model/conversationType";
import Message from '../message';
import MessagePayload from '../messagePayload';

export default class RecallMessageNotification extends NotificationMessageContent {
    operatorId = '';
    messageUid = Long.ZERO;
    originalSender = '';
    originalContentType = 0;
    originalSearchableContent = '';
    originalContent = '';
    originalExtra = '';
    originalMessageTimestamp = Long.ZERO;

    constructor(operatorId: string = '', messageUid: Long = Long.ZERO) {
        super(MessageContentType.RecallMessage_Notification);
        this.operatorId = operatorId;
        this.messageUid = messageUid;
    }

    formatNotification(message: Message) {
        if (this.operatorId === wfc.getUserId()) {
            return "你撤回了一条消息";
        }
        if (message.conversation!.type === ConversationType.Group) {
            return wfc.getGroupMemberDisplayName(message.conversation!.target, this.operatorId) + "撤回了一条消息";
        } else {
            return wfc.getUserDisplayName(this.operatorId) + "撤回了一条消息";
        }
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

        try {
            this.setExtra(payload.extra);
        } catch (e) {
            console.error('decode recallMessage extra error', e)
        }
    }

    setExtra(extra: string) {
        if (extra) {
            extra = extra.replace(/\n/g, "\\n").replace(/\r/g, "\\r").replace(/\t/g, "\\t");
            let obj = JSON.parse(extra) as Record<string, Object>;
            this.originalSender = obj["s"] as string;
            this.originalContentType = obj["t"] as number;
            this.originalSearchableContent = obj["sc"] as string;
            this.originalContent = obj["c"] as string;
            this.originalExtra = obj["e"] as string;
            this.originalMessageTimestamp = Long.fromValue(obj["ts"] as string);
        }
    }
}
