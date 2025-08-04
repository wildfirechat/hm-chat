import CallSession from "@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession";
import ParticipantProfile from "@wfc/avenginekit/src/main/ets/wfc/av/engine/participantProfile";

export function participantXComponentUserId(callSession: CallSession, p: ParticipantProfile) {
    return p.screenSharing ? 'screen_sharing_' + p.userId : p.userId
}

export function participantXComponentId(callSession: CallSession, p: ParticipantProfile) {
    let _userId = p.screenSharing ? 'screen_sharing_' + p.userId : p.userId
    let _componentId = `${_userId}-${callSession?.callId}`
    return _componentId;
}
