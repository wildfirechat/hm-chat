/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import Message from '../../messages/message';
import Conversation from '../../model/conversation';
import AVEngineCallback from './avengineCallback';
import CallSessionCallback from './callSessionCallback';

export default class WfcAVEngineKit {
    sessionCallback?: CallSessionCallback;

    /**
     * 音视频window显示的时候调用
     */
    setup(context: Context, callback: AVEngineCallback) {
    }

    getCurrentSession() {

    }

    static MAX_AUDIO_PARTICIPANT_COUNT = 16;
    static MAX_VIDEO_PARTICIPANT_COUNT = 9;
}
