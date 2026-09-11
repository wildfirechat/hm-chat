/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import url from '@ohos.url'

/**
 * asr-api 鉴权
 *
 * 请求 asr-api 时，需要在 HTTP header authCode 中带上从 IM 服务获取的认证码，asr-api 向 IM 服务校验认证码后得到用户 ID。
 * 认证码 1 分钟内有效，每次请求前重新获取。
 */
export default class AsrAuth {
    static readonly HEADER_AUTH_CODE = 'authCode'

    // 和组织通讯录服务一样，使用管理后台类型（ApplicationType_Admin）的认证码
    private static readonly AUTH_CODE_APP_ID = 'admin'
    private static readonly AUTH_CODE_TYPE = 2

    /**
     * 是否是 asr-api 的地址。asr-api 的接口都在 /api/ 路径下，直连 wf-voice 的地址没有路径
     */
    static isAsrApiUrl(address: string): boolean {
        try {
            return url.URL.parseURL(address).pathname.includes('/api/')
        } catch (e) {
            return false
        }
    }

    static getAuthCode(successCB: (authCode: string) => void, failCB: (errorCode: number) => void) {
        wfc.getAuthCode(AsrAuth.AUTH_CODE_APP_ID, AsrAuth.AUTH_CODE_TYPE, '', successCB, failCB)
    }
}
