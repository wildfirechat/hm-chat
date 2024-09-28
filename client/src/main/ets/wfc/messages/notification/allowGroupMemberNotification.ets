/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import GroupNotificationContent from './groupNotification'
import MessageContentType from '../messageContentType'
import wfc from '../../client/wfc'
import Message from '../message'
import MessagePayload from '../messagePayload'

export default class AllowGroupMemberNotification extends GroupNotificationContent {
    groupId = ''
    operator = ''
    // 操作类型，1允许发言，0禁止发言
    type = 0
    memberIds = [] as string[]

    constructor(operator: string = '', type: number = 0, memberIds: string[] = []) {
        super(MessageContentType.MuteGroupMember_Notification)
        this.operator = operator
        this.type = type
        this.memberIds = memberIds
    }

    formatNotification(message: Message) {
        let notifyStr = ''
        if (this.fromSelf) {
            notifyStr += '您'
        } else {
            notifyStr += wfc.getGroupMemberDisplayName(this.groupId,
                this.operator)
        }
        notifyStr += '把'
        if (this.memberIds) {
            this.memberIds.forEach((memberId) => {
                notifyStr += ' '
                notifyStr += wfc.getGroupMemberDisplayName(this.groupId,
                    memberId)
            })
        }
        if (this.type === 0) {
            notifyStr += '取消群禁言时发言权限'
        } else {
            notifyStr += '允许群禁言时发言'
        }
        return notifyStr
    }

    encode() {
        let payload = super.encode()
        let obj = {
            g: this.groupId,
            o: this.operator,
            n: this.type + '',
            ms: this.memberIds,
        } as Data
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj))
        return payload
    }

    decode(payload: MessagePayload) {
        super.decode(payload)

        let json = wfc.b64_to_utf8(payload.binaryContent)
        let obj = JSON.parse(json) as Data
        this.groupId = obj.g
        this.operator = obj.o
        this.type = parseInt(obj.n)
        this.memberIds = obj.ms
    }
}

class Data {
    g = '';
    o = ''
    n = '0'
    ms = [] as string[]
}
