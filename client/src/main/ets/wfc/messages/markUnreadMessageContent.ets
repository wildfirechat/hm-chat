import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import { _patchToJavaLong, _reverseToJsLongString, longValue, stringValue, numberValue } from "../util/longUtil";
import wfc from "../client/wfc";
import Long from '../util/long';
import MessagePayload from './messagePayload';

export default class MarkUnreadMessageContent extends MessageContent {
    messageUid? = Long.ZERO;
    timestamp = 0

    constructor(messageUid: Long = Long.ZERO) {
        super(MessageContentType.Mark_Unread_Sync);
        this.messageUid = messageUid;
    }

    encode() {
        let payload = super.encode();
        let obj = {
            u: stringValue(this.messageUid!),
            t: stringValue(this.timestamp!),
        } as Data
        let str = JSON.stringify(obj)
        str = _patchToJavaLong(str, 'u');
        str = _patchToJavaLong(str, 't');
        payload.binaryContent = wfc.utf8_to_b64(str);

        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);

        let str = wfc.b64_to_utf8(payload.binaryContent);
        str = _reverseToJsLongString(str, 'u');
        str = _reverseToJsLongString(str, 't');
        let obj = JSON.parse(str) as Data;
        this.messageUid = obj.u ? longValue(obj.u) : undefined;
        this.timestamp = obj.t ? numberValue(obj.t) : 0;
    }
}

class Data {
    u = ''
    t = ''
}
