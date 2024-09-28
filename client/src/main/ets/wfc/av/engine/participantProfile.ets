/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import CallState  from './callState';

export default class ParticipantProfile {
    userId = '';
    callExtra = '';
    status = CallState.STATUS_IDLE;
    joinTime = 0;
    acceptTime = 0;
    audioMuted = false;
    videoMuted = false;
    audience = false;
}
