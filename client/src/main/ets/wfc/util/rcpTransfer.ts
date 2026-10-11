/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

/**
 * 用 RCP 上传下载文件，用于自签名证书的场景：系统上传下载服务不认应用内置的证书。
 *
 * RCP（Remote Communication Kit）是 HarmonyOS 独有的，开源鸿蒙没有。
 * 这里用变量动态 import 加载，编译时不依赖 RCP 的声明，用开源鸿蒙 SDK 也能编译；调用前要先用 canIUse 判断设备是否支持，
 * 见 {@link RCP_SYSCAP}。用 .ts 文件是为了直接使用动态 import 返回的、没有类型声明的模块对象。
 */
const RCP_MODULE_NAME: string = '@hms.collaboration.rcp'

/**
 * RCP 的系统能力，canIUse(RCP_SYSCAP) 为 true 时才能调用这里的方法
 */
export const RCP_SYSCAP = 'SystemCapability.Collaboration.RemoteCommunication'

let rcpModule: Promise<any> | undefined
// 下载共用的 session：同时打开的 session 数量有限制，头像等小文件很多，复用连接也更快
let downloadSession: any
let downloadSessionCaPath = ''

function loadRcp(): Promise<any> {
    if (!rcpModule) {
        rcpModule = import(RCP_MODULE_NAME).then((ns: any) => ns.default)
        rcpModule.catch(() => {
            // 加载失败时下次再试
            rcpModule = undefined
        })
    }
    return rcpModule
}

// 只信任 caPath 中的证书
function configuration(caPath: string, httpEventsHandler?: object): object {
    const config: any = {
        transfer: {
            // 大文件耗时长，放宽总时长，靠 inactivityMs 发现卡住的连接
            timeout: { transferMs: 24 * 60 * 60 * 1000, inactivityMs: 60 * 1000 }
        },
        security: {
            remoteValidation: { filePath: caPath }
        }
    }
    if (httpEventsHandler) {
        config.tracing = { httpEventsHandler: httpEventsHandler }
    }
    return config
}

/**
 * 以 PUT 方式上传文件
 *
 * @param caPath PEM 格式的 CA 证书文件，只信任其中的证书
 * @param onCancelable 开始上传时回调，参数用来取消上传
 * @returns HTTP 状态码
 */
export async function uploadFileWithRcp(url: string, filePath: string, contentType: string, caPath: string,
    progressCB: (uploaded: number, total: number) => void,
    onCancelable: (cancel: () => void) => void): Promise<number> {
    const rcp = await loadRcp()
    const session = rcp.createSession({
        requestConfiguration: configuration(caPath, {
            onUploadProgress: (totalSize: number, transferredSize: number) => {
                progressCB(transferredSize, totalSize)
            }
        })
    })
    try {
        const req = new rcp.Request(url, 'PUT', { 'content-type': contentType }, new rcp.UploadFromFile(filePath))
        onCancelable(() => {
            session.cancel(req)
        })
        const response = await session.fetch(req)
        return response.statusCode
    } finally {
        session.close()
    }
}

/**
 * 下载文件到 filePath，失败时 filePath 中可能是不完整的内容，由调用方处理
 *
 * @param caPath PEM 格式的 CA 证书文件，只信任其中的证书
 * @returns HTTP 状态码
 */
export async function downloadFileWithRcp(url: string, filePath: string, caPath: string,
    progressCB?: (receivedSize: number, totalSize: number) => void): Promise<number> {
    const rcp = await loadRcp()
    if (!downloadSession || downloadSessionCaPath !== caPath) {
        downloadSession?.close()
        downloadSession = rcp.createSession({ requestConfiguration: configuration(caPath) })
        downloadSessionCaPath = caPath
    }
    const req = new rcp.Request(url, 'GET')
    req.configuration = configuration(caPath, progressCB ? {
        onDownloadProgress: (totalSize: number, transferredSize: number) => {
            progressCB(transferredSize, totalSize)
        }
    } : undefined)
    req.destination = { kind: 'file', file: filePath }
    const response = await downloadSession.fetch(req)
    return response.statusCode
}
