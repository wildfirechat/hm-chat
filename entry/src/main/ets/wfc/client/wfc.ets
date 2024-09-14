/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

// import util from '@ohos.util';

// import {atob, btoa} from '../util/base64.min';
// import Long from 'long';

import impl from '../proto/proto.min';
import Config from "../../config";
import Long from '../util/long'
import { atob, btoa } from '../util/base64.min'
// import avenginekit from "../av/engine/avenginekitproxy";
// import pttClient from "../ptt/client/pttClient";
import ConnectionStatus from "./connectionStatus";
import EventType from "./wfcEvent";
import NullUserInfo from "../model/nullUserInfo";
import UserInfo from '../model/userInfo';
import GroupMember from '../model/groupMember';
import SearchType from '../model/searchType';
import FriendRequest from '../model/friendRequest';
import ChannelInfo from '../model/channelInfo';
import GroupSearchResult from '../model/groupSearchResult';
import GroupInfo from '../model/groupInfo';
import ConversationInfo from '../model/conversationInfo';
import Conversation from '../model/conversation';
import AddGroupMemberNotification from '../messages/notification/addGroupMemberNotification';
import KickoffGroupMemberNotification from '../messages/notification/kickoffGroupMemberNotification';
import Message from '../messages/message';
import ChatRoomInfo from '../model/chatRoomInfo';
import MessageContent from '../messages/messageContent';
import { util } from '@kit.ArkTS';
import common from '@ohos.app.ability.common';
import ModifyMyInfoEntry from '../model/modifyMyInfoEntry';
import { FailCallback, SuccessCallback, CallbackWithValue_1, CallbackWithValue_2, numberArray, CallbackWithValue_1_OrNull, CallbackWithValue_2_OrNull, stringArray, FailCallbackOrNull, } from '../type/types';
import SecretChatInfo from '../model/secretChatInfo';
import ConversationSearchResult from '../model/conversationSearchResult';
import UnreadCount from '../model/unreadCount';
import FileRecord from '../model/fileRecord';
import UserOnlineState from '../model/userOnlineState';
import UserSettingScope from './userSettingScope';
import PCOnlineInfo from '../model/pcOnlineInfo';
import fs from '@ohos.file.fs';

const textEncoder = new util.TextEncoder('utf-8')

const textDecoder = util.TextDecoder.create('utf-8')


export class WfcManager {
    /**
     * 事件通知，{@link EventType}中定义的事件，都会采用本{@link eventEmitter} 通知
     * @type {module:events.internal.EventEmitter}
     */
    //eventEmitter = new EventEmitter();
    eventEmitter?: common.EventHub;

    constructor() {
        // impl.eventEmitter = {
        //     emit: (ev, ...args) => {
        //         if (ev === EventType.ConnectionStatusChanged
        //             || ev === EventType.UserOnlineEvent
        //             || ev === EventType.SendMessage
        //             || ev === EventType.connectedToServer
        //             || ev === EventType.MessageStatusUpdate) {
        //             self.eventEmitter.emit(ev, ...args)
        //         } else {
        //             if (impl.connectionStatus === ConnectionStatus.ConnectionStatusConnected) {
        //                 self.eventEmitter.emit(ev, ...args)
        //             } else {
        //                 // ignore
        //             }
        //         }
        //     }
        // };
        // impl.eventEmitter = this.eventEmitter;
    }


    /**
     * 初始化，请参考本demo的用法
     * 只可以在主窗口调用，其他窗口调用应当调用{@link attach}
     * @param {[]} args，pc 时，传入[node实例]; web 时，可以传入Config配置对象，配置项，请参考{@link Config}
     */
    init(context: common.ApplicationContext, eventHub: common.EventHub, dbPath: string, platform: number) {
        this.eventEmitter = eventHub;
        impl.init(context, eventHub, dbPath);
        impl.setPlatform(platform);
        this.startLog();
        // if (Config.ENABLE_PTT) {
        //     pttClient.init();
        // }
        //self.setProxyInfo("", "192.168.1.80", 1080, "", "");
    }

    /**
     * 注册新的自定义消息
     *
     * @param {string} name
     * @param {number} flag 用来标识本消息是否需要存储、计数等，{@link PersistFlag}
     * @param {number} type 消息类型，{@link MessageContentType}
     * @param {class} clazz 消息对应的class
     */
    registerMessageContent(name: string, flag: number, type: number) {
        impl.registerMessageContent(name, flag, type);
    }

    /**
     * 获取clientId，获取用户token时，一定要通过调用此方法获取clientId，否则会连接失败。
     * @returns {string} clientId
     */
    getClientId(): string {
        return impl.getClientId();
    }

    /**
     * 获取协议栈版本号
     */
    getProtoRevision(): string {
        return impl.getProtoRevision();
    }

    /*
     * 启用国密加密。注意需要服务器端同步开启国密配置
     */
    useSM4() {
        impl.useSM4();
    }

    /*
     * 启用AES256加密。注意需要服务器端同步开启AES256配置
     */
    useAES256() {
        impl.useAES256();
    }

    /*
     * 开启日志，需要在connect之前调用。如果有设置包名或者其他connect之前调用的操作，需要放到这些操作之后。
     */
    startLog() {
        impl.startLog();
    }

    /*
     * 结束日志
     */
    stopLog() {
        impl.stopLog();
    }

    /*
     * 设置lite模式。lite模式不同步历史记录，本地不存储消息。
     */
    setLiteMode(liteMode: boolean) {
        impl.setLiteMode(liteMode);
    }

    /**
     * 启动 TCP 短连接
     */
    useTcpShortLink() {
        impl.useTcpShortLink();
    }

    /**
     * 是否启动 TCP 短连接
     * @return {*}
     */
    isTcpShortLink(): boolean {
        return impl.isTcpShortLink();
    }

    /**
     * 连接服务器
     * @param {string} userId 用户id
     * @param {string} token 用户token，生成token时，所使用的clientId，一定要通过{@link getClientId}获取
     * @return {number} 返回上一次活动时间。如果间隔时间较长，可以加个第一次登录的等待提示界面，在等待时同步所有的用户信息/群组信息/频道信息等。
     */
    connect(userId: string, token: string): number {
        return impl.connect(userId, token);
    }

    /**
     * 设置代理，只支持socks5代理
     *
     * @param {String} host       代理host，host和ip必须至少有一个。
     * @param {String} ip         代理IP，host和ip必须至少有一个。
     * @param {number} port       代理端口
     * @param {String} username   username
     * @param {String} password   password
     */
    setProxyInfo(host: string, ip: string, port: number, username: string, password: string) {
        impl.setProxyInfo(host, ip, port, username, password);
    }

    /**
     * 设置第三方推送设备token
     * @param {number} pushType 推送类型，0-5 移动端已经使用了。
     * @param {String} token 设备token
     */
    setDeviceToken(pushType: number, token: string) {
        impl.setDeviceToken(pushType, token);
    }


    /**
     * 主动断开连接
     *
     * @param disablePush  是否停止推送，在cleanSession为true时无意义
     * @param cleanSession 是否清除会话session，清除之后，所有之前的会话信息会被删除
     */
    disconnect(disablePush: boolean, cleanSession: boolean) {
        impl.disconnect(disablePush, cleanSession);
    }

    /**
     * 设置包名。包名会影响到数据库的存储路径，需要在调用connect之前调用。
     * @param packageName
     */
    setPackageName(packageName: string) {
        impl.setPackageName(packageName);
    }

    /**
     * 获取日志文件的路径列表。只有startLo之后才会生成日志。
     * @returns 日志文件的路径列表
     */
    getLogFilesPath(): string[] {
        let logPath = this.getAppPath();
        let filesPath: string[] = [];
        //Todo 遍历logPath目录，找出来所有protocol开头，xlog结尾的所有文件
        return filesPath;
    }

    /**
     * 获取当前用户的id
     * @returns {string} 当前用户的id
     */
    getUserId(): string {
        return impl.getUserId();
    }

    /**
     * 服务器时间和本地时间的差值
     * @returns {number} 服务器时间和本地时间的差值
     */
    getServerDeltaTime(): number {
        return impl.getServerDeltaTime();
    }

    /**
     * 是否成功登录
     * @returns {boolean}
     */
    isLogin(): boolean {
        return impl.isLogin();
    }

    /**
     * 获取连接状态
     * @returns {number} 连接状态，参考{@link ConnectionStatus}
     */
    getConnectionStatus(): number {
        return impl.getConnectionStatus();
    }

    /**
     * 设置网络策略，仅专业版支持
     * @param {int} strategy 网络策略。0 是自动选择；1 选择主网络；2选择备用网络
     *
     */
    setBackupAddressStrategy(strategy: number) {
        impl.setBackupAddressStrategy(strategy);
    }

    /**
     * 设置备选网络信息，仅专业版支持
     * @param {String} backupHost 备选网络主机地址
     * @param {int} backupPort 备选网络主机端口
     */
    setBackupAddress(backupHost: string, backupPort: number) {
        impl.setBackupAddress(backupHost, backupPort);
    }

    /**
     * 设置协议栈短连接UA。
     *
     * @param {string} userAgent 协议栈短连接使用的UA
     */
    setProtoUserAgent(userAgent: string) {
        impl.setProtoUserAgent(userAgent);
    }

    /**
     * 添加协议栈短连接自定义Header
     *
     * @param {string} header 协议栈短连接使用的UA
     * @param {string} value 协议栈短连接使用的UA
     */
    addHttpHeader(header: string, value: string) {
        impl.addHttpHeader(header, value)
    }

    /**
     * 设备从睡眠中恢复
     */
    onAppResume() {
        impl.onAppResume();
    }

    /**
     * 设备进入睡眠状态
     */
    onAppSuspend() {
        impl.onAppSuspend();
    }

    /**
     * 已废弃，请使用{@link getFavGroupList}
     * 获取我保存到通讯录的群组信息列表
     * @returns {[GroupInfo]} 参考{@link GroupInfo}
     */
    getMyGroupList() {
        return impl.getMyGroupList();
    }

    /**
     * 获取我保存到通讯录的群组信息列表
     * @returns {[GroupInfo]} 参考{@link GroupInfo}
     */
    getFavGroupList(): GroupInfo[] {
        return impl.getMyGroupList();
    }

    /**
     * 获取用户的displayName
     * @param {string} userId 用户id
     * @returns {string} 用户displayName
     */
    getUserDisplayName(userId: string) {
        let userInfo = this.getUserInfo(userId, false);
        if (!userInfo) {
            return '<' + userId + '>';
        }
        return userInfo.friendAlias ? userInfo.friendAlias : (userInfo.displayName ? userInfo.displayName : '<' + userId + '>');
    }

    /**
     * 获取用户在群里面的displayName
     * @param {string} groupId 群id
     * @param {string} userId 用户id
     * @param {boolean} ignoreFriendAlias 用户id
     * @returns {string} 用户在群里面的displayName
     */
    getGroupMemberDisplayName(groupId: string, userId: string, ignoreFriendAlias: boolean = false) {
        let userInfo = this.getUserInfo(userId, false, groupId);
        if (!userInfo) {
            return '<' + userId + '>';
        }

        return userInfo.groupAlias ? userInfo.groupAlias : (userInfo.friendAlias && !ignoreFriendAlias ? userInfo.friendAlias : (userInfo.displayName ? userInfo.displayName : '<' + userId + '>'))
    }

    /**
     * 这是一个辅助函数，用来读取用户信息中的用户名。
     * @param userInfo
     * @returns
     */
    getUserDisplayNameEx(userInfo: UserInfo) {
        return userInfo.friendAlias ? userInfo.friendAlias : (userInfo.displayName ? userInfo.displayName : '<' + userInfo.uid + '>');
    }

