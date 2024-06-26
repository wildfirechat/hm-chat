/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import GroupNotificationContent from "./groupNotification";
import wfc from "../../client/wfc";
import MessageContentType from "../messageContentType";
import Message from '../message';
import MessagePayload from '../messagePayload';

export default class GroupJoinTypeNotificationContent extends GroupNotificationContent {
    operator = '';
    //在group type为Restricted时，0 开放加入权限（群成员可以拉人，用户也可以主动加入）；1 只能群成员拉人入群；2 只能群管理拉人入群
    joinType = 0;

    constructor(operator: string = '', joinType: number = 0) {
        super(MessageContentType.ChangeJoinType_Notification);
        this.operator = operator;
        this.type = joinType;
    }

    formatNotification(message: Message) {
        let notifyStr: string;
        if (this.fromSelf) {
            notifyStr = '您';
        } else {
            notifyStr = wfc.getGroupMemberDisplayName(this.groupId, this.operator);
        }
        switch (this.joinType) {
            case 0:
                notifyStr += ' 开放了加入群组功能';
                break;
            case 1:
                notifyStr += ' 仅允许群成员邀请加入群组';
                break;
            case 2:
                notifyStr += " 关闭了加入群组功能";
                break;
            default:
                break;
        }
        return notifyStr;
    }

    encode() {
        let payload = super.encode();
        let obj = {
            g: this.groupId,
            o: this.operator,
            n: (this.joinType + '')
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as Data;
        this.groupId = obj.g;
        this.operator = obj.o;
        this.joinType = parseInt(obj.n);
    }
}

class Data {
    g = '';
    o = '';
    n = '0';
}
