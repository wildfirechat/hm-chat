import MessageContent from "../../messages/messageContent";
import MessageContentType from "../../messages/messageContentType";
import wfc from "../../client/wfc";
import MessagePayload from '../../messages/messagePayload';

export default class ConferenceCommandMessageContent extends MessageContent {
    conferenceId = '';
    commandType = 0;
    targetUserId = '';
    boolValue = false;

    constructor(conferenceId: string = '', commandType: number = 0, targetUserId: string = '', boolValue: boolean = false) {
        super(MessageContentType.CONFERENCE_CONTENT_TYPE_COMMAND);
        this.conferenceId = conferenceId;
        this.commandType = commandType;
        this.targetUserId = targetUserId;
        this.boolValue = boolValue;
    }


    encode() {
        let payload = super.encode();
        payload.content = this.conferenceId;
        let obj = {
            t: this.commandType,
            u: this.targetUserId,
        } as Data;
        if (this.boolValue) {
            obj.b = this.boolValue;
        }

        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));
        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        if (payload.binaryContent) {
            let json = wfc.b64_to_utf8(payload.binaryContent);
            let obj = JSON.parse(json) as Data;
            this.commandType = obj.t;
            this.boolValue = !!obj.b;
            this.targetUserId = obj.u;

        }
        this.conferenceId = payload.content;
    }
}


export class ConferenceCommandType {
    //全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否允许成员自主解除静音。
    static MUTE_ALL_AUDIO = 0;
    //取消全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否邀请成员解除静音。
    static CANCEL_MUTE_ALL_AUDIO = 1;
    //要求某个用户更改静音状态，只有主持人可以操作。带有参数是否静音/解除静音。
    static REQUEST_MUTE_AUDIO = 2;
    //拒绝UNMUTE要求。（如果同意不需要通知对方同意)
    static REJECT_UNMUTE_REQUEST_AUDIO = 3;
    //普通用户申请解除静音，带有参数是请求，还是取消请求。
    static APPLY_UNMUTE_AUDIO = 4;
    //管理员批准解除静音申请，带有参数是同意，还是拒绝申请。
    static APPROVE_UNMUTE_AUDIO = 5;
    //管理员批准全部解除静音申请，带有参数是同意，还是拒绝申请。
    static APPROVE_ALL_UNMUTE_AUDIO = 6;
    //举手，带有参数是举手还是放下举手
    static HANDUP = 7;
    //主持人放下成员的举手
    static PUT_HAND_DOWN = 8;
    //主持人放下全体成员的举手
    static PUT_ALL_HAND_DOWN = 9;
    //录制，有参数是录制还是取消录制
    static RECORDING = 10;
    // 设置焦点用户
    static FOCUS = 11;
    // 取消设置焦点用户
    static CANCEL_FOCUS = 12;
    //全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否允许成员自主解除静音。
    static MUTE_ALL_VIDEO = 13;
    //取消全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否邀请成员解除静音。
    static CANCEL_MUTE_ALL_VIDEO = 14;
    //要求某个用户更改静音状态，只有主持人可以操作。带有参数是否静音/解除静音。
    static REQUEST_MUTE_VIDEO = 15;
    //拒绝UNMUTE要求。（如果同意不需要通知对方同意)
    static REJECT_UNMUTE_REQUEST_VIDEO = 16;
    //普通用户申请解除静音，带有参数是请求，还是取消请求。
    static APPLY_UNMUTE_VIDEO = 17;
    //管理员批准解除静音申请，带有参数是同意，还是拒绝申请。
    static APPROVE_UNMUTE_VIDEO = 18;
    //管理员批准全部解除静音申请，带有参数是同意，还是拒绝申请。
    static APPROVE_ALL_UNMUTE_VIDEO = 19;
}

class Data {
    t = 0
    u = ''
    b = false
}
