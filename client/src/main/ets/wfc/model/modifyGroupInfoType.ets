/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

export default class ModifyGroupInfoType {
    static Modify_Group_Name = 0;
    static Modify_Group_Portrait = 1;
    static Modify_Group_Extra = 2;
    static Modify_Group_Mute = 3;
    static Modify_Group_JoinType = 4;
    static Modify_Group_PrivateChat = 5;
    static Modify_Group_Searchable = 6;
    // 仅专业版支持
    static Modify_Group_History_Message = 7;
    // 仅专业版支持，仅 server api 可以修改
    static Modify_Group_Max_Member_Count = 8;
}