    /**
     * 这是一个辅助函数，用来读取群组用户信息中的用户名。
     * @param userInfo
     * @param ignoreFriendAlias
     * @returns
     */
    getGroupMemberDisplayNameEx(userInfo: UserInfo, ignoreFriendAlias: boolean = false) {
        return userInfo.groupAlias ? userInfo.groupAlias : (userInfo.friendAlias && !ignoreFriendAlias ? userInfo.friendAlias : (userInfo.displayName ? userInfo.displayName : '<' + userInfo.uid + '>'))
    }

    /**
     * 获取用户信息
     * @param {string} userId 用户id
     * @param {boolean} refresh 是否刷新用户信息，如果刷新的话，且用户信息有更新，会通过{@link eventEmitter}进行通知，事件的名字是{@link EventType.UserInfosUpdate }
     * @param {string} groupId
     * @returns {UserInfo}
     */
    getUserInfo(userId: string, refresh = false, groupId = ''): UserInfo {
        let userInfo = impl.getUserInfo(userId, refresh, groupId);
        if (!userInfo.portrait || userInfo.portrait.startsWith(Config.APP_SERVER)) {
            userInfo.portrait = this.defaultUserPortrait(userInfo);
        }
        return userInfo;
    }

    /**
     * 获取用户信息
     * @param {string} userId 用户ID
     * @param {boolean} refresh 是否强制从服务器更新，如果本地没有或者强制，会从服务器刷新
     * @param {function (UserInfo)} success 成功回调，如果本地有该用户信息，则通过回调返回本地的用户信息；如果本地没有，则从服务端拉取该用户信息，并通过回调返回
     * @param {function (number)} fail 失败回调
     */
    getUserInfoEx(userId: string, refresh: boolean, success: (userInfo: UserInfo) => void, fail: (err: number) => void) {
        impl.getUserInfoEx(userId, refresh, (info: UserInfo) => {
            if (!info.portrait || info.portrait.startsWith(Config.APP_SERVER)) {
                info.portrait = this.defaultUserPortrait(info);
            }
            success && success(info);
        }, fail);
    }

    /**
     * 批量获取用户信息
     * @param {[string]} userIds 用户ids
     * @param {string} groupId 群组id
     * @returns {[UserInfo]}
     */
    getUserInfos(userIds: string[], groupId?: string): UserInfo[] {
        let userInfos = impl.getUserInfos(userIds, groupId);
        userInfos.forEach((u) => {
            if (!u.portrait || u.portrait.startsWith(Config.APP_SERVER)) {
                u.portrait = this.defaultUserPortrait(u)
            }
        });
        return userInfos;
    }

    /**
     * 服务端搜索用户
     * @param {string} keyword 搜索关键字
     * @param {number} searchType 搜索类型，可选值参考{@link SearchType}
     * @param {number} page 页数，如果searchType是0，每次搜索20个，可以指定page。如果searchType非0，只能搜索一个，page无意义
     * @param {function (keyword, [UserInfo])} successCB
     * @param {function (number)}failCB
     * @returns {Promise<void>}
     */
    async searchUser(keyword: string, searchType: number, page: number, successCB: (keyword: string, userInfos: UserInfo[]) => void, failCB: (err: number) => void) {
        impl.searchUser(keyword, searchType, page, (keyword: string, userInfos: UserInfo[]) => {
            userInfos.forEach((u) => {
                if (!u.portrait || u.portrait.startsWith(Config.APP_SERVER)) {
                    u.portrait = this.defaultUserPortrait(u)
                }
            });
            successCB && successCB(keyword, userInfos);
        }, failCB);
    }

    /**
     * 本地搜索好友
     * @param keyword 搜索关键字
     * @returns {[UserInfo]}
     */
    searchFriends(keyword: string): UserInfo[] {
        return impl.searchFriends(keyword);
    }

    /**
     * 本地搜索群组
     * @param keyword 搜索关键字
     * @returns {[GroupSearchResult]}
     */
    searchGroups(keyword: string): GroupSearchResult[] {
        return impl.searchGroups(keyword);
    }

    /**
     * 获取收到的好友请求
     * @returns {[FriendRequest]}
     */
    getIncommingFriendRequest(): FriendRequest[] {
        return impl.getIncommingFriendRequest();
    }

    /**
     * 获取发送出去的好友请求
     * @returns {[FriendRequest]}
     */
    getOutgoingFriendRequest(): FriendRequest[] {
        return impl.getOutgoingFriendRequest();
    }

    /**
     * 获取单条好友请求
     * @param {string} userId 对方的用户id
     * @param {boolean} incoming 是否是收到的好友请求
     * @return {FriendRequest|null}
     */
    getOneFriendRequest(userId: string, incoming = true): FriendRequest | null {
        return impl.getOneFriendRequest(userId, incoming);
    }

    /**
     * 从服务端加载好友请求，如果有更新，会通过{@link eventEmitter}通知
     */
    loadFriendRequestFromRemote() {
        impl.loadFriendRequestFromRemote();
    }

    /**
     * 获取未读的好友请求数
     * @returns {number}
     */
    getUnreadFriendRequestCount(): number {
        return impl.getUnreadFriendRequestCount();
    }

    /**
     * 清除好友请求未读状态
     */
    clearUnreadFriendRequestStatus() {
        impl.clearUnreadFriendRequestStatus();
    }

    /**
     * 清除好友请求的历史记录。注意只清理本地数据，服务器端的会一直保留。
     * @param direction 方向，0是发出去的请求，1是收到的请求。
     * @param beforeTime 清除某个时间戳之前的请求，单位毫秒。如果清除全部用0
     */
    clearFriendRequest(direction: number, beforeTime: number) {
        impl.clearFriendRequest(direction, beforeTime);
    }

    /**
     * 删除好友请求
     * @param userId    用户ID
     * @param direction 方向，0是发出去的请求，1是收到的请求。
     */
    deleteFriendRequest(userId: string, direction: number) {
        impl.deleteFriendRequest(userId, direction);
    }


    /**
     * 删除好友
     * @param {string} userId 好友id
     * @param {function ()} successCB
     * @param {function (number) }failCB
     * @returns {Promise<void>}
     */
    async deleteFriend(userId: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.deleteFriend(userId, successCB, failCB);
    }

    /**
     * 处理好友请求
     * @param {string} userId 发送好友请求的用户的id
     * @param {boolean} accept true，接受好友请求；false，拒绝好友请求
     * @param {string} extra 一些额外信息，可用来实现好友来源等，推荐使用json格式
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async handleFriendRequest(userId: string, accept: boolean, extra: string, successCB: () => void, failCB: (err: number) => void) {
        impl.handleFriendRequest(userId, accept, extra, successCB, failCB);
    }

    /**
     * 判断用户是否被加入了黑名单
     * @param userId
     * @returns {boolean}
     */
    isBlackListed(userId: string): boolean {
        return impl.isBlackListed(userId);
    }

    /**
     * 获取黑名单
     * @returns {[string]}
     */
    getBlackList(): string[] {
        return impl.getBlackList();
    }

    /**
     * 设置黑名单
     * @param {string} userId 用户id
     * @param {boolean} block true，加入黑名单；false，移除黑名单
     * @param {function ()} successCB
     * @param {function (number)} failCB
     */
    setBlackList(userId: string, block: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setBlackList(userId, block, successCB, failCB);
    }

    /**
     * 获取好友列表，返回的时好友id数组
     * @param {boolean} fresh 是否刷新好友信息，如果刷新，且有更新的话，会通过{@link eventEmitter}通知
     * @returns {[string]}
     */
    getMyFriendList(fresh: boolean = false): string[] {
        return impl.getMyFriendList(fresh);
    }

    /**
     * 好友列表
     * @returns {[Friend]}
     */
    getFriendList(fresh = false) {
        return impl.getFriendList(fresh);
    }

    /**
     * 获取好友别名
     * @param {string} userId
     * @returns {string}
     */
    getFriendAlias(userId: string) {
        return impl.getFriendAlias(userId);
    }

    /**
     * 获取好友的Extra信息。
     * @param userId
     * @returns
     */
    getFriendExtra(userId: string) {
        return impl.getFriendExtra(userId);
    }

    /**
     * 设置好友别名
     * @param {string} userId 用户id
     * @param {string} alias 别名
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */

    async setFriendAlias(userId: string, alias: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setFriendAlias(userId, alias, successCB, failCB);
    }

    /**
     * 创建群组
     * @param {string | null} groupId 群组id，一般情况下，传null；如果有自己的用户系统，自己维护群信息，那么可以传群id
     * @param {number} groupType 群类型，可参考 {@link GroupType }
     * @param {string} name 群名称
     * @param {string} portrait 群头像的链接
     * @param {string} groupExtra 群组扩展信息
     * @param {[string]} memberIds 群成员id列表
     * @param {string} memberExtra 群组成员扩展信息
     * @param {[number]} lines 会话线路，默认传[0]即可
     * @param {CreateGroupNotification} notifyContent 通知信息，默认传null，服务端会生成默认通知
     * @param {function (string)} successCB 回调通知群id
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async createGroup(groupId: string, groupType: number, name: string, portrait: string, groupExtra: string, memberIds: string[] = [], memberExtra = '', lines: numberArray = [0], notifyContent: MessageContent | null, successCB: CallbackWithValue_1<string>, failCB: FailCallback) {
        impl.createGroup(groupId, groupType, name, portrait == null ? "" : portrait, groupExtra, memberIds, memberExtra, lines, notifyContent, successCB, failCB);
    }

    /**
     * 设置群管理员
     * @param {string} groupId 群id
     * @param {boolean} isSet true，设置；false，取消设置
     * @param {[string]} memberIds 将被设置为管理或取消管理远的群成员的用户id
     * @param {[number]} lines 默认传[0]即可
     * @param {Object} notifyContent 默认传null即可
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async setGroupManager(groupId: string, isSet: boolean, memberIds: string[], lines: numberArray, notifyContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setGroupManager(groupId, isSet, memberIds, lines, notifyContent, successCB, failCB);
    }

    /**
     * 获取群信息
     * @param {string} groupId 群id
     * @param {boolean} refresh 是否刷新，如果刷新，且有更新的话，会通过{@link eventEmitter}通知
     * @returns {GroupInfo}
     */
    getGroupInfo(groupId: string, refresh = false): GroupInfo {
        let info = impl.getGroupInfo(groupId, refresh);
        if (!info.portrait || info.portrait.startsWith(Config.APP_SERVER)) {
            info.portrait = this.defaultGroupPortrait(info);
        }
        return info;
    }


    /**
     * 批量获取群信息
     * @param {[string]} groupIds 群id
     * @param {boolean} refresh 是否刷新，如果刷新，且有更新的话，会通过{@link eventEmitter}通知
     * @returns {[GroupInfo]}
     */
    getGroupInfos(groupIds: string[], refresh = false) {
        let infos = impl.getGroupInfos(groupIds, refresh);
        infos.forEach(info => {
            if (!info.portrait || info.portrait.startsWith(Config.APP_SERVER)) {
                info.portrait = this.defaultGroupPortrait(info);
            }
        })
        return infos;
    }

    /**
     * 获取群信息
     * @param {string} groupId 群id
     * @param {boolean} refresh 是否刷新，如果刷新，且有更新的话，会通过{@link eventEmitter}通知
     * @param {function (GroupInfo)} successCB 成功回调
     * @param {function (number)} failCB 失败回调
     */
    getGroupInfoEx(groupId: string, refresh: boolean, successCB: (info:GroupInfo) => void, failCB: FailCallback) {
        impl.getGroupInfoEx(groupId, refresh, (info: GroupInfo) => {
            if (!info.portrait || info.portrait.startsWith(Config.APP_SERVER)) {
                info.portrait = this.defaultGroupPortrait(info);
            }
            successCB && successCB(info);
        }, failCB);
    }

