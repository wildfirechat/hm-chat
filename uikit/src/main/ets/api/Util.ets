import { url } from "@kit.ArkTS"

export interface HostPortPair {
    host: string,
    port: string
}


export const parseHostAndPort = (urlStr: string): HostPortPair => {
    let _url = url.URL.parseURL(urlStr)
    let host = _url.host
    host = host.indexOf(':') > 0 ? host.substring(0, host.indexOf(':')) : host
    let port = _url.port
    if (!port) {
        port = urlStr.startsWith('https://') ? '443' : '80'
    }

    return {
        host,
        port
    }
}
//https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-basic-components-image-V5#colorfilter9
export const WHITE_FILTER = [
    0, 0, 0, 0, 157,
    0, 0, 0, 0, 171,
    0, 0, 0, 0, 192,
    0, 0, 0, 1, 0
]
