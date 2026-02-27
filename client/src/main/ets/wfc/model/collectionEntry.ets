import { JSONObject } from "../type/types";

export default class CollectionEntry {
    entryId: number = 0;
    collectionId: number = 0;
    userId: string = '';
    content: string = '';
    createdAt: number = 0;
    updatedAt: number = 0;
    deleted: number = 0;

    static fromJson(json: JSONObject): CollectionEntry {
        let entry = new CollectionEntry();
        entry.entryId = json.id as number || 0;
        entry.collectionId = json.collectionId as number || 0;
        entry.userId = json.userId as string || '';
        entry.content = json.content as string || '';
        entry.createdAt = json.createdAt as number || 0;
        entry.updatedAt = json.updatedAt as number || 0;
        entry.deleted = json.deleted as number || 0;
        return entry;
    }
}
