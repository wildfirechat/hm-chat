/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import wfc from '../../client/wfc'
import MessageContentType from '../messageContentType';
import MessagePayload from '../messagePayload';

import GroupNotificationContent from './groupNotification';

export default class QuitVisiableGroupNotification extends GroupNotificationContent {
    operator = '';

    constructor(operator: string = '') {
        super(MessageContentType.QuitGroup_Visible_Notification);
        this.operator = operator;
    }

    formatNotification() {
        if (this.fromSelf) {
            return '您退出了群组';
        } else {
            return wfc.getGroupMemberDisplayName(this.groupId, this.operator) + '退出了群组';
        }
    }

    encode() {
        let payload = super.encode();
        let obj = {
            g: this.groupId,
            o: this.operator,
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let json = wfc.b64_to_utf8(payload.binaryContent)
        let obj = JSON.parse(json) as Data;
        this.groupId = obj.g;
        this.operator = obj.o;
    }
}

class Data {
    g = '';
    o = '';
}
