/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import RTCIceCandidate from '../webrtc/RTCIceCandidate';
import RTCPeerConnection from '../webrtc/RTCPeerConnection';
import CallState from './callState';

export default class Subscriber {
    isInitiator = false;
    userId = '';
    status = CallState.STATUS_IDLE;
    joinTime = 0;
    acceptTime = 0;
    videoMuted = false;
    audioMuted = false;
    audience = false;
    hasReceivedSdp = false;
    peerConnection?: RTCPeerConnection;
    quequedCandidates?: RTCIceCandidate[];

    constructor(userId: string) {
        this.userId = userId;
    }
}
