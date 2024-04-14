/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from '../../messages/messageContent';
import MessageContentType from '../../messages/messageContentType';
import wfc from "../../client/wfc"
import MessagePayload from '../../messages/messagePayload';

export default class CallSignalMessageContent extends MessageContent {
    callId = '';
    payload = '';

    constructor(mentionedType = 0, mentionedTargets = []) {
        super(MessageContentType.VOIP_CONTENT_TYPE_SIGNAL, mentionedType, mentionedTargets);
    }

    digest() {
        return '';
    }

    encode() {
        let payload = super.encode();
        payload.content = this.callId;
        payload.binaryContent = wfc.utf8_to_b64(this.payload);
        return payload;
    };

    decode(payload:MessagePayload) {
        super.decode(payload);
        this.callId = payload.content;
        this.payload = wfc.b64_to_utf8(payload.binaryContent);
    }
}
