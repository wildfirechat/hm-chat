import Message from "./message";
import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import MessagePayload from "./messagePayload";

/**
 * AGENT_Command_Result (209)：AI 面板指令的应答消息（机器人→用户）。
 * 透明消息（Transparent，persistFlag=4）：不存储、不计未读、不在消息流显示（digest 为空）。
 * content = JSON.stringify({ver, op, seq, robotId?, cwd?, root?, dirs?, total?, truncated?})：
 *   op="dirs" 应答 207 {op:"dirs"} 请求（目录列表按需获取，见 INTERACTION_DESIGN.md §10）；
 *   seq      回显请求 207 的 seq，客户端按 seq 关联 pending 请求（未匹配/已超时丢弃）；
 *   robotId  目标机器人完整 uid（与请求一致；多机器人会话校验寻址）；
 *   cwd      应答时的当前工作目录（绝对路径）；
 *   root     目录列表来源目录（项目根，绝对路径；dirs 是它的一级子目录名）；
 *   dirs     目录名列表（非全路径，按名称升序）；
 *   total    截断前目录总数；truncated 是否被插件截断（上限 3000）。
 */
export default class AgentCommandResultMessageContent extends MessageContent {
    // 协议版本（当前 1）
    ver: number = 0
    // 对应请求的 op（当前只有 dirs）
    op: string = ''
    // 回显请求 207 的 seq
    seq: number = 0
    // 目标机器人 uid（与请求一致；空 = 未带）
    robotId: string = ''
    // 应答时当前工作目录
    cwd: string = ''
    // 目录列表来源目录（项目根）
    root: string = ''
    // 目录名列表（非全路径）
    dirs: string[] = []
    // 截断前目录总数
    total: number = 0
    // 是否被截断
    truncated: boolean = false

    constructor() {
        super(MessageContentType.AGENT_COMMAND_RESULT);
    }

    encode(): MessagePayload {
        let payload = super.encode();
        // 209 载荷 {ver, op, seq, robotId?, cwd?, root?, dirs?, total?, truncated?}
        let data: AgentCommandResultData = new AgentCommandResultData();
        data.ver = this.ver;
        data.op = this.op;
        data.seq = this.seq;
        data.robotId = this.robotId;
        data.cwd = this.cwd;
        data.root = this.root;
        data.dirs = this.dirs;
        data.total = this.total;
        data.truncated = this.truncated;
        payload.content = JSON.stringify(data);
        payload.searchableContent = `📂 AI 目录列表（${this.dirs ? this.dirs.length : 0}）`;
        return payload;
    }

    decode(payload: MessagePayload): void {
        super.decode(payload);
        try {
            let d = JSON.parse(payload.content) as Record<string, Object>;
            if (!d) {
                return;
            }
            // 逐字段兜底：缺字段/类型不符时保持默认值，避免脏数据导致面板崩溃
            let ver = d['ver'] as number;
            this.ver = typeof ver === 'number' ? ver : 0;
            let op = d['op'] as string;
            this.op = typeof op === 'string' ? op : '';
            let seq = d['seq'] as number;
            this.seq = typeof seq === 'number' ? seq : 0;
            let robotId = d['robotId'] as string;
            this.robotId = typeof robotId === 'string' ? robotId : '';
            let cwd = d['cwd'] as string;
            this.cwd = typeof cwd === 'string' ? cwd : '';
            let root = d['root'] as string;
            this.root = typeof root === 'string' ? root : '';
            let rawDirs = d['dirs'] as string[];
            let dirs: string[] = [];
            if (rawDirs) {
                for (const item of rawDirs) {
                    if (typeof item === 'string') {
                        dirs.push(item);
                    }
                }
            }
            this.dirs = dirs;
            let total = d['total'] as number;
            this.total = typeof total === 'number' ? total : 0;
            this.truncated = d['truncated'] === true;
        } catch (e) {
            // 非 JSON 内容忽略（字段保持默认值）
        }
    }

    // 透明消息：digest 为空，不产生会话列表预览
    digest(message?: Message | undefined): string {
        return '';
    }
}

/** 209 载荷结构（ArkTS 要求对象字面量对应显式声明的类）。 */
class AgentCommandResultData {
    ver: number = 0
    op: string = ''
    seq: number = 0
    robotId: string = ''
    cwd: string = ''
    root: string = ''
    dirs: string[] = []
    total: number = 0
    truncated: boolean = false
}
