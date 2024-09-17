import MessageContentType from "../messages/messageContentType";
import wfc from "../client/wfc";
import MediaMessageContent from "../messages/mediaMessageContent";
import { stringValue } from "../util/longUtil";
import Message from "../messages/message";
import Conversation from "../model/conversation";
import Long from "../util/long";
import { compare } from "../util/longUtil";
import MessagePayload from "../messages/messagePayload";
import ArticlesMessageContent from "./articlesMessageContent";
import MessageContentMediaType from "./messageContentMediaType";
import assign from '../util/assign';
import fs from '@ohos.file.fs';

export default class CompositeMessageContent extends MediaMessageContent {
    title = '';
    messages = [] as Message[];
    loaded = false;

    constructor() {
        super(MessageContentType.Composite_Message, MessageContentMediaType.General, '', '')
    }

    setMessages(msgs: Message[]) {
        this.messages = [];
        msgs.forEach(m => {
            if (m.messageContent instanceof ArticlesMessageContent) {
                let linkMessageContents = m.messageContent.toLinkMessageContent();
                linkMessageContents.forEach(lm => {
                    let msg = assign(new Message(m.conversation, lm), m);
                    this.messages.push(msg as Message);
                })
            } else {
                this.messages.push(m)
            }
        })
        this.messages = this.messages.sort((m1, m2) => {
            return compare(m1.messageUid, m2.messageUid);
        })
    }

    digest(message: Message) {
        return '[聊天记录]' + this.title;
    }

    compositeDigest() {
        let str = '';
        for (let i = 0; i < this.messages.length && i < 3; i++) {
            let msg = this.messages[i];
            let senderDisplayName = wfc.getUserDisplayName(msg.from)
            let msgDigest = msg.messageContent.digest(msg)
            if (msgDigest.length > 36) {
                msgDigest = msgDigest.substring(0, 33)
                msgDigest += '...'
            }
            str += senderDisplayName + ':' + msgDigest + '\n'
        }
        return str.trim()
    }

    encode() {
        let payload = super.encode();
        payload.content = this.title;
        let arr: Record<string, Object>[] = []
        let binArr: Record<string, Object>[] | undefined;
        let size = 0;
        this.messages.forEach(msg => {
            let msgPayload = msg.messageContent.encode();
            let o: Record<string, Object> = {
                'uid': stringValue(msg.messageUid),
                'type': msg.conversation.type,
                'target': msg.conversation.target,
                'line': msg.conversation.line,
                'from': msg.from,
                'tos': msg.to,
                'direction': msg.direction,
                'status': msg.status,
                //'serverTime': stringValue(msg.timestamp),
                'serverTime': msg.timestamp,
                'ctype': msgPayload.type,
                'csc': msgPayload.searchableContent,
                'cpc': msgPayload.pushContent,
                'cpd': msgPayload.pushData,
                'cc': msgPayload.content,
                'cmt': msgPayload.mentionedType,
                'cmts': msgPayload.mentionedTargets,
                'ce': msgPayload.extra,
            };
            if (msgPayload.searchableContent) {
                payload.searchableContent = payload.searchableContent + msgPayload.searchableContent + ' ';
            }

            if (msgPayload.binaryContent) {
                o.cbc = msgPayload.binaryContent;
            }
            if (msg.messageContent instanceof MediaMessageContent) {
                o.mt = msg.messageContent.mediaType;
                o.mru = msg.messageContent.remotePath;
            }

            if (!binArr) {
                size += JSON.stringify(o).length;
                if (size > 20480 && arr.length > 0) {
                    binArr = arr.map((value) => value);
                }
            }

            arr.push(o);

        });

        let obj: Record<string, Object>;
        if (binArr) {
            obj = {
                'ms': arr,
            }
            let str = JSON.stringify(obj);
            str = str.replace(/"uid":"([0-9]+)"/, "\"uid\":$1");
            // str = str.replace(/"serverTime":"([0-9]+)"/, "\"serverTime\":$1");

            this.localPath = getContext(this)
                .cacheDir + '/' + new Date().getTime() + 'cpm-' + new Date().getTime() + '.data';
            let file = fs.openSync(this.localPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
            fs.writeSync(file.fd, str)
            fs.closeSync(file.fd)
            payload.localMediaPath = this.localPath;
            payload.mediaType = MessageContentType.File;
            obj = {
                'ms': binArr,
            }
        } else {
            if (binArr) {
                obj = {
                    'ms': binArr,
                }
            } else {
                obj = {
                    'ms': arr,
                }
            }
        }

        let str = JSON.stringify(obj);
        str = str.replace(/"uid":"([0-9]+)"/, "\"uid\":$1");
        // str = str.replace(/"serverTime":"([0-9]+)"/, "\"serverTime\":$1");

        payload.binaryContent = wfc.utf8_to_b64(str)
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);

        this.title = payload.content;
        let str: string = '';
        if (payload.binaryContent) {
            str = wfc.b64_to_utf8(payload.binaryContent);
            this._decodeMessages(str);
        }
    }

    _decodeMessages(str: string) {
        // fixme
        if (this.loaded) {
            return;
        }
        this.messages = [];
        // FIXME node 环境，decodeURIComponent 方法，有时候会在最后添加上@字符，目前尚未找到原因，先规避
        // str = str.substring(0, str.lastIndexOf('}') + 1);
        str = str.replace(/"uid":([0-9]+)/g, "\"uid\":\"$1\"");
        // str = str.replace(/"serverTime":([0-9]+)/g, "\"serverTime\":\"$1\"");
        let obj = JSON.parse(str) as Record<string, Object>;
        (obj.ms as Array<Record<string, Object>>).forEach(o => {
            let conv = new Conversation(o.type as number, o.target as string, o.line as number);

            let payload = new MessagePayload();
            payload.type = o.ctype as number;
            payload.searchableContent = o.csc as string;
            payload.pushContent = o.cpc as string;
            payload.pushData = o.cpd as string;
            payload.content = o.cc as string;
            payload.mentionedType = o.cmt as number;
            payload.mentionedTargets = o.cmts as string[];
            payload.extra = o.ce as string;

            payload.binaryContent = o.cbc as string;
            payload.mediaType = o.mt as number;
            payload.remoteMediaUrl = o.mru as string;

            let messageContent = Message.messageContentFromMessagePayload(payload, o.from as string);
            let msg = new Message(conv, messageContent)
            msg.messageUid = Long.fromValue(o.uid as string);
            msg.conversation = conv;
            msg.from = o.from as string;
            msg.to = o.tos as string;
            msg.direction = o.direction as number;
            msg.status = o.status as number;
            msg.timestamp = Long.fromValue(o.serverTime as number).toNumber();
            this.messages.push(msg);
        });
        console.log('cp ms', this.messages)
    }

    getValue<T>(obj: Record<string, Object>, key: string) {
        return obj[key] as T
    }
}

