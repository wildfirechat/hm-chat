import Message from "./message";
import MessageContent from "./messageContent";
import MessagePayload from "./messagePayload";

export default class StreamingTextGeneratedMessageContent extends MessageContent {
    text: string = '';
    streamId: string = '';

    encode(): MessagePayload {
        let payload = super.encode();
        payload.searchableContent = this.text;
        payload.content = this.streamId;
        return payload;
    }

    decode(payload: MessagePayload): void {
        super.decode(payload);
        this.text = payload.searchableContent;
        this.streamId = payload.content;
    }

    digest(message?: Message | undefined): string {
        return this.text;
    }
}