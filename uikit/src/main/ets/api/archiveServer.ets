/*
 * Copyright (c) 2025 WildFireChat. All rights reserved.
 */

import http from '@ohos.net.http';
import wfc from '@wfc/client';
import Config from '@wfc/client/src/main/ets/config';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import MessageStatus from '@wfc/client/src/main/ets/wfc/messages/messageStatus';
import MessageConfig from '@wfc/client/src/main/ets/wfc/client/messageConfig';
import Long from '@wfc/client/src/main/ets/wfc/util/long';
import CustomMessageConfig from '@wfc/client/src/main/ets/wfc_custom_message/customMessageConfig';
import UnknownMessageContent from '@wfc/client/src/main/ets/wfc/messages/unknownMessageContent';
import PersistFlag from '@wfc/client/src/main/ets/wfc/messages/persistFlag';
import ArchivedMessage from './model/archivedMessage';
import ArchiveMessagePayload from './model/archiveMessagePayload';
import ArchiveMessageResult from './model/archiveMessageResult';
import NotificationMessageContent from '@wfc/client/src/main/ets/wfc/messages/notification/notificationMessageContent';
import MessagePayload from '@wfc/client/src/main/ets/wfc/messages/messagePayload';

/**
 * 归档服务
 * 用于从归档服务器加载历史消息
 */
class ArchiveServer {
    /// 归档服务基础 URL，例如：http://localhost:8088
    baseUrl: string = Config.ARCHIVE_SERVER_ADDRESS || '';
    /// 消息ID计数器（用于生成负数消息ID）
    messageIdCounter: number = 0;

    /**
     * 设置归档服务基础 URL
     * @param url 基础 URL
     */
    setBaseUrl(url: string): void {
        this.baseUrl = url;
    }

    /**
     * 获取归档服务基础 URL
     */
    getBaseUrl(): string {
        return this.baseUrl;
    }

    /**
     * 获取归档消息（带线路参数）
     * @param conversationType 会话类型
     * @param convTarget 会话目标
     * @param convLine 会话线路
     * @param startMid 起始消息ID
     * @param before 是否向前查询（获取更早的消息）
     * @param limit 限制条数
     * @returns Promise<ArchiveMessageResult>
     */
    async getArchivedMessages(
        conversationType: number,
        convTarget: string,
        convLine: number,
        startMid: number,
        before: boolean,
        limit: number
    ): Promise<ArchiveMessageResult> {
        const params: Record<string, Object> = {
            'convType': conversationType,
            'convTarget': convTarget || '',
            'convLine': convLine ?? 0,
            'before': before,
            'limit': Math.min(limit, 100),
            'startMid': startMid
        };
        const result = await this.postWithAuth('/api/messages/fetch', params);
        return this.parseResultFromResponse(result);
    }

    /**
     * 搜索归档消息（带过滤条件）
     * @param keyword 搜索关键词
     * @param conversationType 会话类型
     * @param convTarget 会话目标
     * @param convLine 会话线路
     * @param startMid 起始消息ID
     * @param before 是否向前查询
     * @param limit 限制条数
     * @returns Promise<ArchiveMessageResult>
     */
    async searchArchivedMessages(
        keyword: string,
        conversationType: number,
        convTarget: string,
        convLine: number,
        startMid: number,
        before: boolean,
        limit: number
    ): Promise<ArchiveMessageResult> {
        const params: Record<string, Object> = {
            'convType': conversationType,
            'convTarget': convTarget,
            'convLine': convLine,
            'keyword': keyword,
            'before': before,
            'limit': Math.min(limit, 100),
            'startMid': startMid
        };
        const result = await this.postWithAuth('/api/messages/search', params);
        return this.parseResultFromResponse(result);
    }

    /**
     * 将归档服务返回的数据解析为 ArchiveMessageResult
     * 其中 messages 字段会被转换为 Message 对象
     */
    parseResultFromResponse(response: Record<string, Object>): ArchiveMessageResult {
        const result = ArchiveMessageResult.fromObject(response);
        const messageDicts = response['messages'] as Array<Record<string, Object>>;
        if (messageDicts && Array.isArray(messageDicts)) {
            const messages: Message[] = [];
            for (const messageDict of messageDicts) {
                const archivedMsg = ArchivedMessage.fromObject(messageDict);
                if (archivedMsg) {
                    const message = this.convertArchivedMessageToMessage(archivedMsg);
                    if (message) {
                        messages.push(message);
                    }
                }
            }
            result.messages = messages;
        }
        return result;
    }

