/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import GroupNotificationContent from "./groupNotification";
import MessageContentType from "../messageContentType";
import wfc from "../../client/wfc";
import Message from '../message';
import MessagePayload from '../messagePayload';

export default class GroupPrivateChatNotificationContent extends GroupNotificationContent {
    operator = '';
    //是否运行群中普通成员私聊。0 允许，1不允许
    privateChatType = 0;

    constructor(operator: string = '', privateChatType: number = 0) {
        super(MessageContentType.ChangePrivateChat_Notification);
        this.operator = operator;
        this.privateChatType = privateChatType;
    }

    formatNotification(message: Message) {
        // return sb.toString();
        let notifyStr = this.fromSelf ? '您' : wfc.getGroupMemberDisplayName(this.groupId, this.operator);
        notifyStr += this.privateChatType === 0 ? ' 开启了成员私聊' : ' 关闭了成员私聊';

        return notifyStr;
    }

    encode() {
        let payload = super.encode();
        let obj = {
            g: this.groupId,
            o: this.operator,
            n: this.privateChatType + ''
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as Data;
        this.groupId = obj.g;
        this.operator = obj.o;
        this.privateChatType = parseInt(obj.n);
    }
}

class Data {
    g = '';
    o = '';
    n = '0';
}
