/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

// import proto from 'node-loader!../../../marswrapper.node';
import Message from '../messages/message';
import Conversation from '../model/conversation';
import ConversationInfo from '../model/conversationInfo';
import EventType from '../client/wfcEvent'
import UserInfo from '../model/userInfo';
import NullUserInfo from '../model/nullUserInfo';
import NullGroupInfo from '../model/nullGroupInfo';
import GroupInfo from '../model/groupInfo';
import GroupMember from '../model/groupMember';
import UserSettingScope from '../client/userSettingScope';
import AddGroupMemberNotification from '../messages/notification/addGroupMemberNotification';
import MessageConfig from '../client/messageConfig';
import UnreadCount from '../model/unreadCount';
import ConversationSearchResult from '../model/conversationSearchResult';
import MessageStatus from '../messages/messageStatus';
import GroupSearchResult from '../model/groupSearchResult';
import FriendRequest from '../model/friendRequest';
import ChatRoomMemberInfo from '../model/chatRoomMemberInfo';
import ChannelInfo from '../model/channelInfo';
import ConnectionStatus from '../client/connectionStatus';
import Long from '../util/long';
import Config from "../../config";
import ChatRoomInfo from "../model/chatRoomInfo";
import ReadEntry from "../model/readEntry";
import FileRecord from "../model/fileRecord";
import MediaMessageContent from "../messages/mediaMessageContent";
import MarkUnreadMessageContent from "../messages/markUnreadMessageContent";
import { gt, stringValue } from "../util/longUtil";
import NullChannelInfo from "../model/NullChannelInfo";
import UserOnlineState from "../model/userOnlineState";
import UserCustomState from "../model/userCustomState";
import UserClientState from "../model/userClientState";
import SecretChatInfo from "../model/secretChatInfo";
import ConversationType from "../model/conversationType";
import ChannelMenu from "../model/channelMenu";
import TextMessageContent from "../messages/textMessageContent";
import FileMessageContent from "../messages/fileMessageContent";
import ImageMessageContent from "../messages/imageMessageContent";
import protoProxy from 'marswrapper'
// import os from "os";
// import path from "path";

import common from '@ohos.app.ability.common';
import assign from '../util/assign';
import Friend from '../model/friend';
import MessageContent from '../messages/messageContent';
import ModifyMyInfoEntry from '../model/modifyMyInfoEntry';
import request from '@ohos.request';
import { FailCallback, SuccessCallback, CallbackWithValue_1, CallbackWithValue_2 } from '../type/types';
import { uri } from '@kit.ArkTS';
import { fileUri } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { atob } from '../util/base64.min';


/**
 * java long 类型在 javascript 类型的映射说明:
 * 字段messageUid 对应 Long 对象
 * 其他 long 类型的变量 对应 number
 *
 * node addon 和 proto.min.js 之间 java long类型数据的传递
 * 双向传递时，都需 java long 类型的数据转换成字符串传递
 *
 */
class WfcImpl {
    connectionStatus = 0;
    userId = '';
    token = '';
    users: Map<string, UserInfo> = new Map();
    groups: Map<string, GroupInfo> = new Map();
    isLogined = false;
    needPreloadDefaultData = false;
    defaultSilentWhenPCOnline = true;
    doubleNetworkStrategy = 0;
    _connectedToMainNetwork = false;
    eventEmitter?: common.EventHub;
    context?: common.ApplicationContext;
    uploadingMap: Map<number, request.UploadTask> = new Map();
    userOnlineState: Map<string, UserOnlineState> = new Map()

    onConnectionChanged(status: number) {
        if (!self.isLogined && status === ConnectionStatus.ConnectionStatusConnected) {
            self.isLogined = true;
        }
        if (status === ConnectionStatus.ConnectionStatusConnected) {
            if (self.needPreloadDefaultData) {
                self.needPreloadDefaultData = false;
                // 预加载数据
                // 拉取会话相关用户、群信息
                // 自己的用户信息
                // 获取所有好友、好友请求的用户信息
                let estimatedTime = self._preloadDefaultData();
                console.log('to load default data', estimatedTime);
                setTimeout(() => {
                    self.connectionStatus = status;
                    self.eventEmitter!.emit(EventType.ConnectionStatusChanged, status);
                }, estimatedTime)
            } else {
                self.connectionStatus = status;
                self.eventEmitter!.emit(EventType.ConnectionStatusChanged, status);
            }
        } else {
            self.connectionStatus = status;
            self.eventEmitter!.emit(EventType.ConnectionStatusChanged, status);
        }
        console.log('connection status changed', status);
        if (self.isLogined && (status === ConnectionStatus.ConnectionStatusSecretKeyMismatch || status === ConnectionStatus.ConnectionStatusRejected)) {
            self.disconnect();
        }

        // if (status === ConnectionStatus.ConnectionStatusConnected) {
        //     if (self.isEnableSecretChat() && self.isUserEnableSecretChat()) {
        //         ipcRenderer.send('start-secret-server', { port: Config.SECRET_CHAT_MEDIA_DECODE_SERVER_PORT });
        //     }
        // }
    }

    onConnectedToServer(host: string, ip: string, port: number, mainNw: boolean) {
        console.log('connected to server', host, ip, port, mainNw);
        self.eventEmitter!.emit(EventType.ConnectedToServer, host, ip, port);
    }

    onReceiveMessage(messages: string, hasMore: boolean) {
        if (!self.isLogined) {
            return;
        }
        // receiving
        if (self.connectionStatus === 2) {
            return;
        }

        let msgs: Record<string, Object>[] = JSON.parse(messages)
        msgs.forEach(m => {
            let msg = Message.fromProtoMessage(m);
            if (!msg) {
                return
            }
            if (msg.messageContent instanceof MarkUnreadMessageContent && msg.from === self.userId) {
                let markMsg = msg.messageContent;
                let conversation = msg.conversation;
                //protoProxy.setLastReceivedMessageUnRead(JSON.stringify(conversation), stringValue(markMsg.messageUid), stringValue(markMsg.timestamp));
                protoProxy.setLastReceivedMessageUnRead(JSON.stringify(conversation));
            }
            if (msg) {
                self.eventEmitter!.emit(EventType.ReceiveMessage, msg);
            }
        });
    }

    onConferenceEvent(event: string) {
        self.eventEmitter!.emit(EventType.ConferenceEvent, event)
    }

    onOnlineEvent(event: string) {
        let userOnlineStates = self._parseUserOnlineState(event);
        for (const state of userOnlineStates) {
            self.userOnlineState.set(state.userId, state)
        }
        self.eventEmitter!.emit(EventType.UserOnlineEvent, userOnlineStates);
    }

    _parseUserOnlineState(userOnlineStateStr: string) {
        let userOnlineStates = [] as UserOnlineState[];
        let states: Record<string, Object>[] = JSON.parse(userOnlineStateStr);
        states.forEach(s => {
            let userOnlineState = new UserOnlineState();
            userOnlineState.userId = s.userId as string;
            userOnlineState.customState = new UserCustomState();
            userOnlineState.customState.state = s.customState as number;
            userOnlineState.customState.text = s.customText as string;
            userOnlineState.clientStates = [];

            if (s.states) {
                (s.states as Record<string, Object>[]).forEach(ss => {
                    let clientState = new UserClientState();
                    clientState.state = ss.state as number;
                    clientState.platform = ss.platform as number;
                    clientState.lastSeen = ss.lastSeen as number;
                    userOnlineState.clientStates.push(clientState)
                })
            }
            userOnlineStates.push(userOnlineState);
        })
        return userOnlineStates;
    }

    onGroupInfoUpdate(groupListIds: string) {
        if (!self.isLogined) {
            return;
        }

        let groupIdArray = JSON.parse(groupListIds) as string[];
        self._onGroupInfoUpdate(groupIdArray)
    }

    _onGroupInfoUpdate(groupIdArray: string[]) {
        let groupInfos = self.getGroupInfos(groupIdArray, false);
        groupInfos.forEach(gi => {
            self.groups.set(gi.target, gi);
        })

        self.eventEmitter!.emit(EventType.GroupInfosUpdate, groupInfos);
    }

    onChannelInfoUpdate(channelListIds: string) {
        if (!self.isLogined) {
            return;
        }
        let channelIdArray: string[] = JSON.parse(channelListIds);

        let channelInfos: ChannelInfo[] = [];
        channelIdArray.forEach((channelId => {
            channelInfos.push(self.getChannelInfo(channelId, false));
        }))
        self.eventEmitter!.emit(EventType.ChannelInfosUpdate, channelInfos)
    }

    onGroupMemberUpdateListener(groupId: string, groupMembersStr: string) {
        if (!self.isLogined) {
            return;
        }
        let members: GroupMember[] = [];
        let memberIds: string[] = [];
        let arr = JSON.parse(groupMembersStr) as Record<string, Object>[];
        arr.forEach(e => {
            members.push(assign(new GroupMember(), e) as GroupMember);
            memberIds.push(e.memberId as string)
        });
        self._preloadGroupMemberUserInfos(memberIds);

        self.eventEmitter!.emit(EventType.GroupMembersUpdate, groupId, members);
    }

    onSettingUpdate() {
        if (!self.isLogined) {
            return;
        }
        // TODO 具体更新的信息
        self.eventEmitter!.emit(EventType.SettingUpdate);
    }

    onRecallMessage(operatorUid: string, messageUid: string | Long) {
        if (!self.isLogined) {
            return;
        }
        self.eventEmitter!.emit(EventType.RecallMessage, operatorUid, Long.fromValue(messageUid));
    }

    onDeleteRemoteMessage(messageUid: Long | string) {
        if (!self.isLogined) {
            return;
        }
        self.eventEmitter!.emit(EventType.MessageDeleted, Long.fromValue(messageUid));
    }

    onUserReceivedMessage(receivedMapStr: string) {
        if (!self.isLogined) {
            return;
        }
        let deliveries = JSON.parse(receivedMapStr) as Record<string, number>[];
        let deliveryMap: Map<string, number> = new Map();

        deliveries.forEach(e => {
            let entries = Object.entries(e)
            for (let entry of entries) {
                deliveryMap.set(entry[0], entry[1]);
            }
        });

        self.eventEmitter!.emit(EventType.MessageReceived, deliveryMap);
        console.log('onreceive', deliveryMap);
    }

    onUserReadedMessage(readedMapStr: string) {
        if (!self.isLogined) {
            return;
        }
        // [{"userId":"GNMtGtZZ","conversationType":1,"target":"Jl8jLjkk","line":0,"readDt":1590308777299} ]
        let arr = JSON.parse(readedMapStr) as Record<string, Object>[];
        let readEntries: ReadEntry[] = [];
        arr.forEach(e => {
            let entry = new ReadEntry();
            entry.userId = e.userId as string;
            entry.conversation = new Conversation(e.conversationType as number, e.target as string, e.line as number);
            entry.readTime = e.readDt as number;
            readEntries.push(entry);
        })
        self.eventEmitter!.emit(EventType.MessageRead, readEntries);
        console.log('onread', readEntries)
    }

    onMessageDeleted(messageId: number) {
        if (!self.isLogined) {
            return;
        }
        self.eventEmitter!.emit(EventType.DeleteMessage, messageId);
    }

    onUserInfoUpdate(userIds: string) {
        if (!self.isLogined) {
            return;
        }
        let userIdArray = JSON.parse(userIds) as string[];
        let userInfos = self.getUserInfos(userIdArray)
        userInfos.forEach(ui => {
            self.users.set(ui.uid, ui);
        })
        self.eventEmitter!.emit(EventType.UserInfosUpdate, userInfos);
    }

    onFriendListUpdate(friendListIds: string) {
        if (!self.isLogined) {
            return;
        }
        console.log('friendList update, ids', friendListIds);
        let ids = JSON.parse(friendListIds) as string[];
        ids.forEach((uid) => {
            self.users.delete(uid);
        });
        self.eventEmitter!.emit(EventType.FriendListUpdate, ids);
    }

