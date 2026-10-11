/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import { common } from '@kit.AbilityKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { util } from '@kit.ArkTS'
import selfSignedCertUtils from '@wfc/client/src/main/ets/wfc/util/selfSignedCertUtils'

const TAG = 'trustedMedia'
// 缓存目录，在 cacheDir 下
const CACHE_DIR_NAME = 'trusted_media'
// 下载失败后，这段时间内不再重试
const RETRY_INTERVAL_MS = 30 * 1000
// 合并这段时间内下载完成的通知，避免连续刷新界面
const NOTIFY_DELAY_MS = 100

// 下载完成后 version 加一。@Trace 属性在 @Component 中读取时也会被观察，所以组件不需要额外的状态变量：
// trustedMediaSrc 在下载完成之前读一下 version，组件就会在下载完成后刷新
@ObservedV2
class TrustedMediaState {
    @Trace version: number = 0
}

const state = new TrustedMediaState()
// url -> 本地文件地址
const cachedSrcs: Map<string, string> = new Map()
const downloadingUrls: Set<string> = new Set()
// url -> 下载失败的时间
const failedTimes: Map<string, number> = new Map()
let notifyTimer: number = -1

/**
 * Image、Video 组件自己加载网络资源时不认应用内置的自签名证书，network_config.json 的 trust-anchors 对它们也不生效。
 * 有自签名证书时，先用 RCP 下载到缓存目录，再把本地文件交给组件显示：`Image(trustedMediaSrc(url))`。
 *
 * 没有自签名证书、不是 https 地址、或者设备不支持（开源鸿蒙）时原样返回，url 为空时返回空字符串。下载完成之前返回空字符串，Image 显示 alt 设置的占位图，
 * 需要占位图时也可以写成 `trustedMediaSrc(url) || $r('app.media.xxx')`；下载完成后组件自动刷新，换成本地文件。
 * 下载失败时返回原地址，交给组件自己加载。
 */
export function trustedMediaSrc(url: string | undefined | null): string {
    if (!url) {
        return ''
    }
    if (!url.startsWith('https://') || !selfSignedCertUtils.canDownload()) {
        return url
    }
    let src = cachedSrcs.get(url)
    if (src) {
        return src
    }
    // 下载失败过：先用原地址，交给组件自己加载，过一段时间再在后台重试，避免重试时又变成空白
    let failedTime = failedTimes.get(url)
    let failedBefore = failedTime !== undefined
    if (failedTime !== undefined && Date.now() - failedTime < RETRY_INTERVAL_MS) {
        return url
    }
    let context = AppStorage.get<common.UIAbilityContext>('context')
    if (!context) {
        return url
    }
    let dir = context.cacheDir + '/' + CACHE_DIR_NAME
    let filePath: string
    try {
        filePath = dir + '/' + sha256(url)
        if (fs.accessSync(filePath)) {
            src = 'file://' + filePath
            cachedSrcs.set(url, src)
            return src
        }
    } catch (e) {
        // 在 build 里调用，不能抛异常
        console.error(TAG, 'check cache file failed', e)
        return url
    }
    download(url, dir, filePath)
    // 读一下 version，让调用方组件在下载完成后刷新
    let version = state.version
    return failedBefore ? url : ''
}

function download(url: string, dir: string, filePath: string) {
    if (downloadingUrls.has(url)) {
        return
    }
    downloadingUrls.add(url)
    try {
        if (!fs.accessSync(dir)) {
            fs.mkdirSync(dir)
        }
    } catch (e) {
        console.error(TAG, 'create cache dir failed', e)
    }
    selfSignedCertUtils.download(url, filePath)
        .then(() => {
            cachedSrcs.set(url, 'file://' + filePath)
            failedTimes.delete(url)
            notifyChanged()
        })
        .catch((e: Error) => {
            console.error(TAG, 'download failed', url, e?.message)
            failedTimes.set(url, Date.now())
            // 刷新界面，改用原地址
            notifyChanged()
        })
        .finally(() => {
            downloadingUrls.delete(url)
        })
}

function notifyChanged() {
    if (notifyTimer !== -1) {
        return
    }
    notifyTimer = setTimeout(() => {
        notifyTimer = -1
        state.version++
    }, NOTIFY_DELAY_MS)
}

function sha256(text: string): string {
    let md = cryptoFramework.createMd('SHA256')
    md.updateSync({ data: new util.TextEncoder().encodeInto(text) })
    let hex = ''
    md.digestSync().data.forEach((b: number) => {
        hex += (b < 16 ? '0' : '') + b.toString(16)
    })
    return hex
}
