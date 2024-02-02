/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

export default class FriendRequest {
    direction: number;
    target: string;
    reason: string;
    extra: string;
    //    RequestStatus_Sent = 0,
    //    RequestStatus_Accepted = 1,
    //    RequestStatus_Rejected = 3
    status: number;
    readStatus: number;
    timestamp: number;
}
