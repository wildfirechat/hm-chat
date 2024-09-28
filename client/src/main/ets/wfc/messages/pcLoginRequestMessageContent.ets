/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import wfc from '../client/wfc';
import { JSONObject } from '../type/types';

import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import MessagePayload from './messagePayload';

export default class PCLoginRequestMessageContent extends MessageContent {
    // 3 windows, 4 osx, 5 web
    platform = 0
    sessionId = ''

    constructor() {
        super(MessageContentType.PC_Login_Request);
    }

    digest() {
        return '';
    }

    encode() {
        let payload = super.encode();
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as JSONObject;
        this.platform = obj['p'] as number
        this.sessionId = obj['t'] as string
    }
}
