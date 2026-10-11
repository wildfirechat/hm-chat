/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { cert } from '@kit.DeviceCertificateKit';
import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';

const TAG = 'SelfSignedCertUtils'
// 系统预置的 CA 证书
const SYSTEM_CA_FILE = '/etc/ssl/certs/cacert.pem'
// 系统预置 CA 证书和自签名证书合并后的文件，保存在 filesDir
const TRUSTED_CA_FILE_NAME = 'wfc_trusted_ca.pem'
const CERT_FILE_EXTENSIONS = ['.crt', '.pem', '.cer']
const PEM_BEGIN = '-----BEGIN CERTIFICATE-----'
const PEM_END = '-----END CERTIFICATE-----'

/**
 * 自签名证书工具类，让上层网络请求信任自签名证书。
 *
 * 证书统一放在 chat/src/main/resources/resfile 目录（运行时就是 context.resourceDir），协议栈通过 wfc.UseTls 使用，
 * 上层网络请求通过这里使用，共用同一份证书。上层分几种接入方式：
 * 1. Network Kit 的 http、webSocket：请求参数带上 caPath: selfSignedCertUtils.getCaPath()。应用服务、组织通讯录、
 *    投票、接龙、归档、语音识别等都已经接入，新增请求时也要记得带上。
 * 2. 系统上传下载服务（request.uploadFile、request.downloadFile）不认应用内置的证书，有自签名证书时改用 RCP，
 *    security.remoteValidation 设置为 { filePath: selfSignedCertUtils.getCaPath() }。下载直接用 {@link download}，
 *    见 mediaHelper 的 downloadMedia；上传见 proto.min.ets 的 _uploadFileWithRcp。
 * 3. Web 组件：在 onSslErrorEventReceive 里调用 {@link isTrustedBySelfSignedCerts}，见 WfcWebView。
 * 4. Image、Video 组件自己加载网络资源时不认应用内置的证书，network_config.json 的 trust-anchors 对它们也不生效（实测），
 *    要先用 {@link download} 下载到本地再显示，见 uikit 的 trustedMediaSrc。
 *
 * getCaPath 返回的文件里同时有系统预置 CA 证书和自签名证书，所以公网 CA 签发的证书不受影响。
 * 和 Android 不同，这里不会跳过域名校验（Web 组件除外），签发证书时要把服务的域名和 IP 都写进 subjectAltName。
 * 没有证书时不做任何修改，全部使用系统默认配置。
 */
export class SelfSignedCertUtils {
    // 自签名证书，PEM 格式，每项一个证书
    private certPems: string[] = []
    private caPath: string = ''
    // certPems 解析后的证书，Web 组件校验证书时才用到，用到时再解析
    private x509Certs?: cert.X509Cert[]
    // download 共用的 RCP session，同时打开的 session 数量有限制，不能每次下载都创建
    private downloadSession?: rcp.Session

    /**
     * 加载证书目录下的自签名证书，需要在发起网络请求之前调用
     *
     * @param context 用来获取 filesDir，合并后的证书文件保存在这里
     * @param certDir 证书目录，目录下的 .crt、.pem、.cer 文件（PEM 格式）都会加载，一般传 context.resourceDir
     */
    init(context: common.Context, certDir: string) {
        this.certPems = []
        this.caPath = ''
        this.x509Certs = undefined
        this.downloadSession?.close()
        this.downloadSession = undefined
        try {
            if (!fs.accessSync(certDir)) {
                return
            }
            fs.listFileSync(certDir).forEach((name: string) => {
                let lowerName = name.toLowerCase()
                if (CERT_FILE_EXTENSIONS.some((ext: string) => lowerName.endsWith(ext))) {
                    this.certPems.push(...splitPemCerts(fs.readTextSync(certDir + '/' + name)))
                }
            })
        } catch (e) {
            console.error(TAG, 'load self-signed certs failed', certDir, e)
        }
        if (this.certPems.length === 0) {
            return
        }

        // http 的 caPath 会同时使用系统预置的 CA 证书，但 webSocket 的 caPath、RCP 的 remoteValidation 只信任传入的证书，
        // 所以把系统预置的 CA 证书也合并进来，三者共用一个文件
        let systemCa = ''
        try {
            systemCa = fs.readTextSync(SYSTEM_CA_FILE)
        } catch (e) {
            console.error(TAG, 'read system ca failed, only self-signed certs are trusted by webSocket and RCP', e)
        }
        let caPath = context.filesDir + '/' + TRUSTED_CA_FILE_NAME
        try {
            let file = fs.openSync(caPath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)
            try {
                fs.writeSync(file.fd, systemCa + '\n' + this.certPems.join('\n') + '\n')
            } finally {
                fs.closeSync(file)
            }
            this.caPath = caPath
            console.log(TAG, 'self-signed certs loaded', this.certPems.length, certDir)
        } catch (e) {
            console.error(TAG, 'write trusted ca file failed', e)
        }
    }

    /**
     * 是否有自签名证书
     */
    hasCerts(): boolean {
        return this.caPath.length > 0
    }

    /**
     * 系统预置 CA 证书和自签名证书合并后的文件路径（PEM 格式），用于 http、webSocket 的 caPath 和 RCP 的 remoteValidation。
     * 没有自签名证书时返回 undefined，即使用系统默认配置
     */
    getCaPath(): string | undefined {
        return this.caPath ? this.caPath : undefined
    }

