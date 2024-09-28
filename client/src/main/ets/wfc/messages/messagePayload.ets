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
    type = 0;
    searchableContent = '';
    pushContent = '';
    pushData = '';
    content = '';
    binaryContent =''; // base64 string, 图片时，不包含头部信息:data:image/png;base64,
    localContent = '';
    mediaType = 0;
    remoteMediaUrl = '';
    localMediaPath = '';
    mentionedType = 0;
    mentionedTargets:string[] = [];
    extra = '';
}
