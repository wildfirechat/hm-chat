/*
 * Copyright (c) 2025 WildFireChat. All rights reserved.
 */

import Message from '@wfc/client/src/main/ets/wfc/messages/message';

/**
 * 消息归档查询结果
 */
export default class ArchiveMessageResult {
    /// 消息列表（Message 对象）
    messages: Message[] = [];

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

        // messages 字段需要在 archiveServer 中通过转换得到
        // 这里只解析基本字段
        return result;
    }

    toString(): string {
        return `ArchiveMessageResult(messagesCount=${this.messages.length}, hasMore=${this.hasMore}, nextStartMid=${this.nextStartMid})`;
    }
}
