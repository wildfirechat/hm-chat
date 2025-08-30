import conferenceApi from "../../../api/appServer";
import MessageContentType from "@wfc/client/src/main/ets/wfc/messages/messageContentType";
import ConferenceCommandMessageContent from "@wfc/client/src/main/ets/wfc/av/messages/conferenceCommandMessageContent";
import {ConferenceCommandType} from "@wfc/client/src/main/ets/wfc/av/messages/conferenceCommandMessageContent";
import Conversation from "@wfc/client/src/main/ets/wfc/model/conversation";
import Message from "@wfc/client/src/main/ets/wfc/messages/message";
import ConversationType from "@wfc/client/src/main/ets/wfc/model/conversationType";
import wfc from '@wfc/client'
import ConferenceInfo from "@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo";
import { showToast } from "../../../common/utils/Toast";

class ConferenceManager {
    constructor() {
    }

    conferenceInfo ?: ConferenceInfo;
    applyingUnmuteAudioMembers: string[] = [];
    applyingUnmuteVideoMembers: string[] = [];
    isApplyingUnmuteAudio = false;
    isApplyingUnmuteVideo = false;
    handUpMembers: string[] = [];
    isHandUp = false;
    isMuteAll = false;
    allowUnmuteAudio = false;
    allowUnmuteVideo = false;
    currentFocusUser = null;
    localFocusUser = null;
    selfUserId = null;

    destroy() {
        if (this.conferenceInfo) {
            wfc.quitChatroom(this.conferenceInfo.conferenceId);
        }
    }

    getConferenceInfo(conferenceId: string) {
        // TODO password
        conferenceApi.queryConferenceInfo(conferenceId, '')
            .then(info => {
                this.conferenceInfo = info;
            })
            .catch((err: Error) => {
                console.log(err.message)
            })
    }

