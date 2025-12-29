import { JSONObject } from "../type/types";

export class JoinGroupRequest {
    groupId: string = "";
    memberId: string = "";
    requestUserId: string = "";
    acceptUserId: string = "";
    reason: string = "";
    extra: string = "";
    status: number = 0;
    readStatus: number = 0;
    timestamp: number = 0;

    static fromObj(obj: JSONObject): JoinGroupRequest {
        let request = new JoinGroupRequest();
        request.groupId = obj['gid'] as string
        request.memberId = obj['mid'] as string
        request.requestUserId = obj['rid'] as string
        request.acceptUserId = obj['accept_uid'] as string
        request.reason = obj['reason'] as string
        request.extra = obj['extra'] as string
        request.status = obj['status'] as number
        request.readStatus = obj['read_status'] as number
        request.timestamp = obj['update_dt'] as number
        return request;
    }
}
