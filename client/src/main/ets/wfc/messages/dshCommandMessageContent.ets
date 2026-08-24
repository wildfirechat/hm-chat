import Message from "./message";
import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import MessagePayload from "./messagePayload";

/**
 * DSH_Command (207)：AI 面板静默指令消息（用户→机器人）。
 * 透明消息（Transparent）：不存储、不计未读、不在消息流显示（digest 为空）。
 * content = JSON.stringify({op: "query"|"set", cmd?, seq?})：
 *   op=query 组合查询（插件聚合面板数据写 scope=31 type=3，不回复消息）；
 *   op=set   更新（cmd 为命令文本，如 "/model deepseek-official/xxx"，插件执行后写 type=1 lastChange 并刷新 type=3）。
 */
export default class DshCommandMessageContent extends MessageContent {
    // query / set
    op: string = ''
    // op=set 时的命令文本（如 "/model xxx"）
    cmd: string = ''
    // 请求序号（防重/排查用）
    seq: number = 0

    constructor(op: string = '', cmd: string = '', seq: number = 0) {
        super(MessageContentType.DSH_COMMAND);
        this.op = op;
        this.cmd = cmd;
        this.seq = seq;
    }

    encode(): MessagePayload {
        let payload = super.encode();
        payload.content = JSON.stringify({ op: this.op, cmd: this.cmd, seq: this.seq });
        payload.searchableContent = '';
        return payload;
    }

    decode(payload: MessagePayload): void {
        super.decode(payload);
        try {
            let d = JSON.parse(payload.content) as Record<string, Object>;
            this.op = d.op as string;
            this.cmd = d.cmd as string;
            this.seq = d.seq as number;
        } catch (e) {
            // 非 JSON 内容忽略
        }
    }

    // 透明消息：digest 为空，不产生会话列表预览
    digest(message?: Message | undefined): string {
        return '';
    }
}