    /**
     * 添加群成员
     * @param  {string} groupId 群组id
     * @param {[string]} memberIds 新添加的群成员id
     * @param  {string} extra 群成员扩展信息
     * @param {[number]} notifyLines
     * @param {AddGroupMemberNotification} notifyMessageContent
     * @param successCB
     * @param failCB
     */
    addGroupMembers(groupId: string, memberIds: string[], extra: string, notifyLines: numberArray, notifyMessageContent: MessageContent | null, successCB: () => void, failCB: (err: number) => void) {
        impl.addGroupMembers(groupId, memberIds, extra, notifyLines, notifyMessageContent, successCB, failCB);
    }

    /**
     * 获取群成员id列表
     * @param {string} groupId 群id
     * @param {boolean} fresh 是否刷新，刷新时，如果有更新，会通过{@link eventEmitter}通知
     * @returns {[string]} 群成员用户id列表
     */
    getGroupMemberIds(groupId: string, fresh = false): string[] {
        return impl.getGroupMemberIds(groupId, fresh);
    }

    /**
     * 获取群成员信息
     * @param {string} groupId 群id
     * @param {boolean} fresh 是否刷新
     * @returns {GroupMember[]} 群成员信息
     */
    getGroupMembers(groupId: string, fresh: boolean = false): GroupMember[] {
        return impl.getGroupMembers(groupId, fresh);
    }

    /**
     * 根据群成员类型获取群成员列表
     * @param {string} groupId
     * @param {number} memberType，可选值参考{@link GroupMemberType}
     * @return {[GroupMember]} 群成员列表
     */
    getGroupMembersByType(groupId: string, memberType: number): GroupMember[] {
        return impl.getGroupMembersByType(groupId, memberType);
    }

    getGroupMembersByCount(groupId: string, count: number): GroupMember[] {
        return impl.getGroupMembersByCount(groupId, count);
    }

    /**
     * 获取群成员信息
     * @param {string} groupId 群id
     * @param {boolean} fresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
     * @param {function ([GroupMember])} successCB
     * @param {function (number)} failCB
     */
    getGroupMembersEx(groupId: string, fresh: boolean, successCB: CallbackWithValue_1<GroupMember[]>, failCB: FailCallback) {
        impl.getGroupMembersEx(groupId, fresh, successCB, failCB);
    }

    /**
     * 获取单个群成员信息
     * @param {string} groupId 群id
     * @param {string} memberId 群成员id
     * @returns {GroupMember} 群成员信息
     */
    getGroupMember(groupId: string, memberId: string): GroupMember {
        return impl.getGroupMember(groupId, memberId);
    }

    /**
     * 将用户从群里移除
     * @param {string} groupId 群id
     * @param {[string]} memberIds 将要被移除的群成员id列表
     * @param {[]} notifyLines 默认传[0]即可
     * @param {KickoffGroupMemberNotification} notifyMsg 默认传null即可
     * @param {function ()} successCB
     * @param {function (number)} failCB
     */
    kickoffGroupMembers(groupId: string, memberIds: string[], notifyLines: numberArray, notifyMsg: MessageContent | null, successCB: () => void, failCB: (err: number) => void) {
        impl.kickoffGroupMembers(groupId, memberIds, notifyLines, notifyMsg, successCB, failCB);
    }

    /**
     * 对群成员禁言
     * @param {string} groupId 群id
     * @param {boolean} isSet true，禁言；false，取消禁言
     * @param {[string]} memberIds 群成员id列表
     * @param {[number]} notifyLines 默认传[0]即可
     * @param {MessageContent} notifyMsg 默认传null即可
     * @param {function ()} successCB 成功回调
     * @param {function (number)} failCB 失败回调
     */
    muteGroupMembers(groupId: string, isSet: boolean, memberIds: string[], notifyLines: numberArray, notifyMsg: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.muteOrAllowGroupMembers(groupId, isSet, false, memberIds, notifyLines, notifyMsg, successCB, failCB);
    }

    /**
     * 群全局禁言之后，允许白名单成员发言
     * @param {string} groupId 群id
     * @param {boolean} isSet true，加入白名单，允许发言；false，移除白名单，禁止发言
     * @param {[string]} memberIds 群成员id列表
     * @param {[number]} notifyLines 默认传[0]即可
     * @param {MessageContent} notifyMsg 默认传null即可
     * @param {function ()} successCB 成功回调
     * @param {function (number)} failCB 失败回调
     */
    allowGroupMembers(groupId: string, isSet: boolean, memberIds: string[], notifyLines: numberArray, notifyMsg: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.muteOrAllowGroupMembers(groupId, isSet, true, memberIds, notifyLines, notifyMsg, successCB, failCB);
    }

    /**
     * 退出群组
     * @param groupId 群id
     * @param {[]} lines 默认传[0]即可
     * @param {KickoffGroupMemberNotification} notifyMessageContent 默认传null即可
     * @param successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async quitGroup(groupId: string, lines: numberArray, notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.quitGroup(groupId, lines, notifyMessageContent, successCB, failCB);
    }

    /**
     * 解散群组
     * @param {string} groupId 群组id
     * @param {[]} lines 默认传[0]即可
     * @param {KickoffGroupMemberNotification} notifyMessageContent 默认传null即可
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async dismissGroup(groupId: string, lines: numberArray, notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.dismissGroup(groupId, lines, notifyMessageContent, successCB, failCB);
    }

    /**
     * 修改群信息
     * @param {string} groupId 群id
     * @param {number} type 修改信息所属类型，可选值参考{@link ModifyGroupInfoType}
     * @param {string} newValue 准备修改成什么
     * @param {[number]} lines
     * @param {GroupNotificationContent} notifyMessageContent
     * @param successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async modifyGroupInfo(groupId: string, type: number, newValue: string, lines: numberArray, notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.modifyGroupInfo(groupId, type, newValue, lines, notifyMessageContent, successCB, failCB);
    }

    /**
     * 修改我在群组的别名
     * @param {string} groupId 群id
     * @param {string} alias 别名
     * @param lines
     * @param notifyMessageContent
     * @param successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async modifyGroupAlias(groupId: string, alias: string, lines: numberArray, notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.modifyGroupAlias(groupId, alias, lines, notifyMessageContent, successCB, failCB);
    }

    /**
     * 修改群成员在群组的别名
     * @param {string} groupId 群id
     * @param {string} memberId 群成员id
     * @param {string} alias 别名
     * @param lines
     * @param notifyMessageContent
     * @param successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async modifyGroupMemberAlias(groupId: string, memberId: string, alias: string, lines: numberArray, notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.modifyGroupMemberAlias(groupId, memberId, alias, lines, notifyMessageContent, successCB, failCB);
    }

    /**
     * 修改群成员在群组的附加信息
     * @param {string} groupId 群id
     * @param {string} memberId 群成员id
     * @param {string} extra 群成员附加信息
     * @param lines
     * @param notifyMessageContent
     * @param successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async modifyGroupMemberExtra(groupId: string, memberId: string, extra: string, lines: numberArray, notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.modifyGroupMemberExtra(groupId, memberId, extra, lines, notifyMessageContent, successCB, failCB);
    }

    /**
     * 转移群主
     * @param {string} groupId 群id
     * @param {string} newOwner 新群主的id
     * @param lines
     * @param notifyMessageContent
     * @param successCB
     * @param failCB
     */
    transferGroup(groupId: string, newOwner: string, lines: numberArray, notifyMessageContent: MessageContent | null, successCB: SuccessCallback, failCB: FailCallback) {
        impl.transferGroup(groupId, newOwner, lines, notifyMessageContent, successCB, failCB);
    }

    /**
     * 设置群备注
     * @param {string} groupId 群id
     * @param {string} remark 群备注
     * @param successCB
     * @param failCB
     */
    async setGroupRemark(groupId: string, remark: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setGroupRemark(groupId, remark, successCB, failCB);
    }

    /**
     *  获取群备注
     * @param {string} groupId 群id
     * @return 群备注
     */
    getGroupRemark(groupId: string): string {
        return impl.getGroupRemark(groupId);
    }

    /**
     * 获取保存到通讯录的群id列表
     * @returns {[string]}
     */
    getFavGroups(): string[] {
        return impl.getFavGroups();
    }

    /**
     *  判断群是否保存到了通讯录
     * @param {string} groupId
     * @returns {boolean}
     */
    isFavGroup(groupId: string): boolean {
        return impl.isFavGroup(groupId);
    }

    /**
     * 将群保存到通讯录或移除通讯录
     * @param {string} groupId 群id
     * @param {boolean} fav true，保存到通讯录；false，从通讯录移除
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async setFavGroup(groupId: string, fav: boolean, successCB: SuccessCallback | null = null, failCB: FailCallback | null = null) {
        impl.setFavGroup(groupId, fav, successCB, failCB);
    }

    /**
     * 获取当前用户所有群组ID，此方法消耗资源较大，不建议高频使用。
     *
     * @param {function ([string])} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async getMyGroups(successCB: CallbackWithValue_1<string[]>, failCB: FailCallback) {
        impl.getMyGroups(successCB, failCB);
    }

    /**
     * 获取用户共同群组ID
     *
     * @param {string} userId
     * @param {function ([string])} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async getCommonGroups(userId: string, successCB: CallbackWithValue_1<string[]>, failCB: FailCallback) {
        impl.getCommonGroups(userId, successCB, failCB);
    }

    /**
     * 获取用户设置，保存格式可以理解为：scope + key => value
     * @param {number} scope 命名空间，可选值参考{@link UserSettingScope}
     * @param {string} key key
     * @returns {string} 设置的key对应的value
     */
    getUserSetting(scope: number, key: string): string {
        return impl.getUserSetting(scope, key);
    }

    /**
     * 获取某个命名空间下的所有设置
     * @param scope 命名空间，可选值参考{@link UserSettingScope}
     * @returns {Map} key-value
     */
    getUserSettings(scope: number): Record<string, string>[] {
        return impl.getUserSettings(scope);
    }

    /**
     * 设置或更新用户设置
     * @param {number} scope 命名空间
     * @param {string} key 设置的key
     * @param {string} value 设置的value
     * @param {function ()} successCB 成功回调
     * @param {function (number)} failCB 失败回调
     * @returns {Promise<void>}
     */
    async setUserSetting(scope: number, key: string, value: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setUserSetting(scope, key, value, successCB, failCB);
    }

    /**
     * 修改个人信息
     * @param {[ModifyMyInfoEntry]} modifyMyInfoEntries 需要修改的信息列表，pc端，一次只允许修改一个项。
     * @param successCB
     * @param failCB
     */
    modifyMyInfo(modifyMyInfoEntries: ModifyMyInfoEntry[], successCB: SuccessCallback, failCB: FailCallback) {
        impl.modifyMyInfo(modifyMyInfoEntries, successCB, failCB);
    }

    /**
     * 是否全局免打扰
     * @returns {boolean}
     */
    isGlobalSilent(): boolean {
        return impl.isGlobalSilent();
    }

    /**
     * 设置全局免打扰
     * @param {boolean} silent
     * @param {function ()} successCB
     * @param failCB
     */
    setGlobalSilent(silent: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setGlobalSilent(silent, successCB, failCB);
    }

    /**
     * 是否隐藏通知详情
     * @returns {boolean}
     */
    isHiddenNotificationDetail(): boolean {
        return impl.isHiddenNotificationDetail();
    }

    /**
     * 设置或取消设置隐藏通知详情
     * @param {boolean} hide 是否隐藏通知详情
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async setHiddenNotificationDetail(hide: boolean, successCB: SuccessCallback | null = null, failCB: FailCallback | null = null) {
        impl.setHiddenNotificationDetail(hide, successCB, failCB);
    }

    /**
     * 是否隐藏群成员昵称
     * @param {string} groupId 群id
     * @returns {boolean}
     */
    isHiddenGroupMemberName(groupId: string): boolean {
        return impl.isHiddenGroupMemberName(groupId);
    }

