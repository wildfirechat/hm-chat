export default class Mention {
    start = 0;
    end = 0;
    isMentionAll = false;
    uid = '';

    constructor(start: number, end: number, uid: string, isMentionAll: boolean) {
        this.start = start;
        this.end = end;
        this.uid = uid;
        this.isMentionAll = isMentionAll;
    }
}
