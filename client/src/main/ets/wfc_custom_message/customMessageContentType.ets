export default class CustomMessageContentType {
    // 朋友圈消息，与其他端协议保持一致，使用 1000 以下的类型值
    static MESSAGE_CONTENT_TYPE_FEED = 501;
    static MESSAGE_CONTENT_TYPE_COMMENT = 502;
    // 1000 以下为内部消息保留，自定义消息需使用 1000 以上的数字
    static MESSAGE_CONTENT_TYPE_CUSTOM_MESSAGE_TEST = 1001;
    static MESSAGE_CONTENT_TYPE_CUSTOM_MESSAGE_TEST_NOTIFICATION = 1002;

    // Agent 结构化交互消息，200-209 为官方预留 AI 交互段（与 PC 端/服务端协议对齐，不受上面 1000 的限制）
    static MESSAGE_CONTENT_TYPE_AGENT_QUESTION = 200;
    static MESSAGE_CONTENT_TYPE_AGENT_ANSWER = 201;
    static MESSAGE_CONTENT_TYPE_AGENT_APPROVAL = 202;
    static MESSAGE_CONTENT_TYPE_AGENT_APPROVAL_RESULT = 203;
    static MESSAGE_CONTENT_TYPE_AGENT_GOAL = 206;
    static MESSAGE_CONTENT_TYPE_AGENT_TASK_PROGRESS = 208;
    // 添加更多自定义消息
}