    /**
     * 设置或取消设置隐藏群成员昵称
     * @param {string} groupId 群id
     * @param {boolean} hide 是否隐藏
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async setHiddenGroupMemberName(groupId: string, hide: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setHiddenGroupMemberName(groupId, hide, successCB, failCB);
    }

    /**
     * 加入聊天室
     * @param {string} chatroomId 聊天室id
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async joinChatroom(chatroomId: string, successCB: () => void, failCB: (err: number) => void) {
        impl.joinChatroom(chatroomId, successCB, failCB);
    }

    /**
     * 退出聊天室
     * @param {string} chatroomId 聊天室id
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async quitChatroom(chatroomId: string, successCB: (() => void) | null = null, failCB: ((err: number) => void) | null = null) {
        impl.quitChatroom(chatroomId, successCB, failCB);
    }

    /**
     * 获取聊天室信息
     * @param {string} chatroomId 聊天是id
     * @param {number} updateDt 传当前时间对应的毫秒数
     * @param {function (ChatRoomInfo)} successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async getChatroomInfo(chatroomId: string, updateDt: number, successCB: (chatroomInfo: ChatRoomInfo) => void, failCB: (err: number) => void) {
        impl.getChatroomInfo(chatroomId, updateDt, successCB, failCB);
    }

    /**
     * 获取聊天室成员信息
     * @param {string} chatroomId 聊天室id
     * @param {number} maxCount 最多获取多少个聊天室成员信息
     * @param {function (ChatRoomMemberInfo)} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */

    async getChatroomMemberInfo(chatroomId: string, maxCount: number, successCB: SuccessCallback, failCB: FailCallback) {
        impl.getChatroomMemberInfo(chatroomId, maxCount, successCB, failCB);
    }

    /**
     * 创建频道
     * @param {string} name 频道名称
     * @param {string} portrait 频道头像的链接地址
     * @param {string} desc 描述
     * @param {string} extra 额外信息
     * @param {function (string)} successCB 创建成功，会回调通知channelId
     * @param {function (number)} failCB
     */
    createChannel(name: string, portrait: string, desc: string, extra: string, successCB: CallbackWithValue_1<ChannelInfo>, failCB: FailCallback) {
        impl.createChannel(name, portrait, desc, extra, successCB, failCB);
    }

    /**
     * 获取频道信息
     * @param {string} channelId 频道id
     * @param {boolean} refresh 是否强制刷新
     * @returns {ChannelInfo|NullChannelInfo}
     */
    getChannelInfo(channelId: string, refresh: boolean = false): ChannelInfo {
        return impl.getChannelInfo(channelId, refresh);
    }

    /**
     * 获取密聊信息
     * @param {string} targetId
     * @returns {SecretChatInfo}
     */
    getSecretChatInfo(targetId: string): SecretChatInfo | null {
        return impl.getSecretChatInfo(targetId);
    }

    /**
     * 销毁密聊
     * @param targetId
     * @param successCB
     * @param failCB
     */
    destroySecretChat(targetId: string, successCB: SuccessCallback | null = null, failCB: FailCallback | null = null) {
        impl.destroySecretChat(targetId, successCB, failCB);
    }

    /**
     * 使用密聊的密钥，加密数据。一般应用层无法直接使用。
     * @param targetId
     * @param mediaDataBuffer
     * @returns
     */
    encodeSecretChatMediaData(targetId: string, mediaDataBuffer: string): string {
        return impl.encodeSecretChatMediaData(targetId, mediaDataBuffer);
    }

    /**
     * 使用密聊的密钥，解密数据。在密聊会话中发送媒体类信息，对方收到的文件会是加密过的，需要调用此方法解密。
     * @param targetId
     * @param mediaDataBuffer
     * @returns
     */
    decodeSecretChatMediaData(targetId: string, mediaDataBuffer: string): string {
        return impl.decodeSecretChatMediaData(targetId, mediaDataBuffer);
    }

    /**
     * 设置密聊会话阅后即焚时间。
     * @param targetId
     * @param ms
     */
    setSecretChatBurnTime(targetId: string, ms: number) {
        impl.setSecretChatBurnTime(targetId, ms);
    }

    /**
     * 检查是否开启了密聊。密聊仅限于部分客户开启，详情请参考 https://docs.wildfirechat.cn/blogs/野火端到端及阅后即焚功能介绍.html
     * @returns
     */
    isEnableSecretChat(): boolean {
        return impl.isEnableSecretChat();
    }

    /**
     * 获取应用数据目录
     * @returns
     */
    getAppPath(): string {
        return impl.getAppPath();
    }

    /**
     * 获取自己是否开启密聊
     * @returns
     */
    isUserEnableSecretChat(): boolean {
        return impl.isUserEnableSecretChat();
    }

    /**
     * 设置自己是否开启密聊
     * @param enable
     * @param successCB
     * @param failCB
     */
    setUserEnableSecretChat(enable: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setUserEnableSecretChat(enable, successCB, failCB);
    }

    /**
     * 修改频道信息
     * @param {string} channelId 频道id
     * @param {number} type 修改什么，可选值参考{@link ModifyChannelInfoType}
     * @param {string} newValue 修改后的值
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async modifyChannelInfo(channelId: string, type: number, newValue: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.modifyChannelInfo(channelId, type, newValue, successCB, failCB);
    }

    /**
     * 搜索频道
     * @param {string} keyword 关键字
     * @param {boolean} fuzzy 是否模糊搜索
     * @param {function (keyword, [ChannelInfo])} successCB
     * @param {function (number)} failCB
     */
    searchChannel(keyword: string, fuzzy: boolean, successCB: (keyword: string, channelInfos: ChannelInfo[]) => void, failCB: (err: number) => void) {
        impl.searchChannel(keyword, successCB, failCB);
    }

    /**
     * 是否已收听/关注某个频道
     * @param {string} channelId 频道id
     * @returns {boolean}
     */
    isListenedChannel(channelId: string): boolean {
        return impl.isListenedChannel(channelId);
    }

    /**
     * 收听或取消收听频道
     * @param {string} channelId 频道id
     * @param {boolean} listen true，收听；false，取消收听
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async listenChannel(channelId: string, listen: boolean, successCB: SuccessCallback | null, failCB: FailCallback | null) {
        impl.listenChannel(channelId, listen, successCB, failCB);
    }

    /**
     * 获取自己创建的频道id列表
     * @returns {[string]}
     */
    getMyChannels() {
        return impl.getMyChannels();
    }

    /**
     * @deprecated 已废弃，请使用{@link getRemoteListenedChannels}
     * 获取所收听的频道id列表
     * @returns {[string]}
     */
    getListenedChannels(): string[] {
        return impl.getListenedChannels();
    }

    /**
     * 从服务端获取所收听的频道id列表
     * @param {function([String])} successCB
     * @param {function (number)} failCB
     *
     */
    getRemoteListenedChannels(successCB: CallbackWithValue_1<string[]>, failCB: FailCallback) {
        impl.getRemoteListenedChannels(successCB, failCB);
    }

    /**
     * 销毁频道
     * @param {string} channelId 频道id
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async destoryChannel(channelId: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.destoryChannel(channelId, successCB, failCB);
    }

    /**
     * 获取会话列表
     * @param {[number]} types 想获取的会话类型，可选值参考{@link ConversationType}
     * @param {[0]} lines 想获取哪些会话线路的会话，默认传[0]即可
     * @returns {[ConversationInfo]}
     */
    getConversationInfoList(types: numberArray, lines: numberArray): ConversationInfo[] {
        return impl.getConversationInfoList(types, lines);
    }

    /**
     * 获取会话详情
     * @param {Conversation} conversation
     * @returns {ConversationInfo}
     */
    getConversationInfo(conversation: Conversation): ConversationInfo {
        return impl.getConversationInfo(conversation);
    }

    /**
     * 搜索会话
     * @param {string} keyword 关键字
     * @param {[number]} types 从哪些类型的会话中进行搜索，可选值可参考{@link ConversationType}
     * @param {[number]} lines 从哪些会话线路进行搜索，默认传[0]即可
     * @returns {[ConversationSearchResult]}
     */
    searchConversation(keyword: string, types = [0, 1, 2], lines = [0, 1, 2]): ConversationSearchResult[] {
        return impl.searchConversation(keyword, types, lines);
    }

    /**
     * 搜索会话
     * @param {string} keyword 关键字
     * @param {[number]} types 从哪些类型的会话中进行搜索，可选值可参考{@link ConversationType}
     * @param {[number]} lines 从哪些会话线路进行搜索，默认传[0]即可
     * @param {number} startTime 消息的起始时间
     * @param {number} endTime 消息的结束时间
     * @param {boolean} desc 是否逆序
     * @param {boolean} desc 是否逆序
     * @param {int} limit 返回数量
     * @param {int} offset offset
     * @returns {[ConversationSearchResult]}
     */
    searchConversationEx(keyword: string, types: numberArray, lines: numberArray, startTime: number, endTime: number, desc = false, limit = 20, offset = 0): ConversationSearchResult[] {
        return impl.searchConversationEx(keyword, types, lines, startTime, endTime, desc, limit, offset);
    }

    /**
     * 搜索会话
     * @param {string} keyword 关键字
     * @param {[number]} types 从哪些类型的会话中进行搜索，可选值可参考{@link ConversationType}
     * @param {[number]} lines 从哪些会话线路进行搜索，默认传[0]即可
     * @param {[number]} cntTypes 搜索指定消息内容类型
     * @param {number} startTime 消息的起始时间
     * @param {number} endTime 消息的结束时间
     * @param {boolean} desc 是否逆序
     * @param {boolean} desc 是否逆序
     * @param {int} limit 返回数量
     * @param {int} offset offset
     * @param {boolean} onlyMentionedMsg 是否只搜索提醒消息
     * @returns {[ConversationSearchResult]}
     */
    searchConversationEx2(keyword: string, types: numberArray, lines: numberArray, cntTypes: numberArray, startTime: number, endTime: number, desc = false, limit = 20, offset = 0, onlyMentionedMsg = false): ConversationSearchResult[] {
        return impl.searchConversationEx2(keyword, types, lines, cntTypes, startTime, endTime, desc, limit, offset, onlyMentionedMsg);
    }

    /**
     * 删除会话
     * @param {Conversation} conversation 想删除的目标会话
     * @param {boolean} clearMsg 是否已删除的会话的消息
     * @returns {Promise<void>}
     */
    async removeConversation(conversation: Conversation, clearMsg = true) {
        impl.removeConversation(conversation, clearMsg);
    }

    /**
     * 会话置顶或取消置顶
     * @param {Conversation} conversation 需要置顶或取消置顶的会话
     * @param {number} top > 0, 置顶，可以根据这个值进行置顶排序；0，取消置顶
     * @param {function ()} successCB
     * @param {function (number)} failCB
     */
    setConversationTop(conversation: Conversation, top: number, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setConversationTop(conversation, top, successCB, failCB);
    }

    /**
     * 会话免打扰或取消免打扰
     * @param {Conversation} conversation 目标会话
     * @param {boolean} silent true，设置为免打扰；false，取消免打扰
     * @param {function ()} successCB
     * @param {function (number)} failCB
     */
    setConversationSlient(conversation: Conversation, silent: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setConversationSlient(conversation, silent, successCB, failCB);
    }

    /**
     * 保存会话草稿
     * @param {Conversation} conversation 目标会话
     * @param {string} draft 草稿，传''时，相当于清楚会话草稿
     */
    setConversationDraft(conversation: Conversation, draft: string) {
        impl.setConversationDraft(conversation, draft);
    }

    /**
     * 设置会话时间错，当会话不存在时，会创建一个新的会话。
     * @param {Conversation} conversation
     * @param {number} timestamp
     */
    setConversationTimestamp(conversation: Conversation, timestamp: number) {
        impl.setConversationTimestamp(conversation, timestamp);
    }

