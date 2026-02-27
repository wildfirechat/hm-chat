import { MessageContentConfig } from "../client/messageConfig";
import wfc from "../client/wfc";
import CollectionEntry from "../model/collectionEntry";
import { JSONObject } from "../type/types";
import Message from "./message";
import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import MessagePayload from "./messagePayload";

export default class CollectionMessageContent extends MessageContent {
    collectionId: string = '';
    groupId: string = '';
    creatorId: string = '';
    title: string = '';
    desc: string = '';
    template: string = '';
    expireType: number = 0;
    expireAt: number = 0;
    maxParticipants: number = 0;
    status: number = 0;
    createdAt: number = 0;
    updatedAt: number = 0;
    entries: CollectionEntry[] = [];

    constructor() {
        super(MessageContentType.Collection);
    }

    encode(): MessagePayload {
        let payload = super.encode();
        payload.searchableContent = this.title;

        let obj: Record<string, Object> = {
            'collectionId': this.collectionId,
            'groupId': this.groupId,
            'creatorId': this.creatorId,
            'desc': this.desc,
            'template': this.template,
            'expireType': this.expireType,
            'expireAt': this.expireAt,
            'maxParticipants': this.maxParticipants,
            'status': this.status,
            'createdAt': this.createdAt,
            'updatedAt': this.updatedAt
        };

        if (this.entries && this.entries.length > 0) {
            obj['entries'] = this.entries.map(entry => ({
                'id': entry.entryId,
                'collectionId': entry.collectionId,
                'userId': entry.userId,
                'content': entry.content,
                'createdAt': entry.createdAt,
                'updatedAt': entry.updatedAt,
                'deleted': entry.deleted
            } as JSONObject));
        }

        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload): void {
        super.decode(payload);
        this.title = payload.searchableContent;
        if (payload.binaryContent) {
            try {
                let jsonStr = wfc.b64_to_utf8(payload.binaryContent);
                let obj = JSON.parse(jsonStr) as JSONObject;
                this.collectionId = obj['collectionId'] as string || '';
                this.groupId = obj['groupId'] as string || '';
                this.creatorId = obj['creatorId'] as string || '';
                this.desc = obj['desc'] as string || '';
                this.template = obj['template'] as string || '';
                this.expireType = obj['expireType'] as number || 0;
                this.expireAt = obj['expireAt'] as number || 0;
                this.maxParticipants = obj['maxParticipants'] as number || 0;
                this.status = obj['status'] as number || 0;
                this.createdAt = obj['createdAt'] as number || 0;
                this.updatedAt = obj['updatedAt'] as number || 0;

                if (obj['entries']) {
                    this.entries = [];
                    let entriesArray = obj['entries'] as JSONObject[];
                    for (let entryJson of entriesArray) {
                        this.entries.push(CollectionEntry.fromJson(entryJson));
                    }
                }
            } catch (e) {
                console.error("Decode CollectionMessageContent error", e);
            }
        }
    }

    digest(message: Message): string {
        return this.title ? `[接龙] ${this.title}` : '[接龙]';
    }
}