    /**
     * 给 Web 组件的 onSslErrorEventReceive 用：出错的证书是自签名证书本身，或者由自签名证书直接签发、且在有效期内时，返回 true，
     * 这时可以 handler.handleConfirm()，否则应该 handler.handleCancel()。和 Android 一样，不校验域名。
     *
     * @param certChainData onSslErrorEventReceive 回调里的证书链（DER 格式），API 15 才开始提供，没有时返回 false
     */
    async isTrustedBySelfSignedCerts(certChainData?: Array<Uint8Array>): Promise<boolean> {
        if (!this.hasCerts() || !certChainData || certChainData.length === 0) {
            return false
        }
        try {
            let serverCert = await cert.createX509Cert({
                data: certChainData[0],
                encodingFormat: cert.EncodingFormat.FORMAT_DER
            })
            serverCert.checkValidityWithDate(currentGeneralizedTime())
            let trustedCerts = await this.getX509Certs()
            for (let trustedCert of trustedCerts) {
                try {
                    await serverCert.verify(trustedCert.getPublicKey())
                    return true
                } catch (e) {
                    // 不是这个证书签发的，继续检查下一个
                }
            }
        } catch (e) {
            console.error(TAG, 'check server cert failed', e)
        }
        return false
    }

    /**
     * 用 RCP 下载文件，信任系统预置的 CA 证书和自签名证书，没有自签名证书时直接失败。
     * 系统下载服务（request.downloadFile）、Image、Video 组件都不认应用内置的证书，有自签名证书时用这个代替。
     * 先下载到临时文件，成功后再改名，下载失败或者中途退出都不会留下不完整的文件。
     *
     * @returns 下载成功时返回 filePath
     */
    download(url: string, filePath: string, progressCB?: (receivedSize: number, totalSize: number) => void): Promise<string> {
        if (!this.caPath) {
            return Promise.reject(new Error('no self-signed certs'))
        }
        let session: rcp.Session
        try {
            if (!this.downloadSession) {
                this.downloadSession = rcp.createSession({ requestConfiguration: this.downloadConfiguration() })
            }
            session = this.downloadSession
        } catch (e) {
            console.error(TAG, 'create rcp session failed', e)
            return Promise.reject(e as Error)
        }
        // 每次下载用不同的临时文件，同一个文件同时下载多次时互不影响
        let tmpPath = filePath + '.' + util.generateRandomUUID(false) + '.download'
        let req = new rcp.Request(url, 'GET')
        req.configuration = this.downloadConfiguration(progressCB)
        req.destination = { kind: 'file', file: tmpPath }
        return session.fetch(req).then((response: rcp.Response) => {
            if (response.statusCode < 200 || response.statusCode >= 300) {
                throw new Error('download failed, statusCode: ' + response.statusCode)
            }
            fs.renameSync(tmpPath, filePath)
            return filePath
        }).catch((e: Error) => {
            removeFile(tmpPath)
            throw e
        })
    }

    private downloadConfiguration(progressCB?: (receivedSize: number, totalSize: number) => void): rcp.Configuration {
        let configuration: rcp.Configuration = {
            transfer: {
                // 大文件下载耗时长，放宽总时长，靠 inactivityMs 发现卡住的连接
                timeout: { transferMs: 24 * 60 * 60 * 1000, inactivityMs: 60 * 1000 }
            },
            security: {
                remoteValidation: { filePath: this.caPath }
            }
        }
        if (progressCB) {
            configuration.tracing = {
                httpEventsHandler: {
                    onDownloadProgress: (totalSize: number, transferredSize: number) => {
                        progressCB(transferredSize, totalSize)
                    }
                }
            }
        }
        return configuration
    }

    private async getX509Certs(): Promise<cert.X509Cert[]> {
        if (!this.x509Certs) {
            let encoder = new util.TextEncoder()
            let x509Certs: cert.X509Cert[] = []
            for (let pem of this.certPems) {
                try {
                    x509Certs.push(await cert.createX509Cert({
                        data: encoder.encodeInto(pem),
                        encodingFormat: cert.EncodingFormat.FORMAT_PEM
                    }))
                } catch (e) {
                    console.error(TAG, 'parse self-signed cert failed', e)
                }
            }
            this.x509Certs = x509Certs
        }
        return this.x509Certs
    }
}

function removeFile(path: string) {
    try {
        fs.unlinkSync(path)
    } catch (e) {
        // 文件不存在
    }
}

// 一个文件里可能有多个证书，拆成每项一个证书
function splitPemCerts(content: string): string[] {
    let pems: string[] = []
    let begin = content.indexOf(PEM_BEGIN)
    while (begin >= 0) {
        let end = content.indexOf(PEM_END, begin)
        if (end < 0) {
            break
        }
        end += PEM_END.length
        pems.push(content.substring(begin, end))
        begin = content.indexOf(PEM_BEGIN, end)
    }
    return pems
}

// ASN.1 GeneralizedTime 格式的当前 UTC 时间，如 20261011083000Z
function currentGeneralizedTime(): string {
    let now = new Date()
    let pad = (n: number): string => n < 10 ? '0' + n : '' + n
    return '' + now.getUTCFullYear() + pad(now.getUTCMonth() + 1) + pad(now.getUTCDate()) +
        pad(now.getUTCHours()) + pad(now.getUTCMinutes()) + pad(now.getUTCSeconds()) + 'Z'
}

const selfSignedCertUtils = new SelfSignedCertUtils()

export default selfSignedCertUtils