    /**
     * 获取未读消息数
     * @param {[number]} types 获取未读数时，包含哪些类型的会话，可选值参考{@link ConversationType}
     * @param {[number]} lines 获取未读数时，包含哪些会话线路，默认传[0]即可
     * @returns {UnreadCount}
     */
    getUnreadCount(types = [0, 1, 2], lines = [0]): UnreadCount {
        return impl.getUnreadCount(types, lines);
    }

    /**
     * 获取某个会话的未读消息数
     * @param {Conversation} conversation 目标会话
     * @returns {UnreadCount}
     */
    getConversationUnreadCount(conversation: Conversation): UnreadCount {
        return impl.getConversationUnreadCount(conversation);
    }

    clearConversationsUnreadStatus(types = [0, 1, 2], lines = [0]) {
        impl.clearConversationsUnreadStatus(types, lines);
    }

    /**
     * 清楚会话消息未读状态
     * @param {Conversation} conversation 目标会话
     */
    clearConversationUnreadStatus(conversation: Conversation) {
        impl.clearConversationUnreadStatus(conversation);
    }

    /**
     * 清楚会话消息中指定消息id之前的消息（包含）未读状态
     * @param {Conversation} conversation 目标会话
     * @param {int} messageId 消息id
     */
    clearUnreadStatusBeforeMessage(conversation: Conversation, messageId: number) {
        impl.clearUnreadStatusBeforeMessage(conversation, messageId);
    }

    /**
     * 将会话最后一条消息置为未读
     * @param {Conversation} conversation 会话
     * @param {boolean} syncToOtherClient 是否同步给其他端
     * @return {boolean} 是否操作成功
     */
    markConversationAsUnread(conversation: Conversation, syncToOtherClient: boolean): boolean {
        return impl.markConversationAsUnread(conversation, syncToOtherClient);
    }

    /**
     * 清除单条消息的未读状态
     * @param messageId
     */
    clearMessageUnreadStatus(messageId: number) {
        impl.clearMessageUnreadStatus(messageId);
    }

    /**
     * 清除所有消息的未读状态
     *
     * 特别注意1：本方法只清除了底层数据库中的未读状态，并未清理 UI 层会话列表中的未读状态，UI 层会话列表中的未读状态，需要手动重置。
     * 特别注意2：本方法不会触发{@link ConversationInfoUpdate} 事件
     */
    clearAllUnreadStatus() {
        impl.clearAllUnreadStatus();
    }

    /**
     * 设置媒体消息的状态为已播放
     * @param {number} messageId 消息id，不是消息uid!
     */
    setMediaMessagePlayed(messageId: number) {
        impl.setMediaMessagePlayed(messageId);
    }

    /**
     * 设置消息本地扩展信息
     * @param {number} messageId 消息id，不是消息uid!
     * @param {string} extra 扩展信息
     */
    setMessageLocalExtra(messageId: number, extra: string) {
        impl.setMessageLocalExtra(messageId, extra);
    }

    /**
     * 判断是否是好友
     * @param {string} userId 用户id
     * @returns {boolean}
     */
    isMyFriend(userId: string): boolean {
        return impl.isMyFriend(userId);
    }

    /**
     * 获取星标用户id列表
     * @returns {[string]}
     */
    getFavUsers(): string[] {
        return impl.getFavUsers();
    }

    /**
     *  判断用户是否是星标用户
     * @param {string} userId
     * @returns {boolean}
     */
    isFavUser(userId: string): boolean {
        return impl.isFavUser(userId);
    }

    /**
     * 设置或取消星标用户
     * @param {string} userId 用户id
     * @param {boolean} fav true，保存到通讯录；false，从通讯录移除
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async setFavUser(userId: string, fav: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setFavUser(userId, fav, successCB, failCB);
    }

    /**
     * 发送好友请求
     * @param {string} userId 目标用户id
     * @param {string} reason 发送好友请求的原因
     * @param {string} extra 请求的扩展信息
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async sendFriendRequest(userId: string, reason: string, extra: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.sendFriendRequest(userId, reason, extra, successCB, failCB);
    }

    /**
     * 获取会话消息
     * @param {Conversation} conversation 目标会话
     * @param {number} fromIndex messageId，表示从那一条消息开始获取
     * @param {boolean} before true, 获取fromIndex之前的消息，即更旧的消息；false，获取fromIndex之后的消息，即更新的消息。都不包含fromIndex对应的消息
     * @param {number} count 获取多少条消息
     * @param {string} withUser 只有会话类型为{@link ConversationType#Channel}时生效, channel主用来查询和某个用户的所有消息
     * @param {function (Message[])} successCB
     * @param failCB
     */
    getMessagesV2(conversation: Conversation, fromIndex: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.getMessagesV2(conversation, fromIndex, before, count, withUser, successCB, failCB);
    }

    /**
     * 获取会话提醒消息，注意这里是获取所有的提醒消息，包括已读和未读的。如果需要获取未读的提醒消息，请使用getMessagesByStatusV2方法，参数messageStatus填入[MessageStatus.Mentioned, MessageStatus.AllMentioned]
     * @param {Conversation} conversation 目标会话
     * @param {number} fromIndex messageId，表示从那一条消息开始获取
     * @param {boolean} before true, 获取fromIndex之前的消息，即更旧的消息；false，获取fromIndex之后的消息，即更新的消息。都不包含fromIndex对应的消息
     * @param {number} count 获取多少条消息
     * @param {function (Message[])} successCB
     * @param failCB
     */
    getMentionedMessages(conversation: Conversation, fromIndex: number, before: boolean, count: number, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.getMentionedMessages(conversation, fromIndex, before, count, successCB, failCB);
    }

    /**
     * 获取消息
     * @param {[number]} conversationTypes 会话类型列表，可选值参考{@link  ConversationType}
     * @param {[number]} lines 会话线路列表
     * @param {number} fromIndex 本参数暂时无效! messageId，表示从那一条消息开始获取
     * @param {boolean} before 本参数暂时无效! true, 获取fromIndex之前的消息，即更旧的消息；false，获取fromIndex之后的消息，即更新的消息。都不包含fromIndex对应的消息
     * @param {number} count 本参数暂时无效! 获取多少条消息
     * @param {string} withUser 只有会话类型为{@link ConversationType#Channel}时生效, channel主用来查询和某个用户的所有消息
     * @param {[number]} contentTypes 消息类型列表，可选值参考{@link MessageContentType}
     * @param {function (Message)} successCB
     * @param failCB
     */
    getMessagesExV2(conversationTypes: numberArray, lines: numberArray, fromIndex: number, before: boolean, count: number, withUser: string, contentTypes: numberArray, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.getMessagesExV2(conversationTypes, lines, contentTypes, fromIndex, before, count, withUser, successCB, failCB);
    }

    /**
     *
     * @param {[number]} conversationTypes 会话类型列表，可选值参考{@link  ConversationType}
     * @param {[number]} lines 会话线路列表
     * @param {[number]} messageStatus 消息状态，可选值参考{@link MessageStatus}
     * @param {number} fromIndex 本参数暂时无效! messageId，表示从那一条消息开始获取
     * @param {boolean} before 本参数暂时无效! true, 获取fromIndex之前的消息，即更旧的消息；false，获取fromIndex之后的消息，即更新的消息。都不包含fromIndex对应的消息
     * @param {number} count 本参数暂时无效! 获取多少条消息
     * @param {string} withUser 只有会话类型为{@link ConversationType#Channel}时生效, channel主用来查询和某个用户的所有消息
     * @param {function (Message)} successCB
     * @param failCB
     */
    getMessagesEx2V2(conversationTypes: numberArray, lines: numberArray, messageStatus: numberArray, fromIndex: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.getMessagesEx2V2(conversationTypes, lines, messageStatus, fromIndex, before, count, withUser, successCB, failCB);
    }

    /**
     * 获取会话消息
     * @param {Conversation} conversation 目标会话
     * @param {[number]} contentTypes 消息类型，可选值参考{@link MessageContentType}
     * @param {number} timestamp 时间戳
     * @param {boolean} before true, 获取timestamp之前的消息，即更旧的消息；false，获取timestamp之后的消息，即更新的消息。都不包含timestamp对应的消息
     * @param {number} count 获取多少条消息
     * @param {string} withUser 只有会话类型为{@link ConversationType#Channel}时生效, channel主用来查询和某个用户的所有消息
     * @param {function ([Message])} successCB
     * @param failCB
     */
    getMessagesByTimestampV2(conversation: Conversation, contentTypes: numberArray, timestamp: number, before: boolean, count: number, withUser: string, successCB: (msgs: Message[]) => void, failCB: (err: number) => void) {
        impl.getMessagesByTimestampV2(conversation, contentTypes, timestamp, before, count, withUser, successCB, failCB);
    }

    /**
     * 获取会话消息
     * @param {Conversation} conversation 目标会话
     * @param {[number]} statuses 消息状态类型，可选值参考{@link MessageStatus}
     * @param {number} fromIndex 本参数暂时无效！ messageId，表示从那一条消息开始获取
     * @param {boolean} before 本参数暂时无效！ true, 获取fromIndex之前的消息，即更旧的消息；false，获取fromIndex之后的消息，即更新的消息。都不包含fromIndex对应的消息
     * @param {number} count 本参数暂时无效! 获取多少条消息
     * @param {string} withUser 只有会话类型为{@link ConversationType#Channel}时生效, channel主用来查询和某个用户的所有消息
     * @param {function ([Message])} successCB
     * @param failCB
     */
    getMessagesByStatusV2(conversation: Conversation, statuses: numberArray, fromIndex: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.getMessagesByStatusV2(conversation, statuses, fromIndex, before, count, withUser, successCB, failCB);
    }

    /**
     * 获取用户会话消息
     * @param {string} userId 用户id
     * @param {Conversation} conversation 目标会话
     * @param {number[]} contTypes 需要获取的消息类型，为空，获取所有消息类型
     * @param {number} fromIndex 本参数暂时无效！ messageId，表示从那一条消息开始获取
     * @param {boolean} before 本参数暂时无效！ true, 获取fromIndex之前的消息，即更旧的消息；false，获取fromIndex之后的消息，即更新的消息。都不包含fromIndex对应的消息
     * @param {number} count 本参数暂时无效! 获取多少条消息
     * @param {function (Message)} successCB
     * @param failCB
     */
    getUserMessagesV2(userId: string, conversation: Conversation, contTypes: numberArray, fromIndex: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.getUserMessagesV2(userId, conversation, contTypes, fromIndex, before, count, withUser, successCB, failCB);
    }

    /**
     * 获取用户消息
     * @param {string} userId 用户id
     * @param {[number]} conversationTypes 想获取的会话类型，可选值参考{@link ConversationType}
     * @param {[0]} lines 想获取哪些会话线路的会话，默认传[0]即可
     * @param {number} fromIndex 本参数暂时无效！ messageId，表示从那一条消息开始获取
     * @param {boolean} before 本参数暂时无效！ true, 获取fromIndex之前的消息，即更旧的消息；false，获取fromIndex之后的消息，即更新的消息。都不包含fromIndex对应的消息
     * @param {number} count 本参数暂时无效！ 获取多少条消息
     * @param {[number]} contentTypes 消息类型，可选值参考{@link MessageContentType}
     * @param {function (Message)} successCB
     * @param failCB
     */
    getUserMessagesExV2(userId: string, conversationTypes: numberArray, lines: numberArray, contentTypes: numberArray, fromIndex: number, before: boolean, count: number, withUser: string, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.getUserMessagesExV2(userId, conversationTypes, lines, contentTypes, fromIndex, before, count, withUser, successCB, failCB);
    }

    /**
     * 获取会话第一条未读消息的消息id
     * @param {Conversation} conversation
     * @return {number}
     */
    getFirstUnreadMessageId(conversation: Conversation): number {
        return impl.getConversationFirstUnreadMessageId(conversation);
    }

