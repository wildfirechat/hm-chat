/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import GroupNotificationContent from "./groupNotification";
import MessageContentType from "../messageContentType";
import wfc from "../../client/wfc";
import Message from '../message';
import MessagePayload from '../messagePayload';

export default class GroupMuteNotificationContent extends GroupNotificationContent {
    operator = '';
    //0 正常；1 全局禁言
    muteType = 0;

    constructor(operator: string = '', muteType: number = 0) {
        super(MessageContentType.MuteGroup_Notification);
        this.operator = operator;
        this.muteType = muteType;
    }

    formatNotification(message: Message) {
        // return sb.toString();
        let notifyStr = this.fromSelf ? '您' : wfc.getGroupMemberDisplayName(this.groupId, this.operator);
        notifyStr += this.muteType === 0 ? ' 关闭了全员禁言' : ' 开启了全员禁言';

        return notifyStr;
    }

    encode() {
        let payload = super.encode();
        let obj = {
            g: this.groupId,
            o: this.operator,
            n: this.muteType + ''
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as Data;
        this.groupId = obj.g;
        this.operator = obj.o;
        this.muteType = parseInt(obj.n);
    }
}

class Data {
    g = '';
    o = '';
    n = '0';
}
