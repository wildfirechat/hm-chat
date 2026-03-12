/*
 * Copyright (c) 2025 WildFireChat. All rights reserved.
 */

import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import ArchivedMessage from './archivedMessage';

/**
 * 消息归档查询结果
 */
export default class ArchiveMessageResult {
    /// 消息列表（Message 对象，由 archiveServer 转换后填充）
    messages: Message[] = [];

    /// 原始归档消息列表（从 API 响应解析）
    archivedMessages: ArchivedMessage[] = [];

    /// 是否还有更多消息
    hasMore: boolean = false;

    /// 下一页起始消息ID（用于翻页）
    nextStartMid: number = 0;

    /**
     * 从对象/JSON创建结果对象
     */
    static fromObject(obj: Record<string, Object> | null): ArchiveMessageResult {
        const result = new ArchiveMessageResult();
        if (!obj) {
            return result;
        }

        result.hasMore = (obj['hasMore'] as boolean) || false;
        result.nextStartMid = (obj['nextStartMid'] as number) || 0;

        // 解析 messages 字段为 ArchivedMessage 对象
        const messageDicts = obj['messages'] as Array<Record<string, Object>>;
        if (messageDicts && Array.isArray(messageDicts)) {
            for (const messageDict of messageDicts) {
                const archivedMsg = ArchivedMessage.fromObject(messageDict);
                if (archivedMsg) {
                    result.archivedMessages.push(archivedMsg);
                }
            }
        }

        return result;
    }

    toString(): string {
        return `ArchiveMessageResult(messagesCount=${this.messages.length}, archivedMessagesCount=${this.archivedMessages.length}, hasMore=${this.hasMore}, nextStartMid=${this.nextStartMid})`;
    }
}
