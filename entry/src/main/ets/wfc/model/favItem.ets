import ConversationType from "./conversationType";
import wfc from "../client/wfc";
import MessageContentType from "../messages/messageContentType";
import Message from "../messages/message";
import TextMessageContent from "../messages/textMessageContent";
import ImageMessageContent from "../messages/imageMessageContent";
import VideoMessageContent from "../messages/videoMessageContent";
import FileMessageContent from "../messages/fileMessageContent";
import CompositeMessageContent from "../messages/compositeMessageContent";
import MessagePayload from "../messages/messagePayload";
import SoundMessageContent from "../messages/soundMessageContent";
import Long from "../util/long";
import UnknownMessageContent from "../messages/unknownMessageContent";

import Config from '../../config'
import { JSONObject } from '../type/types';
import Conversation from './conversation';
import MessageContent from '../messages/messageContent';

export default class FavItem {
    id = 0;
    messageUid = Long.ZERO;
    // 和消息类型对应
    favType = 0;
    type = 0;
    timestamp = 0;
    conversation?: Conversation;
    origin = '';
    sender = '';
    title = '';
    url = '';
    thumbUrl = '';
    data? = '';

    static fromMessage(message: Message) {
        let favItem = new FavItem();
        favItem.messageUid = message.messageUid;
        favItem.conversation = message.conversation;
        favItem.favType = message.messageContent.type;
        favItem.sender = message.from;
        switch (message.conversation.type) {
            case ConversationType.Group:
                let groupInfo = wfc.getGroupInfo(message.conversation.target, false);
                favItem.origin = groupInfo.name;
                break;
            case ConversationType.Single:
                favItem.origin = wfc.getUserDisplayName(message.from);
                break;
            case ConversationType.Channel:
                let channelInfo = wfc.getChannelInfo(message.conversation.target, false);
                favItem.origin = channelInfo.name;
                break;
            case ConversationType.ChatRoom:
                break;
            default:
                break;
        }

        let data: JSONObject;
        switch (message.messageContent.type) {
            case MessageContentType.Text:
                let textMessageContent = message.messageContent as TextMessageContent;
                favItem.title = textMessageContent.content;
                break;
            case MessageContentType.Image:
                let imageContent = message.messageContent as ImageMessageContent;
                favItem.url = imageContent.remotePath;
                if (imageContent.thumbnail) {
                    data = {
                        "thumb": imageContent.thumbnail,
                    }
                    favItem.data = JSON.stringify(data);
                }
                break;
            case MessageContentType.Video:
                let videoContent = message.messageContent as VideoMessageContent;
                favItem.url = videoContent.remotePath;
                data = {
                    'duration': videoContent.duration,
                }
                if (videoContent.thumbnail) {
                    data['thumb'] = videoContent.thumbnail;
                }
                favItem.data = JSON.stringify(data);
                break;
            case MessageContentType.File:
                let fileContent = message.messageContent as FileMessageContent;
                favItem.url = fileContent.remotePath;
                favItem.title = fileContent.name;
                data = {
                    'size': fileContent.size,
                }
                favItem.data = JSON.stringify(data);
                break;
            case MessageContentType.Composite_Message:
                let compositeContent = message.messageContent as CompositeMessageContent;
                favItem.title = compositeContent.title;
                let payload = compositeContent.encode();

                if (payload.remoteMediaUrl) {
                    let str = wfc.b64_to_utf8(payload.binaryContent);
                    let obj = JSON.parse(str) as JSONObject
                    obj['remote_url'] = payload.remoteMediaUrl;
                    str = JSON.stringify(obj);
                    payload.binaryContent = wfc.utf8_to_b64(str);
                }

                favItem.data = payload.binaryContent;
                break;
            case MessageContentType.Voice:
                let voiceContent = message.messageContent as SoundMessageContent;
                favItem.url = voiceContent.remotePath;
                data = {
                    'duration': voiceContent.duration,
                }
                favItem.data = JSON.stringify(data);
                break;
        // TODO
        // case MessageContentType.Link:
        //     break
            default:
                break;
        }
        if (Config.urlRedirect) {
            favItem.url = Config.urlRedirect(favItem.url);
        }
        return favItem;
    }

    static toMessage(favItem: FavItem) {
        if (favItem.messageUid) {
            let msg = wfc.getMessageByUid(favItem.messageUid);
            if (msg) {
                return msg;
            }
        }
        let content: MessageContent;
        let dataObj: JSONObject = {}
        if (favItem.data && favItem.type !== MessageContentType.Composite_Message) {
            dataObj = JSON.parse(favItem.data)
        }
        try {
            let type = favItem.favType ? favItem.favType : favItem.type;
            switch (type) {
                case MessageContentType.Text:
                    content = new TextMessageContent(favItem.title);
                    break;
                case MessageContentType.Image:
                    content = new ImageMessageContent('', favItem.url, Config.DEFAULT_THUMBNAIL_URL.split(',')[1]);
                    if (favItem.data) {
                        (content as ImageMessageContent).thumbnail = dataObj.thumb as string;
                    }
                    break;
                case MessageContentType.Video:
                    content = new VideoMessageContent('', favItem.url, Config.DEFAULT_THUMBNAIL_URL.split(',')[1]);
                    if (favItem.data) {
                        (content as VideoMessageContent).thumbnail = dataObj.thumb as string;
                    }
                    break;
                case MessageContentType.File:
                    content = new FileMessageContent('', favItem.url, favItem.title, 0);
                    if (favItem.data) {
                        (content as FileMessageContent).size = dataObj.size as number;
                    }
                    break;
                case MessageContentType.Composite_Message:
                    content = new CompositeMessageContent();
                    (content as CompositeMessageContent).title = favItem.title;
                    let payload = new MessagePayload();
                    payload.type = favItem.favType;
                    payload.content = favItem.title;
                    if (favItem.data) {
                        payload.binaryContent = favItem.data;
                        // 兼容处理
                        try {
                            let obj = JSON.parse(favItem.data) as JSONObject
                            payload.remoteMediaUrl = obj['remote_url'] as string;
                            payload.binaryContent = '';
                        } catch (e) {
                        }
                    }
                    content.decode(payload)
                    break;
                case MessageContentType.Voice:
                    content = new SoundMessageContent('', favItem.url, 0)
                    if (favItem.data) {
                        (content as SoundMessageContent).duration = dataObj.duration as number;
                    }
                    break;
            // TODO
            // case MessageContentType.Link:
            //     break
                default:
                    break;
            }
        } catch (e) {
            console.log('toMessage Error', e)
            content = new UnknownMessageContent();
        }
        let msg = new Message(favItem.conversation!, content!);
        if (favItem.messageUid) {
            msg.messageUid = Long.fromValue(favItem.messageUid);
        }

        return msg;
    }
}
