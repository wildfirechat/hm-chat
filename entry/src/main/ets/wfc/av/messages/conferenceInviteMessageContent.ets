import MessageContent from "../../messages/messageContent";
import MessageContentType from "../../messages/messageContentType";
import wfc from "../../client/wfc";
import Message from '../../messages/message';
import MessagePayload from '../../messages/messagePayload';

export default class ConferenceInviteMessageContent extends MessageContent {
    callId = '';
    host = '';
    title = '';
    desc = '';
    startTime = 0;
    audioOnly = false;
    audience = false;
    pin = '';
    advanced = false;

    constructor(callId: string = '', host: string = '', title: string = '', desc: string = '', startTime: number = 0, audioOnly: boolean = false, audience: boolean = false, advance: boolean = false, pin: string = '') {
        super(MessageContentType.CONFERENCE_CONTENT_TYPE_INVITE);
        this.callId = callId;
        this.host = host;
        this.title = title;
        this.desc = desc;
        this.startTime = startTime;
        this.audioOnly = audioOnly;
        this.audience = audience;
        this.advanced = advance;
        this.pin = pin;
    }

    digest(message: Message) {
        let str = '[会议邀请]'
        return str;
    }

    encode() {
        let payload = super.encode();
        payload.content = this.callId;
        payload.pushContent = '会议邀请'
        let obj = {
            h: this.host,
            s: this.startTime,
            t: this.title,
            d: this.desc,
            audience: this.audience ? 1 : 0,
            advanced: this.advanced ? 1 : 0,
            a: this.audioOnly ? 1 : 0,
            p: this.pin,
        } as Data;
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        if (payload.binaryContent) {
            let json = wfc.b64_to_utf8(payload.binaryContent);
            let obj = JSON.parse(json) as Data;
            this.host = obj.h;
            this.startTime = obj.s;
            this.title = obj.t;
            this.desc = obj.d;
            this.audience = obj.audience > 0;
            this.advanced = obj.advanced > 0;
            this.audioOnly = obj.a > 0;
            this.pin = obj.p;
        }
        this.callId = payload.content;
    }
}

class Data {
    h = ''
    s = 0
    t = ''
    d = ''
    audience = 0
    advanced = 0
    a = 0
    p = ''
}
