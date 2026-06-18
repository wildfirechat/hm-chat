/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import CallEndReason from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callEndReason'
import CallSession from '@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession'
import { window } from '@kit.ArkUI';
import AVSessionManager from '@ohos.multimedia.avsession';
import { startContinuousTask, stopContinuousTask } from './helper/continuousTaskHelper';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import AVEngineCallback from '@wfc/avenginekit/src/main/ets/wfc/av/engine/avengineCallback';
import media from '@ohos.multimedia.media';

import { uikitNavigationDestinations } from './pages/uikitNavigationConfig';
import { common } from '@kit.AbilityKit';
import { checkAndRequestPermission } from './helper/permissionHelper';
import { showToast } from './common/utils/Toast';

// 一定要引入，否则不能弹出对应页面
import ('./pages/voip/SingleAudioCallPage')
import ('./pages/voip/SingleVideoCallPage')
import ('./pages/voip/MultiAudioCallPage')
import ('./pages/voip/MultiVideoCallPage')
export default class AVEngineCallbackImpl extends AVEngineCallback {
    private context: common.UIAbilityContext
    private avSession?: AVSessionManager.AVSession
    private mainNavPathStack?: NavPathStack
    private ringPlayer?: media.AVPlayer
    // 记录本次通话 push 到导航栈的页面名。后台收到来电时页面虽被 push 但不会 mount，
    // 其 aboutToAppear/sessionCallback 不会执行，didCallEndWithReason 也就没机会 pop。
    // 通话结束时由全局回调 didCallEnded 按名字把这个残留页面移除，避免点击通知进入
    // App 后再去渲染已失效的通话页面而 crash。
    private pushedCallPageName?: string

    constructor(context: common.UIAbilityContext, mainNavPathStack: NavPathStack) {
        super(context)
        this.context = context
        this.mainNavPathStack = mainNavPathStack
    }

    /**
     * 收到音视频通话邀请
     * @param {CallSession} session 会话信息
     */
    async onReceiveCall(session: CallSession) {
        let cameraGranted =  await checkAndRequestPermission(this.context, 'ohos.permission.CAMERA')
        let microphoneGranted = await checkAndRequestPermission(this.context, 'ohos.permission.MICROPHONE')
        if (!cameraGranted || !microphoneGranted) {
            showToast('请授予摄像头和麦克风权限')
            return
        }

        this.createAVSessionAndStartContinuousTask(session)
        let name = ''
        if (session.conversation?.type === ConversationType.Single) {
            if (session.audioOnly) {
                name = uikitNavigationDestinations.SingleAudioCallPage
            } else {
                name = uikitNavigationDestinations.SingleVideoCallPage
            }
        } else if (session.conversation?.type === ConversationType.Group) {
            if (session.audioOnly) {
                name = uikitNavigationDestinations.MultiAudioCallPage
            } else {
                name = uikitNavigationDestinations.MultiVideoCallPage
            }
        } else {
            // TODO 会议
        }
        this.pushedCallPageName = name
        this.mainNavPathStack?.pushPathByName(name, {} as Record<string, object>)
        this.shouldStartRing(true)
    }

    /**
     * 发起音视频通话请求
     * @param session 会话信息
     */
    onStartCall = (session: CallSession) => {
        this.createAVSessionAndStartContinuousTask(session)
        let name = ''
        if (session.conversation?.type === ConversationType.Single) {
            if (session.audioOnly) {
                name = uikitNavigationDestinations.SingleAudioCallPage
            } else {
                name = uikitNavigationDestinations.SingleVideoCallPage
            }
        } else if (session.conversation?.type === ConversationType.Group) {
            if (session.audioOnly) {
                name = uikitNavigationDestinations.MultiAudioCallPage
            } else {
                name = uikitNavigationDestinations.MultiVideoCallPage
            }
        } else {
            // TODO 会议
        }
        this.pushedCallPageName = name
        this.mainNavPathStack?.pushPathByName(name, {} as Record<string, object>)
        this.shouldStartRing(false)
    }

    /**
     *  加入会议
     * @param session 会话信息
     */
    onJoinConference(session: CallSession) {
        this.createAVSessionAndStartContinuousTask(session)
        // 不加载页面，仅仅开始 avSession
    }

    async shouldStartRing(isIncoming: boolean) {
        const fileName = isIncoming ? 'incoming_call_ring.mp3' : 'outgoing_call_ring.mp3'
        try {
            const player = await media.createAVPlayer()
            this.ringPlayer = player
            player.on('stateChange', async (state: media.AVPlayerState) => {
                if (state === 'initialized') {
                    await player.prepare()
                } else if (state === 'prepared') {
                    player.loop = true
                    await player.play()
                }
            })
            const rawFd = await this.context.resourceManager.getRawFd(fileName)
            player.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
        } catch (e) {
            console.error('shouldStartRing error', JSON.stringify(e))
        }
    }

    async shouldStopRing() {
        if (this.ringPlayer) {
            try {
                await this.ringPlayer.stop()
                await this.ringPlayer.release()
            } catch (e) {
                console.error('shouldStopRing error', JSON.stringify(e))
            }
            this.ringPlayer = undefined
        }
    }

    // 注意：引擎实际传入的是结束原因（reason）与时长（duration），并非 CallSession，
    // 这里拿不到会话对象，因此用之前记录的 pushedCallPageName 来定位要移除的页面。
    didCallEnded(reason: number, duration?: number) {
        this.avSession?.deactivate()
        this.avSession?.destroy()
        this.avSession = undefined
        stopContinuousTask(this.context)

        let mainWindow = AppStorage.get<window.Window>('window')
        mainWindow?.setWindowKeepScreenOn(false)
        this.shouldStopRing()

        // 移除残留的通话页面（主要覆盖后台场景；前台正常结束时页面已被
        // didCallEndWithReason pop 掉，这里 removeByName 找不到即为 no-op，不会重复 pop）。
        if (this.pushedCallPageName) {
            this.mainNavPathStack?.removeByName(this.pushedCallPageName)
            this.pushedCallPageName = undefined
        }
    }

    private async createAVSessionAndStartContinuousTask(callSession: CallSession) {
        let type: AVSessionManager.AVSessionType = callSession.audioOnly ? 'voice_call' : 'video_call';
        this.avSession = await AVSessionManager.createAVSession(this.context, 'voip', type);
        console.log('AVSession成功：' + JSON.stringify(this.avSession))
        // 激活接口要在元数据、控制命令注册完成之后再执行
        await this.avSession.activate();
        try {
            startContinuousTask(this.context, 'voip')
        } catch (e) {
            console.log('startBackgroundRunning', e)
        }

        let window = AppStorage.get<window.Window>('window')
        await window?.setWindowKeepScreenOn(true)
    }
}
