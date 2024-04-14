/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import wfc from '../../client/wfc'
import MessageContentType from "../messageContentType";
import MessagePayload from '../messagePayload';

import GroupNotificationContent from "./groupNotification";

export default class KickoffGroupMemberNotification extends GroupNotificationContent {
    operator = '';
    kickedMembers = [] as string[];

    constructor(operator: string = '', kickedMembers: string[] = []) {
        super(MessageContentType.KickOffGroupMember_Notification);
        this.operator = operator;
        this.kickedMembers = kickedMembers;
    }

    formatNotification() {
        let notifyStr: string;
        if (this.fromSelf) {
            notifyStr = '您把 ';
        } else {
            notifyStr = wfc.getGroupMemberDisplayName(this.groupId, this.operator) + '把 ';
        }

        let kickedMembersStr = '';
        let userInfos = wfc.getUserInfos(this.kickedMembers, this.groupId);
        userInfos.forEach(userInfo => {
            if (userInfo.uid === wfc.getUserId()) {
                kickedMembersStr += ' 您';
            } else {
                kickedMembersStr += ' ' + userInfo.displayName;
            }
        });

        return notifyStr + kickedMembersStr + ' 移除了群组';
    }

    encode() {
        let payload = super.encode();
        let obj = {
            g: this.groupId,
            ms: this.kickedMembers,
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
        this.kickedMembers = obj.ms;
    }
}

class Data {
    g = '';
    ms = [] as string[];
    o = '';
}