    /**
     * 将归档消息转换为 Message
     */
    convertArchivedMessageToMessage(archivedMsg: ArchivedMessage): Message | null {
        if (!archivedMsg) {
            return null;
        }

        const conversation = new Conversation(archivedMsg.convType, archivedMsg.convTarget, archivedMsg.convLine);

        let sdkPayload: MessagePayload;
        if (archivedMsg.payload) {
            sdkPayload = archivedMsg.payload.toSDKPayload(archivedMsg.contentType);
        } else {
            sdkPayload = new ArchiveMessagePayload().toSDKPayload(archivedMsg.contentType);
        }

        let content = CustomMessageConfig.newCustomMessageContent(sdkPayload.type);
        if (!content) {
            content = MessageConfig.newMessageContent(sdkPayload.type);
        }

        if (content) {
            try {
                content.decode(sdkPayload);
            } catch (error) {
                console.error('Failed to decode message payload, fallback to unknownMessage', sdkPayload.type, error);
                const flag: number = MessageConfig.getMessageContentPersitFlag(sdkPayload.type);
                if (PersistFlag.Persist === flag || PersistFlag.Persist_And_Count === flag) {
                    content = new UnknownMessageContent(sdkPayload);
                } else {
                    return null;
                }
            }
        } else {
            content = new UnknownMessageContent(sdkPayload);
        }

        const message = new Message(conversation, content);
        this.messageIdCounter--;
        message.messageId = this.messageIdCounter;
        message.messageUid = Long.fromNumber(archivedMsg.mid);
        message.from = archivedMsg.senderId;

        const currentUserId = wfc.getUserId();
        if (currentUserId && currentUserId === archivedMsg.senderId) {
            message.direction = 0;
            message.status = MessageStatus.Sent;
        } else {
            message.direction = 1;
            message.status = MessageStatus.Readed;
        }

        message.timestamp = archivedMsg.getLocalMessageTimestamp();

        if (content instanceof NotificationMessageContent) {
            content.fromSelf = message.from === currentUserId;
        }

        message.messageContent = content;
        return message;
    }

    /**
     * 带认证的 POST 请求
     * 先获取 authCode，然后发送请求
     */
    async postWithAuth(
        path: string,
        data?: Record<string, Object>
    ): Promise<Record<string, Object>> {
        return new Promise((resolve, reject) => {
            const imHost = wfc.getHost();
            wfc.getAuthCode('admin', 2, imHost, (authCode: string) => {
                this.post(path, data, authCode)
                    .then(resolve)
                    .catch(reject);
            }, (errorCode: number) => {
                reject(new Error(`Failed to get authCode: ${errorCode}`));
            });
        });
    }

    /**
     * 发送 POST 请求
     */
    async post(
        path: string,
        data?: Record<string, Object>,
        authCode?: string
    ): Promise<Record<string, Object>> {
        return new Promise((resolve, reject) => {
            if (!this.baseUrl || this.baseUrl.length === 0) {
                reject(new Error('Archive server base URL not set'));
                return;
            }

            const httpRequest = http.createHttp();
            const url = this.baseUrl + path;

            const header: Record<string, string> = {
                'Content-Type': 'application/json'
            };
            if (authCode && authCode.length > 0) {
                header['authCode'] = authCode;
            }

            console.log('ArchiveServer request:', path, data);

            httpRequest.request(
                url,
                {
                    method: http.RequestMethod.POST,
                    header: header,
                    extraData: data,
                    expectDataType: http.HttpDataType.OBJECT,
                    usingCache: true,
                    priority: 1,
                    connectTimeout: 30000,
                    readTimeout: 30000,
                    usingProtocol: http.HttpProtocol.HTTP1_1,
                },
                (err, data) => {
                    if (!err && data.responseCode === 200) {
                        console.log('ArchiveServer response:', data.result);
                        const result = data.result as Record<string, Object>;
                        if (result.code === 0) {
                            resolve(result.result as Record<string, Object> || {});
                        } else {
                            reject(new Error(`Server error: ${result.code}, ${result.message}`));
                        }
                    } else {
                        console.error('ArchiveServer error:', err);
                        httpRequest.destroy();
                        if (data && data.responseCode === 401) {
                            reject(new Error('Authentication failed'));
                        } else {
                            reject(new Error(err ? err.message : 'Request failed'));
                        }
                    }
                    httpRequest.off('headersReceive');
                    httpRequest.destroy();
                }
            );
        });
    }
}

let archiveServer = new ArchiveServer();

export default archiveServer;
