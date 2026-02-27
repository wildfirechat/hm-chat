import { JSONArray, JSONObject } from "../type/types";
import CollectionEntry from "./collectionEntry";

export default class Collection {
    collectionId: number = 0;
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
    participantCount: number = 0;
    entries: CollectionEntry[] = [];

    static fromJson(json: JSONObject): Collection {
        let collection = new Collection();
        collection.collectionId = json.id as number || 0;
        collection.groupId = json.groupId as string || '';
        collection.creatorId = json.creatorId as string || '';
        collection.title = json.title as string || '';
        collection.desc = json.description as string || '';
        collection.template = json.template as string || '';
        collection.expireType = json.expireType as number || 0;
        collection.expireAt = json.expireAt as number || 0;
        collection.maxParticipants = json.maxParticipants as number || 0;
        collection.status = json.status as number || 0;
        collection.createdAt = json.createdAt as number || 0;
        collection.updatedAt = json.updatedAt as number || 0;
        collection.participantCount = json.participantCount as number || 0;

        if (json.entries) {
            collection.entries = (json.entries as JSONArray).map((entryJson: JSONObject) => CollectionEntry.fromJson(entryJson));
        }

        return collection;
    }

    calculateParticipantCount(): number {
        if (!this.entries) {
            return 0;
        }
        return this.entries.filter(entry => entry.deleted === 0).length;
    }

    getEntryForUser(userId: string): CollectionEntry | null {
        if (!this.entries || !userId) {
            return null;
        }
        for (let entry of this.entries) {
            if (userId === entry.userId && entry.deleted === 0) {
                return entry;
            }
        }
        return null;
    }

    hasUserJoined(userId: string): boolean {
        return this.getEntryForUser(userId) !== null;
    }

    isExpired(): boolean {
        if (this.expireType === 0) {
            return false; // 无限期
        }
        return new Date().getTime() > this.expireAt;
    }

    isFull(): boolean {
        if (this.maxParticipants <= 0) {
            return false; // 无限制
        }
        return this.calculateParticipantCount() >= this.maxParticipants;
    }

    isJoinable(): boolean {
        return this.status === 0 && !this.isExpired() && !this.isFull();
    }
}