    onFriendRequestUpdate(newRequests = '[]') {
        if (!self.isLogined) {
            return;
        }
        console.log('friend request list update, new incomming requests', newRequests);
        let ids = JSON.parse(newRequests) as string[];
        self.eventEmitter!.emit(EventType.FriendRequestUpdate, ids);
    }

    onSecretChatStateChangedListener(targetId: string) {
        console.log('onSecretChatStateChangedListener', targetId);
        self.eventEmitter!.emit(EventType.SecretChatStateChange, targetId);
    }

    onSecretMessageStartBurningListener(targetId: string, playedMessageId: number) {
        console.log('onSecretMessageStartBurningListener', targetId, playedMessageId);
        self.eventEmitter!.emit(EventType.SecretChatStartBurn, targetId, playedMessageId);
    }

    onSecretMessageBurnedListener(messageIds: number[]) {
        console.log('onSecretMessageBurnedListener', messageIds);
        self.eventEmitter!.emit(EventType.SecretChatMessageBurned, messageIds)
    }

    init(context: common.ApplicationContext, eventHub: common.EventHub, dbPath: string) {
        self.context = context
        self.eventEmitter = eventHub;
        protoProxy.setDBPath(dbPath);
        // if(process.platform === 'win32'){
        //     protoProxy.invoke('setDBPath', process.cwd());
        // }
        // protoProxy.invoke('setAppName', 'mychat');
        protoProxy.setLanguage(Config.LANGUAGE);

        this._setupEventListeners();

        self.registerDefaultMessageContents();
    }

    registerMessageContent(name: string, flag: number, type: number) {
        MessageConfig.MessageContents.push(
            {
                name: name,
                flag: flag,
                type: type,
            }
        );
        protoProxy.registerMessageFlag(type, flag);
    }

    useSM4() {
        protoProxy.useSM4();
    }

    useAES256() {
        protoProxy.useAES256();
    }

    startLog() {
        protoProxy.startLog();
    }

    stopLog() {
        protoProxy.stopLog();
    }

    setLiteMode(liteMode: boolean) {
        protoProxy.setLiteMode(liteMode);
    }

    useTcpShortLink() {
        protoProxy.useTcpShortLink();
    }

    /**
     * 是否启动 TCP 短连接
     * @return {*}
     */
    isTcpShortLink(): boolean {
        return protoProxy.isTcpShortLink() === 1;
    }

    setPlatform(platform: number) {
        protoProxy.setPlatform(platform);
    }

    connect(userId: string, token: string): number {
        if (!self.userId) {
            self.userId = userId;
            let status = this.getConnectionStatus();
            if (status === ConnectionStatus.ConnectionStatusConnected) {
                this.onConnectionChanged(status);
                return new Date().getTime();
            }
        }
        self.userId = userId;

        let lastActiveTime: number = protoProxy.connect(userId, token);
        console.log('lastActiveTime', lastActiveTime);
        // 超过一周没有活跃，就预加载数据
        if (new Date().getTime() / 1000 - lastActiveTime > 7 * 24 * 60 * 60) {
            self.needPreloadDefaultData = true;
        }
        return lastActiveTime;
        // for testing your code
        // self.test();
    }

    setProxyInfo(host: string, ip: string, port: number, username: string, password: string) {
        protoProxy.setProxyInfo(host, ip, port, username, password);
    }

    setPackageName(packageName: string) {
        protoProxy.setPackageName(packageName);
    }

    setDeviceToken(pushType: number, token: string) {
        protoProxy.setDeviceToken(pushType, token);
    }

    disconnect(disablePush = false, cleanSession = false) {
        self.userId = '';
        protoProxy.disconnect(disablePush, cleanSession);


        //sleep 1 second wait disconnect with im server
        let now = new Date();
        let exitTime = now.getTime() + 1000;
        while (true) {
            now = new Date();
            if (now.getTime() > exitTime) {
                return;
            }
        }
    }

    registerDefaultMessageContents() {
        MessageConfig.MessageContents.map((e) => {
            protoProxy.registerMessageFlag(e.type, e.flag);
        });
    }

    getClientId(): string {
        return protoProxy.getClientId();
    }

    getProtoRevision(): string {
        return protoProxy.getProtoRevision();
    }

    getUserId(): string {
        return self.userId;
    }

    getServerDeltaTime(): number {
        return protoProxy.getServerDeltaTime();
    }

    isLogin(): boolean {
        // return proto.isLogin();
        return self.isLogined;
    }

    getConnectionStatus(): number {
        return protoProxy.getConnectionStatus();
    }

    setBackupAddressStrategy(strategy: number) {
        self.doubleNetworkStrategy = strategy;
        if (strategy === 0) {
            self._connectedToMainNetwork = true;
        }
        protoProxy.setBackupAddressStrategy(strategy);
    }

    setBackupAddress(backupHost: string, backupPort: number) {
        protoProxy.setBackupAddress(backupHost, backupPort);
    }

    setProtoUserAgent(userAgent: string) {
        if (typeof userAgent !== 'string') {
            console.error('setProtoUserAgent userAgent must be string');
            return;
        }
        protoProxy.setUserAgent(userAgent);
    }

    addHttpHeader(header: string, value: string) {
        if (typeof header !== "string" || typeof value !== "string") {
            console.error('addHttpHeader header, value must be string')
            return;
        }
        protoProxy.addHttpHeader(header, value);
    }

    onAppResume() {
        protoProxy.onAppResume();
    }

    onAppSuspend() {
        protoProxy.onAppSuspend();
    }

    // setLanguage(language) {
    //     proto.setLanguage(language);
    // }

    getMyGroupList(): GroupInfo[] {
        let settings = this.getUserSettings(UserSettingScope.FavoriteGroup);
        let groupInfos = settings.filter(setting => {
            return Object.values(setting)[1] === '1'
        })
            .map(setting => {
                let groupId = Object.values(setting)[0]
                return this.getGroupInfo(groupId, false)
            });
        return groupInfos;
    }

    /**
     * @param {string} userId
     * @param {boolean} fresh
     */
    getUserInfo(userId: string, fresh = false, groupId = '') {
        if (!userId || userId === '') {
            return new NullUserInfo('');
        }
        let userInfo: UserInfo;
        if (!fresh && (!groupId || groupId === '')) {
            let ui = self.users.get(userId);
            if (ui) {
                return ui;
            }
        }

        // console.log('getuserInfo', userId, fresh, groupId);
        let userInfoStr: string = protoProxy.getUserInfo(userId, fresh, groupId);
        if (userInfoStr === '') {
            userInfo = new NullUserInfo(userId);
        } else {
            userInfo = assign(new UserInfo(), JSON.parse(userInfoStr)) as UserInfo;
        }
        if (!groupId || groupId === '') {
            self.users.set(userInfo.uid, userInfo);
        }
        return userInfo;
    }

    getUserInfos(userIds: string[], groupId = ''): UserInfo[] {
        let users: UserInfo[] = [];
        let userInfoStrs: string = protoProxy.getUserInfos(userIds, groupId);
        if (userInfoStrs && userInfoStrs !== '') {
            let tmp = JSON.parse(userInfoStrs) as Record<string, Object>[];
            tmp.forEach((u) => {
                let userInfo = assign(new UserInfo(), u) as UserInfo;
                users.push(userInfo)
            });
        }
        return users;
    }

    async getUserInfoEx(userId: string, refresh: boolean, successCB: CallbackWithValue_1<UserInfo>, failCB: FailCallback) {
        protoProxy.getUserInfoEx(userId, refresh, (userInfoStr: string) => {
            const userInfo = assign(new UserInfo(), JSON.parse(userInfoStr)) as UserInfo;

            if (successCB) {
                successCB(userInfo);
            }
        }, (errorCode: number) => {
            if (errorCode) {
                failCB(errorCode);
            }

        });
    }

    async searchUser(keyword: string, searchType: number, page: number, successCB: CallbackWithValue_2<string, UserInfo[]>, failCB: FailCallback) {
        protoProxy.searchUser(keyword, searchType, page, (result: string) => {
            let userListStr = JSON.parse(result) as Record<string, Object>[];
            let userList: UserInfo[] = [];
            if (userListStr && userListStr.length > 0) {
                userListStr.forEach(u => {
                    userList.push(assign(new UserInfo(), u) as UserInfo);
                });
            }
            if (successCB) {
                successCB(keyword, userList);
            }
        }, (errorCode: number) => {
            if (errorCode) {
                failCB(errorCode);
            }

        });
    }

    searchFriends(keyword: string) {
        let result: string = protoProxy.searchFriends(keyword);
        let userListStr = JSON.parse(result) as Record<string, Object>[];
        let userList: UserInfo[] = [];
        if (userListStr && userListStr.length > 0) {
            userListStr.forEach(u => {
                userList.push(assign(new UserInfo(), u) as UserInfo);
            });
        }
        return userList;
    }

    searchGroups(keyword: string) {
        let result: string = protoProxy.searchGroups(keyword);
        let groupSearchResultListStr = JSON.parse(result) as Record<string, Object>[];
        let groupSearchResultList: GroupSearchResult[] = [];
        if (groupSearchResultListStr && groupSearchResultListStr.length > 0) {
            groupSearchResultListStr.forEach(g => {
                groupSearchResultList.push(GroupSearchResult.fromProtoGroupSearchResult(g));
            });
        }
        return groupSearchResultList;
    }

    getIncommingFriendRequest() {
        let result: string = protoProxy.getIncommingFriendRequest();
        let friendRequestListStr = JSON.parse(result) as Record<string, Object>[];
        let firendRequestList: FriendRequest[] = [];
        if (friendRequestListStr && friendRequestListStr.length > 0) {
            friendRequestListStr.forEach((r) => {
                firendRequestList.push(assign(new FriendRequest(), r) as FriendRequest);
            });
        }
        return firendRequestList;
    }

    getOutgoingFriendRequest(): FriendRequest[] {
        let result: string = protoProxy.getOutgoingFriendRequest();
        let friendRequestListStr = JSON.parse(result) as Record<string, Object>[];
        let firendRequestList: FriendRequest[] = [];
        if (friendRequestListStr && friendRequestListStr.length > 0) {
            friendRequestListStr.forEach((r) => {
                firendRequestList.push(assign(new FriendRequest(), r) as FriendRequest);
            });
        }
        return firendRequestList;
    }

    getOneFriendRequest(userId: string, incoming: boolean) {
        let result: string = protoProxy.getFriendRequest(userId, incoming);
        return JSON.parse(result) as FriendRequest;
    }

    loadFriendRequestFromRemote() {
        protoProxy.loadFriendRequestFromRemote();
    }

    getFavUsers() {
        let result: string = protoProxy.getFavUsers();
        return JSON.parse(result) as string[];
    }

    isFavUser(userId: string): boolean {
        return protoProxy.isFavUser(userId) === 1;
    }

