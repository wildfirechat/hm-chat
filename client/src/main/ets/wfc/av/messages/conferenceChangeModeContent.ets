import MessageContent from "../../messages/messageContent";
import MessageContentType from "../../messages/messageContentType";
import wfc from "../../client/wfc";
import MessagePayload from '../../messages/messagePayload';

export default class ConferenceChangeModeContent extends MessageContent {
    callId = '';
    audience = false;

    constructor(callId: string = '', audience: boolean = false) {
        super(MessageContentType.CONFERENCE_CONTENT_TYPE_CHANGE_MODE);
        this.callId = callId;
        this.audience = audience;
    }

    encode() {
        let payload = super.encode();
        payload.content = this.callId;
        let obj: Record<string, boolean> = {
            'a': this.audience
        };
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj))
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.callId = payload.content;
        if (payload.binaryContent) {
            let json = wfc.b64_to_utf8(payload.binaryContent);
            let obj = JSON.parse(json) as Record<string, boolean>;
            this.audience = !!obj.a;
        }
    }
}