    onReceiveMessage = async (msg: Message) => {
        if (msg.messageContent.type === MessageContentType.CONFERENCE_CONTENT_TYPE_COMMAND) {
            let command = msg.messageContent as ConferenceCommandMessageContent;
            if (command.conferenceId !== this.conferenceInfo?.conferenceId) {
                console.log('not current conference', command.conferenceId, this.conferenceInfo?.conferenceId);
                return;
            }
            console.log('receive conference command message', msg);
            let senderName: string;
            switch (command.commandType) {
                case ConferenceCommandType.MUTE_ALL_AUDIO:
                    this._reloadCurrentConferenceInfo();
                    this.onMuteAll(true);
                    this.allowUnmuteAudio = command.boolValue;
                    break;
                case ConferenceCommandType.MUTE_ALL_VIDEO:
                    this._reloadCurrentConferenceInfo();
                    this.onMuteAll(false);
                    this.allowUnmuteVideo = command.boolValue;
                    break;
                case ConferenceCommandType.CANCEL_MUTE_ALL_AUDIO:
                    this._reloadCurrentConferenceInfo();
                    this.onCancelMuteAll(true, command.boolValue);
                    break;
                case ConferenceCommandType.CANCEL_MUTE_ALL_VIDEO:
                    this._reloadCurrentConferenceInfo();
                    this.onCancelMuteAll(false, command.boolValue);
                    break;
                case ConferenceCommandType.REQUEST_MUTE_AUDIO:
                    if (command.targetUserId === this.selfUserId) {
                        this.onRequestMute(true, command.boolValue);
                    }
                    break;
                case ConferenceCommandType.REQUEST_MUTE_VIDEO:
                    if (command.targetUserId === this.selfUserId) {
                        this.onRequestMute(false, command.boolValue);
                    }
                    break;
                case ConferenceCommandType.REJECT_UNMUTE_REQUEST_AUDIO:
                    showToast('主持人拒绝了你的发言请求')
                    break;
                case ConferenceCommandType.REJECT_UNMUTE_REQUEST_VIDEO:
                        showToast('主持人拒绝了你的打开摄像头请求')
                    break;
                case ConferenceCommandType.APPLY_UNMUTE_AUDIO:
                    senderName = wfc.getUserDisplayName(msg.from);
                    if (command.boolValue) {
                        this.applyingUnmuteAudioMembers.filter(uid => uid !== msg.from)
                    } else {
                        let index = this.applyingUnmuteAudioMembers.findIndex(uid => uid === msg.from);
                        if (index === -1) {
                            this.applyingUnmuteAudioMembers.push(msg.from);
                        }
                        showToast(senderName + '请求发言')
                    }
                    break;
                case ConferenceCommandType.APPLY_UNMUTE_VIDEO:
                    senderName = wfc.getUserDisplayName(msg.from);
                    if (command.boolValue) {
                        this.applyingUnmuteVideoMembers.filter(uid => uid !== msg.from)
                    } else {
                        let index = this.applyingUnmuteVideoMembers.findIndex(uid => uid === msg.from);
                        if (index === -1) {
                            this.applyingUnmuteVideoMembers.push(msg.from);
                        }
                        showToast(senderName + '请求打开摄像头')
                    }
                    break;
                case ConferenceCommandType.APPROVE_UNMUTE_AUDIO:
                case ConferenceCommandType.APPROVE_ALL_UNMUTE_AUDIO:
                    if (this.isApplyingUnmuteAudio) {
                        this.isApplyingUnmuteAudio = false;
                        if (command.boolValue) {
                            // TODO
                            // this.vueInstance.$eventBus.$emit('muteAudio', false);
                            showToast('主持人已同意了你的发言请求')
                        }
                    }
                    break;
                case ConferenceCommandType.APPROVE_UNMUTE_VIDEO:
                case ConferenceCommandType.APPROVE_ALL_UNMUTE_VIDEO:
                    if (this.isApplyingUnmuteVideo) {
                        this.isApplyingUnmuteVideo = false;
                        if (command.boolValue) {
                            // TODO
                            // this.vueInstance.$eventBus.$emit('muteVideo', false);
                            showToast('主持人已同意了你的打开摄像头请求')
                        }
                    }
                    break;
                case ConferenceCommandType.HANDUP:
                    if (command.boolValue) {
                        let index = this.handUpMembers.findIndex(uid => uid === msg.from);
                        if (index === -1) {
                            this.handUpMembers.push(msg.from);
                        }
                    } else {
                        this.handUpMembers = this.handUpMembers.filter(uid => uid !== msg.from);
                    }
                    senderName = wfc.getUserDisplayName(msg.from);
                    showToast(command.boolValue ? senderName + '举手' : senderName + '放下举手')
                    break;
                case ConferenceCommandType.PUT_HAND_DOWN:
                case ConferenceCommandType.PUT_ALL_HAND_DOWN:
                    if (this.isHandUp) {
                        this.isHandUp = false;
                        showToast('主持人放下了你的举手')
                    }
                    break
                case ConferenceCommandType.RECORDING:
                    this.conferenceInfo.recording = command.boolValue;
                    showToast( command.boolValue ? '主持人开始录制' : '主持人结束录制')
                    break;
                case ConferenceCommandType.FOCUS:
                    this.conferenceInfo.focus = command.targetUserId;
                    showToast('主持人锁定焦点用户')
                    break;
                case ConferenceCommandType.CANCEL_FOCUS:
                    this.conferenceInfo.focus = '';
                    showToast('主持人取消锁定焦点用户')
                    break;
                default:
                    break;
            }
        }
    }

    /**
     * 申请解除打开麦克风或摄摄像头
     * @param {boolean} audio true，麦克风；false，摄像头
     * @param isCancel true，取消之前的申请；false，发起申请
     */
    applyUnmute(audio: boolean, isCancel: boolean) {
        if (audio) {
            this.isApplyingUnmuteAudio = !isCancel;
        } else {
            this.isApplyingUnmuteVideo = !isCancel;
        }
        let type = audio ? ConferenceCommandType.APPLY_UNMUTE_AUDIO : ConferenceCommandType.APPLY_UNMUTE_VIDEO;
        this._sendCommandMessage(type, '', isCancel);
    }

    /**
     * 批准用户打开麦克风/摄像头请求
     * @param {string} userId 用户 id
     * @param {boolean} audio true，麦克风；false，摄像头
     * @param {boolean} isAllow 是否批准
     */
    approveUnmute(userId:string, audio:boolean, isAllow:boolean) {
        if (!this.isOwner()) {
            return;
        }
        if (audio) {
            this.applyingUnmuteAudioMembers = this.applyingUnmuteAudioMembers.filter(uid => uid !== userId);
        } else {
            this.applyingUnmuteVideoMembers = this.applyingUnmuteVideoMembers.filter(uid => uid !== userId);
        }
        let type = audio ? ConferenceCommandType.APPROVE_UNMUTE_AUDIO : ConferenceCommandType.APPROVE_UNMUTE_VIDEO;
        this._sendCommandMessage(type, userId, isAllow);
    }

