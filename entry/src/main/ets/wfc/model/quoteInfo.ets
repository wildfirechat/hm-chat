import wfc from "../client/wfc";
import { stringValue } from "../util/longUtil";
import Long from "../util/long";
import Message from '../messages/message';
import QuoteInfoPayload from './quoteInfoPayload';

export default class QuoteInfo {
    messageUid = Long.ZERO;
    userId = '';
    userDisplayName = '';
    messageDigest = '';

    static initWithMessage(message: Message) {
        let info = new QuoteInfo();
        if (message) {
            info.messageUid = message.messageUid;
            info.userId = message.from;
            let userInfo = wfc.getUserInfo(message.from, false);
            info.userDisplayName = userInfo.displayName;
            info.messageDigest = message.messageContent.digest();
            if (info.messageDigest.length > 48) {
                info.messageDigest = info.messageDigest.substr(0, 48);
            }
        }
        return info;
    }

    encode() {
        let obj = {
            u: stringValue(this.messageUid),
            i: this.userId,
            n: this.userDisplayName,
            d: this.messageDigest,
        } as QuoteInfoPayload;
        return obj;
    }

    decode(obj?: QuoteInfoPayload) {
        if (!obj) {
            return;
        }
        this.messageUid = Long.fromValue(obj.u);
        this.userId = obj.i;
        this.userDisplayName = obj.n;
        this.messageDigest = obj.d;
    }
}
