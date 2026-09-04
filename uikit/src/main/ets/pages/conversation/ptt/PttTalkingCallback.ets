import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import { TalkingCallback } from '@wfc/ptt'

/**
 * 把对讲 SDK 的 {@link TalkingCallback} 转成几个可赋值的回调，方便在 struct 里用箭头函数接。
 */
export default class PttTalkingCallback extends TalkingCallback {
    onStart?: (conversation: Conversation) => void
    onEnd?: (conversation: Conversation, reason: number) => void
    onFail?: (conversation: Conversation, errorCode: number) => void
    onAmplitude?: (conversation: Conversation, averageAmplitude: number) => void

    onStartTalking(conversation: Conversation) {
        this.onStart?.(conversation)
    }

    onTalkingEnd(conversation: Conversation, reason: number) {
        this.onEnd?.(conversation, reason)
    }

    onRequestFail(conversation: Conversation, errorCode: number) {
        this.onFail?.(conversation, errorCode)
    }

    onAmplitudeUpdate(conversation: Conversation, averageAmplitude: number) {
        this.onAmplitude?.(conversation, averageAmplitude)
    }
}
