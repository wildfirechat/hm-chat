// @ts-nocheck
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

import request from '@ohos.request';


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
    users = new Map();
    groups = new Map();
    isLogined = false;
    needPreloadDefaultData = false;
    doubleNetworkStrategy = 0;
    _connectedToMainNetwork = false;
    eventEmitter;
    context;
    uploadingMap = new Map();

    onConnectionChanged(status) {
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
                    self.eventEmitter.emit(EventType.ConnectionStatusChanged, status);
                }, estimatedTime)
            } else {
                self.connectionStatus = status;
                self.eventEmitter.emit(EventType.ConnectionStatusChanged, status);
            }
        } else {
            self.connectionStatus = status;
            self.eventEmitter.emit(EventType.ConnectionStatusChanged, status);
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

    onConnectedToServer(host, ip, port, mainNw) {
        console.log('connected to server', host, ip, port, mainNw);
        self.eventEmitter.emit(EventType.ConnectedToServer, host, ip, port);
    }

    onReceiveMessage(messages, hasMore) {
        if (!self.isLogined) {
            return;
        }
        // receiving
        if (self.connectionStatus === 2) {
            return;
        }

        var msgs = JSON.parse(messages);
        msgs.forEach(m => {
            let msg = Message.fromProtoMessage(m);
            if (msg.messageContent instanceof MarkUnreadMessageContent && msg.from === self.userId) {
                let markMsg = msg.messageContent;
                let conversation = msg.conversation;
                protoProxy.setLastReceivedMessageUnRead(JSON.stringify(conversation), stringValue(markMsg.messageUid), stringValue(markMsg.timestamp));
            }
            if (msg) {
                self.eventEmitter.emit(EventType.ReceiveMessage, msg);
            }
        });
    }

    onConferenceEvent(event) {
        self.eventEmitter.emit(EventType.ConferenceEvent, event)
    }

    onOnlineEvent(event) {
        let userOnlineStates = self._parseUserOnlineState(event);
        self.eventEmitter.emit(EventType.UserOnlineEvent, userOnlineStates);
    }

    _parseUserOnlineState(userOnlineStateStr) {
        let userOnlineStates = [];
        let states = JSON.parse(userOnlineStateStr);
        states.forEach(s => {
            let userOnlineState = new UserOnlineState();
            userOnlineState.userId = s.userId;
            userOnlineState.customState = new UserCustomState();
            userOnlineState.customState.state = s.customState;
            userOnlineState.customState.text = s.customText;
            userOnlineState.clientStates = [];

            if (s.states) {
                s.states.forEach(ss => {
                    let clientState = new UserClientState();
                    clientState.state = ss.state;
                    clientState.platform = ss.platform;
                    clientState.lastSeen = Long.fromValue(ss.lastSeen);
                    userOnlineState.clientStates.push(clientState)
                })
            }
            userOnlineStates.push(userOnlineState);
        })
        return userOnlineStates;
    }

    onGroupInfoUpdate(groupListIds) {
        if (!self.isLogined) {
            return;
        }

        let groupIdArray = JSON.parse(groupListIds);
        let groupInfos = self.getGroupInfos(groupIdArray, false);
        groupInfos.forEach(gi => {
            self.groups.set(gi.target, gi);
        })

        self.eventEmitter.emit(EventType.GroupInfosUpdate, groupInfos);
    }

    onChannelInfoUpdate(channelListIds) {
        if (!self.isLogined) {
            return;
        }
        let channelIdArray = JSON.parse(channelListIds);

        let channelInfos = [];
        channelIdArray.forEach((channelId => {
            channelInfos.push(self.getChannelInfo(channelId, false));
        }))
        self.eventEmitter.emit(EventType.ChannelInfosUpdate, channelInfos)
    }

    onGroupMemberUpdateListener(groupId, groupMembersStr) {
        if (!self.isLogined) {
            return;
        }
        let members = [];
        let memberIds = [];
        let arr = JSON.parse(groupMembersStr);
        arr.forEach(e => {
            members.push(Object.assign(new GroupMember(), e));
            memberIds.push(e.memberId)
        });
        self._preloadGroupMemberUserInfos(memberIds);

        self.eventEmitter.emit(EventType.GroupMembersUpdate, groupId, members);
    }

    onSettingUpdate() {
        if (!self.isLogined) {
            return;
        }
        // TODO 具体更新的信息
        self.eventEmitter.emit(EventType.SettingUpdate);
    }

    onRecallMessage(operatorUid, messageUid) {
        if (!self.isLogined) {
            return;
        }
        self.eventEmitter.emit(EventType.RecallMessage, operatorUid, Long.fromValue(messageUid));
    }

    onDeleteRemoteMessage(messageUid) {
        if (!self.isLogined) {
            return;
        }
        self.eventEmitter.emit(EventType.MessageDeleted, Long.fromValue(messageUid));
    }

    onUserReceivedMessage(receivedMapStr) {
        if (!self.isLogined) {
            return;
        }
        let deliveries = JSON.parse(receivedMapStr);
        let deliveryMap = new Map();
        deliveries.forEach(e => {
            deliveryMap.set(e.key, e.value);
        });
        self.eventEmitter.emit(EventType.MessageReceived, deliveryMap);
        console.log('onreceive', deliveryMap);
    }

    onUserReadedMessage(readedMapStr) {
        if (!self.isLogined) {
            return;
        }
        // [{"userId":"GNMtGtZZ","conversationType":1,"target":"Jl8jLjkk","line":0,"readDt":1590308777299} ]
        let arr = JSON.parse(readedMapStr);
        let readEntries = [];
        arr.forEach(e => {
            let entry = new ReadEntry();
            entry.userId = e.userId;
            entry.conversation = new Conversation(e.conversationType, e.target, e.line);
            entry.readTime = e.readDt;
            readEntries.push(entry);
        })
        self.eventEmitter.emit(EventType.MessageRead, readEntries);
        console.log('onread', readEntries)
    }

    onMessageDeleted(messageId) {
        if (!self.isLogined) {
            return;
        }
        self.eventEmitter.emit(EventType.DeleteMessage, messageId);
    }

    onUserInfoUpdate(userIds) {
        if (!self.isLogined) {
            return;
        }
        let userIdArray = JSON.parse(userIds);
        let userInfos = self.getUserInfos(userIdArray)
        userInfos.forEach(ui => {
            self.users.set(ui.uid, ui);
        })
        self.eventEmitter.emit(EventType.UserInfosUpdate, userInfos);
    }

    onFriendListUpdate(friendListIds) {
        if (!self.isLogined) {
            return;
        }
        console.log('friendList update, ids', friendListIds);
        let ids = JSON.parse(friendListIds);
        ids.forEach((uid) => {
            self.users.delete(uid);
        });
        self.eventEmitter.emit(EventType.FriendListUpdate, ids);
    }

    onFriendRequestUpdate(newRequests = '[]') {
        if (!self.isLogined) {
            return;
        }
        console.log('friend request list update, new incomming requests', newRequests);
        let ids = JSON.parse(newRequests);
        self.eventEmitter.emit(EventType.FriendRequestUpdate, ids);
    }

    onSecretChatStateChangedListener(targetId) {
        console.log('onSecretChatStateChangedListener', targetId);
        self.eventEmitter.emit(EventType.SecretChatStateChange, targetId);
    }

    onSecretMessageStartBurningListener(targetId, playedMessageId) {
        console.log('onSecretMessageStartBurningListener', targetId, playedMessageId);
        self.eventEmitter.emit(EventType.SecretChatStartBurn, targetId, playedMessageId);
    }

    onSecretMessageBurnedListener(messageIds) {
        console.log('onSecretMessageBurnedListener', messageIds);
        self.eventEmitter.emit(EventType.SecretChatMessageBurned, messageIds)
    }

    init(context, eventHub, dbPath) {
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

    registerMessageContent(name, flag, type, clazz) {
        MessageConfig.MessageContents.push(
            {
                name: name,
                flag: flag,
                type: type,
                contentClazz: clazz,
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

    useTcpShortLink() {
        protoProxy.useTcpShortLink();
    }

    /**
     * 是否启动 TCP 短连接
     * @return {*}
     */
    isTcpShortLink() {
        return protoProxy.isTcpShortLink() === 1;
    }

    setPlatform(platform) {
        protoProxy.setPlatform(platform);
    }

    connect(userId, token) {
        if (!self.userId) {
            self.userId = userId;
            let status = this.getConnectionStatus();
            if (status === ConnectionStatus.ConnectionStatusConnected) {
                this.onConnectionChanged(status);
                return false;
            }
        }
        self.userId = userId;

        let lastActiveTime = protoProxy.connect(userId, token);
        console.log('lastActiveTime', lastActiveTime);
        // 超过一周没有活跃，就预加载数据
        if (new Date().getTime() / 1000 - lastActiveTime > 7 * 24 * 60 * 60) {
            self.needPreloadDefaultData = true;
        }
        return lastActiveTime;
        // for testing your code
        // self.test();
    }

    setProxyInfo(host, ip, port, username, password) {
        protoProxy.setProxyInfo(host, ip, port, username, password);
    }

    setPackageName(packageName) {
        protoProxy.setPackageName(packageName);
    }

    setDeviceToken(pushType, token) {
        protoProxy.setDeviceToken(pushType, token);
    }

    disconnect(disablePush, cleanSession) {
        self.userId = '';
        protoProxy.disconnect(disablePush, cleanSession);


        //sleep 1 second wait disconnect with im server
        var now = new Date();
        var exitTime = now.getTime() + 1000;
        while (true) {
            now = new Date();
            if (now.getTime() > exitTime)
                return;
        }
    }

    registerDefaultMessageContents() {
        MessageConfig.MessageContents.map((e) => {
            protoProxy.registerMessageFlag(e.type, e.flag);
        });
    }

    getClientId() {
        return protoProxy.getClientId();
    }

    getProtoRevision() {
        return protoProxy.getProtoRevision();
    }

    getUserId() {
        return self.userId;
    }

    getServerDeltaTime() {
        return protoProxy.getServerDeltaTime();
    }

    isLogin() {
        // return proto.isLogin();
        return self.isLogined;
    }

    getConnectionStatus() {
        return protoProxy.getConnectionStatus();
    }

    setBackupAddressStrategy(strategy) {
        self.doubleNetworkStrategy = strategy;
        if (strategy === 0) {
            self._connectedToMainNetwork = true;
        }
        protoProxy.setBackupAddressStrategy(strategy);
    }

    setBackupAddress(backupHost, backupPort) {
        protoProxy.setBackupAddress(backupHost, backupPort);
    }

    setProtoUserAgent(userAgent) {
        if (typeof userAgent !== 'string') {
            console.error('setProtoUserAgent userAgent must be string');
            return;
        }
        protoProxy.setUserAgent(userAgent);
    }

    addHttpHeader(header, value) {
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

    getMyGroupList() {
        let settings = this.getUserSettings(UserSettingScope.FavoriteGroup);
        let groupInfos = settings.filter(setting => setting.value === '1')
            .map(setting => this.getGroupInfo(setting.key, false));
        return groupInfos;
    }

    /**
     * @param {string} userId
     * @param {boolean} fresh
     */
    getUserInfo(userId, fresh = false, groupId = '') {
        if (!userId || userId === '') {
            return new NullUserInfo('');
        }
        let userInfo;
        if (!fresh && (!groupId || groupId === '')) {
            userInfo = self.users.get(userId);
            if (userInfo) {
                return userInfo;
            }
        }

        // console.log('getuserInfo', userId, fresh, groupId);
        let userInfoStr = protoProxy.getUserInfo(userId, fresh, groupId);
        if (userInfoStr === '') {
            userInfo = new NullUserInfo(userId);
        } else {
            userInfo = Object.assign(new UserInfo(), JSON.parse(userInfoStr));
        }
        if (!groupId || groupId === '') {
            self.users.set(userInfo.uid, userInfo);
        }
        return userInfo;
    }

    getUserInfos(userIds, groupId = '') {
        let users = [];
        let userInfoStrs = protoProxy.getUserInfos(userIds, groupId);
        if (userInfoStrs && userInfoStrs !== '') {
            let tmp = JSON.parse(userInfoStrs);
            tmp.forEach((u) => {
                let userInfo = Object.assign(new UserInfo(), u);
                users.push(userInfo)
            });
        }
        return users;
    }

    async getUserInfoEx(userId, refresh, successCB, failCB) {
        protoProxy.getUserInfoEx(userId, refresh, (userInfoStr) => {
            const userInfo = Object.assign(new UserInfo(), JSON.parse(userInfoStr));

            if (successCB) {
                successCB(userInfo);
            }
        }, (errorCode) => {
            if (errorCode) {
                failCB(errorCode);
            }

        });
    }

    async searchUser(keyword, searchType, page, successCB, failCB) {
        protoProxy.searchUser(keyword, searchType, page, (result) => {
            let userListStr = JSON.parse(result);
            let userList = [];
            if (userListStr && userListStr.length > 0) {
                userListStr.forEach(u => {
                    userList.push(Object.assign(new UserInfo(), u));
                });
            }
            if (successCB) {
                successCB(keyword, userList);
            }
        }, (errorCode) => {
            if (errorCode) {
                failCB(errorCode);
            }

        });
    }

    searchFriends(keyword) {
        let result = protoProxy.searchFriends(keyword);
        let userListStr = JSON.parse(result);
        let userList = [];
        if (userListStr && userListStr.length > 0) {
            userListStr.forEach(u => {
                userList.push(Object.assign(new UserInfo(), u));
            });
        }
        return userList;
    }

    searchGroups(keyword) {
        let result = protoProxy.searchGroups(keyword);
        let groupSearchResultListStr = JSON.parse(result);
        let groupSearchResultList = [];
        if (groupSearchResultListStr && groupSearchResultListStr.length > 0) {
            groupSearchResultListStr.forEach(g => {
                groupSearchResultList.push(GroupSearchResult.fromProtoGroupSearchResult(g));
            });
        }
        return groupSearchResultList;
    }

    getIncommingFriendRequest() {
        let result = protoProxy.getIncommingFriendRequest();
        let friendRequestListStr = JSON.parse(result);
        let firendRequestList = [];
        if (friendRequestListStr && friendRequestListStr.length > 0) {
            friendRequestListStr.forEach((r) => {
                firendRequestList.push(Object.assign(new FriendRequest(), r));
            });
        }
        return firendRequestList;
    }

    getOutgoingFriendRequest() {
        let result = protoProxy.getOutgoingFriendRequest();
        let friendRequestListStr = JSON.parse(result);
        let firendRequestList = [];
        if (friendRequestListStr && friendRequestListStr.length > 0) {
            friendRequestListStr.forEach((r) => {
                firendRequestList.push(Object.assign(new FriendRequest(), r));
            });
        }
        return firendRequestList;
    }

    getOneFriendRequest(userId, incoming) {
        let result = protoProxy.getFriendRequest(userId, incoming);
        return JSON.parse(result);
    }

    loadFriendRequestFromRemote() {
        protoProxy.loadFriendRequestFromRemote();
    }

    getFavUsers() {
        let result = protoProxy.getFavUsers();
        return JSON.parse(result);
    }

    isFavUser(userId) {
        return protoProxy.isFavUser(userId) === 1;
    }

    setFavUser(userId, fav, successCB, failCB) {
        protoProxy.setFavUser(userId, fav, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    loadRemoteMessages(conversation, contentTypes, beforeUid, count, successCB, failCB) {
        if (!contentTypes) {
            contentTypes = [];
        }
        protoProxy.getRemoteMessages(JSON.stringify(conversation), stringValue(beforeUid), count, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('loadRemoteMessages', stringValue(beforeUid), msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("loadRemoteMessages failure:", errorCode);
            failCB && failCB(errorCode);
        }, contentTypes);
    }

    loadRemoteMessage(messageUid, successCB, failCB) {
        protoProxy.getRemoteMessage(stringValue(messageUid), (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
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
        }, (errorCode) => {
            console.log("loadRemoteMessage failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getUnreadFriendRequestCount() {
        return protoProxy.getUnreadFriendRequestStatus();
    }

    clearUnreadFriendRequestStatus() {
        protoProxy.clearUnreadFriendRequestStatus();
    }

    async deleteFriend(userId, successCB, failCB) {
        protoProxy.deleteFriend(userId, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            failCB(errorCode);
        });
    }

    async handleFriendRequest(userId, accept, extra, successCB, failCB) {
        protoProxy.handleFriendRequest(userId, accept, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }

        }, extra);
    }

    isBlackListed(userId) {
        return protoProxy.isBlackListed(userId) === 1;
    }

    getBlackList() {
        let result = protoProxy.getBlackList();
        return JSON.parse(result);
    }

    setBlackList(userId, block, successCB, failCB) {
        protoProxy.setBlackList(userId, block, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getMyFriendList(fresh = false) {
        let idsStr = protoProxy.getMyFriendList(fresh);
        if (idsStr !== '') {
            return JSON.parse(idsStr);
        }
        return [];
    }

    getFriendList(fresh = false) {
        let result = protoProxy.getFriendList(fresh);
        return JSON.parse(result);
    }

    getFriendAlias(userId) {
        return protoProxy.getFriendAlias(userId);
    }

    async setFriendAlias(userId, alias, successCB, failCB) {
        protoProxy.setFriendAlias(userId, alias, successCB, failCB);
    }

    async createGroup(groupId, groupType, name, portrait, groupExtra = '', memberIds = [], memberExtra = '', lines = [0], notifyContent, successCB, failCB) {
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
            (groupId) => {
                if (successCB) {
                    successCB(groupId);
                }
            },
            (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async setGroupManager(groupId, isSet, memberIds = [], lines = [0], notifyContent, successCB, failCB) {
        let payload = notifyContent ? notifyContent.encode() : '';
        let notifyContentStr = JSON.stringify(payload);
        protoProxy.setGroupManager(groupId, isSet, memberIds, lines, notifyContentStr, successCB, failCB);
    }

    async muteOrAllowGroupMembers(groupId, isSet, isAllow, memberIds, notifyLines = [0], notifyContent, successCB, failCB) {
        if (isAllow) {
            let payload = notifyContent ? notifyContent.encode() : '';
            let notifyContentStr = JSON.stringify(payload);
            protoProxy.allowGroupMember(groupId, isSet, memberIds, notifyLines, notifyContentStr, () => {
                successCB && successCB();
            }, (errorCode) => {
                failCB && failCB(errorCode);
            });
        } else {
            let payload = notifyContent ? notifyContent.encode() : '';
            let notifyContentStr = JSON.stringify(payload);
            protoProxy.muteGroupMember(groupId, isSet, memberIds, notifyLines, notifyContentStr, () => {
                successCB && successCB();
            }, (errorCode) => {
                failCB && failCB(errorCode);
            });
        }
    }

    async setGroupRemark(groupId, remark, successCB, failCB) {
        protoProxy.setGroupRemark(groupId, remark, () => {
            successCB && successCB();
        }, (errorCode) => {
            failCB && failCB(errorCode);
        });
    }

    getGroupRemark(groupId) {
        return protoProxy.setGroupRemark(groupId);
    }

    getGroupInfo(groupId, fresh = false) {
        let groupInfo;
        if (!fresh) {
            groupInfo = self.groups.get(groupId);
            if (groupInfo) {
                return groupInfo;
            }
        }

        console.log('get groupInfo', groupId, fresh);
        let groupInfoStr = protoProxy.getGroupInfo(groupId, fresh);
        if (groupInfoStr === '') {
            return new NullGroupInfo(groupId);
        } else {
            groupInfo = Object.assign(new GroupInfo(), JSON.parse(groupInfoStr));
            self.groups.set(groupId, groupInfo);
            return groupInfo;
        }
    }

    getGroupInfos(groupIds, fresh = false) {
        let groups = [];
        let groupInfoStrs = protoProxy.getGroupInfos(groupIds, fresh);
        if (groupInfoStrs && groupInfoStrs !== '') {
            let tmp = JSON.parse(groupInfoStrs);
            tmp.forEach((u) => {
                let groupInfo = Object.assign(new GroupInfo(), u);
                groups.push(groupInfo)
            });
        }
        return groups;
    }

    async getGroupInfoEx(groupId, refresh, successCB, failCB) {
        protoProxy.getGroupInfoEx(groupId, refresh, (groupInfoStr) => {
            let groupInfo = Object.assign(new GroupInfo(), JSON.parse(groupInfoStr));

            if (successCB) {
                successCB(groupInfo);
            }
        }, (errorCode) => {
            if (errorCode) {
                failCB(errorCode);
            }

        });
    }

    addGroupMembers(groupId, memberIds, extra, notifyLines, notifyMessageContent, successCB, failCB) {
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
            (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    getGroupMemberIds(groupId, fresh = false) {
        let groupMembers = self.getGroupMembers(groupId, fresh);
        var groupMemberIds = [];
        groupMembers.forEach(e => {
            groupMemberIds.push(e.memberId);
        });
        return groupMemberIds;
    }

    getGroupMembers(groupId, fresh = false) {
        let memberIdsStr = protoProxy.getGroupMembers(groupId, fresh);
        var members = [];
        let arr = JSON.parse(memberIdsStr);
        arr.forEach(e => {
            members.push(Object.assign(new GroupMember(), e));
        });
        return members;
    }

    getGroupMembersByType(groupId, memberType) {
        let memberIdsStr = protoProxy.getGroupMembersByType(groupId, memberType);
        var members = [];
        let arr = JSON.parse(memberIdsStr);
        arr.forEach(e => {
            members.push(Object.assign(new GroupMember(), e));
        });
        return members;
    }

    getGroupMember(groupId, memberId) {
        let result = protoProxy.getGroupMember(groupId, memberId);
        return Object.assign(new GroupMember(), JSON.parse(result));
    }

    async getGroupMembersEx(groupId, refresh, successCB, failCB) {
        protoProxy.getGroupMembersEx(groupId, refresh, (memberIdsStr) => {
            var members = [];
            let arr = JSON.parse(memberIdsStr);
            arr.forEach(e => {
                members.push(Object.assign(new GroupMember(), e));
            });

            if (successCB) {
                successCB(members);
            }
        }, (errorCode) => {
            if (errorCode) {
                failCB(errorCode);
            }

        });
    }

    kickoffGroupMembers(groupId, memberIds, notifyLines, notifyMsg, successCB, failCB) {
        let payload = notifyMsg ? notifyMsg.encode() : '';
        let strCont = JSON.stringify(payload);
        protoProxy.kickoffMembers(groupId, memberIds, notifyLines, strCont,
            () => {
                if (successCB) {
                    successCB();
                }

            }, (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async quitGroup(groupId, lines = [0], notifyMessageContent, successCB, failCB) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.quitGroup(groupId, lines, JSON.stringify(payload), () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            failCB(errorCode);
        });
    }

    async dismissGroup(groupId, lines = [0], notifyMessageContent, successCB, failCB) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.dismissGroup(groupId, lines, JSON.stringify(payload), () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            failCB(errorCode);
        });
    }

    async modifyGroupInfo(groupId, type, newValue, lines = [0], notifyMessageContent, successCB, failCB) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.modifyGroupInfo(groupId, type, newValue, lines, JSON.stringify(payload),
            () => {
                if (successCB) {
                    successCB();
                }
            }, (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async modifyGroupAlias(groupId, alias, lines = [0], notifyMessageContent, successCB, failCB) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.modifyGroupAlias(groupId, alias, lines, JSON.stringify(payload), () => {
            successCB();
        }, (errorCode) => {
            failCB(errorCode);
        });
    }

    async modifyGroupMemberAlias(groupId, memberId, alias, lines = [0], notifyMessageContent, successCB, failCB) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.modifyGroupMemberAlias(groupId, memberId, alias, lines, JSON.stringify(payload), () => {
            successCB();
        }, (errorCode) => {
            failCB(errorCode);
        });
    }

    async modifyGroupMemberExtra(groupId, memberId, extra, lines = [0], notifyMessageContent, successCB, failCB) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.modifyGroupMemberExtra(groupId, memberId, extra, lines, JSON.stringify(payload), () => {
            successCB();
        }, (errorCode) => {
            failCB(errorCode);
        });
    }

    transferGroup(groupId, newOwner, lines = [0], notifyMessageContent, successCB, failCB) {
        let payload = notifyMessageContent ? notifyMessageContent.encode() : '';
        protoProxy.transferGroup(groupId, newOwner, lines, JSON.stringify(payload), () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getFavGroups() {
        let result = protoProxy.getFavGroups();
        return JSON.parse(result);
    }

    isFavGroup(groupId) {
        return protoProxy.isFavGroup(groupId) === 1;
    }

    async setFavGroup(groupId, fav, successCB, failCB) {
        protoProxy.setFavGroup(groupId, fav, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    async getMyGroups(successCB, failCB) {
        protoProxy.getMyGroups((groupIds) => {
            if (successCB) {
                successCB(groupIds);
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    async getCommonGroups(userId, successCB, failCB) {
        protoProxy.getCommonGroups(userId, (groupIds) => {
            if (successCB) {
                successCB(groupIds);
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getUserSetting(scope, key) {
        return protoProxy.getUserSetting(scope, key);
    }

    getUserSettings(scope) {
        let result = protoProxy.getUserSettings(scope);
        return JSON.parse(result);
    }

    async setUserSetting(scope, key, value, successCB, failCB) {
        protoProxy.setUserSetting(scope, key, value, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    modifyMyInfo(modifyMyInfoEntries, successCB, failCB) {
        protoProxy.modifyMyInfo(modifyMyInfoEntries[0].type, modifyMyInfoEntries[0].value, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    isGlobalSlient() {
        return protoProxy.isGlobalSlient() === 1;
    }

    setGlobalSlient(silent, successCB, failCB) {
        protoProxy.setGlobalSlient(silent, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    isHiddenNotificationDetail() {
        return protoProxy.isHiddenNotificationDetail() === 1;
    }

    async setHiddenNotificationDetail(hide, successCB, failCB) {
        protoProxy.setHiddenNotificationDetail(hide, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    isHiddenGroupMemberName(groupId) {
        return protoProxy.isHiddenGroupMemberName(groupId) === 1;
    }

    async setHiddenGroupMemberName(groupId, hide, successCB, failCB) {
        protoProxy.setHiddenGroupMemberName(groupId, hide, () => {
            successCB();
        }, (errorCode) => {
            failCB(errorCode);
        });
    }

    isUserReceiptEnabled() {
        return protoProxy.isUserReceiptEnabled() === 1;
    }

    async setUserEnableReceipt(enable, successCB, failCB) {
        protoProxy.setUserReceiptEnable(enable, () => {
            successCB && successCB();
        }, (errorCode) => {
            failCB && failCB(errorCode);
        });
    }

    async joinChatroom(chatroomId, successCB, failCB) {
        protoProxy.joinChatroom(chatroomId, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    quitChatroom(chatroomId, successCB, failCB) {
        protoProxy.quitChatroom(chatroomId, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getChatroomInfo(chatroomId, updateDt, successCB, failCB) {
        protoProxy.getChatroomInfo(chatroomId, '' + updateDt, (info) => {
            if (successCB) {
                let chatRoomInfo = Object.assign(new ChatRoomInfo(), JSON.parse(info));
                chatRoomInfo.chatRoomId = chatroomId;
                successCB(chatRoomInfo);
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getChatroomMemberInfo(chatroomId, maxCount, successCB, failCB) {
        protoProxy.getChatroomMemberInfo(chatroomId, maxCount, (info) => {
            if (successCB) {
                successCB(Object.assign(new ChatRoomMemberInfo(), JSON.parse(info)));
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    createChannel(name, portrait, desc, extra, successCB, failCB) {
        protoProxy.createChannel(name, portrait, 0, desc, extra, (info) => {
            if (successCB) {
                successCB(Object.assign(new ChannelInfo(), JSON.parse(info)));
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getChannelInfo(channelId, refresh = false) {
        let result = protoProxy.getChannelInfo(channelId, refresh);
        if (result === '') {
            return new NullChannelInfo(channelId);
        }

        let ci = Object.assign(new ChannelInfo(), JSON.parse(result));
        if (ci.menus) {
            ci.menus = ci.menus.map(menu => {
                menu = Object.assign(new ChannelMenu(), menu)
                if (menu.subMenus) {
                    menu.subMenus = menu.subMenus.map(sm => Object.assign(new ChannelMenu(), sm))
                }
                return menu;
            })
        }
        return ci;
    }

    async modifyChannelInfo(channelId, type, newValue, successCB, failCB) {
        protoProxy.modifyChannelInfo(channelId, type, newValue, () => {
            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    searchChannel(keyword, successCB, failCB) {
        protoProxy.searchChannel(keyword, (result) => {
            if (successCB) {
                let channels = [];
                let tmp = JSON.parse(result);
                tmp.forEach(channel => {
                    channels.push(Object.assign(new ChannelInfo(), channel));
                });
                successCB(keyword, channels);
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    isListenedChannel(channelId) {
        return protoProxy.isListenedChannel(channelId);
    }

    async listenChannel(channelId, listen, successCB, failCB) {
        protoProxy.listenChannel(channelId, listen, () => {
            successCB && successCB();
        }, errorCode => {
            failCB && failCB(errorCode);
        });
    }

    // return channelIds
    getMyChannels() {
        let result = protoProxy.getMyChannels();
        return JSON.parse(result);
    }

    getListenedChannels() {
        let result = protoProxy.getListenedChannels();
        return JSON.parse(result);
    }

    getRemoteListenedChannels(successCB, failCB) {
        protoProxy.getRemoteListenedChannels((channelIds) => {
            successCB && successCB(channelIds);
        }, errorCode => {
            failCB && failCB(errorCode);
        });
    }

    async destoryChannel(channelId, successCB, failCB) {
        protoProxy.destoryChannel(channelId, () => {
            if (successCB) {
                successCB();
            }
        }, errorCode => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    getConversationInfoList(types, lines) {
        let conversationListStr = protoProxy.getConversationInfos(types, lines);
        // console.log(conversationListStr);
        // TODO convert to conversationInfo, messageContent

        let conversationInfoList = [];
        let tmp = JSON.parse(conversationListStr);
        tmp.forEach(c => {
            conversationInfoList.push(ConversationInfo.protoConversationToConversationInfo(c));
        });

        return conversationInfoList;
    }

    getConversationInfo(conversation) {
        let convStr = protoProxy.getConversationInfo(JSON.stringify(conversation));
        return ConversationInfo.protoConversationToConversationInfo(JSON.parse(convStr));
    }

    searchConversation(keyword, types = [], lines = []) {
        let result = protoProxy.searchConversation(keyword, types, lines);
        let resultList = JSON.parse(result);
        var conversationSearchResult = [];
        if (resultList && resultList.length > 0) {
            resultList.forEach(r => {
                conversationSearchResult.push(ConversationSearchResult.fromProtoConversationSearchResult(r));
            });
        }
        return conversationSearchResult;
    }

    searchConversationEx(keyword, types, lines, startTime, endTime, desc, limit, offset) {
        let result = protoProxy.searchConversationEx(keyword, types, lines, startTime, endTime, desc, limit, offset);
        let resultList = JSON.parse(result);
        var conversationSearchResult = [];
        if (resultList && resultList.length > 0) {
            resultList.forEach(r => {
                conversationSearchResult.push(ConversationSearchResult.fromProtoConversationSearchResult(r));
            });
        }
        return conversationSearchResult;
    }

    searchConversationEx2(keyword, types, lines, cntTypes, startTime, endTime, desc, limit, offset, onlyMentionedMsg) {
        let result = protoProxy.searchConversationEx2(keyword, types, lines, cntTypes, startTime, endTime, desc, limit, offset, onlyMentionedMsg);
        let resultList = JSON.parse(result);
        var conversationSearchResult = [];
        if (resultList && resultList.length > 0) {
            resultList.forEach(r => {
                conversationSearchResult.push(ConversationSearchResult.fromProtoConversationSearchResult(r));
            });
        }
        return conversationSearchResult;
    }

    async removeConversation(conversation, clearMsg) {
        protoProxy.removeConversation(JSON.stringify(conversation), clearMsg);
    }

    setConversationTop(conversation, top, successCB, failCB) {
        protoProxy.setConversationTop(JSON.stringify(conversation), top, () => {
            let conversationInfo = self.getConversationInfo(conversation);
            self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);

            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    setConversationSlient(conversation, silent, successCB, failCB) {
        protoProxy.setConversationSilent(JSON.stringify(conversation), silent, () => {
            let conversationInfo = self.getConversationInfo(conversation);
            self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);

            if (successCB) {
                successCB();
            }
        }, (errorCode) => {
            if (failCB) {
                failCB(errorCode);
            }
        });
    }

    setConversationDraft(conversation, draft = '') {
        let conversationInfo = self.getConversationInfo(conversation);
        if (conversationInfo.draft === draft) {
            return;
        }
        protoProxy.setConversationDraft(JSON.stringify(conversation), draft);
        conversationInfo = self.getConversationInfo(conversation);
        self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    //timestamp 为毫秒，字符串类型
    setConversationTimestamp(conversation, timestamp) {
        timestamp = timestamp + '';
        protoProxy.setConversationTimestamp(JSON.stringify(conversation), timestamp);
        let conversationInfo = self.getConversationInfo(conversation);
        self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    getUnreadCount(types = [], lines = [0]) {
        let unreadCountStr = protoProxy.getUnreadCount(types, lines);
        return Object.assign(new UnreadCount(), JSON.parse(unreadCountStr));
    }

    getConversationUnreadCount(conversation) {
        let unreadCountStr = protoProxy.getConversationUnreadCount(JSON.stringify(conversation));
        return Object.assign(new UnreadCount(), JSON.parse(unreadCountStr));
    }

    clearConversationUnreadStatus(conversation) {
        protoProxy.clearUnreadStatus(JSON.stringify(conversation));
        let conversationInfo = self.getConversationInfo(conversation);
        self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    clearUnreadStatusBeforeMessage(conversation, messageId) {
        protoProxy.clearMessageUnreadStatusBefore(JSON.stringify(conversation), messageId);
        let conversationInfo = self.getConversationInfo(conversation);
        self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    markConversationAsUnread(conversation, syncToOtherClient) {
        let msgUid = protoProxy.setLastReceivedMessageUnRead(JSON.stringify(conversation), '0', '0');
        if (msgUid && gt(msgUid, 0)) {
            if (syncToOtherClient) {
                let msg = this.getMessageByUid(msgUid);
                let content = new MarkUnreadMessageContent(msgUid);
                content.timestamp = msg.timestamp;
                this.sendConversationMessage(conversation, content)
            }
            let conversationInfo = self.getConversationInfo(conversation);
            self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);
            return true;
        }
        return false;
    }

    getConversationRead(conversation) {
        let readedStr = protoProxy.getConversationRead(JSON.stringify(conversation));
        let readedArr = JSON.parse(readedStr);
        // let result = []
        // if (readedArr) {
        //     readedArr.forEach(e => {
        //         result.push({e.key, e.value})
        //     })
        // }
        return readedArr;
    }

    getConversationDelivery(conversation) {
        let deliveryStr = protoProxy.getMessageDelivery(JSON.stringify(conversation));
        let deliveryArr = JSON.parse(deliveryStr);
        let result = new Map();
        if (deliveryArr) {
            deliveryArr.forEach(e => {
                result.set(e.key, e.value)
            })
        }
        return result;
    }

    clearMessageUnreadStatus(messageId) {
        protoProxy.clearMessageUnreadStatus(messageId);
    }

    clearAllUnreadStatus() {
        // TODO emit ConversationInfoUpdate event
        protoProxy.clearAllUnreadStatus();
    }

    getConversationFirstUnreadMessageId(conversation) {
        let messageId = protoProxy.getConversationFirstUnreadMessageId(JSON.stringify(conversation));
        return messageId;
    }

    setMediaMessagePlayed(messageId) {
        // TODO need to emit message update event?
        protoProxy.setMediaMessagePlayed(messageId);
    }

    setMessageLocalExtra(messageId, extra) {
        protoProxy.setMessageLocalExtra(messageId, extra);
    }

    isMyFriend(userId) {
        return protoProxy.isMyFriend(userId) === 1;
    }

    async sendFriendRequest(userId, reason, extra, successCB, failCB) {
        extra = !extra ? '' : extra;
        protoProxy.sendFriendRequest(userId, reason, extra, () => {
            if (successCB) {
                successCB();
            }

        }, (errorCode) => {
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
    getMessages(conversation, fromIndex, before = true, count = 20, withUser = '') {
        let protoMsgsStr = protoProxy.getMessages(JSON.stringify(conversation), [], fromIndex, before, count, withUser);
        // let protoMsgsStr = proto.getMessages('xxx', [0], fromIndex, before, count, withUser);
        var protoMsgs = JSON.parse(protoMsgsStr);
        let msgs = [];
        protoMsgs.map(m => {
            let msg = Message.fromProtoMessage(m);
            if (msg) {
                msgs.push(msg);
            }
        });
        console.log('getMessages', msgs.length);

        return msgs;
    }

    getMessagesV2(conversation, fromIndex, before, count, withUser, successCB, failCB) {
        protoProxy.getMessagesV2(JSON.stringify(conversation), [], fromIndex, before, count, withUser, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("getMessagesV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMentionedMessages(conversation, fromIndex, before, count, successCB, failCB) {
        protoProxy.getMentionedMessages(JSON.stringify(conversation), fromIndex, before, count, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMentionedMessages', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("getMentionedMessages failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessagesEx(conversationTypes, lines, contentTypes, fromIndex, before = true, count = 20, withUser = '') {
        let protoMsgsStr = protoProxy.getMessagesEx(conversationTypes, lines, contentTypes, fromIndex, before, count, withUser);
        // let protoMsgsStr = proto.getMessages('xxx', [0], fromIndex, before, count, withUser);
        var protoMsgs = JSON.parse(protoMsgsStr);
        let msgs = [];
        protoMsgs.map(m => {
            let msg = Message.fromProtoMessage(m);
            if (msg) {
                msgs.push(msg);
            }
        });
        console.log('getMessages', msgs.length);

        return msgs;
    }

    getMessagesExV2(conversationTypes, lines, contentTypes, fromIndex, before, count, withUser, successCB, failCB) {
        protoProxy.getMessagesExV2(conversationTypes, lines, contentTypes, fromIndex, before, count, withUser, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesExV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("getMessagesExV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessagesEx2(conversationTypes, lines, status, fromIndex, before = true, count = 20, withUser = '') {
        let protoMsgsStr = protoProxy.getMessagesEx2(conversationTypes, lines, status, fromIndex, before, count, withUser);
        // let protoMsgsStr = proto.getMessages('xxx', [0], fromIndex, before, count, withUser);
        var protoMsgs = JSON.parse(protoMsgsStr);
        let msgs = [];
        protoMsgs.map(m => {
            let msg = Message.fromProtoMessage(m);
            if (msg) {
                msgs.push(msg);
            }
        });
        console.log('getMessages', msgs.length);

        return msgs;
    }

    getMessagesEx2V2(conversationTypes, lines, status, fromIndex, before, count, withUser, successCB, failCB) {
        protoProxy.getMessagesEx2V2(conversationTypes, lines, status, fromIndex, before, count, withUser, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesEx2V2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("getMessagesEx2V2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessagesByTimestamp(conversation, contentTypes, timestamp, before = true, count = 20, withUser = '') {
        let protoMsgsStr = protoProxy.getMessagesByTimestamp(JSON.stringify(conversation), contentTypes, timestamp, before, count, withUser);
        var protoMsgs = JSON.parse(protoMsgsStr);
        let msgs = [];
        protoMsgs.map(m => {
            let msg = Message.fromProtoMessage(m);
            if (msg) {
                msgs.push(msg);
            }
        });
        console.log('getMessagesByTimestamp', msgs.length);

        return msgs;
    }

    getMessagesByTimestampV2(conversation, contentTypes, timestamp, before, count, withUser, successCB, failCB) {
        protoProxy.getMessagesByTimestampV2(JSON.stringify(conversation), contentTypes, timestamp, before, count, withUser, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesByTimestampV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("getMessagesByTimestampV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessagesByStatusV2(conversation, statuses, fromIndex, before, count, withUser, successCB, failCB) {
        protoProxy.getMessagesByStatusV2(JSON.stringify(conversation), statuses, fromIndex, before, count, withUser, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getMessagesByStatusV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("getMessagesByStatusV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getUserMessages(userId, conversation, fromIndex, before = true, count = 20, contentTypes = []) {
        let protoMsgsStr = protoProxy.getUserMessages(userId, JSON.stringify(conversation), contentTypes, fromIndex, before, count);
        var protoMsgs = JSON.parse(protoMsgsStr);
        let msgs = [];
        protoMsgs.map(m => {
            let msg = Message.fromProtoMessage(m);
            if (msg) {
                msgs.push(msg);
            }
        });
        console.log('getMessages', msgs.length);

        return msgs;
    }

    getUserMessagesV2(userId, conversation, fromIndex, before, count, contentTypes, successCB, failCB) {
        protoProxy.getUserMessagesV2(userId, JSON.stringify(conversation), contentTypes, fromIndex, before, count, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getUserMessagesV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("getUserMessagesV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getUserMessagesEx(userId, conversationTypes, lines, fromIndex, before = true, count = 20, contentTypes = []) {
        let protoMsgsStr = protoProxy.getUserMessagesEx(userId, conversationTypes, lines, contentTypes, fromIndex, before, count);
        var protoMsgs = JSON.parse(protoMsgsStr);
        let msgs = [];
        protoMsgs.map(m => {
            let msg = Message.fromProtoMessage(m);
            if (msg) {
                msgs.push(msg);
            }
        });
        console.log('getMessages', msgs.length);

        return msgs;
    }

    getUserMessagesExV2(userId, conversationTypes, lines, fromIndex, before, count, contentTypes, successCB, failCB) {
        protoProxy.getUserMessagesExV2(userId, conversationTypes, lines, contentTypes, fromIndex, before, count, (protoMsgsStr) => {
            let protoMsgs = JSON.parse(protoMsgsStr);
            let msgs = [];
            protoMsgs.map(m => {
                let msg = Message.fromProtoMessage(m);
                if (msg) {
                    msgs.push(msg);
                }
            });
            console.log('getUserMessagesExV2', msgs.length);
            successCB && successCB(msgs);
        }, (errorCode) => {
            console.log("getUserMessagesExV2 failure:", errorCode);
            failCB && failCB(errorCode);
        });
    }

    getMessageById(messageId) {
        let mStr = protoProxy.getMessage(messageId);
        return Message.fromProtoMessage(JSON.parse(mStr));
    }

    getMessageByUid(messageUid) {
        let mStr = protoProxy.getMessageByUid(Long.fromValue(messageUid).toString());
        return Message.fromProtoMessage(JSON.parse(mStr));
    }

    searchMessage(conversation, keyword, withUser = '') {
        let result = protoProxy.searchMessage(JSON.stringify(conversation), keyword, withUser);
        let msgs = JSON.parse(result);
        let matchMsgs = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m));
            });
        }

        return matchMsgs;
    }

    searchMessageEx(conversation, keyword, desc, limit, offset, withUser = '') {
        let result = protoProxy.searchMessageEx(JSON.stringify(conversation), keyword, desc, limit, offset, withUser);
        let msgs = JSON.parse(result);
        let matchMsgs = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m));
            });
        }

        return matchMsgs;
    }

    searchMentionedMessages(conversation, keyword, desc, limit, offset) {
        let result = protoProxy.searchMentionedMessages(JSON.stringify(conversation), keyword, desc, limit, offset);
        let msgs = JSON.parse(result);
        let matchMsgs = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m));
            });
        }

        return matchMsgs;
    }

    searchMessageByTypes(conversation, keyword, contentTypes, desc, limit, offset, withUser = '') {
        if (!contentTypes) {
            contentTypes = [];
        }
        let result = protoProxy.searchMessageByTypes(JSON.stringify(conversation), keyword, contentTypes, desc, limit, offset, withUser);
        let msgs = JSON.parse(result);
        let matchMsgs = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m));
            });
        }

        return matchMsgs;
    }

    searchMessageByTypesAndTimes(conversation, keyword, contentTypes, startTime, endTime, desc, limit, offset, withUser = '') {
        if (!contentTypes) {
            contentTypes = [];
        }
        let result = protoProxy.searchMessageByTypesAndTimes(JSON.stringify(conversation), keyword, contentTypes, startTime.toString(), endTime.toString(), desc, limit, offset, withUser);
        let msgs = JSON.parse(result);
        let matchMsgs = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m));
            });
        }

        return matchMsgs;
    }

    searchMessageEx2(conversationTypes, lines, contentTypes, keyword, fromIndex, desc, count, withUser = '') {
        if (!contentTypes) {
            contentTypes = [];
        }
        let result = protoProxy.searchMessageEx2(conversationTypes, lines, contentTypes, keyword, fromIndex, desc, count, withUser);
        let msgs = JSON.parse(result);
        let matchMsgs = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m));
            });
        }

        return matchMsgs;
    }

    searchMentionedMessageEx(conversationTypes, lines, keyword, desc, limit, offset) {
        if (!conversationTypes) {
            conversationTypes = [];
        }
        let result = protoProxy.searchMentionedMessagesEx(conversationTypes, lines, keyword, desc, limit, offset);
        let msgs = JSON.parse(result);
        let matchMsgs = [];
        if (msgs && msgs.length > 0) {
            msgs.forEach(m => {
                matchMsgs.push(Message.fromProtoMessage(m));
            });
        }

        return matchMsgs;
    }

    async sendConversationMessage(conversation, messageContent, toUsers = [], preparedCB, progressCB, uploadedCB, successCB, failCB) {
        let message = new Message();
        message.conversation = conversation;
        message.messageContent = messageContent;
        self.sendMessageEx(message, toUsers, preparedCB, progressCB, uploadedCB, successCB, failCB);
    }

    async sendMessage(message, preparedCB, progressCB, uploadedCB, successCB, failCB) {
        self.sendMessageEx(message, [], preparedCB, progressCB, uploadedCB, successCB, failCB);
    }

    // toUsers 用来实现定向消息
    async sendMessageEx(message, toUsers = [], preparedCB, progressCB, uploadedCB, successCB, failCB) {
        let strConv = JSON.stringify(message.conversation);
        message.content = message.messageContent.encode();
        message.from = this.userId;

        let mediaMessageUploadCallback;
        if (message.messageContent instanceof TextMessageContent && Config.SEND_LOG_COMMAND && Config.SEND_LOG_COMMAND.trim() && message.messageContent.content === Config.SEND_LOG_COMMAND.trim()) {
            let latestLogFilePath = this._getLatestLogFilePath();
            if (latestLogFilePath) {
                mediaMessageUploadCallback = (remoteUrl) => {
                    let textMessageContent = new TextMessageContent(remoteUrl);
                    this.sendConversationMessage(message.conversation, textMessageContent);
                }
                let file = {
                    path: latestLogFilePath,
                    name: latestLogFilePath.substring((latestLogFilePath.lastIndexOf('/') + 1)),
                    size: 0
                    // fixme
                    // size: require('fs').statSync(latestLogFilePath).size

                }
                let mediaMessageContent = new FileMessageContent(file, null)
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

        if (message.messageContent instanceof MediaMessageContent && (message.messageContent.localPath || message.messageContent.file) && !message.messageContent.remotePath && this.isSupportBigFilesUpload()) {
            let insertedMsg = this.insertMessage(message.conversation, message.messageContent, MessageStatus.Sending, false, toUsers, 0);
            // 有一个副作用，后续调用sendSavedMessage时，还会触发一次 SendMessage 事件
            this.eventEmitter.emit(EventType.SendMessage, insertedMsg);
            preparedCB && preparedCB(insertedMsg.messageId, insertedMsg.timestamp);

            // image/jpeg
            this._uploadFile(insertedMsg, message.messageContent.localPath, message.messageContent.mediaType, (uploaded, total) => {
                progressCB && progressCB(uploaded, total, insertedMsg.messageId);
            }, (remoteUrl) => {
                insertedMsg.messageContent.remotePath = remoteUrl;
                this.updateMessageContent(insertedMsg.messageId, insertedMsg.messageContent);
                uploadedCB && uploadedCB(remoteUrl);
                protoProxy.sendSavedMessage(insertedMsg.messageId, 0, (messageUid, timestamp) => {
                    messageUid = Long.fromValue(messageUid);
                    insertedMsg.messageUid = messageUid;
                    insertedMsg.timestamp = timestamp;
                    insertedMsg.status = MessageStatus.Sent;
                    console.log('send saved msg success', messageUid, insertedMsg);
                    successCB && successCB(insertedMsg.messageUid, insertedMsg.timestamp);
                }, err => {
                    failCB && failCB(err)
                })
                mediaMessageUploadCallback && mediaMessageUploadCallback(remoteUrl);
            }, (err) => {
                this.updateMessageStatus(insertedMsg.messageId, MessageStatus.SendFailure);
                insertedMsg.status = MessageStatus.SendFailure;
                failCB && failCB(err);
            });
            return
        }

        if (message.messageContent instanceof MediaMessageContent) {
            if (!message.messageContent.localPath && message.messageContent.file) {
                let file = message.messageContent.file;
                let filePath = path.join(os.tmpdir(), file.name);
                let buffer = Buffer.from(await file.arrayBuffer())
                require('fs').writeFileSync(filePath, buffer);
                message.messageContent.localPath = filePath;

                message.content = message.messageContent.encode();
            }
        }

        let strCont = JSON.stringify(message.content);
        let msgStr = protoProxy.sendMessage(strConv, strCont, toUsers, 0,
            (messageId, timestamp) => { //preparedCB
                message.messageId = messageId;
                message.timestamp = Long.fromValue(timestamp).toNumber();
            },
            (uploaded, total) => { //progressCB
                if (typeof progressCB === 'function') {
                    progressCB(uploaded, total, message.messageId);
                }
                // upload progress update
            },
            (mediaUrl) => {
                if (uploadedCB && typeof uploadedCB === 'function') {
                    uploadedCB(mediaUrl);
                }
            },
            (messageUid, timestamp) => { //successCB
                message.status = MessageStatus.Sent;
                message.messageUid = Long.fromValue(messageUid);
                message.timestamp = Long.fromValue(timestamp).toNumber();
                // update remote url
                if (message.messageContent instanceof MediaMessageContent) {
                    let msg = self.getMessageById(message.messageId);
                    message.messageContent = msg.messageContent;
                }
                if (message.conversation.type === ConversationType.ChatRoom) {
                    this.eventEmitter.emit(EventType.MessageStatusUpdate, message);
                }

                if (typeof successCB === 'function') {
                    successCB(Long.fromValue(messageUid), Long.fromValue(timestamp).toNumber());
                }
            },
            (errorCode) => { //errorCB
                message.status = MessageStatus.SendFailure;
                if (message.conversation.type === ConversationType.ChatRoom) {
                    this.eventEmitter.emit(EventType.MessageStatusUpdate, message);
                }
                if (typeof failCB === 'function') {
                    failCB(errorCode);
                }
            });


        let msgObj = JSON.parse(msgStr);
        message.messageId = msgObj.messageId;
        message.timestamp = Long.fromValue(msgObj.timestamp).toNumber();
        if (typeof preparedCB === 'function') {
            preparedCB(message.messageId, Long.fromValue(msgObj.timestamp).toNumber());
        }

        this.eventEmitter.emit(EventType.SendMessage, message);
    }

    async sendSavedMessage(message, expireDuration, successCB, failCB) {
        protoProxy.sendSavedMessage(message.messageId, expireDuration,
            (messageUid, timestamp) => { //successCB
                message.status = MessageStatus.Sent;
                message.messageUid = Long.fromValue(messageUid);
                message.timestamp = Long.fromValue(timestamp).toNumber();
                // update remote url
                if (message.messageContent instanceof MediaMessageContent) {
                    let msg = self.getMessageById(message.messageId);
                    message.messageContent = msg.messageContent;
                }

                if (typeof successCB === 'function') {
                    successCB(Long.fromValue(messageUid), Long.fromValue(timestamp).toNumber());
                }
            },
            (errorCode) => { //errorCB
                message.status = MessageStatus.SendFailure;
                if (typeof failCB === 'function') {
                    failCB(errorCode);
                }
            });
    }

    async readLocalFile(path, name) {
        let response = await fetch('file://' + path);
        let data = await response.blob();
        return new File([data], name);
    }

    cancelSendingMessage(messageId) {
        let canceled = protoProxy.cancelSendingMessage(messageId);
        if (!canceled) {
            let xhr = this.uploadingMap.get(messageId);
            if (xhr) {
                this.uploadingMap.delete(messageId);
                try {
                    xhr.abort();
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

    _uploadXMLHttpRequest(messageId, fileName, remoteUrl, progressCB, successCB, failCB) {
        let xhr = new XMLHttpRequest();
        xhr.upload.onprogress = (e) => {
            // console.log('upload.onprogress', Math.ceil(e.loaded / e.total * 100))
            let progress = e.loaded;
            let total = e.total;
            progressCB(progress, total);
        }
        xhr.onreadystatechange = (e) => {
            console.log('onr', xhr.readyState, xhr.status, e)
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    console.log('upload file success', fileName, remoteUrl);
                    this.uploadingMap.delete(messageId);
                    successCB(remoteUrl);
                } else {
                    console.log('upload file error', xhr.status);
                    this.uploadingMap.delete(messageId);
                    failCB && failCB(-1);
                }
            }
        }
        xhr.onerror = e => {
            console.log('upload file error', e);
            this.uploadingMap.delete(messageId);
            failCB && failCB(-1);
        }

        if (messageId) {
            this.uploadingMap.set(messageId, xhr);
        }
        return xhr;
    }

    // 大文件上传
    async _uploadFile(message, file: string, mediaType, progressCB, successCB, failCB) {
        let fileName = file.substring(file.lastIndexOf('/') + 1);
        let contentType = this._getContentType(mediaType, fileName);
        this.getUploadMediaUrl(fileName, mediaType, contentType, (uploadUrl, remoteUrl, backUploadUrl, serverType) => {
            uploadUrl = (self.connectedToMainNetwork() || !backUploadUrl) ? uploadUrl : backUploadUrl;
            console.log('getUploadMediaUrl', uploadUrl, remoteUrl, backUploadUrl, serverType)
            let xhr;
            if (serverType === 0) {
                // 内置存储，不支持大文件上传
            } else if (serverType === 1) {
                // qiniu
                let ss = uploadUrl.split('?');
                let url = ss[0];
                let token = ss[1];
                let key = ss[2];
                xhr = this._uploadXMLHttpRequest(message ? message.messageId : 0, fileName, remoteUrl, progressCB, successCB, failCB);

                let formData = new FormData();
                formData.append('key', key)
                formData.append('token', token)
                formData.append('file', file)
                xhr.open('POST', url);
                xhr.setRequestHeader('content-type', contentType);
                xhr.setRequestHeader("content-disposition", `attachment; filename="${fileName}"`);
                xhr.send(formData);
            } else {
                // 野火专业存储或阿里云
                // xhr = this._uploadXMLHttpRequest(message ? message.messageId : 0, fileName, remoteUrl, progressCB, successCB, failCB);
                // xhr.open('PUT', uploadUrl);
                //
                // xhr.setRequestHeader('content-type', contentType);
                // xhr.setRequestHeader("content-disposition", `attachment; filename="${fileName}"`);
                // xhr.send(file);

                let uploadRequestOptions: request.UploadConfig = {
                    url: uploadUrl,
                    header: {
                        'Content-Type': 'multipart/form-data'
                    },
                    method: 'POST',
                    files: [{
                        filename: fileName,
                        name: 'file',
                        uri: file,
                        type: 'jpg'
                    }],
                    data: []
                };

                // Upload the file.
                request.uploadFile(self.context, uploadRequestOptions).then((data: request.UploadTask) => {
                    data.on('complete', (result: Array<request.TaskState>) => {
                        if (result && result.length >= 1) {
                            // serverData.code = Constants.SERVER_CODE_SUCCESS;
                            // serverData.msg = result[0].message;
                            // serverData.data = Constants.IMAGE_PREFIX + result[0].path;
                            // resolve(serverData);
                        }
                    });
                    data.on('fail', (result: Array<request.TaskState>) => {
                        if (result && result.length >= 1) {
                            // serverData.msg = '上传失败'
                            // reject(serverData);
                        }
                    })
                }).catch((err: Error) => {
                    // reject(serverData);
                });
            }

        }, (e) => {
            console.log('getUploadMediaUrl e', e)
        })
    }

    // 更新了原始消息的内容
    async recallMessage(messageUid, successCB, failCB) {
        console.log('recall', messageUid);
        protoProxy.recall(messageUid.toString(),
            () => {
                console.log('recall, s', messageUid);
                if (successCB) {
                    successCB();
                }
                this.onRecallMessage(this.getUserId(), messageUid);
            },
            (errorCode) => {
                console.log('recall, f', messageUid, errorCode);
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async deleteRemoteMessage(messageUid, successCB, failCB) {
        console.log('deleteRemoteMessageByUid', messageUid);
        protoProxy.deleteRemoteMessage(messageUid.toString(),
            () => {
                if (successCB) {
                    successCB();
                }
                this.onDeleteRemoteMessage(messageUid);
            },
            (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    async updateRemoteMessageContent(messageUid, messageContent, distribute, updateLocal, successCB, failCB) {
        console.log('updateRemoteMessageContent', messageUid);
        let protoMessageContent = messageContent.encode();
        protoProxy.updateRemoteMessageContent(messageUid.toString(), JSON.stringify(protoMessageContent), distribute, updateLocal,
            () => {
                if (successCB) {
                    successCB();
                }
            },
            (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    deleteMessageById(messageId) {
        let result = protoProxy.deleteMessage(messageId);
        if (result) {
            this.onMessageDeleted(messageId);
        }
        return result;
    }

    batchDeleteMessages(messageUids) {
        let result = protoProxy.batchDeleteMessages(messageUids);
        return result;
    }

    watchOnlineState(conversationType, targets, duration, successCB, failCB) {
        protoProxy.watchOnlineState(conversationType, targets, duration,
            (strStates) => {
                let userOnlineStates = self._parseUserOnlineState(strStates);
                successCB && successCB(userOnlineStates);
            },
            (errorCode) => {
                failCB && failCB(errorCode);
            });
    }

    unwatchOnlineState(conversationType, targets, successCB, failCB) {
        protoProxy.unwatchOnlineState(conversationType, targets,
            () => {
                if (successCB) {
                    successCB();
                }
            },
            (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            });
    }

    setMyCustomState(customState, customText, successCB, failCB) {
        let csSetting = customState + '-' + customText;
        this.setUserSetting(UserSettingScope.CustomState, "", csSetting, successCB, failCB);
    }

    isCommercialServer() {
        return protoProxy.isCommercialServer() === 1;
    }

    isReceiptEnabled() {
        return protoProxy.isReceiptEnabled() === 1
    }

    isGroupReceiptEnabled() {
        return protoProxy.isGroupReceiptEnabled() === 1;
    }

    isGlobalDisableSyncDraft() {
        return protoProxy.isGlobalDisableSyncDraft() === 1
    }

    isUserOnlineStateEnabled() {
        return protoProxy.isEnableUserOnlineState() === 1;
    }

    setDisableSyncDraft(disable, successCB, failCB) {
        this.setUserSetting(UserSettingScope.DisableSyncDraft, '', disable ? '1' : '0',
            () => successCB && successCB(),
            (err) => failCB && failCB(err));
    }

    isDisableSyncDraft() {
        return this.getUserSetting(UserSettingScope.DisableSyncDraft, '') === '1';
    }

    getAuthorizedMediaUrl(messageUid, mediaType, mediaPath, successCB, failCB) {
        protoProxy.getAuthorizedMediaUrl(stringValue(messageUid), mediaType, mediaPath, successCB, failCB);
    }

    isSupportBigFilesUpload() {
        return false
        //return protoProxy.isSupportBigFilesUpload();
    }

    getUploadMediaUrl(fileName, mediaType, contentType, successCB, failCB) {
        protoProxy.getUploadMediaUrl(fileName, mediaType, contentType, successCB, failCB);
    }

    getConversationFileRecords(conversation, fromUser, beforeUid, order, count, successCB, failCB) {
        protoProxy.getConversationFiles(JSON.stringify(conversation), fromUser, Long.fromValue(beforeUid)
            .toString(), order, count, (frsStr) => {
            let frs = JSON.parse(frsStr);
            let fileRecords = [];
            frs.forEach(fr => {
                fileRecords.push(this._objStrToFileRecordObj(fr));
            })
            successCB && successCB(fileRecords);
        }, (errorCode) => {
            failCB && failCB(errorCode);
        });
    }

    _objStrToFileRecordObj(obj) {

        let fileRecord = new FileRecord();
        fileRecord.userId = obj.userId;
        fileRecord.conversation = new Conversation(obj.conversationType, obj.target, obj.line);
        fileRecord.messageUid = Long.fromValue(obj.messageUid);
        fileRecord.name = obj.name;
        fileRecord.url = obj.url;
        fileRecord.size = obj.size;
        fileRecord.downloadCount = obj.downloadCount;
        fileRecord.timestamp = obj.timestamp;

        return fileRecord;
    }

    getMyFileRecords(beforeUid, order, count, successCB, failCB) {
        protoProxy.getMyFiles(Long.fromValue(beforeUid).toString(), order, count, (frsStr) => {
            let frs = JSON.parse(frsStr);
            let fileRecords = [];
            frs.forEach(fr => {
                fileRecords.push(this._objStrToFileRecordObj(fr));
            })
            successCB && successCB(fileRecords);
        }, (errorCode) => {
            failCB && failCB(errorCode);
        });
    }

    deleteFileRecord(messageUid, successCB, failCB) {
        protoProxy.deleteFileRecord(Long.fromValue(messageUid).toString(), () => {
            successCB && successCB();
        }, (errorCode) => {
            failCB && failCB(errorCode);
        });
    }

    async clearMessages(conversation) {
        protoProxy.clearMessages(JSON.stringify(conversation));
        let conversationInfo = this.getConversationInfo(conversation);
        self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    async clearUserMessages(userId, startTime, endTime) {
        protoProxy.clearUserMessages(userId, startTime, endTime);
    }

    async clearRemoteConversationMessages(conversation, successCB, failCB) {
        protoProxy.clearRemoteConversationMessages(JSON.stringify(conversation),
            () => {
                let conversationInfo = this.getConversationInfo(conversation);
                self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);
                successCB && successCB();
            },
            (errorCode) => {
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
    async clearMessagesByTime(conversation, before) {
        protoProxy.clearMessagesByTime(JSON.stringify(conversation), before);
        let conversationInfo = this.getConversationInfo(conversation);
        self.eventEmitter.emit(EventType.ConversationInfoUpdate, conversationInfo);
    }

    async clearMessagesKeepLatest(conversation, count) {
        protoProxy.clearMessagesKeepLatest(JSON.stringify(conversation), count);
    }

    clearAllMessages(removeConversation) {
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
    insertMessage(conversation, messageContent, status, notify = false, toUsers = [], serverTime = 0) {
        let protoMessageContent = messageContent.encode();
        let mStr = protoProxy.insertMessage(JSON.stringify(conversation), self.userId, JSON.stringify(protoMessageContent), status, notify, toUsers, serverTime);
        return Message.fromProtoMessage(JSON.parse(mStr));
    }

    insertMessageEx(messageUid, conversation, fromUser, messageContent, status, serverTime, localExtra) {
        let protoMessageContent = messageContent.encode();
        let mStr = protoProxy.insertMessageEx(Long.fromValue(messageUid)
            .toString(), JSON.stringify(conversation), fromUser, JSON.stringify(protoMessageContent), status, serverTime, localExtra);
        return Message.fromProtoMessage(JSON.parse(mStr));
    }

    async updateMessageContent(messageId, messageContent) {
        let protoMessageContent = messageContent.encode();
        protoProxy.updateMessage(messageId, JSON.stringify(protoMessageContent));
    }

    async updateMessageStatus(messageId, status) {
        protoProxy.updateMessageStatus(messageId, status);
    }

    async uploadMedia(fileName, fileOrData, mediaType, successCB, failCB, progressCB) {
        // var data = file.slile(0, file.size);
        if (this.isTcpShortLink() && !this.isSupportBigFilesUpload()) {
            console.error('TCP短连接不支持内置对象存储，请把对象存储切换到其他类型')
            failCB && failCB(-1);
            return;
        }
        // dataUri
        if (typeof fileOrData === 'string' && fileOrData.indexOf("base64,") >= 0) {
            fileOrData = fileOrData.substring(fileOrData.indexOf(',') + 1);
        }
        if (this.isTcpShortLink() || this.isSupportBigFilesUpload()) {
            let file;
            if (typeof fileOrData === 'string') {
                const byteCharacters = atob(fileOrData);
                const byteArray = new Uint8Array(byteCharacters.length);
                for (let i = 0; i < byteCharacters.length; i++) {
                    byteArray[i] = byteCharacters.charCodeAt(i);
                }
                file = new Blob([new Uint8Array(byteArray, 0, byteArray.byteLength)]);
            } else {
                file = fileOrData;
            }
            this._uploadFile(null, file, mediaType, progressCB, successCB, failCB);
        } else {
            // file
            if (fileOrData.path) {
                fileOrData = await fs.readFile(fileOrData.path, { encoding: 'base64' });
            }
            protoProxy.uploadMedia(fileName, fileOrData, mediaType,
                (remoteUrl) => {
                    if (successCB) {
                        successCB(remoteUrl);
                    }
                },
                (errorCode) => {
                    if (failCB) {
                        failCB(errorCode);
                    }
                },
                (current, total) => {
                    if (progressCB) {
                        progressCB(current, total);
                    }
                });
        }
    }

    sendConferenceRequest(sessionId, roomId, request, data, advance, callback) {
        protoProxy.sendConferenceRequest('' + sessionId, roomId, request, data,
            (resp) => {
                callback && callback(0, resp);
            },
            (errorCode) => {
                callback && callback(errorCode, null)
            }, advance === true);
    }

    searchFiles(keyword, conversation, fromUser, beforeMessageId, order, count, successCB, failCB) {
        protoProxy.searchFiles(keyword, conversation ? JSON.stringify(conversation) : '', fromUser, Long.fromValue(beforeMessageId)
            .toString(), order, count,
            (files) => {
                let frs = JSON.parse(files);

                let fileRecords = [];
                frs.forEach(fr => {
                    fileRecords.push(this._objStrToFileRecordObj(fr));
                })
                successCB && successCB(fileRecords);
            },
            (errorCode) => {
                failCB && failCB(errorCode);
            })
    }

    searchMyFiles(keyword, beforeMessageUid, order, count, successCB, failCB) {
        protoProxy.searchMyFiles(keyword, Long.fromValue(beforeMessageUid).toString(), order, count,
            (files) => {
                let frs = JSON.parse(files);

                let fileRecords = [];
                frs.forEach(fr => {
                    fileRecords.push(this._objStrToFileRecordObj(fr));
                })
                successCB && successCB(fileRecords);
            },
            (errorCode) => {
                failCB && failCB(errorCode);
            });
    }

    getHost() {
        return protoProxy.getHost();
    }

    async createSecretChat(userId, successCB, failCB) {
        protoProxy.createSecretChat(userId,
            (targetId, line) => {
                if (successCB) {
                    successCB(targetId, line);
                }
            },
            (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            }
        );
    }

    async destroySecretChat(targetId, successCB, failCB) {
        protoProxy.destroySecretChat(targetId,
            () => {
                if (successCB) {
                    successCB();
                }
            },
            (errorCode) => {
                if (failCB) {
                    failCB(errorCode);
                }
            }
        );
    }

    getSecretChatInfo(targetId) {
        let secretChatInfoStr = protoProxy.getSecretChatInfo(targetId);
        if (!secretChatInfoStr) {
            return null;
        }
        let obj = Object.assign(new SecretChatInfo(), JSON.parse(secretChatInfoStr));
        obj.targetId = targetId;
        return obj;
    }

    getAuthCode(appId, appType, host, successCB, failCB) {
        protoProxy.getAuthCode(appId, appType, host, (authCode) => {
            successCB && successCB(authCode);
        }, (err) => {
            failCB && failCB(err);
        });
    }

    //public void configApplication(String appId, int appType, long timestamp, String nonceStr, String signature, GeneralCallback callback) {
    configApplication(appId, appType, timestamp, nonceStr, signature, successCB, failCB) {
        protoProxy.configApplication(appId, appType, timestamp, nonceStr, signature, () => {
            successCB && successCB();
        }, (err) => {
            failCB && failCB(err);
        });
    }

    //byte[]
    decodeSecretChatMediaData(targetId, mediaDatas) {
        return protoProxy.decodeSecretChatMediaData(targetId, mediaDatas);
    }

    //byte[]
    encodeSecretChatMediaData(targetId, mediaDatas) {
        return protoProxy.encodeSecretChatMediaData(targetId, mediaDatas);
    }

    setSecretChatBurnTime(targetId, ms) {
        protoProxy.setSecretChatBurnTime(targetId, ms);
    }

    isEnableSecretChat() {
        return protoProxy.isEnableSecretChat() === 1;
    }

    getAppPath() {
        return protoProxy.getAppPath();
    }

    isUserEnableSecretChat() {
        return protoProxy.isUserEnableSecretChat() === 1;
    }

    async setUserEnableSecretChat(enable, successCB, failCB) {
        protoProxy.setUserEnableSecretChat(enable, () => {
            successCB && successCB();
        }, (errorCode) => {
            failCB && failCB(errorCode);
        });
    }

    beginTransaction() {
        return protoProxy.beginTransaction();
    }

    commitTransaction() {
        return protoProxy.commitTransaction();
    }

    rollbackTransaction() {
        return protoProxy.roolbackTransaction();
    }

    requireLock(lockId, duration, successCB, failCB) {
        protoProxy.requireLock(lockId, duration, () => {
            successCB && successCB();
        }, (errorCode) => {
            failCB && failCB(errorCode);
        })
    }

    releaseLock(lockId, successCB, failCB) {
        protoProxy.releaseLock(lockId, () => {
            successCB && successCB();
        }, errorCode => {
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
        protoProxy.setConnectToServerListener(self.onConnectedToSer1ver)
        protoProxy.setReceiveMessageListener(self.onReceiveMessage, self.onRecallMessage, self.onDeleteRemoteMessage, self.onUserReceivedMessage, self.onUserReadedMessage);

        // protoProxy.setProtoEventListener('onSendMessage', (message) => {
        //     let msg = Message.fromProtoMessage(JSON.parse(message));
        //     self.eventEmitter.emit(EventType.SendMessage, msg);
        // });

        // protoProxy.setProtoEventListener('onMessageStatusUpdate', (message) => {
        //     let msg = Message.fromProtoMessage(JSON.parse(message));
        //     self.eventEmitter.emit(EventType.MessageStatusUpdate, msg);
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
        protoProxy.setSecretMessageBurnStateListener(self.onSecretMessageStartBurningListener)
        protoProxy.setSecretMessageBurnStateListener(self.onSecretMessageStartBurningListener, self.onSecretMessageBurnedListener);
    }

    _getLatestLogFilePath() {
        let appPath = this.getAppPath();
        const fileNames = require('fs').readdirSync(appPath)
        const logFiles = fileNames.filter(fn => fn.endsWith(".xlog")).sort((a, b) => a > b ? 1 : -1)
        return logFiles.length > 0 ? appPath + '/' + logFiles[logFiles.length - 1] : null;
    }

    // 预加载数据
    // 拉取会话相关用户、群信息
    // 自己的用户信息
    // 获取所有好友、好友请求的用户信息
    _preloadDefaultData() {
        let requests = self.getIncommingFriendRequest()
        let userIdSet = new Set();
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
        let groupIdIds = [];
        let channelIds = [];
        conversationInfoList.forEach(info => {
            if (info.conversation.type === ConversationType.Single) {
                userIdSet.add(info.conversation.target);
            } else if (info.conversation.type === ConversationType.Group) {
                groupIdIds.push(info.conversation.target);
            } else if (info.conversation.type === ConversationType.Channel) {
                channelIds.push(info.conversation.target)
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

    _preloadGroupMemberUserInfos(memberIds) {
        for (let i = 0; i < memberIds.length / 2000; i++) {
            self.getUserInfos(memberIds.slice(2000 * i, (i + 1) * 2000), '');
            console.log('to preload', memberIds.slice(2000 * i, (i + 1) * 2000))
        }
    }

    _getStore() {
        console.log('not support')
        return null;
    }

    _getContentType(mediaType, fileName) {
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
