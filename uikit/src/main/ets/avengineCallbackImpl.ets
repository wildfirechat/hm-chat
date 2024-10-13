/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import CallEndReason from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callEndReason'
import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import { router, window } from '@kit.ArkUI';
import AVSessionManager from '@ohos.multimedia.avsession';
import { startContinuousTask, stopContinuousTask } from './helper/continuousTaskHelper';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import AVEngineCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/avengineCallback';
// 一定要引入，否则不能弹出对应页面
import './pages/voip/SingleAudioCallPage'
import './pages/voip/SingleVideoCallPage'
import './pages/voip/MultiAudioCallPage'
import './pages/voip/MultiVideoCallPage'

import { BusinessError } from '@kit.BasicServicesKit';

export default class AVEngineCallbackImpl extends AVEngineCallback {
    private context: Context
    private avSession?: AVSessionManager.AVSession

    constructor(context: Context) {
        super(context)
        this.context = context
    }

    /**
     * 收到音视频通话邀请
     * @param {CallSession} session 会话信息
     */
    async onReceiveCall(session: CallSession) {
        this.createAVSessionAndStartContinuousTask(session.audioOnly)
        let url = ''
        if (session.conversation?.type === ConversationType.Single) {
            if (session.audioOnly) {
                url = 'singleAudioCallPage'
            } else {
                url = 'singleVideoCallPage'
            }
        } else if (session.conversation?.type === ConversationType.Group) {
            if (session.audioOnly) {
                url = 'multiAudioCallPage'
            } else {
                url = 'multiVideoCallPage'
            }
        } else {
            // TODO 会议
        }

        router.pushNamedRoute({
            name: url,
        }).catch((e: BusinessError) => {
            console.log('router to voip page error', e)
        })
    }

    /**
     * 发起音视频通话请求
     * @param session 会话信息
     */
    onStartCall = (session: CallSession) => {
        this.createAVSessionAndStartContinuousTask(session.audioOnly)
        let url = ''
        if (session.conversation?.type === ConversationType.Single) {
            if (session.audioOnly) {
                url = 'singleAudioCallPage'
            } else {
                url = 'singleVideoCallPage'
            }
        } else if (session.conversation?.type === ConversationType.Group) {
            if (session.audioOnly) {
                url = 'multiAudioCallPage'
            } else {
                url = 'multiVideoCallPage'
            }
        } else {
            // TODO 会议
        }
        router.pushNamedRoute({
            name: url,
        }).catch((e: BusinessError) => {
            console.error('router to voip page error', e)
        })
    }

    shouldStartRing(isIncoming: boolean) {
        // TODO
    }

    shouldStopRing() {
        // TODO
    }

    didCallEnded(reason: CallEndReason, duration: number) {
        this.avSession?.deactivate()
        this.avSession?.destroy()
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

        let mainWindow = AppStorage.get<window.Window>('window')
        mainWindow?.setWindowKeepScreenOn(false)
    }

    private async createAVSessionAndStartContinuousTask(audioOnly: boolean) {
        let type: AVSessionManager.AVSessionType = audioOnly ? 'voice_call' : 'video_call';
        this.avSession = await AVSessionManager.createAVSession(this.context, 'voip', type);
        console.log('AVSession成功：' + JSON.stringify(this.avSession))
        // 激活接口要在元数据、控制命令注册完成之后再执行
        await this.avSession.activate();
        try {
            startContinuousTask(this.context)
        } catch (e) {
            console.log('startBackgroundRunning', e)
        }

        let window = AppStorage.get<window.Window>('window')
        await window?.setWindowKeepScreenOn(true)
    }
}