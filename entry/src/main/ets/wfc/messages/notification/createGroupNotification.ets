/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import wfc from '../../client/wfc'
import MessageContentType from '../messageContentType';
import MessagePayload from '../messagePayload';

import GroupNotificationContent from './groupNotification';

export default class CreateGroupNotification extends GroupNotificationContent {
    creator = '';
    groupName = '';

    constructor(creator: string = '', groupName: string = '') {
        super(MessageContentType.CreateGroup_Notification);
        this.creator = creator;
        this.groupName = groupName;
    }

    formatNotification() {
        if (this.fromSelf) {
            return '您创建了群组 ' + this.groupName;
        } else {
            return wfc.getUserDisplayName(this.creator) + '创建了群组 ' + this.groupName;
        }
    }

    encode() {
        let payload = super.encode();
        let obj = {
            g: this.groupId,
            n: this.groupName,
            o: this.creator,
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let json = wfc.b64_to_utf8(payload.binaryContent)
        let obj = JSON.parse(json) as Data;
        this.groupId = obj.g;
        this.creator = obj.o;
        this.groupName = obj.n;
    }
}

class Data {
    g = '';
    n = '';
    o = '';
}
