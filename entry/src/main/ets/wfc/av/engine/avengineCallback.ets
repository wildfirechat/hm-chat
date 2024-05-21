/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import UserInfo from '../../model/userInfo';
import CallEndReason from './callEndReason';
import CallSession from './callSession';
import { router, window } from '@kit.ArkUI';
import AVSessionManager from '@ohos.multimedia.avsession';
import { startContinuousTask, stopContinuousTask } from '../../../helper/continuousTaskHelper';

export default class AVEngineCallback {
    private context: Context
    private avSession?: AVSessionManager.AVSession

    constructor(context: Context) {
        this.context = context
    }

    /**
     * 收到音视频通话邀请
     * @param {CallSession} session 会话信息
     */
    async onReceiveCall(session: CallSession) {
        this.createAVSessionAndStartContinuousTask()
        router.pushUrl({
            url: 'pages/voip/SingleAudioCallPage'
        })
    }

    /**
     * 发起音视频通话请求
     * @param session 会话信息
     */
    onStartCall(session: CallSession) {
        this.createAVSessionAndStartContinuousTask()
        router.pushUrl({
            url: 'pages/voip/SingleAudioCallPage'
        })
    }

    shouldStartRing(isIncoming: boolean) {

    }

    shouldStopRing() {

    }

    didCallEnded(reason: CallEndReason, duration: number) {
        this.avSession?.deactivate()
        this.avSession = undefined
        stopContinuousTask(this.context)
        try {
            let floatWindow = window.findWindow("voipFloatingWindow")
            if (floatWindow) {
                floatWindow.destroyWindow()
            }
        } catch (exception) {
            console.error('Failed to find the Window. Cause: ' + JSON.stringify(exception));
        }
    }

    private async createAVSessionAndStartContinuousTask() {
        let type: AVSessionManager.AVSessionType = 'voice_call';
        this.avSession = await AVSessionManager.createAVSession(this.context, 'voip', type);
        console.log('AVSession成功：' + JSON.stringify(this.avSession))
        // 激活接口要在元数据、控制命令注册完成之后再执行
        await this.avSession.activate();
        try {
            startContinuousTask(this.context)
        } catch (e) {
            console.log('startBackgroundRunning', e)
        }
    }
}