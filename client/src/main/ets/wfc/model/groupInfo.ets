/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import GroupType from "./groupType";

/*
public String target;
    public String name;
    public String portrait;
    public String owner;
    public GroupType type;
    public int memberCount;
    public String extra;
    public long updateDt
    */

export default class GroupInfo {
    target = '';
    name = '';
    portrait: string = '';
    owner = '';
    type = GroupType.Normal;
    memberCount = 0;
    extra = '';
    remark = '';
    updateDt = 0;
    // 群成员的最后更新日期，一般是没有什么作用，唯一的作用就是当用户退出群组后，再获取群组信息，memberDt会为负数。
    // < -1 已退出群组；-1 未加入群组；>-1 已加入群组
    memberDt = 0;
    memberUpdateDt = 0;

    //0 正常；1 全局禁言
    mute = 0;

    //在group type为Restricted时，0 开放加入权限（群成员可以拉人，用户也可以主动加入）；1 只能群成员拉人入群；2 只能群管理拉人入群
    joinType = 0;

    //是否运行群中普通成员私聊。0 允许，1不允许
    privateChat = 0;

    //是否是超级群组
    superGroup = 0;

    //是否可以搜索到该群
    searchable = 0

    //是否可以查看群历史消息, 0 不允许，1允许。仅专业版有效
    historyMessage = 0;

    //群最大成员数。仅专业版有效
    maxMemberCount = 0;
}
