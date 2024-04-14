/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import GroupInfo from "./groupInfo";
import GroupMember from './groupMember';

export default class GroupSearchResult {
    groupInfo: GroupInfo;
    //0 march group name, 1 march group member name, 2 both
    matchType = 0
    matchMembers: GroupMember[] = [];

    constructor(groupInfo: GroupInfo) {
        this.groupInfo = groupInfo
    }

    static fromProtoGroupSearchResult(obj: Record<string, Object>) {
        let groupSearchResult = new GroupSearchResult(obj.groupInfo as GroupInfo);
        groupSearchResult.matchType = obj.marchedType as number;
        groupSearchResult.matchMembers = obj.marchedMemberNames as GroupMember[];
        return groupSearchResult;

    }
}