    /**
     * 已废弃，请使用{@link loadRemoteConversationMessages}
     * 获取会还的远程历史消息
     * @param {Conversation} conversation 目标会话
     * @param {[number]} contentTypes 消息类型列表，可选值参考{@link MessageContentType}
     * @param {number | Long} beforeUid 消息uid，表示拉取本条消息之前的消息
     * @param {number} count
     * @param {function (Message)} successCB
     * @param failCB
     */
    loadRemoteMessages(conversation: Conversation, contentTypes: numberArray, beforeUid: Long, count: number, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.loadRemoteMessages(conversation, contentTypes, beforeUid, count, successCB, failCB);
    }

    /**
     * 获取会话的远程历史消息
     * @param {Conversation} conversation 目标会话
     * @param {[number]} contentTypes 消息类型列表，可选值参考{@link MessageContentType}
     * @param {number | Long} beforeUid 消息uid，表示拉取本条消息之前的消息
     * @param {number} count
     * @param {function ([Message])} successCB
     * @param failCB
     */
    loadRemoteConversationMessages(conversation: Conversation, contentTypes: numberArray, beforeUid: Long, count: number, successCB: CallbackWithValue_1<Message[]>, failCB: FailCallback) {
        impl.loadRemoteMessages(conversation, contentTypes, beforeUid, count, successCB, failCB);
    }

    // /**
    //  * 获取会话的远程历史消息，仅 web 有效
    //  * @param {Conversation} conversation 目标会话
    //  * @param {[number]} contentTypes 消息类型列表，可选值参考{@link MessageContentType}
    //  * @param {number | Long} beforeUid 消息uid，表示拉取本条消息之前的消息
    //  * @param {number} count
    //  * @param {boolean} filterLocalMessage 是否过滤本地已经存在的消息
    //  * @param {function ([Message])} successCB
    //  * @param failCB
    //  */
    // TODO
    // loadRemoteConversationMessagesEx(conversation:Conversation, contentTypes:number[], beforeUid:Long, count:number, filterLocalMessage:boolean, successCB, failCB) {
    //     impl.loadRemoteMessages(conversation, contentTypes, beforeUid, count, successCB, failCB);
    // }

    /**
     * 根据会话线路，获取远程历史消息，仅 web 端有效
     * @param {number} line 会话线路
     * @param {number | Long} beforeUid 消息uid，表示拉取本条消息之前的消息
     * @param {[number]} contentTypes 消息类型列表，可选值参考{@link MessageContentType}
     * @param {number} count
     * @param {boolean} filterLocalMessage 是否过滤本地已经存在的消息
     * @param {function ([Message])} successCB
     * @param failCB
     */
    // TODO
    // loadRemoteLineMessages(line:number, contentTypes:number[], beforeUid:Long, count:number, filterLocalMessage, successCB, failCB) {
    //     // fixme
    //     // impl.loadRemoteLineMessages(line, contentTypes, beforeUid, count, successCB, failCB, filterLocalMessage)
    // }

    /**
     * 根据消息 uid，获取远程消息
     * @param {Long |String} messageUid 消息uid
     * @param {function ([Message])} successCB
     * @param failCB
     */
    loadRemoteMessage(messageUid: Long, successCB: CallbackWithValue_1<Message>, failCB: FailCallback) {
        impl.loadRemoteMessage(messageUid, successCB, failCB);
    }

    /**
     * 获取消息
     * @param {number} messageId 消息id
     * @returns {null|Message}
     */
    getMessageById(messageId: number): Message | null {
        return impl.getMessageById(messageId);
    }

    /**
     * 获取消息
     * @param {Long|string|number} messageUid
     * @returns {null|Message}
     */
    getMessageByUid(messageUid: Long): Message | null {
        return impl.getMessageByUid(messageUid);
    }

    /**
     * 搜索消息
     * @param {Conversation} conversation 目标会话
     * @param {string} keyword 关键字
     * @param {string} withUser 目标用户
     * @returns {[Message]}
     */
    searchMessage(conversation: Conversation, keyword: string, withUser = '') {
        return impl.searchMessage(conversation, keyword, withUser);
    }

    /**
     * 搜索消息
     * @param {Conversation} conversation 目标会话，如果为空搜索所有会话
     * @param {string} keyword 关键字
     * @param {boolean} desc 逆序排列
     * @param {int} limit 返回数量
     * @param {int} offset 偏移
     * @param {string} withUser 目标用户
     * @returns {Message[]}
     */
    searchMessageEx(conversation: Conversation, keyword: string, desc: boolean, limit = 20, offset = 0, withUser = ''): Message[] {
        return impl.searchMessageEx(conversation, keyword, desc, limit, offset, withUser);
    }

    /**
     * 搜索提醒消息
     * @param {Conversation} conversation 目标会话，如果为空搜索所有会话
     * @param {string} keyword 关键字
     * @param {boolean} desc 逆序排列
     * @param {int} limit 返回数量
     * @param {int} offset 偏移
     * @returns {Message[]}
     */
    searchMentionedMessages(conversation: Conversation, keyword: string, desc: boolean, limit = 20, offset = 0): Message[] {
        return impl.searchMentionedMessages(conversation, keyword, desc, limit, offset);
    }

    /**
     * 搜索消息
     * @param {Conversation} conversation 目标会话，如果为空搜索所有会话
     * @param {string} keyword 关键字
     * @param {[number]} contentTypes 消息类型列表，可选值参考{@link MessageContentType}
     * @param {boolean} desc 逆序排列
     * @param {int} limit 返回数量
     * @param {int} offset 偏移
     * @param {string} withUser 目标用户
     * @returns {Message[]}
     */
    searchMessageByTypes(conversation: Conversation, keyword: string, contentTypes: numberArray, desc: boolean, limit = 20, offset = 0, withUser = ''): Message[] {
        return impl.searchMessageByTypes(conversation, keyword, contentTypes, desc, limit, offset, withUser);
    }

    /**
     * 搜索消息
     * @param {Conversation} conversation 目标会话，如果为空搜索所有会话
     * @param {string} keyword 关键字
     * @param {[number]} contentTypes 消息类型列表，可选值参考{@link MessageContentType}
     * @param {Long} 消息起始时间，如果为0，则忽略起始时间。
     * @param {Long} 消息结束时间，如果为0，测忽略结束时间。
     * @param {boolean} desc 逆序排列
     * @param {int} limit 返回数量
     * @param {int} offset 偏移
     * @param {string} withUser 目标用户
     * @returns {Message[]}
     */
    searchMessageByTypesAndTimes(conversation: Conversation, keyword: string, contentTypes: numberArray, startTime: number, endTime: number, desc: boolean, limit = 20, offset = 0, withUser = ''): Message[] {
        return impl.searchMessageByTypesAndTimes(conversation, keyword, contentTypes, startTime, endTime, desc, limit, offset, withUser);
    }

    /**
     * 搜索消息
     * @param {[number]} conversationTypes 会话类型列表，可选值参考{@link  ConversationType}
     * @param {[number]} lines 会话线路列表
     * @param {[number]} contentTypes 消息类型列表，可选值参考{@link MessageContentType}
     * @param {string} keyword 关键字
     * @param {number} fromIndex messageId，表示从那一条消息开始获取
     * @param {boolean} desc 逆序排列
     * @param {number} count 最大数量
     * @param {string} withUser 目标用户
     * @returns {[Message]}
     */
    searchMessageEx2(conversationTypes: numberArray, lines: numberArray, contentTypes: numberArray, keyword: string, fromIndex: number, desc: boolean, count = 20, withUser = ''): Message[] {
        return impl.searchMessageEx2(conversationTypes, lines, contentTypes, keyword, fromIndex, desc, count, withUser);
    }

    /**
     * 搜索提醒消息
     * @param {[number]} conversationTypes 会话类型列表，可选值参考{@link  ConversationType}
     * @param {[number]} lines 会话线路列表
     * @param {string} keyword 关键字
     * @param {boolean} desc 逆序排列
     * @param {int} limit 返回数量
     * @param {int} offset 偏移
     * @returns {[Message]}
     */
    searchMentionedMessageEx(conversationTypes: numberArray, lines: numberArray, keyword: string, desc: boolean, limit = 20, offset = 0): Message[] {
        return impl.searchMentionedMessageEx(conversationTypes, lines, keyword, desc, limit, offset);
    }

    /**
     * 发送消息
     * @param {Conversation} conversation 目标会话
     * @param {MessageContent} messageContent 具体的消息内容，一定要求是{@link MessageContent} 的子类，不能是普通的object
     * @param {[string]} toUsers 定向发送给会话中的某些用户；为空，则发给所有人；另外对单聊会话，本参数无效
     * @param {function (number, number)} preparedCB 消息已插入本地数据的回调，回调的两个参数表示：messageId, timestamp
     * @param {function (number, number)} progressCB 媒体上传进度回调，针对媒体消息，且媒体大于100K时有效，回调参数表示：uploaded, total
     * @param {function (string)} uploadedCB 媒体上传成功回调，针对媒体消息
     * @param {function (long, number)} successCB 发送成功回调，回调参数表示：messageUid, timestamp
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async sendConversationMessage(conversation: Conversation, messageContent: MessageContent, toUsers: string[] = [], preparedCB?: CallbackWithValue_1_OrNull<number>, progressCB?: CallbackWithValue_2_OrNull<number, number>, uploadedCB?: CallbackWithValue_1_OrNull<string>, successCB?: CallbackWithValue_2_OrNull<Long, number>, failCB?: FailCallbackOrNull) {
        impl.sendConversationMessage(conversation, messageContent, toUsers, preparedCB, progressCB, uploadedCB, successCB, failCB);
    }

    /**
     * 发送消息，参考{@link sendConversationMessage}
     * @param {Message} message 一定要求是{@link Message}类型
     * @param preparedCB
     * @param progressCB
     * @param uploadedCB 媒体上传成功回调，针对媒体消息
     * @param successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async sendMessage(message: Message, preparedCB: CallbackWithValue_1_OrNull<number>, progressCB: CallbackWithValue_2<number, number>, uploadedCB: CallbackWithValue_1_OrNull<string>, successCB: CallbackWithValue_2<Long, number>, failCB: FailCallback) {
        impl.sendMessage(message, preparedCB, progressCB, uploadedCB, successCB, failCB);
    }

    /**
     * 发送消息，参考{@link sendMessage}
     * @param message
     * @param toUsers
     * @param preparedCB
     * @param progressCB
     * @param uploadedCB
     * @param successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async sendMessageEx(message: Message, toUsers = [], preparedCB: CallbackWithValue_1<number>, progressCB: CallbackWithValue_2_OrNull<number, number>, uploadedCB: CallbackWithValue_1_OrNull<string>, successCB: CallbackWithValue_2<Long, number>, failCB: FailCallback) {
        impl.sendMessageEx(message, toUsers, preparedCB, progressCB, uploadedCB, successCB, failCB);
    }

    /**
     * 发送已经保存的消息，参考{@link sendMessage}
     * @param message
     * @param expireDuration
     * @param successCB
     * @param failCB
     * @returns {Promise<void>}
     */
    async sendSavedMessage(message: Message, expireDuration: number, successCB: CallbackWithValue_2<Long, number>, failCB: FailCallback) {
        impl.sendSavedMessage(message, expireDuration, successCB, failCB);
    }

    /**
     * 取消发送消息，仅媒体类消息可以取消
     * @param messageId 消息ID
     * @returns 是否取消成功
     */
    cancelSendingMessage(messageId: number): boolean {
        return impl.cancelSendingMessage(messageId);
    }

    // 更新了原始消息的内容
    /**
     * 撤回消息
     * @param {Long} messageUid
     * @param {function ()} successCB
     * @param {function (number)} failCB
     * @returns {Promise<void>}
     */
    async recallMessage(messageUid: Long, successCB: SuccessCallback, failCB: FailCallback) {
        impl.recallMessage(messageUid, successCB, failCB);
    }

