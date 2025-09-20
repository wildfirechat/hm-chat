/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import MessageContent from './messageContent'
import MessageContentType from './messageContentType';
import wfc from '../client/wfc'
import QuoteInfo from "../model/quoteInfo";
import MessagePayload from './messagePayload';
import QuoteInfoPayload from '../model/quoteInfoPayload';
import { _patchToJavaLong, _reverseToJsLongString } from '../util/longUtil';

export default class TextMessageContent extends MessageContent {
    content = '';
    quoteInfo?: QuoteInfo;

    constructor(content: string = '', mentionedType = 0, mentionedTargets: string[] = []) {
        super(MessageContentType.Text, mentionedType, mentionedTargets);
        this.content = content;
    }

    digest() {
        return this.content;
    }

    encode() {
        let payload = super.encode();
        payload.searchableContent = this.content;
        if (this.quoteInfo) {
            let obj: Record<string, QuoteInfoPayload> = {
                "quote": this.quoteInfo.encode()
            }
            // JSON.parse 和 JSON.stringify 不能处理java long
            let str = JSON.stringify(obj);
            str = _patchToJavaLong(str, 'u');

            payload.binaryContent = wfc.utf8_to_b64(str);
        }
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        this.content = payload.searchableContent;
        if (payload.binaryContent && payload.binaryContent.length > 0) {
            // JSON.parse 和 JSON.stringify 不能处理java long
            let quoteInfoStr = wfc.b64_to_utf8(payload.binaryContent)
            // FIXME node 环境，decodeURIComponent 方法，有时候会在最后添加上@字符，目前尚未找到原因，先规避
            quoteInfoStr = quoteInfoStr.substring(0, quoteInfoStr.lastIndexOf('}') + 1)
            quoteInfoStr = _reverseToJsLongString(quoteInfoStr, 'u')
            let obj = JSON.parse(quoteInfoStr) as Record<string, QuoteInfoPayload>
            if(obj){
                this.quoteInfo = new QuoteInfo();
                this.quoteInfo.decode(obj.quote as QuoteInfoPayload);
            }
        }
    }

    setQuoteInfo(quoteInfo: QuoteInfo) {
        this.quoteInfo = quoteInfo;
    }
}
