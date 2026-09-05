import Message from "./message";
import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import MessagePayload from "./messagePayload";

/**
 * AGENT_Command (207)：AI 面板静默指令消息（用户→机器人）。
 * 透明消息（Transparent）：不存储、不计未读、不在消息流显示（digest 为空）。
 * content = JSON.stringify({op: "query"|"set", cmd?, seq?, robotId?})：
 *   op=query 组合查询（插件聚合面板数据写 scope=31 type=3，不回复消息）；
 *   op=set   更新（cmd 为命令文本，如 "/model deepseek-official/xxx"，插件执行后写 type=1 lastChange 并刷新 type=3）；
 *   robotId  目标机器人完整 uid（多机器人会话寻址；缺省/空 = 会话默认机器人，仅该机器人执行）。
 */
export default class AgentCommandMessageContent extends MessageContent {
    // query / set
    op: string = ''
    // op=set 时的命令文本（如 "/model xxx"）
    cmd: string = ''
    // 请求序号（防重/排查用）
    seq: number = 0
    // 目标机器人 uid（多机器人会话寻址；空 = 会话默认机器人）
    robotId: string = ''

    constructor(op: string = '', cmd: string = '', seq: number = 0, robotId: string = '') {
        super(MessageContentType.AGENT_COMMAND);
        this.op = op;
        this.cmd = cmd;
        this.seq = seq;
        this.robotId = robotId;
    }

    encode(): MessagePayload {
        let payload = super.encode();
        // 207 载荷 {op, cmd, seq, robotId?}；robotId 恒写入（多机器人寻址，空串等价于未带=会话默认机器人，插件按 falsy 处理）
        let data: AgentCommandData = new AgentCommandData();
        data.op = this.op;
        data.cmd = this.cmd;
        data.seq = this.seq;
        data.robotId = this.robotId;
        payload.content = JSON.stringify(data);
        payload.searchableContent = '';
        return payload;
    }

    decode(payload: MessagePayload): void {
        super.decode(payload);
        try {
            let d = JSON.parse(payload.content) as AgentCommandData;
            this.op = d.op as string;
            this.cmd = d.cmd as string;
            this.seq = d.seq as number;
            this.robotId = d.robotId as string || '';
        } catch (e) {
            // 非 JSON 内容忽略
        }
    }

    // 透明消息：digest 为空，不产生会话列表预览
    digest(message?: Message | undefined): string {
        return '';
    }
}

/** 207 载荷结构（ArkTS 要求对象字面量对应显式声明的类）。 */
class AgentCommandData {
    op: string = ''
    cmd: string = ''
    seq: number = 0
    robotId: string = ''
}
