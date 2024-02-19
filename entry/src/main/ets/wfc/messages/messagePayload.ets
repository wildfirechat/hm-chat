/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

/**
 *
 "content": {
            "type": 1,
            "searchableContent": "1234",
            "pushContent": "",
            "content": "",
            "binaryContent": "",
            "localContent": "",
            "mediaType": 0,
            "remoteMediaUrl": "",
            "localMediaPath": "",
            "mentionedType": 0,
            "mentionedTargets": [ ]
        },
 */
export default class MessagePayload {
    type: number;
    searchableContent: string;
    pushContent: string;
    pushData: string;
    content: string;
    binaryContent: string; // base64 string, 图片时，不包含头部信息:data:image/png;base64,
    localContent: string;
    mediaType: number;
    remoteMediaUrl: string;
    localMediaPath: string;
    mentionedType: number = 0;
    mentionedTargets: number[] = [];
    extra: string;
}