    /**
     * 批准所有打开麦克风/摄像头请求
     * @param {boolean} audio true，麦克风；false，摄像头
     * @param {boolean} isAllow 是否批准
     */
    approveAllUnmute(audio:boolean, isAllow:boolean) {
        if (!this.isOwner()) {
            return;
        }
        if (audio) {
            this.applyingUnmuteAudioMembers.length = 0;
        } else {
            this.applyingUnmuteVideoMembers.length = 0;
        }
        let type = audio ? ConferenceCommandType.APPROVE_ALL_UNMUTE_AUDIO : ConferenceCommandType.APPROVE_ALL_UNMUTE_VIDEO;
        this._sendCommandMessage(type, '', isAllow);
    }

    /**
     * 主持人邀请打开/关闭麦克风或摄像
     * @param {string} userId
     * @param {boolean} audio true，麦克风；false，摄像头
     * @param {boolean} mute true，打开；false，关闭
     */
    requestMemberMute(userId:string, audio:boolean, mute:boolean) {
        if (!this.isOwner()) {
            return;
        }

        let type = audio ? ConferenceCommandType.REQUEST_MUTE_AUDIO : ConferenceCommandType.REQUEST_MUTE_VIDEO;
        this._sendCommandMessage(type, userId, mute);
    }

    /**
     * 主持人关闭所有人的麦克风或摄像头
     * @param {boolean} audio true 麦克风， false 摄像头
     * @param {boolean} allowMemberUnmute 允许成员主动开启麦克风或摄像头
     */
    requestMuteAll(audio:boolean, allowMemberUnmute:boolean) {
        if (!this.isOwner()) {
            return;
        }
        this.isMuteAll = true;
        this.conferenceInfo!.audience = true;
        this.conferenceInfo!.allowSwitchMode = allowMemberUnmute;
        conferenceApi.updateConference(this.conferenceInfo!)
            .then(r => {
                let type = audio ? ConferenceCommandType.MUTE_ALL_AUDIO : ConferenceCommandType.MUTE_ALL_VIDEO;
                this._sendCommandMessage(type, '', allowMemberUnmute);
            })
            .catch((err:Error) => {
                console.log('updateConference error', err)
            })
    }

    /**
     * 主持人取消所有人关闭麦克风或摄像头
     * @param {boolean} audio true 麦克风， false 摄像头
     * @param {boolean} unmute 是否提示成员打开麦克风或摄像头
     */
    requestUnmuteAll(audio:boolean, unmute:boolean) {
        if (!this.isOwner()) {
            return;
        }

        this.isMuteAll = false;
        this.conferenceInfo!.audience = false;
        this.conferenceInfo!.allowSwitchMode = true;
        conferenceApi.updateConference(this.conferenceInfo!)
            .then(r => {
                let type = audio ? ConferenceCommandType.CANCEL_MUTE_ALL_AUDIO : ConferenceCommandType.CANCEL_MUTE_ALL_VIDEO
                this._sendCommandMessage(type, '', unmute);
            })
            .catch((err:Error) => {
                console.log('updateConference error', err)
            })
    }

    /**
     * 举手
     * @param {boolean} isHandUp
     */
    handUp(isHandUp:boolean) {
        this.isHandUp = isHandUp;
        this._sendCommandMessage(ConferenceCommandType.HANDUP, '', isHandUp);
        showToast(isHandUp ? "已举手，等待管理员处理" : "已放下举手")
    }

    /**
     * 主持人放下成员举手
     * @param {string} memberId
     */
    putMemberHandDown(memberId:string) {
        if (!this.isOwner()) {
            return;
        }
        this.handUpMembers = this.handUpMembers.filter(uid => uid !== memberId);
        this._sendCommandMessage(ConferenceCommandType.PUT_HAND_DOWN, memberId, false);
    }

    /**
     * 主持人放下所有人举手
     */
    putAllHandDown() {
        if (!this.isOwner()) {
            return;
        }
        this.handUpMembers.length = 0;
        this._sendCommandMessage(ConferenceCommandType.PUT_ALL_HAND_DOWN, '', false);
    }

    requestRecord(record:boolean) {
        if (!this.isOwner()) {
            return;
        }
        conferenceApi.recordConference(this.conferenceInfo!.conferenceId, record)
            .then(r => {
                this.conferenceInfo!.recording= record;
            })
            .catch((err:Error) => {
                console.log('recordConference error', err);
            });
    }

    /**
     * 主持人设置焦点用户
     * @param {string} userId
     */
    requestFocus(userId:string) {
        if (!this.isOwner()) {
            return;
        }
        conferenceApi.setConferenceFocusUserId(this.conferenceInfo!.conferenceId, userId)
            .then(r => {
                this.conferenceInfo!.focus = userId;
            })
            .catch((err:Error) => {
                console.log('requestFocus err', err);
            })
    }

