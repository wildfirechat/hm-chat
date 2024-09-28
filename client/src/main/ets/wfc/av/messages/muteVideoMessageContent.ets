/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import NotificationMessageContent from "../../messages/notification/notificationMessageContent";
import MessageContentType from "../../messages/messageContentType";
import wfc from "../../client/wfc"
import Message from '../../messages/message';
import MessagePayload from '../../messages/messagePayload';

class ParticipantStatus {
    userId = '';
    acceptTime = 0;
    joinTime = 0;
    videoMuted = false;
}

export default class MuteVideoMessageContent extends NotificationMessageContent {
    callId = '';
    videoMuted = false;
    existParticipants = [] as ParticipantStatus[];

    constructor(mentionedType = 0, mentionedTargets = []) {
        super(MessageContentType.VOIP_CONTENT_TYPE_MUTE_VIDEO);
    }

    formatNotification(message: Message) {
        // TODO
        return "mute video";
    }

    encode() {
        let payload = super.encode();
        payload.content = this.callId;

        let obj = {
            existParticipants: this.existParticipants,
            videoMuted: this.videoMuted,
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));

        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.callId = payload.content;
        let json = wfc.b64_to_utf8(payload.binaryContent);
        let obj = JSON.parse(json) as Data;
        this.existParticipants = obj.existParticipants;
        this.videoMuted = obj.videoMuted;
    }
}

class Data {
    existParticipants = [] as ParticipantStatus[];
    videoMuted = false;
}
