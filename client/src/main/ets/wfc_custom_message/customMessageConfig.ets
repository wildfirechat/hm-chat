import { MessageContentConfig } from '../wfc/client/messageConfig';
import wfc from '../wfc/client/wfc';
import MessageContent from '../wfc/messages/messageContent';
import PersistFlag from '../wfc/messages/persistFlag';
import MessageContentType from '../wfc/messages/messageContentType';
import UnknownMessageContent from '../wfc/messages/unknownMessageContent';
import CustomMessageContentType from "./customMessageContentType";
import MomentCommentMessageContent from "./momentCommentMessageContent";
import MomentFeedMessageContent from "./momentFeedMessageContent";
import TestCustomMessageContent from "./testCustomMessageContent";
import TestCustomNotificationMessageContent from "./testCustomNotificationMessageContent";
import PollMessageContent from "../wfc/messages/pollMessageContent";
import PollResultMessageContent from "../wfc/messages/pollResultMessageContent";

export default class CustomMessageConfig {
    static CustomMessageContents: MessageContentConfig[] = [
        {
            name: 'momentFeedMessage', // 消息名字
            flag: PersistFlag.Persist_And_Count, // 消息的存储类型，根据消息是否需要存储选择
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_FEED, // 消息类型
        },
        {
            name: 'momentCommentMessage',
            flag: PersistFlag.Persist_And_Count,
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_COMMENT,
        },
        {
            name: 'testCustomMessage', // 消息名字
            flag: PersistFlag.Persist, // 消息的存储类型，根据消息是否需要存储选择
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_CUSTOM_MESSAGE_TEST, // 消息类型
        },
        {
            name: 'testCustomNotificationMessage',
            flag: PersistFlag.Persist,
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_CUSTOM_MESSAGE_TEST_NOTIFICATION,
        },
        {
            name: 'poll',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Poll,
        },
        {
            name: 'pollResult',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Poll_Result,
        },
        // 添加更多自定义消息
    ];

    static newCustomMessageContent(customMessageType: number): MessageContent | undefined {
        let content: MessageContent | undefined
        switch (customMessageType) {
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_FEED:
                content = new MomentFeedMessageContent();
                break;
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_COMMENT:
                content = new MomentCommentMessageContent();
                break;
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_CUSTOM_MESSAGE_TEST:
                content = new TestCustomMessageContent();
                break;
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_CUSTOM_MESSAGE_TEST_NOTIFICATION:
                content = new TestCustomNotificationMessageContent()
                break;
            case MessageContentType.Poll:
                content = new PollMessageContent()
                break;
            case MessageContentType.Poll_Result:
                content = new PollResultMessageContent()
                break;
             // 参考上面的逻辑，根据消息类型，创建其他自定义消息
            default:
                content = undefined
                break
        }
        return content
    }

    // 请勿修改
    static registerCustomMessages() {
        CustomMessageConfig.CustomMessageContents.forEach(cmc => {
            wfc.registerMessageContent(cmc.name, cmc.flag, cmc.type)
        })
    }
}