    setFavUser(userId: string, fav: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.setFavUser(userId, fav, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    loadRemoteMessages(conversation: Conversation, contentTypes: number[], beforeUid: Long, count: number, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        if (!contentTypes) {
            contentTypes = [];
        }
        protoProxy.getRemoteMessages(JSON.stringify(conversation), stringValue(beforeUid), count, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('loadRemoteMessages', stringValue(beforeUid), msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("loadRemoteMessages failure:", errorCode);
            failCB && failCB(errorCode);
        }, contentTypes);
    }

    loadRemoteMessage(messageUid: Long, successCB: CallbackWithValue_1<Message>, failCB: FailCallback) {
        protoProxy.getRemoteMessage(stringValue(messageUid), (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('loadRemoteMessage', msgs.length);
            if (msgs.length === 1) {
                successCB && successCB(msgs[0]);
            } else {
                failCB && failCB(-1);
            }
        }, (errorCode: number) => {
            console.log("loadRemoteMessage failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getUnreadFriendRequestCount(): number {
        return protoProxy.getUnreadFriendRequestStatus();
    }

    clearUnreadFriendRequestStatus() {
        protoProxy.clearUnreadFriendRequestStatus();
    }

    clearFriendRequest(direction: number, beforeTime: number) {
        protoProxy.clearFriendRequest(direction, beforeTime);
    }

    deleteFriendRequest(userId: string, direction: number) {
        protoProxy.deleteFriendRequest(userId, direction);
    }

    async deleteFriend(userId: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.deleteFriend(userId, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            failCB(errorCode);
        });
    }

    async handleFriendRequest(userId: string, accept: boolean, extra: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.handleFriendRequest(userId, accept, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }

        }, extra);
    }

    isBlackListed(userId: string): boolean {
        return protoProxy.isBlackListed(userId) === 1;
    }

    getBlackList(refresh = false) {
        let result: string = protoProxy.getBlackList(refresh);
        return JSON.parse(result) as string[];
    }

    setBlackList(userId: string, block: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.setBlackList(userId, block, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getMyFriendList(fresh = false) {
        let idsStr: string = protoProxy.getMyFriendList(fresh);
        if (idsStr !== '') {
            return JSON.parse(idsStr) as string[];
        }
        return [];
    }

    getFriendList(fresh = false): Friend[] {
        let result: string = protoProxy.getFriendList(fresh);
        let friendList = JSON.parse(result) as Record<string, Object>[];

        return friendList.map(f => {
            return assign(new Friend(), f) as Friend
        })
    }

    getFriendExtra(userId: string): string {
        return protoProxy.getFriendAlias(userId);
    }

    getFriendAlias(userId: string): string {
        return protoProxy.getFriendAlias(userId);
    }

    async setFriendAlias(userId: string, alias: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.setFriendAlias(userId, alias, successCB, failCB);
    }

    async createGroup(groupId: string, groupType: number, name: string, portrait: string, groupExtra: string = '', memberIds: string[] = [], memberExtra = '', lines: number[] = [0],
        notifyContent: MessageContent | null, successCB: CallbackWithValue_1<string>, failCB: FailCallback) {
        groupId = !groupId ? '' : groupId;
        groupExtra = !groupExtra ? '' : groupExtra;
        memberExtra = !memberExtra ? '' : memberExtra;
        let myUid = self.getUserId();

        if (!memberIds.includes(myUid)) {
            memberIds.push(myUid);
        }

        let payload = notifyContent ? notifyContent.encode() : '';
        let notifyContentStr = JSON.stringify(payload);
        //群组类型0，管理员和群主才能加人和退群，修改群信息；2，严格模式，只有群主和管理员才能操作群
        protoProxy.createGroup(groupId, groupType, name, portrait, groupExtra, memberIds, memberExtra, lines, notifyContentStr,
            (groupId: string) => {
                if (successCB) {
                    successCB(groupId);
                }
            },
            (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async setGroupManager(groupId: string, isSet: boolean, memberIds: string[] = [], lines = [0], notifyContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        let payload = notifyContent ? notifyContent.encode() : '';
        let notifyContentStr = JSON.stringify(payload);
        protoProxy.setGroupManager(groupId, isSet, memberIds, lines, notifyContentStr, successCB, failCB);
    }

    async muteOrAllowGroupMembers(groupId: string, isSet: boolean, isAllow: boolean, memberIds: string[], notifyLines: number[] = [0], notifyContent: MessageContent | null, successCB: SuccessCallback,
        failCB: FailCallback) {
        if (isAllow) {
            let payload = notifyContent ? notifyContent.encode() : '';
            let notifyContentStr = JSON.stringify(payload);
            protoProxy.allowGroupMember(groupId, isSet, memberIds, notifyLines, notifyContentStr, () => {
                successCB && successCB();
            }, (errorCode: number) => {
                failCB && failCB(errorCode);
            });
        } else {
            let payload = notifyContent ? notifyContent.encode() : '';
            let notifyContentStr = JSON.stringify(payload);
            protoProxy.muteGroupMember(groupId, isSet, memberIds, notifyLines, notifyContentStr, () => {
                successCB && successCB();
            }, (errorCode: number) => {
                failCB && failCB(errorCode);
            });
        }
    }

    async setGroupRemark(groupId: string, remark: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.setGroupRemark(groupId, remark, () => {
            self._onGroupInfoUpdate([groupId])
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    getGroupRemark(groupId: string): string {
        return protoProxy.getGroupRemark(groupId);
    }

    getGroupInfo(groupId: string, fresh = false): GroupInfo {
        let groupInfo: GroupInfo;
        if (!fresh) {
            let gi = self.groups.get(groupId);
            if (gi) {
                return gi;
            }
        }

        console.log('get groupInfo', groupId, fresh);
        let groupInfoStr: string = protoProxy.getGroupInfo(groupId, fresh);
        if (groupInfoStr === '') {
            return new NullGroupInfo(groupId);
        } else {
            groupInfo = assign(new GroupInfo(), JSON.parse(groupInfoStr)) as GroupInfo;
            self.groups.set(groupId, groupInfo);
            return groupInfo;
        }
    }

    getGroupInfos(groupIds: string[], fresh = false) {
        let groups: GroupInfo[] = [];
        let groupInfoStrs: string = protoProxy.getGroupInfos(groupIds, fresh);
        if (groupInfoStrs && groupInfoStrs !== '') {
            let tmp: Record<string, Object>[] = JSON.parse(groupInfoStrs);
            tmp.forEach((u) => {
                let groupInfo = assign(new GroupInfo(), u) as GroupInfo;
                groups.push(groupInfo)
            });
        }
        return groups;
    }

    async getGroupInfoEx(groupId: string, refresh: boolean, successCB: CallbackWithValue_1<GroupInfo>, failCB: FailCallback) {
        protoProxy.getGroupInfoEx(groupId, refresh, (groupInfoStr: string) => {
            let groupInfo = assign(new GroupInfo(), JSON.parse(groupInfoStr)) as GroupInfo;

            if (successCB) {
                successCB(groupInfo);
            }
        }, (errorCode: number) => {
            if (errorCode) {
                failCB(errorCode);
            }

        });
    }

    addGroupMembers(groupId: string, memberIds: string[], extra: string, notifyLines: number[], notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        if (!notifyMessageContent) {
            notifyMessageContent = new AddGroupMemberNotification(self.getUserId(), memberIds);
        }
        let payload = notifyMessageContent.encode();
        let notifyContentStr = JSON.stringify(payload);
        extra = !extra ? '' : extra;
        protoProxy.addMembers(memberIds, groupId, extra, notifyLines, notifyContentStr,
            () => {
                if (successCB) {
                    successCB();
                }
            },
            (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    getGroupMemberIds(groupId: string, fresh = false) {
        let groupMembers = self.getGroupMembers(groupId, fresh);
        let groupMemberIds: string[] = [];
        groupMembers.forEach(e => {
            groupMemberIds.push(e.memberId);
        });
        return groupMemberIds;
    }

    getGroupMembers(groupId: string, fresh = false) {
        let membersStr: string = protoProxy.getGroupMembers(groupId, fresh);
        let members: GroupMember[] = [];
        let arr = JSON.parse(membersStr) as Record<string, Object>[];
        arr.forEach(e => {
            members.push(assign(new GroupMember(), e) as GroupMember);
        });
        return members;
    }

    getGroupMembersByType(groupId: string, memberType: number): GroupMember[] {
        let membersStr: string = protoProxy.getGroupMembersByType(groupId, memberType);
        let members: GroupMember[] = [];
        let arr = JSON.parse(membersStr) as Record<string, Object>[];
        arr.forEach(e => {
            members.push(assign(new GroupMember(), e) as GroupMember);
        });
        return members;
    }

    getGroupMembersByCount(groupId: string, count: number): GroupMember[] {
        let membersStr = protoProxy.getGroupMembersByCount(groupId, count);
        let members: GroupMember[] = [];
        let arr = JSON.parse(membersStr) as Record<string, Object>[];
        arr.forEach(e => {
            members.push(assign(new GroupMember(), e) as GroupMember);
        });
        return members;
    }

    getGroupMember(groupId: string, memberId: string): GroupMember {
        let result: string = protoProxy.getGroupMember(groupId, memberId);
        return assign(new GroupMember(), JSON.parse(result)) as GroupMember;
    }

    async getGroupMembersEx(groupId: string, refresh: boolean, successCB: CallbackWithValue_1<GroupMember[]>, failCB: FailCallback) {
        protoProxy.getGroupMembersEx(groupId, refresh, (membersStr: string) => {
            let members: GroupMember[] = [];
            let arr = JSON.parse(membersStr) as Record<string, Object>[];
            arr.forEach(e => {
                members.push(assign(new GroupMember(), e) as GroupMember);
            });

            if (successCB) {
                successCB(members);
            }
        }, (errorCode: number) => {
            if (errorCode) {
                failCB(errorCode);
            }

        });
    }

    kickoffGroupMembers(groupId: string, memberIds: string[], notifyLines: number[], notifyMsg: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        let payload = notifyMsg ? notifyMsg.encode() : '';
        let strCont = JSON.stringify(payload);
        protoProxy.kickoffMembers(groupId, memberIds, notifyLines, strCont,
            () => {
                if (successCB) {
                    successCB();
                }

            }, (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async quitGroup(groupId: string, lines: number[] = [0], notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.quitGroup(groupId, lines, JSON.stringify(payload), () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            failCB(errorCode);
        });
    }

    async dismissGroup(groupId: string, lines: number[] = [0], notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.dismissGroup(groupId, lines, JSON.stringify(payload), () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            failCB(errorCode);
        });
    }

    async modifyGroupInfo(groupId: string, type: number, newValue: string, lines: number[] = [0], notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.modifyGroupInfo(groupId, type, newValue, lines, JSON.stringify(payload),
            () => {
                if (successCB) {
                    successCB();
                }
                self._onGroupInfoUpdate([groupId])
            }, (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async modifyGroupAlias(groupId: string, alias: string, lines: number[] = [0], notifyMessageContent: MessageContent | null | undefined, successCB: SuccessCallback | null | undefined,
        failCB: FailCallback | null | undefined) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.modifyGroupAlias(groupId, alias, lines, JSON.stringify(payload), () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    async modifyGroupMemberAlias(groupId: string, memberId: string, alias: string, lines: number[] = [0], notifyMessageContent: MessageContent | null | undefined,
        successCB: SuccessCallback | null | undefined, failCB: FailCallback | null | undefined) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.modifyGroupMemberAlias(groupId, memberId, alias, lines, JSON.stringify(payload), () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    async modifyGroupMemberExtra(groupId: string, memberId: string, extra: string, lines: number[] = [0], notifyMessageContent: MessageContent | null | undefined,
        successCB: SuccessCallback | null | undefined, failCB: FailCallback | null | undefined) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.modifyGroupMemberExtra(groupId, memberId, extra, lines, JSON.stringify(payload), () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    transferGroup(groupId: string, newOwner: string, lines: number[] = [0], notifyMessageContent: MessageContent | null | undefined, successCB: SuccessCallback | null | undefined,
        failCB: FailCallback | null | undefined) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.transferGroup(groupId, newOwner, lines, JSON.stringify(payload), () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getFavGroups(): string[] {
        let result: string = protoProxy.getFavGroups();
        return JSON.parse(result) as string[];
    }

    isFavGroup(groupId: string): boolean {
        return protoProxy.isFavGroup(groupId) === 1;
    }

    async setFavGroup(groupId: string, fav: boolean, successCB: SuccessCallback | null | undefined, failCB: FailCallback | null | undefined) {
        protoProxy.setFavGroup(groupId, fav, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    async getMyGroups(successCB: CallbackWithValue_1<string[]>, failCB: FailCallback) {
        protoProxy.getMyGroups((groupIds: string[]) => {
            if (successCB) {
                successCB(groupIds);
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    async getCommonGroups(userId: string, successCB: CallbackWithValue_1<string[]>, failCB: FailCallback) {
        protoProxy.getCommonGroups(userId, (groupIds: string[]) => {
            if (successCB) {
                successCB(groupIds);
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getUserSetting(scope: number, key: string): string {
        return protoProxy.getUserSetting(scope, key);
    }

    getUserSettings(scope: number): Record<string, string>[] {
        let result: string = protoProxy.getUserSettings(scope);
        return JSON.parse(result);
    }

    async setUserSetting(scope: number, key: string, value: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.setUserSetting(scope, key, value, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    modifyMyInfo(modifyMyInfoEntries: ModifyMyInfoEntry[], successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.modifyMyInfo(modifyMyInfoEntries[0].type, modifyMyInfoEntries[0].value, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    isGlobalSilent(): boolean {
        return protoProxy.isGlobalSilent() === 1;
    }

    setGlobalSilent(silent: boolean, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.setGlobalSilent(silent, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    isHiddenNotificationDetail(): boolean {
        return protoProxy.isHiddenNotificationDetail() === 1;
    }

    async setHiddenNotificationDetail(hide: boolean, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.setHiddenNotificationDetail(hide, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    isHiddenGroupMemberName(groupId: string): boolean {
        return protoProxy.isHiddenGroupMemberName(groupId) === 1;
    }

    async setHiddenGroupMemberName(groupId: string, hide: boolean, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.setHiddenGroupMemberName(groupId, hide, () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    isUserReceiptEnabled() {
        return protoProxy.isUserReceiptEnabled() === 1;
    }

    async setUserEnableReceipt(enable: boolean, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.setUserReceiptEnable(enable, () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    async joinChatroom(chatroomId: string, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.joinChatroom(chatroomId, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    quitChatroom(chatroomId: string, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.quitChatroom(chatroomId, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getChatroomInfo(chatroomId: string, updateDt: number, successCB: CallbackWithValue_1<ChatRoomInfo> | null, failCB: FailCallback | null) {
        protoProxy.getChatroomInfo(chatroomId, '' + updateDt, (info: string) => {
            if (successCB) {
                let chatRoomInfo = assign(new ChatRoomInfo(), JSON.parse(info)) as ChatRoomInfo;
                chatRoomInfo.chatRoomId = chatroomId;
                successCB(chatRoomInfo);
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getChatroomMemberInfo(chatroomId: string, maxCount: number, successCB: CallbackWithValue_1<ChatRoomMemberInfo>, failCB: FailCallback) {
        protoProxy.getChatroomMemberInfo(chatroomId, maxCount, (info: string) => {
            if (successCB) {
                successCB(assign(new ChatRoomMemberInfo(), JSON.parse(info)) as ChatRoomMemberInfo);
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    createChannel(name: string, portrait: string, desc: string, extra: string, successCB: CallbackWithValue_1<ChannelInfo> | null, failCB: FailCallback | null) {
        protoProxy.createChannel(name, portrait, 0, desc, extra, (info: string) => {
            if (successCB) {
                successCB(assign(new ChannelInfo(), JSON.parse(info)) as ChannelInfo);
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getChannelInfo(channelId: string, refresh = false) {
        let result: string = protoProxy.getChannelInfo(channelId, refresh);
        if (result === '') {
            return new NullChannelInfo(channelId);
        }

        let ci = assign(new ChannelInfo(), JSON.parse(result)) as ChannelInfo;
        if (ci.menus) {
            ci.menus = ci.menus.map(menustr => {
                let menu = assign(new ChannelMenu(), menustr) as ChannelMenu
                if (menu.subMenus) {
                    menu.subMenus = menu.subMenus.map(sm => assign(new ChannelMenu(), sm) as ChannelMenu)
                }
                return menu;
            })
        }
        return ci;
    }

    async modifyChannelInfo(channelId: string, type: number, newValue: string, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.modifyChannelInfo(channelId, type, newValue, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    searchChannel(keyword: string, successCB: CallbackWithValue_2<string, ChannelInfo[]>, failCB: FailCallback) {
        protoProxy.searchChannel(keyword, (result: string) => {
            if (successCB) {
                let channels: ChannelInfo[] = [];
                let tmp = JSON.parse(result) as Record<string, Object>[];
                tmp.forEach(channel => {
                    channels.push(assign(new ChannelInfo(), channel) as ChannelInfo);
                });
                successCB(keyword, channels);
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    isListenedChannel(channelId: string): boolean {
        return protoProxy.isListenedChannel(channelId) === 1;
    }

    async listenChannel(channelId: string, listen: boolean, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.listenChannel(channelId, listen, () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    // return channelIds
    getMyChannels(): string[] {
        let result: string = protoProxy.getMyChannels();
        return JSON.parse(result) as string[];
    }

    getListenedChannels(): string[] {
        // TODO
        // let result: string = protoProxy.getListenedChannels();
        // return JSON.parse(result);
        return [] as string[]
    }

    getRemoteListenedChannels(successCB: CallbackWithValue_1<string[]>, failCB: FailCallback) {
        protoProxy.getRemoteListenedChannels((channelIds: string[]) => {
            successCB && successCB(channelIds);
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    async destoryChannel(channelId: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.destoryChannel(channelId, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getConversationInfoList(types: number[], lines: number[]): ConversationInfo[] {
        let conversationListStr: string = protoProxy.getConversationInfos(types, lines);
        // console.log(conversationListStr);
        // TODO convert to conversationInfo, messageContent

        let conversationInfoList: ConversationInfo[] = [];
        let tmp = JSON.parse(conversationListStr) as Record<string, Object>[];
        tmp.forEach(c => {
            conversationInfoList.push(ConversationInfo.protoConversationToConversationInfo(c));
        });

        return conversationInfoList;
    }

    getConversationInfo(conversation: Conversation): ConversationInfo {
        let convStr: string = protoProxy.getConversationInfo(JSON.stringify(conversation));
        return ConversationInfo.protoConversationToConversationInfo(JSON.parse(convStr));
    }

    searchConversation(keyword: string, types: number[] = [], lines: number[] = []) {
        let result: string = protoProxy.searchConversation(keyword, types, lines);
        let resultList = JSON.parse(result) as Record<string, Object>[];
        let conversationSearchResult: ConversationSearchResult[] = [];
        if (resultList && resultList.length > 0) {
            resultList.forEach(r => {
                conversationSearchResult.push(ConversationSearchResult.fromProtoConversationSearchResult(r));
            });
        }
        return conversationSearchResult;
    }

    searchConversationEx(keyword: string, types: number[], lines: number[], startTime = 0, endTime = 0, desc = false, limit = 20, offset = 0) {
        let result: string = protoProxy.searchConversationEx(keyword, types, lines, startTime, endTime, desc, limit, offset);
        let resultList = JSON.parse(result) as Record<string, Object>[];
        let conversationSearchResult: ConversationSearchResult[] = [];
        if (resultList && resultList.length > 0) {
            resultList.forEach(r => {
                conversationSearchResult.push(ConversationSearchResult.fromProtoConversationSearchResult(r));
            });
        }
        return conversationSearchResult;
    }

    searchConversationEx2(keyword: string, types: number[], lines: number[], cntTypes: number[], startTime = 0, endTime = 0, desc = false, limit = 20, offset = 0, onlyMentionedMsg = false) {
        let result: string = protoProxy.searchConversationEx2(keyword, types, lines, cntTypes, startTime, endTime, desc, limit, offset, onlyMentionedMsg);
        let resultList = JSON.parse(result) as Record<string, Object>[];
        let conversationSearchResult: ConversationSearchResult[] = [];
        if (resultList && resultList.length > 0) {
            resultList.forEach(r => {
                conversationSearchResult.push(ConversationSearchResult.fromProtoConversationSearchResult(r));
            });
        }
        return conversationSearchResult;
    }

    async removeConversation(conversation: Conversation, clearMsg: boolean = false) {
        protoProxy.removeConversation(JSON.stringify(conversation), clearMsg);
    }

    setConversationTop(conversation: Conversation, top: number, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.setConversationTop(JSON.stringify(conversation), top, () => {
            let conversationInfo = self.getConversationInfo(conversation);
            self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);

            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    setConversationSlient(conversation: Conversation, silent: boolean, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        protoProxy.setConversationSilent(JSON.stringify(conversation), silent, () => {
            let conversationInfo = self.getConversationInfo(conversation);
            self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);

            if (successCB) {
                successCB();
            }
        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    setConversationDraft(conversation: Conversation, draft = '') {
        let conversationInfo = self.getConversationInfo(conversation);
        if (conversationInfo.draft === draft) {
            return;
        }
        protoProxy.setConversationDraft(JSON.stringify(conversation), draft);
        conversationInfo = self.getConversationInfo(conversation);
        self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    //timestamp 为毫秒，字符串类型
    setConversationTimestamp(conversation: Conversation, timestamp: number) {
        protoProxy.setConversationTimestamp(JSON.stringify(conversation), timestamp);
        let conversationInfo = self.getConversationInfo(conversation);
        self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    getUnreadCount(types: number[], lines: number[] = [0]) {
        let unreadCountStr: string = protoProxy.getUnreadCount(types, lines);
        return assign(new UnreadCount(), JSON.parse(unreadCountStr)) as UnreadCount;
    }

    getConversationUnreadCount(conversation: Conversation) {
        let unreadCountStr: string = protoProxy.getConversationUnreadCount(JSON.stringify(conversation));
        return assign(new UnreadCount(), JSON.parse(unreadCountStr)) as UnreadCount;
    }

    clearConversationsUnreadStatus(types: number[], lines: number[] = [0]) {
        protoProxy.clearConversationsUnreadStatus(types, lines);
        //Todo notify UI?
    }

    clearConversationUnreadStatus(conversation: Conversation) {
        protoProxy.clearUnreadStatus(JSON.stringify(conversation));
        let conversationInfo = self.getConversationInfo(conversation);
        self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    clearUnreadStatusBeforeMessage(conversation: Conversation, messageId: number) {
        protoProxy.clearMessageUnreadStatusBefore(JSON.stringify(conversation), messageId);
        let conversationInfo = self.getConversationInfo(conversation);
        self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    markConversationAsUnread(conversation: Conversation, syncToOtherClient: boolean) {
        let msgUid: string = protoProxy.setLastReceivedMessageUnRead(JSON.stringify(conversation));
        if (msgUid && gt(msgUid, 0)) {
            if (syncToOtherClient) {
                let msg = this.getMessageByUid(msgUid);
                let content = new MarkUnreadMessageContent(Long.fromString(msgUid));
                content.timestamp = msg!.timestamp;
                this.sendConversationMessage(conversation, content)
            }
            let conversationInfo = self.getConversationInfo(conversation);
            self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);
            return true;
        }
        return false;
    }

    getConversationRead(conversation: Conversation): Map<string, number> {
        let readedStr: string = protoProxy.getConversationRead(JSON.stringify(conversation));
        let readedArr = JSON.parse(readedStr) as Record<string, Object>[];
        // let result = []
        // if (readedArr) {
        //     readedArr.forEach(e => {
        //         result.push({e.key, e.value})
        //     })
        // }
        // return readedArr;
        let result: Map<string, number> = new Map();
        if (readedArr) {
            readedArr.forEach(e => {
                let values = Object.values(e)
                result.set(values[0] as string, values[1] as number)
            })
        }
        return result;
    }

    getConversationDelivery(conversation: Conversation): Map<string, number> {
        let deliveryStr: string = protoProxy.getMessageDelivery(JSON.stringify(conversation));
        let deliveryArr = JSON.parse(deliveryStr) as Record<string, Object>[];
        let result: Map<string, number> = new Map();
        if (deliveryArr) {
            deliveryArr.forEach(e => {
                let values = Object.values(e)
                result.set(values[0] as string, values[1] as number)
            })
        }
        return result;
    }

    kickoffPCClient(clientId: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.kickoffPCClient(clientId, successCB, failCB);
    }

    isMuteNotificationWhenPcOnline(): boolean {
        let strValue = this.getUserSetting(UserSettingScope.MuteWhenPCOnline, "");
        if ("1" === strValue) {
            return !this.defaultSilentWhenPCOnline;
        }
        return this.defaultSilentWhenPCOnline;
    }

    setDefaultSilentWhenPcOnline(defaultSilent: boolean) {
        this.defaultSilentWhenPCOnline = defaultSilent;
    }

    muteNotificationWhenPcOnline(isMute: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        let strValue: string;
        if (!this.defaultSilentWhenPCOnline) {
            isMute = !isMute;
        }
        if (isMute) {
            strValue = "0";
        } else {
            strValue = "1";
        }
        this.setUserSetting(UserSettingScope.MuteWhenPCOnline, "", strValue, successCB, failCB);
    }

    clearMessageUnreadStatus(messageId: number) {
        protoProxy.clearMessageUnreadStatus(messageId);
    }

    clearAllUnreadStatus() {
        // TODO emit ConversationInfoUpdate event
        protoProxy.clearAllUnreadStatus();
    }

    getConversationFirstUnreadMessageId(conversation: Conversation): number {
        let messageId: number = protoProxy.getConversationFirstUnreadMessageId(JSON.stringify(conversation));
        return messageId;
    }

    setMediaMessagePlayed(messageId: number) {
        // TODO need to emit message update event?
        protoProxy.setMediaMessagePlayed(messageId);
    }

    setMessageLocalExtra(messageId: number, extra: string) {
        protoProxy.setMessageLocalExtra(messageId, extra);
    }

    isMyFriend(userId: string) {
        return protoProxy.isMyFriend(userId) === 1;
    }

    async sendFriendRequest(userId: string, reason: string, extra = '', successCB: SuccessCallback | null | undefined, failCB: FailCallback | null | undefined) {
        extra = !extra ? '' : extra;
        protoProxy.sendFriendRequest(userId, reason, extra, () => {
            if (successCB) {
                successCB();
            }

        }, (errorCode: number) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    /**
     *
     * @param {Conversation} conversation
     * @param {number} fromIndex
     * @param {boolean} before
     * @param {number} count
     * @param {string} withUser
     * @param {array} contentTypes
     */
    getMessages(conversation: Conversation, fromIndex: number, before = true, count = 20, withUser = '') {
        // TODO
        // let protoMsgsStr: string = protoProxy.getMessages(JSON.stringify(conversation), [], fromIndex, before, count, withUser);
        // // let protoMsgsStr = proto.getMessages('xxx', [0], fromIndex, before, count, withUser);
        // var protoMsgs = JSON.parse(protoMsgsStr);
        // let msgs = [];
        // protoMsgs.map(m => {
        //     let msg = Message.fromProtoMessage(m);
        //     if (msg) {
        //         msgs.push(msg);
        //     }
        // });
        // console.log('getMessages', msgs.length);
        //
        // return msgs;

        return [] as Message[]
    }

    getMessagesV2(conversation: Conversation, fromIndex: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        protoProxy.getMessagesV2(JSON.stringify(conversation), [], fromIndex, before, count, withUser, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("getMessagesV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMentionedMessages(conversation: Conversation, fromIndex: number, before: boolean, count: number, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        protoProxy.getMentionedMessages(JSON.stringify(conversation), fromIndex, before, count, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMentionedMessages', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("getMentionedMessages failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessagesEx(conversationTypes: number[], lines: Number[], contentTypes: number[], fromIndex: number = 0, before = true, count = 20, withUser = '') {
        // let protoMsgsStr: string = protoProxy.getMessagesEx(conversationTypes, lines, contentTypes, fromIndex, before, count, withUser);
        // // let protoMsgsStr = proto.getMessages('xxx', [0], fromIndex, before, count, withUser);
        // var protoMsgs = JSON.parse(protoMsgsStr);
        // let msgs = [];
        // protoMsgs.map(m => {
        //     let msg = Message.fromProtoMessage(m);
        //     if (msg) {
        //         msgs.push(msg);
        //     }
        // });
        // console.log('getMessages', msgs.length);
        //
        // return msgs;
        return [] as Message[]
    }

    getMessagesExV2(conversationTypes: number[], lines: number[], contentTypes: number[], fromIndex: number, before: boolean, count: number, withUser: string,
        successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        protoProxy.getMessagesExV2(conversationTypes, lines, contentTypes, fromIndex, before, count, withUser, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesExV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("getMessagesExV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessagesEx2(conversationTypes: number[], lines: number[], status: number, fromIndex: number, before = true, count = 20, withUser = '') {
        // let protoMsgsStr: string = protoProxy.getMessagesEx2(conversationTypes, lines, status, fromIndex, before, count, withUser);
        // // let protoMsgsStr = proto.getMessages('xxx', [0], fromIndex, before, count, withUser);
        // var protoMsgs = JSON.parse(protoMsgsStr);
        // let msgs = [];
        // protoMsgs.map(m => {
        //     let msg = Message.fromProtoMessage(m);
        //     if (msg) {
        //         msgs.push(msg);
        //     }
        // });
        // console.log('getMessages', msgs.length);
        //
        // return msgs;

        return [] as Message[]
    }

    getMessagesEx2V2(conversationTypes: number[], lines: number[], statuses: number[], fromIndex: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>,
        failCB: FailCallback) {
        protoProxy.getMessagesEx2V2(conversationTypes, lines, statuses, fromIndex, before, count, withUser, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesEx2V2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("getMessagesEx2V2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessagesByTimestamp(conversation: Conversation, contentTypes: number[], timestamp: number, before = true, count = 20, withUser = '') {
        // let protoMsgsStr: string = protoProxy.getMessagesByTimestamp(JSON.stringify(conversation), contentTypes, timestamp, before, count, withUser);
        // var protoMsgs = JSON.parse(protoMsgsStr);
        // let msgs = [];
        // protoMsgs.map(m => {
        //     let msg = Message.fromProtoMessage(m);
        //     if (msg) {
        //         msgs.push(msg);
        //     }
        // });
        // console.log('getMessagesByTimestamp', msgs.length);
        //
        // return msgs;

        return [] as Message[]
    }

    getMessagesByTimestampV2(conversation: Conversation, contentTypes: number[], timestamp: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>,
        failCB: FailCallback) {
        protoProxy.getMessagesByTimestampV2(JSON.stringify(conversation), contentTypes, timestamp, before, count, withUser, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesByTimestampV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("getMessagesByTimestampV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessagesByStatusV2(conversation: Conversation, statuses: number[], fromIndex: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>,
        failCB: FailCallback) {
        protoProxy.getMessagesByStatusV2(JSON.stringify(conversation), statuses, fromIndex, before, count, withUser, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesByStatusV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("getMessagesByStatusV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    // getUserMessages(userId, conversation, fromIndex, before = true, count = 20, contentTypes = []) {
    //     let protoMsgsStr: string = protoProxy.getUserMessages(userId, JSON.stringify(conversation), contentTypes, fromIndex, before, count);
    //     var protoMsgs = JSON.parse(protoMsgsStr);
    //     let msgs = [];
    //     protoMsgs.map(m => {
    //         let msg = Message.fromProtoMessage(m);
    //         if (msg) {
    //             msgs.push(msg);
    //         }
    //     });
    //     console.log('getMessages', msgs.length);
    //
    //     return msgs;
    // }

    getUserMessagesV2(userId: string, conversation: Conversation, contentTypes: number[], fromIndex: number, before: boolean, count: number, withUser: string,
        successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        protoProxy.getUserMessagesV2(userId, JSON.stringify(conversation), contentTypes, fromIndex, before, count, withUser, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getUserMessagesV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("getUserMessagesV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    // getUserMessagesEx(userId, conversationTypes, lines, fromIndex, before = true, count = 20, contentTypes = []) {
    //     let protoMsgsStr: string = protoProxy.getUserMessagesEx(userId, conversationTypes, lines, contentTypes, fromIndex, before, count);
    //     var protoMsgs = JSON.parse(protoMsgsStr);
    //     let msgs = [];
    //     protoMsgs.map(m => {
    //         let msg = Message.fromProtoMessage(m);
    //         if (msg) {
    //             msgs.push(msg);
    //         }
    //     });
    //     console.log('getMessages', msgs.length);
    //
    //     return msgs;
    // }

    getUserMessagesExV2(userId: string, conversationTypes: number[], lines: number[], contentTypes: number[], fromIndex: number, before: boolean, count: number, withUser: string,
        successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        protoProxy.getUserMessagesExV2(userId, conversationTypes, lines, contentTypes, fromIndex, before, count, withUser, (protoMsgsStr: string) => {
            let protoMsgs = JSON.parse(protoMsgsStr) as Record<string, Object>[];
            let msgs: Message[] = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getUserMessagesExV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode: number) => {
            console.log("getUserMessagesExV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessageById(messageId: number): Message | null {
        let mStr: string = protoProxy.getMessage(messageId);
        return Message.fromProtoMessage(JSON.parse(mStr));
    }

    getMessageByUid(messageUid: Long | string): Message | null {
        let mStr: string = protoProxy.getMessageByUid(Long.fromValue(messageUid).toString());
        return Message.fromProtoMessage(JSON.parse(mStr));
    }

    searchMessage(conversation: Conversation, keyword: string, withUser = ''): Message[] {
        let result: string = protoProxy.searchMessage(JSON.stringify(conversation), keyword, withUser);
        let msgs = JSON.parse(result) as Record<string, Object>[];
        let matchMsgs: Message[] = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m)!);
            });
        }

        return matchMsgs;
    }

    searchMessageEx(conversation: Conversation, keyword: string, desc: boolean, limit = 20, offset = 0, withUser = ''): Message[] {
        let result: string = protoProxy.searchMessageEx(JSON.stringify(conversation), keyword, desc, limit, offset, withUser);
        let msgs = JSON.parse(result) as Record<string, Object>[];
        let matchMsgs: Message[] = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m)!);
            });
        }

        return matchMsgs;
    }

    searchMentionedMessages(conversation: Conversation, keyword: string, desc: boolean, limit = 20, offset = 0): Message[] {
        let result: string = protoProxy.searchMentionedMessages(JSON.stringify(conversation), keyword, desc, limit, offset);
        let msgs = JSON.parse(result) as Record<string, Object>[];
        let matchMsgs: Message[] = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m)!);
            });
        }

        return matchMsgs;
    }

    searchMessageByTypes(conversation: Conversation, keyword: string, contentTypes: number[], desc: boolean = false, limit = 20, offset = 0, withUser = '') {
        if (!contentTypes) {
            contentTypes = [];
        }
        let result: string = protoProxy.searchMessageByTypes(JSON.stringify(conversation), keyword, contentTypes, desc, limit, offset, withUser);
        let msgs = JSON.parse(result) as Record<string, Object>[];
        let matchMsgs: Message[] = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m)!);
            });
        }

        return matchMsgs;
    }

    searchMessageByTypesAndTimes(conversation: Conversation, keyword: string, contentTypes: number[], startTime: number, endTime: number, desc: boolean = false, limit = 20, offset = 0,
        withUser = ''): Message[] {
        if (!contentTypes) {
            contentTypes = [];
        }
        let result: string = protoProxy.searchMessageByTypesAndTimes(JSON.stringify(conversation), keyword, contentTypes, startTime, endTime, desc, limit, offset, withUser);
        let msgs = JSON.parse(result) as Record<string, Object>[];
        let matchMsgs: Message[] = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m)!);
            });
        }

        return matchMsgs;
    }

    searchMessageEx2(conversationTypes: number[], lines: number[], contentTypes: number[], keyword: string, fromIndex: number, desc = false, count = 20, withUser = '') {
        if (!contentTypes) {
            contentTypes = [];
        }
        let result: string = protoProxy.searchMessageEx2(conversationTypes, lines, contentTypes, keyword, fromIndex, desc, count, withUser);
        let msgs = JSON.parse(result) as Record<string, Object>[];
        let matchMsgs: Message[] = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m)!);
            });
        }

        return matchMsgs;
    }

    searchMentionedMessageEx(conversationTypes: number[], lines: number[], keyword: string, desc = false, limit = 20, offset = 0): Message[] {
        if (!conversationTypes) {
            conversationTypes = [];
        }
        let result: string = protoProxy.searchMentionedMessagesEx(conversationTypes, lines, keyword, desc, limit, offset);
        let msgs = JSON.parse(result) as Record<string, Object>[];
        let matchMsgs: Message[] = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m)!);
            });
        }

        return matchMsgs;
    }

    async sendConversationMessage(conversation: Conversation, messageContent: MessageContent, toUsers: string[] = [], preparedCB: CallbackWithValue_2<number, number> | null = null,
        progressCB: CallbackWithValue_2<number, number> | null = null, uploadedCB: CallbackWithValue_1<string> | null = null, successCB: CallbackWithValue_2<Long, number> | null = null,
        failCB: FailCallback | null = null) {
        let message = new Message(conversation, messageContent);
        self.sendMessageEx(message, toUsers, preparedCB, progressCB, uploadedCB, successCB, failCB);
    }

    async sendMessage(message: Message, preparedCB: CallbackWithValue_2<number, number> | null = null, progressCB: CallbackWithValue_2<number, number> | null = null,
        uploadedCB: CallbackWithValue_1<string> | null = null, successCB: CallbackWithValue_2<Long, number> | null = null, failCB: FailCallback | null = null) {
        self.sendMessageEx(message, [], preparedCB, progressCB, uploadedCB, successCB, failCB);
    }

    // toUsers 用来实现定向消息
    async sendMessageEx(message: Message, toUsers: string[] = [], preparedCB: CallbackWithValue_2<number, number> | null, progressCB: CallbackWithValue_2<number, number> | null,
        uploadedCB: CallbackWithValue_1<string> | null, successCB: CallbackWithValue_2<Long, number> | null, failCB: FailCallback | null) {
        let strConv = JSON.stringify(message.conversation);
        message.content = message.messageContent!.encode();
        message.from = this.userId;

        let mediaMessageUploadCallback: Function;
        if (message.messageContent instanceof TextMessageContent && Config.SEND_LOG_COMMAND && Config.SEND_LOG_COMMAND.trim() && message.messageContent.content === Config.SEND_LOG_COMMAND.trim()) {
            let latestLogFilePath = this._getLatestLogFilePath();
            if (latestLogFilePath) {
                mediaMessageUploadCallback = (remoteUrl: string) => {
                    let textMessageContent = new TextMessageContent(remoteUrl);
                    this.sendConversationMessage(message.conversation!, textMessageContent);
                }
                let name = latestLogFilePath.substring((latestLogFilePath.lastIndexOf('/') + 1));
                // todo
                // fixme
                // size: require('fs').statSync(latestLogFilePath).size

                let mediaMessageContent = new FileMessageContent(latestLogFilePath, '', name, 0)
                message.messageContent = mediaMessageContent;
                message.content = mediaMessageContent.encode();
            }
        }
        if (message.messageContent instanceof MediaMessageContent
            && message.messageContent.localPath
            && !message.messageContent.remotePath
            && this.isTcpShortLink() && !this.isSupportBigFilesUpload()) {
            console.error('TCP短连接不支持内置对象存储，请把对象存储切换到其他类型')
            failCB && failCB(-1);
            return;
        }

        if (message.messageContent instanceof MediaMessageContent && (message.messageContent.localPath) && !message.messageContent.remotePath && this.isSupportBigFilesUpload()) {
            let insertedMsg = this.insertMessage(message.conversation!, message.messageContent, MessageStatus.Sending, false, toUsers, 0)!;
            // 有一个副作用，后续调用sendSavedMessage时，还会触发一次 SendMessage 事件
            self.eventEmitter!.emit(EventType.SendMessage, insertedMsg);
            preparedCB && preparedCB(insertedMsg.messageId, insertedMsg.timestamp);

            // image/jpeg
            this._uploadFile(insertedMsg, null, message.messageContent.localPath, null, message.messageContent.mediaType, (uploaded: number, total: number) => {
                progressCB && progressCB(uploaded, total);
            }, (remoteUrl: string) => {
                (insertedMsg.messageContent as MediaMessageContent).remotePath = remoteUrl;
                this.updateMessageContent(insertedMsg.messageId, insertedMsg.messageContent!);
                uploadedCB && uploadedCB(remoteUrl);
                protoProxy.sendSavedMessage(insertedMsg.messageId, 0, (messageUid: string, timestamp: string) => {
                    insertedMsg.messageUid = Long.fromValue(messageUid);
                    insertedMsg.timestamp = Long.fromValue(timestamp).toNumber();
                    insertedMsg.status = MessageStatus.Sent;
                    console.log('send saved msg success', messageUid, insertedMsg);
                    successCB && successCB(insertedMsg.messageUid, insertedMsg.timestamp);
                }, (err: number) => {
                    failCB && failCB(err)
                })
                mediaMessageUploadCallback && mediaMessageUploadCallback(remoteUrl);
            }, (err: number) => {
                this.updateMessageStatus(insertedMsg.messageId, MessageStatus.SendFailure);
                insertedMsg.status = MessageStatus.SendFailure;
                failCB && failCB(err);
            });
            return
        }

        if (message.messageContent instanceof MediaMessageContent) {
            // if (!message.messageContent.localPath && message.messageContent.file) {
            //     let file = message.messageContent.file;
            //     let filePath = path.join(os.tmpdir(), file.name);
            //     let buffer = Buffer.from(await file.arrayBuffer())
            //     require('fs').writeFileSync(filePath, buffer);
            //     message.messageContent.localPath = filePath;
            //
            //     message.content = message.messageContent.encode();
            // }
        }

        let strCont = JSON.stringify(message.content);
        let msgStr: string = protoProxy.sendMessage(strConv, strCont, toUsers, 0,
            (messageId: number, timestamp: number) => { //preparedCB
                message.messageId = messageId;
                message.timestamp = Long.fromValue(timestamp).toNumber();
            },
            (uploaded: number, total: number) => { //progressCB
                progressCB && progressCB(uploaded, total);
                // upload progress update
            },
            (mediaUrl: string) => {
                uploadedCB && uploadedCB(mediaUrl);
            },
            (messageUid: string, timestamp: string) => { //successCB
                message.status = MessageStatus.Sent;
                message.messageUid = Long.fromValue(messageUid);
                message.timestamp = Long.fromValue(timestamp).toNumber();
                // update remote url
                if (message.messageContent instanceof MediaMessageContent) {
                    let msg = self.getMessageById(message.messageId)!;
                    message.messageContent = msg.messageContent;
                }
                if (message.conversation!.type === ConversationType.ChatRoom) {
                    self.eventEmitter!.emit(EventType.MessageStatusUpdate, message);
                }
                successCB && successCB(Long.fromValue(messageUid), Long.fromValue(timestamp).toNumber());
            },
            (errorCode: number) => { //errorCB
                message.status = MessageStatus.SendFailure;
                if (message.conversation!.type === ConversationType.ChatRoom) {
                    self.eventEmitter!.emit(EventType.MessageStatusUpdate, message);
                }
                failCB && failCB(errorCode);
            });


        let msgObj = JSON.parse(msgStr) as Record<string, Object>;
        message.messageId = msgObj.messageId as number;
        message.timestamp = Long.fromValue(msgObj.timestamp as number).toNumber();
        preparedCB && preparedCB(message.messageId, Long.fromValue(msgObj.timestamp as number).toNumber());

        self.eventEmitter!.emit(EventType.SendMessage, message);
    }

    async sendSavedMessage(message: Message, expireDuration: number, successCB: CallbackWithValue_2<Long, number> | null = null, failCB: FailCallback | null = null) {
        protoProxy.sendSavedMessage(message.messageId, expireDuration,
            (messageUid: string, timestamp: string) => { //successCB
                message.status = MessageStatus.Sent;
                message.messageUid = Long.fromValue(messageUid);
                message.timestamp = Long.fromValue(timestamp).toNumber();
                // update remote url
                if (message.messageContent instanceof MediaMessageContent) {
                    let msg = self.getMessageById(message.messageId)!;
                    message.messageContent = msg.messageContent;
                }

                successCB && successCB(Long.fromValue(messageUid), Long.fromValue(timestamp).toNumber());
            },
            (errorCode: number) => { //errorCB
                message.status = MessageStatus.SendFailure;
                failCB && failCB(errorCode);
            });
    }

    // async readLocalFile(path, name) {
    //     let response = await fetch('file://' + path);
    //     let data = await response.blob();
    //     return new File([data], name);
    // }

    cancelSendingMessage(messageId: number): boolean {
        let canceled = protoProxy.cancelSendingMessage(messageId) === 1;
        if (!canceled) {
            let task = this.uploadingMap.get(messageId);
            if (task) {
                this.uploadingMap.delete(messageId)
                try {
                    task.delete()
                    canceled = true;
                } catch (e) {
                    console.log(e);
                }
            }
        }
        return canceled;
    }

    // cancelUploadBigFile(remoteUrl) {
    //     miscState.uploadBigFiles.forEach(upload => {
    //         if (upload.remoteUrl === remoteUrl) {
    //             let xhr = upload.xhr;
    //             upload.status = 3;
    //             upload.xhr = null;
    //             xhr && xhr.abort();
    //         }
    //     })
    // }

    // _uploadXMLHttpRequest(messageId, fileName, remoteUrl, progressCB, successCB, failCB) {
    //     let xhr = new XMLHttpRequest();
    //     xhr.upload.onprogress = (e) => {
    //         // console.log('upload.onprogress', Math.ceil(e.loaded / e.total * 100))
    //         let progress = e.loaded;
    //         let total = e.total;
    //         progressCB(progress, total);
    //     }
    //     xhr.onreadystatechange = (e) => {
    //         console.log('onr', xhr.readyState, xhr.status, e)
    //         if (xhr.readyState === 4) {
    //             if (xhr.status === 200) {
    //                 console.log('upload file success', fileName, remoteUrl);
    //                 this.uploadingMap.delete(messageId);
    //                 successCB(remoteUrl);
    //             } else {
    //                 console.log('upload file error', xhr.status);
    //                 this.uploadingMap.delete(messageId);
    //                 failCB && failCB(-1);
    //             }
    //         }
    //     }
    //     xhr.onerror = e => {
    //         console.log('upload file error', e);
    //         this.uploadingMap.delete(messageId);
    //         failCB && failCB(-1);
    //     }
    //
    //     if (messageId) {
    //         this.uploadingMap.set(messageId, xhr);
    //     }
    //     return xhr;
    // }

    // 大文件上传
    async _uploadFile(message: Message | null, fileName: string | null, filePath: string | null, data: string | null, mediaType: number, progressCB: CallbackWithValue_2<number, number>, successCB: CallbackWithValue_1<string>, failCB: FailCallback) {
        if (filePath) {
            if (!fileName) {
                fileName = filePath.substring(filePath.lastIndexOf('/') + 1);
            }
        } else if (data) {
            if (!fileName) {
                fileName = new Date().getTime() + ''
            }
            filePath = self.context!.cacheDir + '/' + fileName
            let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
            fs.writeSync(file.fd, atob(data).buffer)
            fs.closeSync(file)
        } else {
            console.log('filePath and data must not be null at the same time')
            failCB(-1)
        }

        let contentType = this._getContentType(mediaType, fileName!);
        this.getUploadMediaUrl(fileName!, mediaType, contentType, (uploadUrl: string, remoteUrl: string, backUploadUrl: string, serverType: number) => {
            // TODO
            // FIXME
            // uploadUrl = (self.connectedToMainNetwork() || !backUploadUrl) ? uploadUrl : backUploadUrl;
            console.log('getUploadMediaUrl', uploadUrl, remoteUrl, backUploadUrl, serverType)
            if (serverType === 0) {
                // 内置存储，不支持大文件上传
            } else if (serverType === 1) {
                // qiniu
                // TODO
                // FIXME
                // let ss = uploadUrl.split('?');
                // let url = ss[0];
                // let token = ss[1];
                // let key = ss[2];
                // xhr = this._uploadXMLHttpRequest(message ? message.messageId : 0, fileName, remoteUrl, progressCB, successCB, failCB);
                //
                // let formData = new FormData();
                // formData.append('key', key)
                // formData.append('token', token)
                // formData.append('file', file)
                // xhr.open('POST', url);
                // xhr.setRequestHeader('content-type', contentType);
                // xhr.setRequestHeader("content-disposition", `attachment; filename="${fileName}"`);
                // xhr.send(formData);
            } else {
                // 野火专业存储或阿里云
                // xhr = this._uploadXMLHttpRequest(message ? message.messageId : 0, fileName, remoteUrl, progressCB, successCB, failCB);
                // xhr.open('PUT', uploadUrl);
                //
                // xhr.setRequestHeader('content-type', contentType);
                // xhr.setRequestHeader("content-disposition", `attachment; filename="${fileName}"`);
                // xhr.send(file);

                let header = new Map<Object, string>();
                header.set('content-type', contentType);
                header.set('content-disposition', `attachment; filename="${fileName}"`);

                let uploadRequestOptions: request.UploadConfig = {
                    url: uploadUrl,
                    header: header,
                    method: 'PUT',
                    files: [{
                        filename: fileName!,
                        //uri前缀internal://cache 对应applicationCache.cacheDir目录
                        name: 'file',
                        uri: `internal://${filePath!.substring(filePath!.indexOf('/cache') + 1)}`,
                        type: contentType
                    }],
                    data: []
                };

                // Upload the file.
                request.uploadFile(self.context, uploadRequestOptions).then((data: request.UploadTask) => {
                    if (message) {
                        self.uploadingMap.set(message.messageId, data)
                    }

                    data.on('complete', (result: Array<request.TaskState>) => {
                        message && self.uploadingMap.delete(message!.messageId)
                        if (result && result.length >= 1) {
                            if (result[0].responseCode === 0) {
                                successCB(remoteUrl)
                            } else {
                                failCB(result[0].responseCode)
                            }
                        }
                    });
                    data.on('fail', (result: Array<request.TaskState>) => {
                        message && self.uploadingMap.delete(message.messageId)
                        if (result && result.length >= 1) {
                            // serverData.msg = '上传失败'
                            // reject(serverData);
                        }
                        failCB(-1)
                    })
                }).catch((err: Error) => {
                    // reject(serverData);
                    console.error('upload File error', err)
                    failCB(-1)
                });
            }

        }, (e: number) => {
            console.log('getUploadMediaUrl e', e)
        })
    }

    // 更新了原始消息的内容
    async recallMessage(messageUid: Long, successCB: SuccessCallback | null = null, failCB: FailCallback | null = null) {
        console.log('recall', messageUid);
        protoProxy.recall(messageUid.toString(),
            () => {
                console.log('recall, s', messageUid);
                if (successCB) {
                    successCB();
                }
                this.onRecallMessage(this.getUserId(), messageUid);
            },
            (errorCode: number) => {
                console.log('recall, f', messageUid, errorCode);
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async deleteRemoteMessage(messageUid: Long, successCB: SuccessCallback | null = null, failCB: FailCallback | null = null) {
        console.log('deleteRemoteMessageByUid', messageUid);
        protoProxy.deleteRemoteMessage(messageUid.toString(),
            () => {
                if (successCB) {
                    successCB();
                }
                this.onDeleteRemoteMessage(messageUid);
            },
            (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async updateRemoteMessageContent(messageUid: Long, messageContent: MessageContent, distribute: boolean, updateLocal: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        console.log('updateRemoteMessageContent', messageUid);
        let protoMessageContent = messageContent.encode();
        protoProxy.updateRemoteMessageContent(messageUid.toString(), JSON.stringify(protoMessageContent), distribute, updateLocal,
            () => {
                if (successCB) {
                    successCB();
                }
            },
            (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    deleteMessageById(messageId: number): boolean {
        let result: boolean = protoProxy.deleteMessage(messageId);
        if (result) {
            this.onMessageDeleted(messageId);
        }
        return result;
    }

    batchDeleteMessages(messageUids: string[]): boolean {
        return protoProxy.batchDeleteMessages(messageUids);
    }

    getUserOnlineState(userId: string): UserOnlineState | undefined {
        return self.userOnlineState.get(userId);
    }

    getUserOnlineStateMap(): Map<string, UserOnlineState> {
        return self.userOnlineState;
    }

    watchOnlineState(conversationType: number, targets: string[], duration: number, successCB: CallbackWithValue_1<UserOnlineState[]>, failCB: FailCallback) {
        protoProxy.watchOnlineState(conversationType, targets, duration,
            (strStates: string) => {
                let userOnlineStates = self._parseUserOnlineState(strStates);
                for (const state of userOnlineStates) {
                    self.userOnlineState.set(state.userId, state)
                }

                successCB && successCB(userOnlineStates);
            },
            (errorCode: number) => {
                failCB && failCB(errorCode);
            });
    }

    unwatchOnlineState(conversationType: number, targets: string[], successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.unwatchOnlineState(conversationType, targets,
            () => {
                if (successCB) {
                    successCB();
                }
            },
            (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    setMyCustomState(customState: number, customText: string, successCB: SuccessCallback, failCB: FailCallback) {
        let csSetting = customState + '-' + customText;
        this.setUserSetting(UserSettingScope.CustomState, "", csSetting, successCB, failCB);
    }

    isCommercialServer(): boolean {
        return protoProxy.isCommercialServer() === 1;
    }

    isReceiptEnabled(): boolean {
        return protoProxy.isReceiptEnabled() === 1
    }

    isGroupReceiptEnabled(): boolean {
        return protoProxy.isGroupReceiptEnabled() === 1;
    }

    isGlobalDisableSyncDraft(): boolean {
        return protoProxy.isGlobalDisableSyncDraft() === 1
    }

    isUserOnlineStateEnabled(): boolean {
        return protoProxy.isEnableUserOnlineState() === 1;
    }

    setDisableSyncDraft(disable: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        this.setUserSetting(UserSettingScope.DisableSyncDraft, '', disable ? '1' : '0', successCB, failCB)
    }

    isDisableSyncDraft(): boolean {
        return this.getUserSetting(UserSettingScope.DisableSyncDraft, '') === '1';
    }

    getAuthorizedMediaUrl(messageUid: Long, mediaType: number, mediaPath: string, successCB: CallbackWithValue_1<string>, failCB: FailCallback) {
        protoProxy.getAuthorizedMediaUrl(stringValue(messageUid), mediaType, mediaPath, successCB, failCB);
    }

    isSupportBigFilesUpload(): boolean {
        return protoProxy.isSupportBigFilesUpload() === 1;
    }

    getUploadMediaUrl(fileName: string, mediaType: number, contentType: string, successCB: (uploadUrl: string, remoteUrl: string, backUploadUrl: string, serverType: number) => void,
        failCB: FailCallback) {
        protoProxy.getUploadMediaUrl(fileName, mediaType, contentType, successCB, failCB);
    }

    getConversationFileRecords(conversation: Conversation, fromUser: string, beforeUid: Long, order: number, count: number, successCB: CallbackWithValue_1<FileRecord[]>, failCB: FailCallback) {
        protoProxy.getConversationFiles(JSON.stringify(conversation), fromUser, Long.fromValue(beforeUid)
            .toString(), order, count, (frsStr: string) => {
            let frs = JSON.parse(frsStr) as Record<string, Object>[];
            let fileRecords: FileRecord[] = [];
            frs.forEach(fr => {
                fileRecords.push(this._objStrToFileRecordObj(fr));
            })
            successCB && successCB(fileRecords);
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    _objStrToFileRecordObj(obj: Record<string, Object>) {

        let fileRecord = new FileRecord();
        fileRecord.userId = obj.userId as string;
        fileRecord.conversation = new Conversation(obj.conversationType as number, obj.target as string, obj.line as number);
        fileRecord.messageUid = Long.fromValue(obj.messageUid as string);
        fileRecord.name = obj.name as string;
        fileRecord.url = obj.url as string;
        fileRecord.size = obj.size as number;
        fileRecord.downloadCount = obj.downloadCount as number;
        fileRecord.timestamp = obj.timestamp as number;

        return fileRecord;
    }

    getMyFileRecords(beforeUid: Long, order: number, count: number, successCB: CallbackWithValue_1<FileRecord[]>, failCB: FailCallback) {
        protoProxy.getMyFiles(Long.fromValue(beforeUid).toString(), order, count, (frsStr: string) => {
            let frs = JSON.parse(frsStr) as Record<string, Object>[];
            let fileRecords: FileRecord[] = [];
            frs.forEach(fr => {
                fileRecords.push(this._objStrToFileRecordObj(fr));
            })
            successCB && successCB(fileRecords);
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    deleteFileRecord(messageUid: Long, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.deleteFileRecord(Long.fromValue(messageUid).toString(), () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    async clearMessages(conversation: Conversation) {
        protoProxy.clearMessages(JSON.stringify(conversation));
        let conversationInfo = this.getConversationInfo(conversation);
        self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    async clearUserMessages(userId: string, startTime: number, endTime: number) {
        protoProxy.clearUserMessages(userId, startTime, endTime);
    }

    async clearRemoteConversationMessages(conversation: Conversation, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.clearRemoteConversationMessages(JSON.stringify(conversation),
            () => {
                let conversationInfo = this.getConversationInfo(conversation);
                self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);
                successCB && successCB();
            },
            (errorCode: number) => {
                failCB && failCB(errorCode);
            }
        );
    }

    /**
     * 删除before时间之前的所有消息
     *
     * @param {Conversation} conversation
     * @param {String} before 时间精度到毫秒，字符串格式
     */
    async clearMessagesByTime(conversation: Conversation, before: number) {
        protoProxy.clearMessagesByTime(JSON.stringify(conversation), before);
        let conversationInfo = this.getConversationInfo(conversation);
        self.eventEmitter!.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    async clearMessagesKeepLatest(conversation: Conversation, count: number) {
        protoProxy.clearMessagesKeepLatest(JSON.stringify(conversation), count);
    }

    clearAllMessages(removeConversation: boolean) {
        protoProxy.clearAllMessages(removeConversation);
    }

    /**
     *
     * @param {Conversation} conversation
     * @param {MessageContent} messageContent
     * @param {number} status
     * @param {boolean} notify 是否触发onReceiveMessage
     * @param {[string]} toUsers
     * @param {Number} serverTime 服务器时间，精度到毫秒
     */
    insertMessage(conversation: Conversation, messageContent: MessageContent, status: number, notify = false, toUsers: string[] = [], serverTime = 0): Message | null {
        let protoMessageContent = messageContent.encode();
        let mStr: string = protoProxy.insertMessage(JSON.stringify(conversation), self.userId, JSON.stringify(protoMessageContent), status, notify, toUsers, serverTime);
        return Message.fromProtoMessage(JSON.parse(mStr));
    }

    insertMessageEx(messageUid: Long, conversation: Conversation, fromUser: string, messageContent: MessageContent, status: number, serverTime: number, localExtra = ''): Message | null {
        let protoMessageContent = messageContent.encode();
        let mStr: string = protoProxy.insertMessageEx(Long.fromValue(messageUid)
            .toString(), JSON.stringify(conversation), fromUser, JSON.stringify(protoMessageContent), status, serverTime, localExtra);
        return Message.fromProtoMessage(JSON.parse(mStr));
    }

    async updateMessageContent(messageId: number, messageContent: MessageContent) {
        let protoMessageContent = messageContent.encode();
        protoProxy.updateMessage(messageId, JSON.stringify(protoMessageContent));
    }

    async updateMessageStatus(messageId: number, status: number) {
        protoProxy.updateMessageStatus(messageId, status);
    }

    getMessageCount(conversation: Conversation): number {
        return protoProxy.getMessageCount(JSON.stringify(conversation));
    }

    async uploadMedia(fileName: string, fileOrData: string, mediaType: number, successCB: CallbackWithValue_1<string>, failCB: FailCallback, progressCB: CallbackWithValue_2<number, number>) {
        if (this.isTcpShortLink() && !this.isSupportBigFilesUpload()) {
            console.error('TCP短连接不支持内置对象存储，请把对象存储切换到其他类型')
            failCB && failCB(-1);
            return;
        }
        if (this.isTcpShortLink() || this.isSupportBigFilesUpload()) {
            this._uploadFile(null, fileName, null, fileOrData, mediaType, progressCB, successCB, failCB);
        } else {
            protoProxy.uploadMedia(fileName, fileOrData, mediaType,
                (remoteUrl: string) => {
                    if (successCB) {
                        successCB(remoteUrl);
                    }
                },
                (errorCode: number) => {
                    if (failCB) {
                        failCB(errorCode);
                    }
                },
                (current: number, total: number) => {
                    if (progressCB) {
                        progressCB(current, total);
                    }
                });
        }
    }

    sendConferenceRequest(sessionId: string, roomId: string, request: string, data: string, advance: boolean, callback: CallbackWithValue_2<number, string | null>) {
        protoProxy.sendConferenceRequest('' + sessionId, roomId, request, data,
            (resp: string) => {
                callback && callback(0, resp);
            },
            (errorCode: number) => {
                callback && callback(errorCode, null)
            }, advance);
    }

    searchFiles(keyword: string, conversation: Conversation, fromUser: string, beforeMessageId: number, order: number, count: number, successCB: CallbackWithValue_1<FileRecord[]>,
        failCB: FailCallback) {
        protoProxy.searchFiles(keyword, conversation ? JSON.stringify(conversation) : '', fromUser, Long.fromValue(beforeMessageId)
            .toString(), order, count,
            (files: string) => {
                let frs = JSON.parse(files) as Record<string, Object>[];

                let fileRecords: FileRecord[] = [];
                frs.forEach(fr => {
                    fileRecords.push(this._objStrToFileRecordObj(fr));
                })
                successCB && successCB(fileRecords);
            },
            (errorCode: number) => {
                failCB && failCB(errorCode);
            })
    }

    searchMyFiles(keyword: string, beforeMessageUid: Long, order: number, count: number, successCB: CallbackWithValue_1<FileRecord[]>, failCB: FailCallback) {
        protoProxy.searchMyFiles(keyword, Long.fromValue(beforeMessageUid).toString(), order, count,
            (files: string) => {
                let frs = JSON.parse(files) as Record<string, Object>[];

                let fileRecords: FileRecord[] = [];
                frs.forEach(fr => {
                    fileRecords.push(this._objStrToFileRecordObj(fr));
                })
                successCB && successCB(fileRecords);
            },
            (errorCode: number) => {
                failCB && failCB(errorCode);
            });
    }

    getHost(): string {
        return protoProxy.getHost();
    }

    async createSecretChat(userId: string, successCB: CallbackWithValue_2<string, number>, failCB: FailCallback) {
        protoProxy.createSecretChat(userId,
            (targetId: string, line: number) => {
                if (successCB) {
                    successCB(targetId, line);
                }
            },
            (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            }
        );
    }

    async destroySecretChat(targetId: string, successCB: SuccessCallback | null = null, failCB: FailCallback | null = null) {
        protoProxy.destroySecretChat(targetId,
            () => {
                if (successCB) {
                    successCB();
                }
            },
            (errorCode: number) => {
                if (failCB) {
                    failCB(errorCode);
                }
            }
        );
    }

    getSecretChatInfo(targetId: string): SecretChatInfo | null {
        let secretChatInfoStr: string = protoProxy.getSecretChatInfo(targetId);
        if (!secretChatInfoStr) {
            return null;
        }
        let obj = assign(new SecretChatInfo(), JSON.parse(secretChatInfoStr)) as SecretChatInfo;
        obj.targetId = targetId;
        return obj;
    }

    getAuthCode(appId: string, appType: number, host: string, successCB: CallbackWithValue_1<string>, failCB: FailCallback) {
        protoProxy.getAuthCode(appId, appType, host, (authCode: string) => {
            successCB && successCB(authCode);
        }, (err: number) => {
            failCB && failCB(err);
        });
    }

    //public void configApplication(String appId, int appType, long timestamp, String nonceStr, String signature, GeneralCallback callback) {
    configApplication(appId: string, appType: number, timestamp: number, nonceStr: string, signature: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.configApplication(appId, appType, timestamp, nonceStr, signature, () => {
            successCB && successCB();
        }, (err: number) => {
            failCB && failCB(err);
        });
    }

    //byte[]
    // FIXME  mediaDatas 类型不知道对不对
    decodeSecretChatMediaData(targetId: string, mediaDatas: string): string {
        return protoProxy.decodeSecretChatMediaData(targetId, mediaDatas);
    }

    //byte[]
    encodeSecretChatMediaData(targetId: string, mediaDatas: string): string {
        return protoProxy.encodeSecretChatMediaData(targetId, mediaDatas);
    }

    setSecretChatBurnTime(targetId: string, ms: number) {
        protoProxy.setSecretChatBurnTime(targetId, ms);
    }

    isEnableSecretChat() {
        return protoProxy.isEnableSecretChat() === 1;
    }

    getAppPath(): string {
        return protoProxy.getAppPath();
    }

    isUserEnableSecretChat(): boolean {
        return protoProxy.isUserEnableSecretChat() === 1;
    }

    async setUserEnableSecretChat(enable: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.setUserEnableSecretChat(enable, () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        });
    }

    beginTransaction(): boolean {
        return protoProxy.beginTransaction() === 1;
    }

    commitTransaction(): boolean {
        return protoProxy.commitTransaction() === 1;
    }

    // TODO
    // FIXME
    rollbackTransaction(): boolean {
        //return protoProxy.roolbackTransaction();
        return false
    }

    requireLock(lockId: string, duration: number, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.requireLock(lockId, duration, () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        })
    }

    releaseLock(lockId: string, successCB: SuccessCallback, failCB: FailCallback) {
        protoProxy.releaseLock(lockId, () => {
            successCB && successCB();
        }, (errorCode: number) => {
            failCB && failCB(errorCode);
        })
    }

    connectedToMainNetwork() {
        if (self.doubleNetworkStrategy === 1) {
            return true;
        } else if (self.doubleNetworkStrategy === 2) {
            return false;
        } else {
            return self._connectedToMainNetwork;
        }
    }

    _setupEventListeners() {
        protoProxy.setConnectionStatusListener(self.onConnectionChanged)
        protoProxy.setConnectToServerListener(self.onConnectedToServer)
        protoProxy.setReceiveMessageListener(self.onReceiveMessage, self.onRecallMessage, self.onDeleteRemoteMessage, self.onUserReceivedMessage, self.onUserReadedMessage);

        // protoProxy.setProtoEventListener('onSendMessage', (message) => {
        //     let msg = Message.fromProtoMessage(JSON.parse(message));
        //     self.eventEmitter!.emit(EventType.SendMessage, msg);
        // });

        // protoProxy.setProtoEventListener('onMessageStatusUpdate', (message) => {
        //     let msg = Message.fromProtoMessage(JSON.parse(message));
        //     self.eventEmitter!.emit(EventType.MessageStatusUpdate, msg);
        // });

        protoProxy.setConferenceEventListener(self.onConferenceEvent);
        protoProxy.setOnlineEventListener(self.onOnlineEvent);
        protoProxy.setUserInfoUpdateListener(self.onUserInfoUpdate);

        protoProxy.setFriendUpdateListener(self.onFriendListUpdate);

        protoProxy.setFriendRequestListener(self.onFriendRequestUpdate);
        protoProxy.setGroupInfoUpdateListener(self.onGroupInfoUpdate);
        protoProxy.setSettingUpdateListener(self.onSettingUpdate);
        protoProxy.setChannelInfoUpdateListener(self.onChannelInfoUpdate);
        protoProxy.setGroupMemberUpdateListener(self.onGroupMemberUpdateListener);
        protoProxy.setSecretChatStateListener(self.onSecretChatStateChangedListener);
        protoProxy.setSecretMessageBurnStateListener(self.onSecretMessageStartBurningListener, self.onSecretMessageBurnedListener)
        protoProxy.setSecretMessageBurnStateListener(self.onSecretMessageStartBurningListener, self.onSecretMessageBurnedListener);
    }

    _getLatestLogFilePath() {
        // TODO
        // FIXME
        // let appPath = this.getAppPath();
        // const fileNames = require('fs').readdirSync(appPath)
        // const logFiles = fileNames.filter(fn => fn.endsWith(".xlog")).sort((a, b) => a > b ? 1 : -1)
        // return logFiles.length > 0 ? appPath + '/' + logFiles[logFiles.length - 1] : null;
        return ''
    }

    // 预加载数据
    // 拉取会话相关用户、群信息
    // 自己的用户信息
    // 获取所有好友、好友请求的用户信息
    _preloadDefaultData() {
        let requests = self.getIncommingFriendRequest()
        let userIdSet: Set<string> = new Set();
        requests.forEach(fr => {
            userIdSet.add(fr.target);
        });
        requests = self.getOutgoingFriendRequest()
        requests.forEach(fr => {
            userIdSet.add(fr.target);
        });

        let friendIds = self.getMyFriendList(false);
        friendIds.forEach(uid => userIdSet.add(uid));

        let conversationInfoList = self.getConversationInfoList([0, 1, 3], [0, 1, 2]);
        let groupIdIds: string[] = [];
        let channelIds: string[] = [];
        conversationInfoList.forEach(info => {
            if (info.conversation!.type === ConversationType.Single) {
                userIdSet.add(info.conversation!.target);
            } else if (info.conversation!.type === ConversationType.Group) {
                groupIdIds.push(info.conversation!.target);
            } else if (info.conversation!.type === ConversationType.Channel) {
                channelIds.push(info.conversation!.target)
            }
            if (info.lastMessage && info.lastMessage.from) {
                userIdSet.add(info.lastMessage.from);
            }
        })
        let uids = Array.from(userIdSet);
        console.log('to preload userIds', uids, userIdSet)
        for (let i = 0; i < uids.length / 2000; i++) {
            self.getUserInfos(uids.slice(2000 * i, (i + 1) * 2000), '');
            console.log('to preload', uids.slice(2000 * i, (i + 1) * 2000))
        }

        console.log('to preload groupIds', groupIdIds)
        self.getGroupInfos(groupIdIds, false)
        groupIdIds.forEach(groupId => {
            self.getGroupMembers(groupId, false);
        })
        channelIds.forEach(channelId => {
            self.getChannelInfo(channelId)
        })

        let estimatedTime = 0;
        // 每 2000 人 5 秒
        estimatedTime += Math.round(uids.length / 2000) * 4
        // 每 10 个群 2 秒
        estimatedTime += Math.round(groupIdIds.length / 10) * 2

        return estimatedTime * 1000;
    }

    _preloadGroupMemberUserInfos(memberIds: string[]) {
        for (let i = 0; i < memberIds.length / 2000; i++) {
            self.getUserInfos(memberIds.slice(2000 * i, (i + 1) * 2000), '');
            console.log('to preload', memberIds.slice(2000 * i, (i + 1) * 2000))
        }
    }

    _getStore() {
        console.log('not support')
        return null;
    }

    _getContentType(mediaType: number, fileName: string) {
        let contentType = "application/octet-stream";
        if (fileName) {
            let suffix = fileName.substring(fileName.lastIndexOf('.') + 1)
            if (suffix === "jpg" || suffix === "jpeg") {
                contentType = "image/jpeg";
            } else if (suffix === "gif") {
                contentType = "image/gif";
            } else if (suffix === "png") {
                contentType = "image/png";
            } else if (suffix === "mp3") {
                contentType = "audio/mpeg";
            } else if (suffix === "mp4") {
                contentType = "video/mp4";
            } else if (suffix === "doc") {
                contentType = "application/vnd.ms-word";
            } else if (suffix === "docx") {
                contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            } else if (suffix === "xls") {
                contentType = "application/vnd.ms-xls";
            } else if (suffix === "xlsx") {
                contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            } else if (suffix === "ppt") {
                contentType = "application/vnd.ms-powerpoint";
            } else if (suffix === "pptx") {
                contentType = "application/vnd.openxmlformats-officedocument.presentationml.presentation";
            } else if (suffix === "pps") {
                contentType = "application/vnd.ms-powerpoint";
            } else if (suffix === "pdf") {
                contentType = "application/pdf";
            } else if (suffix === "xml") {
                contentType = "application/vnd.ms-xml";
            } else {
                // return "application/octet-stream";
            }
        } else {
            if (mediaType === 1) {
                contentType = "image/jpeg";
            } else if (mediaType === 2) {
                contentType = "audio/amr";
            } else if (mediaType === 3) {
                contentType = "video/mp4";
            }
        }
        return contentType;
    }
}

const self = new WfcImpl();

export default self;
