/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import MessageContent from '../../messages/messageContent';
import wfc from "../../client/wfc"
import MessageContentType from '../../messages/messageContentType';
import MessagePayload from '../../messages/messagePayload';

export default class JoinCallRequestMessageContent extends MessageContent {
    callId = '';
    clientId = '';

    constructor(callId: string = '', clientId: string = '') {
        super(MessageContentType.VOIP_Join_Call_Request);
        this.callId = callId;
        this.clientId = clientId;
    }

    digest() {
        return '';
    }

    encode() {
        let payload = super.encode();
        payload.content = this.callId;

        let obj = {
            clientId: this.clientId
        } as Data
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.callId = payload.content;
        let json = wfc.b64_to_utf8(payload.binaryContent);
        let obj = JSON.parse(json) as Data;
        this.clientId = obj.clientId;
    }
}

class Data {
    clientId = ''
}
