/*
 * Copyright (c) 2023 WildFireChat. All rights reserved.
 */

import wfc from '../../client/wfc'
import MessageContentType from '../messageContentType';
import MessagePayload from '../messagePayload';

import GroupNotificationContent from './groupNotification';

export default class ModifyGroupSettingNotification extends GroupNotificationContent {
    operator = '';
    //修改设置类型。7为修改是否查看历史消息；8为修改群最大成员数，9为修改是否为超级群
    settingType = 0;
    //修改后的值
    settingValue = '';

    constructor(settingType: number = 0, settingValue: string = '') {
        super(MessageContentType.ModifyGroupSetting_Notification);
        this.settingType = settingType;
        this.settingValue = settingValue;
    }

    formatNotification() {
        return '';
    }

    encode() {
        let payload = super.encode();
        let obj = {
            g: this.groupId,
            n: this.settingType,
            o: this.operator,
            m: this.settingValue,
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
        this.type = obj.n;
        this.settingValue = obj.m;
    }
}

class Data {
    g = '';
    n = 0;
    o = '';
    m = '';
}
