/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from '../../messages/messageContent';
import wfc from "../../client/wfc"
import MessageContentType from '../../messages/messageContentType';
import MessagePayload from '../../messages/messagePayload';

export default class CallModifyMessageContent extends MessageContent {
    callId = '';
    audioOnly = false;

    constructor(mentionedType = 0, mentionedTargets = []) {
        super(MessageContentType.VOIP_CONTENT_TYPE_MODIFY, mentionedType, mentionedTargets);
    }

    digest() {
        return '';
    }

    encode() {
        let payload = super.encode();
        payload.content = this.callId;

        let obj:string;
        if (this.audioOnly) {
            obj = '1';
        } else {
            obj = '0';
        }
        payload.binaryContent = wfc.utf8_to_b64(obj);
        return payload;
    };

    decode(payload:MessagePayload) {
        super.decode(payload);
        this.callId = payload.content;
        let str = wfc.b64_to_utf8(payload.binaryContent);

        this.audioOnly = (str === '1');
    }
}
