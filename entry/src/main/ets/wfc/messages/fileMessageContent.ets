/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContentMediaType from "./messageContentMediaType";
import MediaMessageContent from "./mediaMessageContent";
import MessageContentType from "./messageContentType";
import MessagePayload from './messagePayload';

export default class FileMessageContent extends MediaMessageContent {
    name = '';
    size = 0;

    constructor(fileOrLocalPath: string = '', remotePath: string = '', name: string = '', size = 0) {
        super(MessageContentType.File, MessageContentMediaType.File, fileOrLocalPath, remotePath);
        // if (fileOrLocalPath && fileOrLocalPath.name) {
        //     this.name = fileOrLocalPath.name;
        //     this.size = fileOrLocalPath.size;
        // } else if (remotePath) {
        //     this.name = name ? name : remotePath.substring(remotePath.lastIndexOf('/') + 1)
        //     this.size = size ? size : 0;
        // }
        this.name = name;
        this.size = size
    }

    digest() {
        return '[文件]' + this.name;
    }

    encode() {
        let payload = super.encode();
        payload.searchableContent = this.name;
        payload.content = this.size + '';
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        if (payload.searchableContent) {
            this.name = payload.searchableContent;
            this.size = Number(payload.content);
        }
    }
}
