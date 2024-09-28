import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import wfc from "../client/wfc";
import MessagePayload from './messagePayload';
import Message from './message';

export default class LinkMessageContent extends MessageContent {
    title = '';
    contentDigest = '';
    url = '';
    thumbnail = '';

    constructor() {
        super(MessageContentType.Link);
    }

    encode() {
        let payload = super.encode();
        let obj = {
            d: this.contentDigest,
            u: this.url,
            t: this.thumbnail
        } as Data

        payload.searchableContent = this.title;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));

        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.title = payload.searchableContent;
        let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as Data;
        this.contentDigest = obj.d;
        this.url = obj.u;
        this.thumbnail = obj.t;
    }

    digest(message: Message) {
        let tmp = this.title ? this.title.trim() : this.contentDigest ? this.contentDigest.trim() : null;
        return tmp ? tmp : this.url;
    }
}

class Data {
    d = ''
    u = ''
    t = ''
}