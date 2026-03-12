/*
 * Copyright (c) 2025 WildFireChat. All rights reserved.
 */

import MessagePayload from '@wfc/client/src/main/ets/wfc/messages/messagePayload';

/**
 * 消息内容 Payload
 * 对应服务端 API 返回的 payload 结构（已解析的消息内容）
 */
export default class ArchiveMessagePayload {
    /// 消息类型
    type: number = 0;

    /// 消息文本内容（如文本消息的实际内容、位置标题、链接标题等）
    content: string = '';

    /// 可搜索内容
    searchableContent: string = '';

    /// 推送内容
    pushContent: string = '';

    /// 推送数据
    pushData: string = '';

    /// @类型：0-不提醒，1-所有人，2-部分人
    mentionedType: number = 0;

    /// @的目标用户ID列表
    mentionedTargets: string[] = [];

    /// 媒体文件远程URL（图片、语音、文件、视频等）
    remoteMediaUrl: string = '';

    /// 扩展字段（JSON格式，包含类型特定的额外信息）
    extra: string = '';

    /// 原始Base64数据（解析失败时保留）
    binaryContent: string = '';

    /// 子类型（如Typing消息的类型）
    subType: number = 0;

    /**
     * 从对象/JSON创建 payload 对象
     */
    static fromObject(obj: Record<string, Object> | null): ArchiveMessagePayload | null {
        if (!obj) {
            return null;
        }

        const payload = new ArchiveMessagePayload();
        payload.type = (obj['type'] as number) || 0;
        payload.content = (obj['content'] as string) || '';
        payload.searchableContent = (obj['searchableContent'] as string) || '';
        payload.pushContent = (obj['pushContent'] as string) || '';
        payload.pushData = (obj['pushData'] as string) || '';
        payload.mentionedType = (obj['mentionedType'] as number) || 0;
        payload.mentionedTargets = (obj['mentionedTargets'] as string[]) || [];
        payload.remoteMediaUrl = (obj['remoteMediaUrl'] as string) || '';
        payload.extra = (obj['extra'] as string) || '';
        payload.binaryContent = (obj['binaryContent'] as string) || '';
        payload.subType = (obj['subType'] as number) || 0;

        return payload;
    }

    /**
     * 将 payload 转换为 SDK 使用的 MessagePayload 格式
     * @param contentType 消息内容类型
     */
    toSDKPayload(contentType: number): MessagePayload {
        const sdkPayload = new MessagePayload();
        sdkPayload.type = contentType;
        sdkPayload.searchableContent = this.searchableContent;
        sdkPayload.pushContent = this.pushContent;
        sdkPayload.pushData = this.pushData;
        sdkPayload.content = this.content;
        sdkPayload.mentionedType = this.mentionedType;
        sdkPayload.mentionedTargets = this.mentionedTargets || [];
        sdkPayload.remoteMediaUrl = this.remoteMediaUrl;
        sdkPayload.extra = this.extra;
        sdkPayload.binaryContent = this.binaryContent;

        return sdkPayload;
    }

    toString(): string {
        return `ArchiveMessagePayload(type=${this.type}, content=${this.content})`;
    }
}
