/*
 * Copyright (c) 2025 WildFireChat. All rights reserved.
 */

import ArchiveMessagePayload from './archiveMessagePayload';

/**
 * 归档消息模型
 * 对应备份服务 API 返回的消息结构
 */
export default class ArchivedMessage {
    /// 消息唯一ID
    mid: number = 0;

    /// 发送者用户ID
    senderId: string = '';

    /// 会话类型：0单聊, 1群组, 2聊天室, 3频道
    convType: number = 0;

    /// 会话目标（用户ID或群组ID）
    convTarget: string = '';

    /// 会话线路
    convLine: number = 0;

    /// 消息内容类型
    contentType: number = 0;

    /// 消息内容（已解析的 payload）
    payload: ArchiveMessagePayload | null = null;

    /// 可搜索文本
    searchableKey: string = '';

    /// 当前用户ID（用户视角）
    userId: string = '';

    /// 消息发送时间（ISO 8601格式，UTC时间）
    messageDt: string = '';

    /// 用户哈希值（用于分区）
    userHash: number = 0;

    /**
     * 从对象/JSON创建归档消息对象
     */
    static fromObject(obj: Record<string, Object> | null): ArchivedMessage | null {
        if (!obj) {
            return null;
        }

        const message = new ArchivedMessage();
        message.mid = (obj['mid'] as number) || 0;
        message.senderId = (obj['senderId'] as string) || '';
        message.convType = (obj['convType'] as number) || 0;
        message.convTarget = (obj['convTarget'] as string) || '';
        message.convLine = (obj['convLine'] as number) || 0;
        message.contentType = (obj['contentType'] as number) || 0;

        // 解析 payload
        const payloadObj = obj['payload'] as Record<string, Object>;
        if (payloadObj) {
            message.payload = ArchiveMessagePayload.fromObject(payloadObj);
        }

        message.searchableKey = (obj['searchableKey'] as string) || '';
        message.userId = (obj['userId'] as string) || '';
        message.messageDt = (obj['messageDt'] as string) || '';
        message.userHash = (obj['userHash'] as number) || 0;

        return message;
    }

    /**
     * 获取本地时间格式的消息时间（毫秒时间戳）
     */
    getLocalMessageTimestamp(): number {
        if (!this.messageDt) {
            return Date.now();
        }

        try {
            // ISO 8601 格式解析
            const date = new Date(this.messageDt);
            if (isNaN(date.getTime())) {
                return Date.now();
            }
            return date.getTime();
        } catch (e) {
            return Date.now();
        }
    }

    toString(): string {
        return `ArchivedMessage(mid=${this.mid}, sender=${this.senderId}, convType=${this.convType}, convTarget=${this.convTarget}, contentType=${this.contentType})`;
    }
}
