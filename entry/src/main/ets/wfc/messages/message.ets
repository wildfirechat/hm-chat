/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

/**
 *
 message in json format
 {
 "conversation":{
 "conversationType": 0,
 "target": "UZUWUWuu",
 "line": 0,
 }
 "from": "UZUWUWuu",
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
 "messageId": 52,
 "direction": 1,
 "status": 5,
 "messageUid": 75735276990792720,
 "timestamp": 1550849394256,
 "to": ""
 }
 */
import Conversation from '../model/conversation'
import NotificationMessageContent from './notification/notificationMessageContent'
import wfc from '../client/wfc'
import MessageConfig from '../client/messageConfig';
import UnknownMessageContent from './unknownMessageContent';
import PersistFlag from './persistFlag';
import MessageStatus from './messageStatus';
import ConversationType from '../model/conversationType';
import { encode } from '../util/base64-arraybuffer';
import Config from '../../config';

import Long from '../util/long'
import UnsupportMessageContent from "../messages/unsupportMessageConten";
import RecallMessageNotification from "../messages/notification/recallMessageNotification";
import MessageContent from './messageContent';
import assign from '../util/assign';
import MessagePayload from './messagePayload';
import CustomMessageConfig from '../../wfc_custom_message/customMessageConfig';

export default class Message {
    conversation: Conversation;
    from = '';
    content?: MessagePayload;
    messageContent: MessageContent;
    messageId = 0;
    direction = 0;
    status = 0;
    messageUid = Long.ZERO;
    timestamp = 0;
    to = '';
    localExtra = '';

    constructor(conversation: Conversation, messageContent: MessageContent) {
        this.conversation = conversation;
        this.messageContent = messageContent;
    }

    static fromProtoMessage(obj: Record<string, Object>): Message | null {
        if (!obj) {
            return null;
        }
        if (!(obj.conversation as Conversation).target) {
            return null;
        }
        // iOS，Android，Windows，OSX
        if ([1, 2, 3, 4, 7, 8, 9, 10, 11, 12].indexOf(Config.getWFCPlatform()) >= 0) {
            let payload = obj.content as MessagePayload
            let content = CustomMessageConfig.newCustomMessageContent(payload.type);
            if (!content) {
                content = MessageConfig.newMessageContent(payload.type);
            }
            let objConv = obj.conversation as Record<string, Object>
            let conversation = new Conversation(objConv.conversationType as number, objConv.target as string, objConv.line as number)

            let msg = assign(new Message(conversation, content), obj) as Message;
            msg.conversation = conversation;
            // big integer to number
            msg.messageId = Number(msg.messageId);

            msg.messageUid = Long.fromValue(msg.messageUid);
            msg.timestamp = Long.fromValue(msg.timestamp).toNumber();
            msg.localExtra = obj.localExtra as string;
            if (!msg.from) {
                // 移动端
                msg.from = obj.sender as string;
            }
            try {
                content.decode(payload);
                if (content instanceof NotificationMessageContent) {
                    content.fromSelf = msg.from === wfc.getUserId();
                }
            } catch (error) {
                console.error('decode message payload failed, fallback to unkownMessage', msg.content?.type, msg.content, error);
                let flag = MessageConfig.getMessageContentPersitFlag(payload.type);
                if (PersistFlag.Persist === flag || PersistFlag.Persist_And_Count === flag) {
                    content = new UnknownMessageContent(payload);
                } else {
                    return null;
                }
            }
            msg.messageContent = content;
            if (content instanceof UnknownMessageContent) {
                console.log('unknownMessage Content', obj)
            }

            return msg;

        } else {
            // let msg = new Message();
            // msg.from = obj.fromUser;
            // msg.content = obj.content;
            // msg.messageUid = obj.messageId;
            // msg.localExtra = obj.localExtra;
            // msg.timestamp = obj.serverTimestamp;
            // let contentClazz = MessageConfig.getMessageContentClazz(obj.content.type);
            // if (contentClazz) {
            //     let content = new contentClazz();
            //     if (obj.content.__notLoaded) {
            //         content.__notLoaded = true;
            //         content.type = obj.content.type;
            //     } else {
            //         try {
            //             if (obj.content.data && obj.content.data.length > 0) {
            //                 obj.content.binaryContent = encode(obj.content.data);
            //             }
            //             content.decode(obj.content);
            //             content.extra = obj.content.extra;
            //             if (content instanceof NotificationMessageContent) {
            //                 content.fromSelf = msg.from === wfc.getUserId();
            //             }
            //         } catch (error) {
            //             console.error('decode message payload failed, fallback to unkownMessage', obj.content, error);
            //             let flag = MessageConfig.getMessageContentPersitFlag(obj.content.type);
            //             if (PersistFlag.Persist === flag || PersistFlag.Persist_And_Count === flag) {
            //                 content = new UnknownMessageContent(obj.content);
            //             } else {
            //                 return null;
            //             }
            //         }
            //     }
            //     msg.messageContent = content;
            //
            //     if (content instanceof UnknownMessageContent) {
            //         console.log('unknownMessage Content', obj)
            //     }
            // } else {
            //     console.error('message content not register', obj);
            // }
            //
            //
            // if (msg.from === wfc.getUserId()) {
            //     msg.conversation = new Conversation(obj.conversation.type, obj.conversation.target, obj.conversation.line);
            //     // out
            //     msg.direction = 0;
            //     msg.status = MessageStatus.Sent;
            // } else {
            //     if (obj.conversation.type === ConversationType.Single) {
            //         msg.conversation = new Conversation(obj.conversation.type, obj.fromUser, obj.conversation.line);
            //     } else {
            //         msg.conversation = new Conversation(obj.conversation.type, obj.conversation.target, obj.conversation.line);
            //     }
            //
            //     // in
            //     msg.direction = 1;
            //     msg.status = MessageStatus.Unread;
            //
            //     if (msg.content.mentionedType === 2) {
            //         msg.status = MessageStatus.AllMentioned;
            //     } else if (msg.content.mentionedType === 1) {
            //         for (const target of msg.content.mentionedTarget) {
            //             if (target === wfc.getUserId()) {
            //                 msg.status = MessageStatus.Mentioned;
            //                 break;
            //             }
            //         }
            //     }
            // }
            // return msg;
            return null
        }

    }

    static messageContentFromMessagePayload(payload: MessagePayload, from: string) {
        let content = CustomMessageConfig.newCustomMessageContent(payload.type)
        if(!content){
            content = MessageConfig.newMessageContent(payload.type)
        }
        content.decode(payload);

        let selfUid = wfc.getUserId();
        if (content instanceof NotificationMessageContent) {
            if (content instanceof RecallMessageNotification) {
                if (content.operatorId === selfUid) {
                    content.fromSelf = true;
                }
            } else if (from === selfUid) {
                content.fromSelf = true;
            }
        }

        return content;
    }

    static toMessagePayload(message: Message): MessagePayload {
        return message.messageContent!.encode();
    }
}
