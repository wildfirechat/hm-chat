/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from '../../messages/messageContent';
import MessageContentType from '../../messages/messageContentType';
import wfc from "../../client/wfc"
import MessagePayload from '../../messages/messagePayload';
import { FaultLogger } from '@kit.PerformanceAnalysisKit';

export default class CallStartMessageContent extends MessageContent {
    callId = '';
    targetIds = [] as string[];
    connectTime = 0;
    endTime = 0;
    /**
     * 0, UnKnown,
     * 1, Busy,
     * 2, SignalError,
     * 3, Hangup,
     * 4, MediaError,
     * 5, RemoteHangup,
     * 6, OpenCameraFailure,
     * 7, Timeout,
     * 8, AcceptByOtherClient
     */
    status = 0;
    audioOnly = false;
    pin = '';
    sdkType = 0;

    constructor(mentionedType = 0, mentionedTargets = []) {
        super(MessageContentType.VOIP_CONTENT_TYPE_START, mentionedType, mentionedTargets);
    }

    digest() {
        if (this.audioOnly) {
            return '[语音通话]';
        } else {
            return '[视频通话]';
        }
    }

    encode() {
        let payload = super.encode();
        payload.content = this.callId;
        payload.pushContent = '音视频通话邀请';

        let obj = {
            c: this.connectTime,
            e: this.endTime,
            s: this.status,
            a: this.audioOnly ? 1 : 0,
            ts: this.targetIds,
            t: this.targetIds[0],
            p: this.pin
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));

        let pushData: Record<string, string | string[] | boolean> = {
            'callId': this.callId,
            'audioOnly': this.audioOnly,
            'participants': this.targetIds,
        }
        payload.pushData = JSON.stringify(pushData);

        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.callId = payload.content;
        let json = wfc.b64_to_utf8(payload.binaryContent);
        let obj = JSON.parse(json) as Data;

        this.connectTime = obj.c;
        this.endTime = obj.e;
        this.status = obj.s;
        this.audioOnly = (obj.a === 1);
        this.targetIds = obj.ts;
        if (!this.targetIds) {
            this.targetIds = [obj.t];
        }
        this.pin = obj.p;
    }
}

class Data {
    c = 0;
    e = 0;
    s = 0;
    a = 0;
    ts = [] as string[]
    t = ''
    p = '';
}

