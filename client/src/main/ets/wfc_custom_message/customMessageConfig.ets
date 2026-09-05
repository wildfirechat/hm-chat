import { MessageContentConfig } from '../wfc/client/messageConfig';
import wfc from '../wfc/client/wfc';
import MessageContent from '../wfc/messages/messageContent';
import PersistFlag from '../wfc/messages/persistFlag';
import UnknownMessageContent from '../wfc/messages/unknownMessageContent';
import CustomMessageContentType from "./customMessageContentType";
import AgentAnswerMessageContent from "./agentAnswerMessageContent";
import AgentApprovalMessageContent from "./agentApprovalMessageContent";
import AgentApprovalResultMessageContent from "./agentApprovalResultMessageContent";
import AgentGoalMessageContent from "./agentGoalMessageContent";
import AgentQuestionMessageContent from "./agentQuestionMessageContent";
import AgentTaskProgressMessageContent from "./agentTaskProgressMessageContent";
import MomentCommentMessageContent from "./momentCommentMessageContent";
import MomentFeedMessageContent from "./momentFeedMessageContent";
import TestCustomMessageContent from "./testCustomMessageContent";
import TestCustomNotificationMessageContent from "./testCustomNotificationMessageContent";

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
        // Agent 结构化交互消息（官方预留 AI 交互段 200-209），与 PC 端一致均用 Persist
        {
            name: 'agentQuestionMessage',
            flag: PersistFlag.Persist,
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_QUESTION,
        },
        {
            name: 'agentAnswerMessage',
            flag: PersistFlag.Persist,
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_ANSWER,
        },
        {
            name: 'agentApprovalMessage',
            flag: PersistFlag.Persist,
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_APPROVAL,
        },
        {
            name: 'agentApprovalResultMessage',
            flag: PersistFlag.Persist,
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_APPROVAL_RESULT,
        },
        {
            name: 'agentGoalMessage',
            flag: PersistFlag.Persist,
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_GOAL,
        },
        {
            name: 'agentTaskProgressMessage',
            flag: PersistFlag.Persist,
            type: CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_TASK_PROGRESS,
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
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_QUESTION:
                content = new AgentQuestionMessageContent();
                break;
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_ANSWER:
                content = new AgentAnswerMessageContent();
                break;
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_APPROVAL:
                content = new AgentApprovalMessageContent();
                break;
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_APPROVAL_RESULT:
                content = new AgentApprovalResultMessageContent();
                break;
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_GOAL:
                content = new AgentGoalMessageContent();
                break;
            case CustomMessageContentType.MESSAGE_CONTENT_TYPE_AGENT_TASK_PROGRESS:
                content = new AgentTaskProgressMessageContent();
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