    /**
     * 删除消息
     * @param {number} messageId 消息id
     * @returns {*}
     */
    deleteMessage(messageId: number): boolean {
        return impl.deleteMessageById(messageId);
    }

    /**
     * 批量删除本地消息
     * @param {[string]} messageUids 消息uid列表
     * @returns {*}
     */
    batchDeleteMessages(messageUids: string[]): boolean {
        return impl.batchDeleteMessages(messageUids);
    }

    /**
     * 删除远程消息
     * @param {Long | string} msgUid 消息uid
     * @param {function ()} successCB
     * @param {function (number)} failCB
     */
    deleteRemoteMessageByUid(msgUid: Long, successCB: SuccessCallback, failCB: FailCallback) {
        impl.deleteRemoteMessage(msgUid, successCB, failCB);
    }

    /**
     * 更新远程消息消息内容，只有专业版支持。客户端仅能更新自己发送的消息，更新的消息类型不能变，更新的消息类型是服务配置允许更新的内容。Server API更新则没有限制。
     * @param {Long | string} msgUid 消息uid
     * @param {MessageContent} messageContent 具体的消息内容，一定要求是{@link MessageContent} 的子类，不能是普通的object
     * @param {boolean} distribute 是否重新分发给其他客户端
     * @param {boolean} updateLocal 是否更新本地消息内容
     * @param {function ()} successCB
     * @param {function (number)} failCB
     */
    updateRemoteMessageContent(msgUid: Long, messageContent: MessageContent, distribute: boolean, updateLocal: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.updateRemoteMessageContent(msgUid, messageContent, distribute, updateLocal, successCB, failCB);
    }

    /**
     * 清除会话消息
     * @param {Conversation} conversation 目标会话
     * @returns {Promise<void>}
     */
    async clearMessages(conversation: Conversation) {
        impl.clearMessages(conversation);
    }

    /**
     * 清除会话中指定时间之前的消息
     * @param {Conversation} conversation 目标会话
     * @param {long} before 时间，单位毫秒
     * @returns {Promise<void>}
     */
    async clearMessagesBefore(conversation: Conversation, before: number) {
        impl.clearMessagesByTime(conversation, before);
    }

    /**
     * 清除会话中出了最新指定条数之前的消息
     * @param {Conversation} conversation 目标会话
     * @param {int} count 时间，单位毫秒
     * @returns {Promise<void>}
     */
    async clearMessagesKeepLatest(conversation: Conversation, count: number) {
        impl.clearMessagesKeepLatest(conversation, count);
    }

    /**
     * 清除用户消息
     * @param {string} userId 目标用户
     * @param {number} startTime 开始时间，如果为0忽略开始时间
     * @param {number} endTime 结束时间，如果为0忽略结束时间
     * @returns {Promise<void>}
     */
    async clearUserMessages(userId: string, startTime: number, endTime: number) {
        impl.clearUserMessages(userId, startTime, endTime);
    }

    /**
     * 清除所有消息
     * @param {boolean} removeConversation 是否同时删除会话
     */
    clearAllMessages(removeConversation: boolean) {
        impl.clearAllMessages(removeConversation);
    }

    /**
     * 清除远程会话消息
     * @param {Conversation} conversation
     * @param {function ()} successCB
     * @param {function (error)} failCB
     * @return {Promise<void>}
     */
    async clearRemoteConversationMessages(conversation: Conversation, successCB: SuccessCallback, failCB: FailCallback) {
        impl.clearRemoteConversationMessages(conversation, successCB, failCB);
    }

    /**
     * 插入消息
     * @param {Conversation} conversation 目标会话
     * @param {MessageContent} messageContent 具体的消息内容，一定要求是{@link MessageContent} 的子类，不能是普通的object
     * @param {number} status 消息状态，可选值参考{@link MessageStatus}
     * @param {boolean} notify 是否触发onReceiveMessage
     * @param {[string]} toUsers 定向发送给会话中的某些用户；为空，则发给所有人；另外对单聊会话，本参数无效
     * @param {Number} serverTime 服务器时间，精度到毫秒
     *
     * @return {Message} 插入的消息
     */
    insertMessage(conversation: Conversation, messageContent: MessageContent, status: number, notify = false, toUsers: string[] = [], serverTime = 0): Message | null {
        return impl.insertMessage(conversation, messageContent, status, notify, toUsers, serverTime);
    }

    /**
     * 插入消息
     * @param {Conversation} conversation 目标会话
     * @param {string} fromUser 发送者
     * @param {MessageContent} messageContent 具体的消息内容，一定要求是{@link MessageContent} 的子类，不能是普通的object
     * @param {number} status 消息状态，可选值参考{@link MessageStatus}
     * @param {Number} serverTime 服务器时间，精度到毫秒
     * @param {string} localExtra 附加信息
     *
     * @return {Message} 插入的消息
     */
    insertMessageEx(messageUid: Long, conversation: Conversation, fromUser: string, messageContent: MessageContent, status: number, serverTime: number, localExtra: string = ''): Message | null {
        return impl.insertMessageEx(messageUid, conversation, fromUser, messageContent, status, serverTime);
    }

    /**
     * 更新消息
     * @param {number} messageId 消息id
     * @param {MessageContent} messageContent 具体的消息内容，一定要求是{@link MessageContent} 的子类，不能是普通的object
     * @returns {Promise<void>}
     */
    async updateMessageContent(messageId: number, messageContent: MessageContent) {
        impl.updateMessageContent(messageId, messageContent);
    }

    /**
     * 更新消息状态
     * @param {number} messageId 消息id
     * @param {MessageStatus} status 消息状态，可选值参考{@link MessageStatus}
     */
    async updateMessageStatus(messageId: number, status: number) {
        impl.updateMessageStatus(messageId, status);
    }

    /**
     * 获取会话内的消息总数。
     * @param conversation
     * @returns
     */
    getMessageCount(conversation: Conversation): number {
        return impl.getMessageCount(conversation);
    }

    /**
     * 上传媒体文件
     * @param {string} fileName
     * @param {string } fileOrData base64格式的媒体数据
     * @param {number} mediaType 媒体类型，可选值参考{@link MessageContentMediaType}
     * @param {function (string)} successCB 回调通知上传成功之后的url
     * @param {function (number)} failCB
     * @param {function (number, number)} progressCB
     * @returns {Promise<void>}
     */
    async uploadMedia(fileName: string, fileOrData: string, mediaType: number, successCB: CallbackWithValue_1<string>, failCB: FailCallback, progressCB: CallbackWithValue_2<number, number>) {
        impl.uploadMedia(fileName, fileOrData, mediaType, successCB, failCB, progressCB);
    }

    getVersion() {
        // fixme
        //return impl.getVersion();
    }

    /**
     * 获取经过认证的下载地址。
     * @param messageUid
     * @param mediaType 媒体类型，可选值参考{@link MediaType}，不能填写错误。
     * @param mediaPath
     * @param successCB
     * @param failCB
     */
    getAuthorizedMediaUrl(messageUid: Long, mediaType: number, mediaPath: string, successCB: CallbackWithValue_1<string>, failCB: FailCallback) {
        impl.getAuthorizedMediaUrl(messageUid, mediaType, mediaPath, successCB, failCB)
    }

    /**
     * 是否支持上传大文件上传。只有专业版才支持此功能。当支持大文件上传时，调用getUploadMediaUrl获取上传url，然后在应用层上传
     */
    isSupportBigFilesUpload(): boolean {
        return impl.isSupportBigFilesUpload();
    }

    /**
     * 获取上传链接。一般用户大文件上传。
     * @param {string} fileName
     * @param {number} mediaType 媒体类型，可选值参考{@link MessageContentMediaType}
     * @param {string} contentType HTTP请求的ContentType header，为空时默认为"application/octet-stream"
     * @param {function (string, string, string, number)} successCB 回调通知上传url，及成功之后的url
     * @param {function (number)} failCB
     */
    getUploadMediaUrl(fileName: string, mediaType: number, contentType: string, successCB: (uploadUrl: string, remoteUrl: string, backUploadUrl: string, serverType: number) => void, failCB: FailCallback) {
        impl.getUploadMediaUrl(fileName, mediaType, contentType, successCB, failCB);
    }

    /**
     *
     * 是否开启了已读报告功能
     * @return {boolean}
     */
    isReceiptEnabled(): boolean {
        return impl.isReceiptEnabled();
    }

    /**
     *
     * 是否开启了群组已读报告功能
     * @return {boolean}
     */
    isGroupReceiptEnabled(): boolean {
        return impl.isGroupReceiptEnabled();
    }

    /**
     * 当前用户是否开启消息回执
     * @return {boolean}
     */
    isUserReceiptEnabled(): boolean {
        return impl.isUserReceiptEnabled();
    }

    /**
     * 判断是否是专业版IM服务
     * @return {boolean}
     */
    isCommercialServer(): boolean {
        return impl.isCommercialServer();
    }

    /**
     * 判断是否应用禁止草稿同步
     * @return {boolean}
     */
    isGlobalDisableSyncDraft(): boolean {
        return impl.isGlobalDisableSyncDraft();
    }

    /**
     * 设置是否禁止草稿同步
     * @param disable
     * @param successCB
     * @param failCB
     */
    setDisableSyncDraft(disable: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setDisableSyncDraft(disable, successCB, failCB)
    }

    /**
     * 是否关闭草稿同步
     * @returns
     */
    isDisableSyncDraft(): boolean {
        return impl.isDisableSyncDraft();
    }

    /**
     * 设置当前用户是否开启消息回执
     * @param enable
     * @param successCB
     * @param failCB
     */
    setUserEnableReceipt(enable: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setUserEnableReceipt(enable, successCB, failCB);
    }

    /**
     *
     * @param conversation
     * @return {Map<string, Long>}
     */
    getConversationDelivery(conversation: Conversation): Map<string, number> {
        return impl.getConversationDelivery(conversation);
    }

    /**
     *
     * @param conversation
     * @return {Map<string, Long>}
     */
    getConversationRead(conversation: Conversation): Map<string, number> {
        return impl.getConversationRead(conversation);
    }

    /**
     * 踢掉在线的电脑客户端。
     * @param clientId
     * @param successCB
     * @param failCB
     */
    kickoffPCClient(clientId: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.kickoffPCClient(clientId, successCB, failCB);
    }

    /**
     * 是否PC在线时禁止通知
     * @returns
     */
    isMuteNotificationWhenPcOnline(): boolean {
        return impl.isMuteNotificationWhenPcOnline();
    }

    /**
     * 设置PC在线时默认是否静音
     * @param enable
     * @param successCB
     * @param failCB
     */
    setDefaultSilentWhenPcOnline(defaultSilent: boolean) {
        impl.setDefaultSilentWhenPcOnline(defaultSilent);
    }

    /**
     * 设置是否PC在线时禁止通知
     * @param disable
     * @param successCB
     * @param failCB
     */
    muteNotificationWhenPcOnline(isMute: boolean, successCB: SuccessCallback, failCB: FailCallback) {
        impl.muteNotificationWhenPcOnline(isMute, successCB, failCB)
    }

    /**
     * 获取会话中的文件记录
     * @param {Conversation} conversation 会话
     * @param {String} fromUser 来源用户
     * @param {Long} beforeMessageUid 消息uid，表示获取此消息uid之前的文件记录
     * @param {int} order 排序。0 按照时间逆序；1 按照时间顺序；2 按照大小逆序；3 按照大小顺序。
     * @param {number} count 数量
     * @param {function (FileRecord[])} successCB 成功回调
     * @param {function (number)} failCB 失败回调
     */
    getConversationFileRecords(conversation: Conversation, fromUser: string, beforeMessageUid: Long, order: number, count: number, successCB: CallbackWithValue_1<FileRecord[]>, failCB: FailCallback) {
        impl.getConversationFileRecords(conversation, fromUser, beforeMessageUid, order, count, successCB, failCB);
    }