    requestCancelFocus() {
        this.requestFocus('');
    }

    /**
     * 主任任请求全员静音
     */
    onMuteAll(audio:boolean) {
        let desc:string = '';
        // TODO
        // if (audio) {
        //     desc = '管理员将全体成员静音了';
        //     //this.vueInstance.$eventBus.$emit('muteAudio', true);
        // } else {
        //     desc = '管理员关闭了所有人的摄像头';
        //     this.vueInstance.$eventBus.$emit('muteVideo', true);
        // }
        showToast(desc)
    }

    /**
     * 主持人取消全员静音
     * @param audio
     * @param requestUnmute
     */
    onCancelMuteAll(audio:boolean, requestUnmute:boolean) {
        // TODO
        // if (requestUnmute && this.vueInstance.selfUserInfo._isAudience) {
        //     this.vueInstance.$alert({
        //         showIcon: false,
        //         content: audio ? '主持人关闭了全员静音，是否要打开麦克风' : '管理员取消了全体成员关闭摄像头，是否打开摄像头',
        //         confirmText: '打开',
        //         cancelCallback: () => {
        //             // do nothing
        //         },
        //         confirmCallback: () => {
        //             if (audio) {
        //                 this.vueInstance.$eventBus.$emit('muteAudio', false);
        //             } else {
        //                 this.vueInstance.$eventBus.$emit('muteVideo', false);
        //             }
        //         }
        //     })
        //
        // }
        let desc = audio ? '管理员取消了全体成员静音' : '管理员取消了全体成员关闭摄像'
        showToast(desc)
    }

    /**
     * 主持人请求 mute 操作
     * @param audio
     * @param mute
     */
    onRequestMute(audio:boolean, mute:boolean) {
        // TODO
        // if (!mute) {
        //     this.vueInstance.$alert({
        //         showIcon: false,
        //         content: audio ? '主持人邀请你发言' : '主持人邀请你打开摄像头',
        //         confirmText: '接受',
        //         cancelCallback: () => {
        //             // do nothing
        //         },
        //         confirmCallback: () => {
        //             if (audio) {
        //                 this.vueInstance.$eventBus.$emit('muteAudio', false);
        //             } else {
        //                 this.vueInstance.$eventBus.$emit('muteVideo', false);
        //             }
        //         }
        //     })
        // } else {
        //     if (audio) {
        //         this.vueInstance.$eventBus.$emit('muteAudio', true);
        //     } else {
        //         this.vueInstance.$eventBus.$emit('muteVideo', true);
        //     }
        //
        //     this.vueInstance.$notify({
        //         text: audio ? '管理员关闭了你的发言' : '管理员关闭了你的摄像头',
        //         type: 'info'
        //     });
        // }
    }

    addHistory(conferenceInfo:ConferenceInfo, durationMS:number) {
        // TODO
        // console.log('addHistory', conferenceInfo, durationMS);
        // let tmp = localStorage.getItem('historyConfList');
        // let historyList = JSON.parse(tmp);
        // historyList = historyList ? historyList : [];
        // conferenceInfo.endTime = Math.ceil(conferenceInfo.startTime + durationMS / 1000);
        // let index = historyList.findIndex(info => info.conferenceId === conferenceInfo.conferenceId)
        // if (index >= 0) {
        //     historyList[index] = conferenceInfo;
        // } else {
        //     historyList.push(conferenceInfo);
        //     if (historyList.length > 50) {
        //         historyList = historyList.shift();
        //     }
        // }
        // localStorage.setItem('historyConfList', JSON.stringify(historyList, null, ''));
    }

    getHistoryConference() {
        // TODO
        // let tmp = localStorage.getItem('historyConfList');
        // let historyList = JSON.parse(tmp);
        // historyList = historyList ? historyList : [];
        // return historyList;
    }

    _reloadCurrentConferenceInfo() {
        conferenceApi.queryConferenceInfo(this.conferenceInfo!.conferenceId, this.conferenceInfo!.password)
            .then(info => {
                this.conferenceInfo = info;
            })
            .catch((err:Error) => {
                console.log(err.message)
            })
    }

    isOwner() {
        return this.conferenceInfo!.owner === this.selfUserId;
    }

    _sendCommandMessage(commandType:number, targetUser:string, boolValue:boolean) {
        let content = new ConferenceCommandMessageContent(this.conferenceInfo!.conferenceId, commandType, targetUser, boolValue);
        let conversation = new Conversation(ConversationType.ChatRoom, this.conferenceInfo!.conferenceId, 0);
        wfc.sendConversationMessage(conversation, content);
    }
}

let self = new ConferenceManager();

export default self;
