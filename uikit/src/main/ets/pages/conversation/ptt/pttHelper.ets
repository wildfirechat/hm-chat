import { PttEndReason, PttErrorCode } from '@wfc/ptt'

/** 请求说话失败的提示文案 */
export function pttErrorText(errorCode: number): string {
    switch (errorCode) {
        case PttErrorCode.OCCUPIED:
            return '有人正在讲话，请稍后再试'
        case PttErrorCode.MAX_SPEAKER:
            return '同时讲话人数已达上限'
        case PttErrorCode.GROUP_MUTED:
            return '群组已全员禁言'
        case PttErrorCode.GROUP_MEMBER_MUTED:
            return '你已被禁言'
        case PttErrorCode.TALKING:
            return '正在讲话中'
        case PttErrorCode.NOT_IN_GROUP:
            return '你不在该群组中'
        case PttErrorCode.PTT_DISABLED:
            return '该会话未开启对讲'
        case PttErrorCode.RECORDER_ERROR:
            return '麦克风不可用，请检查权限'
        default:
            return `请求对讲失败 ${errorCode}`
    }
}

/**
 * 说话被动结束的提示文案。主动松手和超时是正常结束，不需要提示，返回空字符串。
 */
export function pttEndReasonText(reason: number): string {
    switch (reason) {
        case PttEndReason.Take_Over:
            return '对讲已被他人抢占'
        case PttEndReason.Network_Error:
            return '网络异常，对讲已结束'
        case PttEndReason.Channel_Muted:
            return '群组已全员禁言，对讲已结束'
        case PttEndReason.Member_Muted:
            return '你已被禁言，对讲已结束'
        case PttEndReason.Media_Error:
            return '录音异常，对讲已结束'
        case PttEndReason.Not_InChannel:
            return '你已不在该群组中，对讲已结束'
        case PttEndReason.User_Disabled:
            return '账号已被禁用，对讲已结束'
        default:
            return ''
    }
}