    /**
     * 获取我发送的文件记录
     * @param {Long} beforeMessageUid 消息uid，表示获取此消息uid之前的文件记录
     * @param {int} order 排序。0 按照时间逆序；1 按照时间顺序；2 按照大小逆序；3 按照大小顺序。
     * @param {number} count 数量
     * @param {function (FileRecord[])} successCB 成功回调
     * @param {function (number)} failCB 失败回调
     */
    getMyFileRecords(beforeMessageUid: Long, order: number, count: number, successCB: CallbackWithValue_1<FileRecord[]>, failCB: FailCallback) {
        impl.getMyFileRecords(beforeMessageUid, order, count, successCB, failCB);
    }

    /**
     * 删除文件记录
     * @param {Long} messageUid 文件对应的消息的uid
     * @param {function ()} successCB 成功回调
     * @param {function (number)} failCB 失败回调
     */
    deleteFileRecord(messageUid: Long, successCB: SuccessCallback, failCB: FailCallback) {
        impl.deleteFileRecord(messageUid, successCB, failCB);
    }

    /**
     * 搜索远程文件记录
     * @param {string} keyword
     * @param {Conversation} conversation 会话，如果为空则获取当前用户所有收到和发出的文件记录
     * @param {string} fromUser 文件发送用户，如果为空则获取该用户发出的文件记录
     * @param {Long | string} beforeMessageId 起始消息的消息id
     * @param {int} order 排序。0 按照时间逆序；1 按照时间顺序；2 按照大小逆序；3 按照大小顺序。
     * @param {number} count
     * @param {function (FileRecord[])} successCB
     * @param {function (number)} failCB
     */
    searchFiles(keyword: string, conversation: Conversation, fromUser: string, beforeMessageId: number, order: number, count: number, successCB: CallbackWithValue_1<FileRecord[]>, failCB: FailCallback) {
        impl.searchFiles(keyword, conversation, fromUser, beforeMessageId, order, count, successCB, failCB)
    }

    /**
     * 搜索我自己的远程文件记录
     * @param keyword
     * @param beforeMessageUid
     * @param {int} order 排序。0 按照时间逆序；1 按照时间顺序；2 按照大小逆序；3 按照大小顺序。
     * @param count
     * @param successCB
     * @param failCB
     */
    searchMyFiles(keyword: string, beforeMessageUid: Long, order: number, count: number, successCB: CallbackWithValue_1<FileRecord[]>, failCB: FailCallback) {
        impl.searchMyFiles(keyword, beforeMessageUid, order, count, successCB, failCB);
    }

    /**
     * 获取host
     */
    getHost(): string {
        return impl.getHost();
    }


    getEncodedClientId() {
        // fixme
        //return impl.getEncodedClientId();
    }

    /**
     *
     * @param {string} data 将要编码的数据
     * @returns {string} 编码结果，base64格式
     */
    encodeData(data: string): string {
        // TODO
        // fixme
        // return impl.encodeData(data);
        return ''
    }

    /**
     *
     * @param {string} encodedData 将要解码的数据，base64格式
     * @returns {null | string} 解码之后的数据
     */
    decodeData(encodedData: string): string {
        // fixme
        // return impl.decodeData(encodedData);
        return ''
    }

    /**
     * 发送会议相关请求
     * @param sessionId
     * @param roomId
     * @param request
     * @param data
     * @param callback
     */
    sendConferenceRequest(sessionId: string, roomId: string, request: string, data: string, callback: CallbackWithValue_2<number, string | null>) {
        this.sendConferenceRequestEx(sessionId, roomId, request, data, false, callback)
    }

    /**
     * 发送会议相关的请求
     * @param sessionId
     * @param roomId
     * @param request
     * @param data
     * @param advance
     * @param callback
     */
    sendConferenceRequestEx(sessionId: string, roomId: string, request: string, data: string, advance: boolean, callback: CallbackWithValue_2<number, string | null>) {
        impl.sendConferenceRequest(sessionId, roomId, request, data, advance, callback);
    }

    /**
     * 当前用户是否开启在线状态
     * @returns
     */
    isUserOnlineStateEnabled(): boolean {
        return impl.isUserOnlineStateEnabled();
    }

    getUserOnlineState(userId: string): UserOnlineState | undefined {
        return impl.getUserOnlineState(userId)
    }

    getUserOnlineStateMap(): Map<string, UserOnlineState> {
        return impl.getUserOnlineStateMap()
    }

    /**
     * 定义目标在线状态
     * @param {number} type 会话类型， 支持{@link ConversationType.Single}和{@link ConversationType.Group}
     * @param {string[]} targets 会话类型为单聊时，是用户 id列表；会话类型为群组时，是群组 id 列表
     * @param {number} duration 关注时间长度，单位是秒
     * @param {function(UserOnlineState[])} successCB
     * @param {function(number)} failCB
     */
    watchOnlineState(type: number, targets: stringArray, duration: number, successCB: CallbackWithValue_1<UserOnlineState[]>, failCB: FailCallback) {
        impl.watchOnlineState(type, targets, duration, successCB, failCB);
    }

    /**
     * 取消订阅目标在线状态。
     * @param type 会话类型， 支持{@link ConversationType.Single}和{@link ConversationType.Group}
     * @param targets 会话类型为单聊时，是用户 id列表；会话类型为群组时，是群组 id 列表
     * @param successCB
     * @param failCB
     */
    unwatchOnlineState(type: number, targets: stringArray, successCB: SuccessCallback, failCB: FailCallback) {
        impl.unwatchOnlineState(type, targets, successCB, failCB);
    }

    /**
     * 设置我的自定义状态
     * @param customState
     * @param customText
     * @param successCB
     * @param failCB
     */
    setMyCustomState(customState: number, customText: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.setMyCustomState(customState, customText, successCB, failCB)
    }

    /**
     * 获取AuthCode，AuthCode用于开放平台，详情请参考 https://gitee.com/wfchat/open-platform
     * @param appId
     * @param appType
     * @param host
     * @param successCB
     * @param failCB
     */
    getAuthCode(appId: string, appType: number, host: string, successCB: CallbackWithValue_1<string>, failCB: FailCallback) {
        impl.getAuthCode(appId, appType, host, successCB, failCB);
    }

    /**
     * config应用，开放平台接口，详情请参考 https://gitee.com/wfchat/open-platform
     * @param appId
     * @param appType
     * @param timestamp
     * @param nonceStr
     * @param signature
     * @param successCB
     * @param failCB
     */
    configApplication(appId: string, appType: number, timestamp: number, nonceStr: string, signature: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.configApplication(appId, appType, timestamp, nonceStr, signature, successCB, failCB);
    }

    /**
     * 开启数据库的事物。用户数据备份与恢复的接口。
     * @returns
     */
    beginTransaction(): boolean {
        return impl.beginTransaction();
    }

    /**
     * 提交数据库的事物。用户数据备份与恢复的接口。
     * @returns
     */
    commitTransaction(): boolean {
        return impl.commitTransaction();
    }

    /**
     * 回滚数据库的事物。用户数据备份与恢复的接口。
     * @returns
     */
    rollbackTransaction(): boolean {
        return impl.rollbackTransaction();
    }

    /**
     * 应用锁，可以用于多个客户端抢某个共同资源。
     * @param lockId  资源ID
     * @param duration 单位为秒
     * @param successCB
     * @param failCB
     */
    requireLock(lockId: string, duration: number, successCB: SuccessCallback, failCB: FailCallback) {
        impl.requireLock(lockId, duration, successCB, failCB);
    }

    /**
     * 应用锁，可以用于多个客户端抢某个共同资源。
     * @param lockId
     * @param successCB
     * @param failCB
     */
    releaseLock(lockId: string, successCB: SuccessCallback, failCB: FailCallback) {
        impl.releaseLock(lockId, successCB, failCB);
    }

    getPCOnlinesInfos(): PCOnlineInfo[] {
        let pcOnline = this.getUserSetting(UserSettingScope.UserSettingPCOnline, "PC");
        let webOnline = this.getUserSetting(UserSettingScope.UserSettingPCOnline, "Web");
        let wxOnline = this.getUserSetting(UserSettingScope.UserSettingPCOnline, "WX");
        let padOnline = this.getUserSetting(UserSettingScope.UserSettingPCOnline, "Pad");

        let infos: PCOnlineInfo[] = []
        let info = PCOnlineInfo.infoFromStr(pcOnline, PCOnlineInfo.PC_Online);
        if (info != null) {
            infos.push(info);
        }
        info = PCOnlineInfo.infoFromStr(webOnline, PCOnlineInfo.Web_Online);
        if (info != null) {
            infos.push(info);
        }
        info = PCOnlineInfo.infoFromStr(wxOnline, PCOnlineInfo.WX_Online);
        if (info != null) {
            infos.push(info);
        }
        info = PCOnlineInfo.infoFromStr(padOnline, PCOnlineInfo.Pad_Online);
        if (info != null) {
            infos.push(info);
        }

        return infos;
    }

    // _getStore() {
    //     return impl._getStore();
    // }

    /**
     * utf8转base64
     * @param {string} str
     * @returns {string}
     */
    utf8_to_b64(str: string): string {
        //return btoa(this.unescape(encodeURIComponent(str)));
        let uint8Arr = textEncoder.encodeInto(str)
        return btoa(uint8Arr)
    }

    /**
     * base64转utf8
     * @param {string} str
     * @returns {string}
     */
    b64_to_utf8(str: string) {
        // return decodeURIComponent(this.escape(atob(str)));
        return textDecoder.decodeWithStream(atob(str))
    }

    b64_to_arrayBuffer(str: string): ArrayBuffer {
        // let binary_string = atob(str);
        // let len = binary_string.length;
        // let bytes = atob(str)
        // for (let i = 0; i < len; i++) {
        //     bytes[i] = binary_string.charCodeAt(i);
        // }
        // return bytes.buffer;
        return atob(str).buffer
    }

    arrayBuffer_to_b64(data: ArrayBuffer): string {
        return btoa(new Uint8Array(data))

    }

    // // 兼容 web 端
    // unescape(str) {
    //     return decodeURIComponent(str)
    // }
    //
    // // 兼容 web 端
    // escape(str) {
    //     return encodeURIComponent(str)
    // }

    defaultUserPortrait(userInfo: UserInfo): string {
        return `${Config.APP_SERVER}/avatar?name=${encodeURIComponent(userInfo.displayName)}`
        // return `http://localhost:8888/avatar?name=${encodeURIComponent(userInfo.displayName)}`
    }

    defaultGroupPortrait(groupInfo: GroupInfo): string {
        let memberIds = this.getGroupMemberIds(groupInfo.target)
        memberIds = memberIds.slice(0, 9);
        // let members = this.getUserInfos(memberIds, groupInfo.target);
        let members = impl.getUserInfos(memberIds, groupInfo.target);
        let req: Record<string, Object> = {
            'members': [] as Record<string, Object>[]
        }
        let pending = false;
        members.forEach(m => {
            if (m.portrait && !m.portrait.startsWith(`${Config.APP_SERVER}`)) {
                (req['members'] as Record<string, Object>[]).push({
                    'avatarUrl': m.portrait
                })
            } else {
                (req['members'] as Record<string, Object>[]).push({
                    'name': m.displayName
                })
            }
            if (m instanceof NullUserInfo) {
                pending = true;
            }
        })
        if (members.length === 0 || pending) {
            return '';
        }

        let reqStr = JSON.stringify(req, null, '');

        return `${Config.APP_SERVER}/avatar/group?request=${encodeURIComponent(reqStr)}`
        //return `http://localhost:8888/avatar/group?request=${encodeURIComponent(req)}`
    }

    connectedToMainNetwork(): boolean {
        return impl.connectedToMainNetwork();
    }
}

const self = new WfcManager();

export default self;
