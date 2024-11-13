/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

export default class GroupType {
    //member can add quit change group name and portrait, owner can do all the operations
    static Normal = 0;
    //every member can add quit change group name and portrait, no one can kickoff others
    static Free = 1;
    //member can only quit, owner can do all the operations
    static Restricted = 2;
    //member can do nothing, server api manage the group.
    static Organization = 3;
}
