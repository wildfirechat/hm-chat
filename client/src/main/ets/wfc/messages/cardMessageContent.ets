/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */


/*
 * Copyright © 2020 WildFireChat. All rights reserved.
 */

import MessageContent from './messageContent'
import MessageContentType from './messageContentType'
import wfc from '../client/wfc'
import Config from '../../config'
import MessagePayload from './messagePayload'

export default class CardMessageContent extends MessageContent {
    /**
     * 0，用户；1，群组；2，聊天室；3，频道
     */
    cardType = 0;
    target = '';
    name = '';
    displayName = '';
    portrait = '';
    from = '';

    constructor(cardType: number = 0, target: string = '', displayName: string = '', portrait: string = '', from: string = '') {
        super(MessageContentType.UserCard);
        this.cardType = cardType;
        this.target = target;
        this.displayName = displayName;
        this.portrait = portrait;
        this.from = from;
    }

    encode() {
        let payload = super.encode()
        payload.content = this.target;
        let obj = {
            t: this.cardType,
            n: this.name,
            d: this.displayName,
            p: this.portrait,
            f: this.from,
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload)
        this.target = payload.content;
        let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as Data;
        this.cardType = obj.t;
        this.name = obj.n;
        this.displayName = obj.d;
        this.portrait = obj.p;
        if (Config.urlRedirect) {
            this.portrait = Config.urlRedirect(obj.p);
        }
        this.from = obj.f;
    }

    digest() {
        let msg = '[名片]';
        switch (this.cardType) {
            case 0:
                msg = '[个人名片]'
                break;
            case 1:
                msg = '[群组名片]'
                break;
            case 2:
                msg = '[聊天室名]'
                break;
            case 3:
                msg = '[频道名片]'
                break;
            default:
                break;
        }
        return msg + this.displayName;
    }
}

class Data {
    t = 0
    n = ''
    d = ''
    p = ''
    f = ''
}