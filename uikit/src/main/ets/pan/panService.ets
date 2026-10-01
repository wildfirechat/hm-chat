/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 网盘服务（独立 wf-pan-server）：API 基址 Config.getPanApiBase()（…/api/v1），
 * 每个请求带 header authCode（IM application authCode），响应体 {code,message,data}。
 */

import http from '@ohos.net.http';
import wfc from '@wfc/client';
import Config from '@wfc/client/src/main/ets/config';
import { parseHostAndPort } from '../api/Util';
import {
    PanDocEntry,
    PanDocFormats,
    PanFile,
    PanShare,
    PanSpace,
    PanSpaceType,
    PanVersion,
    panArray,
    panMap,
    panNum,
    panStr
} from './panModels';

export class PanError extends Error {
    code: number;

    constructor(code: number, message: string) {
        super(message);
        this.name = 'PanError';
        this.code = code;
    }
}

export interface PanCreateFileParams {
    spaceId: number;
    name: string;
    size: number;
    storageUrl: string;
    parentId?: number;
    mimeType?: string;
    md5?: string;
    copy?: boolean;
}

export class PanService {
    static baseUrl(): string {
        return Config.getPanApiBase() ?? '';
    }

    private static post<T>(path: string, data: Record<string, Object>): Promise<T> {
        let base = PanService.baseUrl();
        if (!base) {
            return Promise.reject(new PanError(-1, '网盘服务未配置'));
        }
        let fullUrl = base + path;
        return new Promise<T>((resolve, reject) => {
            let pair = parseHostAndPort(base);
            wfc.getAuthCode('admin', 2, pair.host, (authCode: string) => {
                let req = http.createHttp();
                req.request(fullUrl, {
                    method: http.RequestMethod.POST,
                    header: {
                        'Content-Type': 'application/json',
                        'authCode': authCode
                    },
                    extraData: data,
                    expectDataType: http.HttpDataType.OBJECT,
                    usingCache: false,
                    priority: 1,
                    connectTimeout: 60000,
                    readTimeout: 60000,
                    usingProtocol: http.HttpProtocol.HTTP1_1,
                }, (err, resp) => {
                    req.destroy();
                    if (err) {
                        reject(new PanError(-1, err.message));
                        return;
                    }
                    PanService.handleResponse<T>(resp, resolve, reject);
                });
            }, (err: number) => {
                reject(new PanError(-1, '获取认证码失败: ' + err));
            });
        });
    }

    private static get<T>(path: string): Promise<T> {
        let base = PanService.baseUrl();
        if (!base) {
            return Promise.reject(new PanError(-1, '网盘服务未配置'));
        }
        let fullUrl = base + path;
        return new Promise<T>((resolve, reject) => {
            let pair = parseHostAndPort(base);
            wfc.getAuthCode('admin', 2, pair.host, (authCode: string) => {
                let req = http.createHttp();
                req.request(fullUrl, {
                    method: http.RequestMethod.GET,
                    header: {
                        'Content-Type': 'application/json',
                        'authCode': authCode
                    },
                    expectDataType: http.HttpDataType.OBJECT,
                    usingCache: false,
                    priority: 1,
                    connectTimeout: 60000,
                    readTimeout: 60000,
                    usingProtocol: http.HttpProtocol.HTTP1_1,
                }, (err, resp) => {
                    req.destroy();
                    if (err) {
                        reject(new PanError(-1, err.message));
                        return;
                    }
                    PanService.handleResponse<T>(resp, resolve, reject);
                });
            }, (err: number) => {
                reject(new PanError(-1, '获取认证码失败: ' + err));
            });
        });
    }

    private static handleResponse<T>(resp: http.HttpResponse, resolve: (value: T) => void, reject: (reason: PanError) => void): void {
        if (resp.responseCode !== 200) {
            // 鉴权失败时服务端直接返回 {code,message}（无 data 包装）
            let body = resp.result as Record<string, Object>;
            let code = body ? panNum(body['code']) : resp.responseCode;
            let message = body ? panStr(body['message']) : '';
            if (code === 0) {
                code = resp.responseCode;
            }
            if (!message) {
                message = `HTTP Error ${resp.responseCode}`;
            }
            reject(new PanError(code === 0 ? -1 : code, message));
            return;
        }
        let body = resp.result as Record<string, Object>;
        if (!body) {
            reject(new PanError(-1, '返回数据为空'));
            return;
        }
        let code = panNum(body['code']);
        if (code === 0) {
            // 兼容两代响应字段：优先 result，其次 data
            let payload = body['result'] ?? body['data'];
            resolve(payload as T);
        } else {
            reject(new PanError(code, panStr(body['message'])));
        }
    }

    // ---- 空间 ----

    static getSpaces(): Promise<PanSpace[]> {
        return PanService.post<Record<string, Object>[]>('/spaces/list', {} as Record<string, Object>)
            .then((list: Record<string, Object>[]) => {
                return panArray(list).map((item: Record<string, Object>) => PanSpace.fromJson(item));
            });
    }

    /** 网盘首页列出的空间：全局公共空间 + 自己的空间，个人空间排最前 */
    static getVisibleSpaces(): Promise<PanSpace[]> {
        let me = wfc.getUserId();
        return PanService.getSpaces().then((spaces: PanSpace[]) => {
            let visible = spaces.filter((s: PanSpace) => s.spaceType === PanSpaceType.GLOBAL_PUBLIC || s.ownerId === me);
            visible.sort((a: PanSpace, b: PanSpace) => PanService.spaceOrder(a) - PanService.spaceOrder(b));
            return visible;
        });
    }

    private static spaceOrder(space: PanSpace): number {
        if (space.spaceType === PanSpaceType.USER_PRIVATE) {
            return 0;
        }
        if (space.spaceType === PanSpaceType.USER_PUBLIC) {
            return 1;
        }
        return 2;
    }

    static getMySpaces(): Promise<PanSpace[]> {
        return PanService.post<Record<string, Object>[]>('/spaces/my', {} as Record<string, Object>)
            .then((list: Record<string, Object>[]) => {
                return panArray(list).map((item: Record<string, Object>) => PanSpace.fromJson(item));
            });
    }

    static getUserPublicSpace(userId: string): Promise<PanSpace | null> {
        let params: Record<string, Object> = { 'targetUserId': userId };
        return PanService.post<Record<string, Object>>('/spaces/user/public', params)
            .then((result: Record<string, Object>) => {
                if (!result) {
                    return null;
                }
                return PanSpace.fromJson(result);
            });
    }

    static getSpaceFiles(spaceId: number, parentId: number = 0): Promise<PanFile[]> {
        let params: Record<string, Object> = {
            'spaceId': spaceId,
            'parentId': parentId
        };
        return PanService.post<Record<string, Object>[]>('/spaces/files', params)
            .then((list: Record<string, Object>[]) => {
                let files = panArray(list).map((item: Record<string, Object>) => PanFile.fromJson(item));
                // 文件夹在前，其余保持服务端顺序
                let folders = files.filter((f: PanFile) => f.isFolder);
                let rest = files.filter((f: PanFile) => !f.isFolder);
                return folders.concat(rest);
            });
    }

    // ---- 文件 ----

    static createFolder(spaceId: number, name: string, parentId: number = 0): Promise<PanFile> {
        let params = {
            'spaceId': spaceId,
            'name': name,
            'parentId': parentId > 0 ? parentId : null
        } as Record<string, Object>;
        return PanService.post<Record<string, Object>>('/files/folder', params)
            .then((result: Record<string, Object>) => PanFile.fromJson(panMap(result)));
    }

    static createFile(p: PanCreateFileParams): Promise<PanFile> {
        let params = {
            'spaceId': p.spaceId,
            'name': p.name,
            'size': p.size,
            'storageUrl': p.storageUrl,
            'copy': p.copy === true
        } as Record<string, Object>;
        if (p.parentId !== undefined) {
            let pid = p.parentId;
            if (pid > 0) {
                params['parentId'] = pid;
            }
        }
        if (p.mimeType) {
            params['mimeType'] = p.mimeType;
        }
        if (p.md5) {
            params['md5'] = p.md5;
        }
        return PanService.post<Record<string, Object>>('/files', params)
            .then((result: Record<string, Object>) => PanFile.fromJson(panMap(result)));
    }

    /** 把一个存储地址（消息里的文件）保存进「我的网盘」个人空间根目录，重名自动加 (1) */
    static saveFileToMyPan(name: string, size: number, storageUrl: string, mimeType?: string, md5?: string): Promise<PanFile> {
        return PanService.getMySpaces().then((spaces: PanSpace[]) => {
            if (spaces.length === 0) {
                throw new PanError(-1, '没有可用的网盘空间');
            }
            let space = spaces.find((s: PanSpace) => s.spaceType === PanSpaceType.USER_PRIVATE);
            if (!space) {
                space = spaces[0];
            }
            let target = space;
            return PanService.getSpaceFiles(target.spaceId, 0).then((files: PanFile[]) => {
                let unique = PanService.uniqueFileName(files, name);
                let p: PanCreateFileParams = {
                    spaceId: target.spaceId,
                    name: unique,
                    size: size,
                    storageUrl: storageUrl,
                    mimeType: mimeType,
                    md5: md5,
                    copy: true
                };
                return PanService.createFile(p);
            });
        });
    }

    static deleteFile(fileId: number): Promise<void> {
        let params: Record<string, Object> = { 'fileId': fileId };
        return PanService.post<void>('/files/delete', params);
    }

    static renameFile(fileId: number, newName: string): Promise<PanFile> {
        let params: Record<string, Object> = {
            'fileId': fileId,
            'newName': newName
        };
        return PanService.post<Record<string, Object>>('/files/rename', params)
            .then((result: Record<string, Object>) => PanFile.fromJson(panMap(result)));
    }

    static moveFile(fileId: number, targetSpaceId: number, targetParentId: number): Promise<PanFile> {
        let params: Record<string, Object> = {
            'fileId': fileId,
            'targetSpaceId': targetSpaceId,
            'targetParentId': targetParentId
        };
        return PanService.post<Record<string, Object>>('/files/move', params)
            .then((result: Record<string, Object>) => PanFile.fromJson(panMap(result)));
    }

    static copyFile(fileId: number, targetSpaceId: number, targetParentId: number): Promise<PanFile> {
        let params: Record<string, Object> = {
            'fileId': fileId,
            'targetSpaceId': targetSpaceId,
            'targetParentId': targetParentId
        };
        return PanService.post<Record<string, Object>>('/files/copy', params)
            .then((result: Record<string, Object>) => PanFile.fromJson(panMap(result)));
    }

    static getFileDownloadUrl(fileId: number, versionNo: number = 0): Promise<string> {
        let params: Record<string, Object> = { 'fileId': fileId };
        if (versionNo > 0) {
            params['versionNo'] = versionNo;
        }
        return PanService.post<Record<string, Object>>('/files/url', params)
            .then((result: Record<string, Object>) => panStr(panMap(result)['storageUrl']));
    }

    /** 独立服务端：GET /permission/space/{id}/write */
    static checkSpaceWrite(spaceId: number): Promise<boolean> {
        return PanService.get<boolean>(`/permission/space/${spaceId}/write`);
    }

    // ---- 分享 ----

    static getShares(fileId: number): Promise<PanShare[]> {
        let params: Record<string, Object> = { 'fileId': fileId };
        return PanService.post<Record<string, Object>[]>('/shares/list', params)
            .then((list: Record<string, Object>[]) => {
                return panArray(list).map((item: Record<string, Object>) => PanShare.fromJson(item));
            });
    }

    static setShare(fileId: number, isGroup: boolean, targetId: string, canEdit: boolean): Promise<void> {
        let params: Record<string, Object> = {
            'fileId': fileId,
            'targetType': isGroup ? 'GROUP' : 'USER',
            'targetId': targetId,
            'permission': canEdit ? 'EDIT' : 'VIEW'
        };
        return PanService.post<void>('/shares/add', params);
    }

    static removeShare(shareId: number): Promise<void> {
        let params: Record<string, Object> = { 'shareId': shareId };
        return PanService.post<void>('/shares/remove', params);
    }

    static getSharedWithMe(): Promise<PanDocEntry[]> {
        return PanService.post<Record<string, Object>[]>('/shares/with-me', {} as Record<string, Object>)
            .then((list: Record<string, Object>[]) => {
                return panArray(list).map((item: Record<string, Object>) => PanDocEntry.fromShared(item));
            });
    }

    // ---- 在线文档 ----

    static getRecentDocs(): Promise<PanDocEntry[]> {
        return PanService.post<Record<string, Object>[]>('/docs/recent', {} as Record<string, Object>)
            .then((list: Record<string, Object>[]) => {
                return panArray(list).map((item: Record<string, Object>) => PanDocEntry.fromRecent(item));
            });
    }

    static removeRecentDoc(fileId: number): Promise<void> {
        let params: Record<string, Object> = { 'fileId': fileId };
        return PanService.post<void>('/docs/recent/remove', params);
    }

    static createDoc(type: string, name?: string): Promise<PanFile> {
        let params = { 'type': type } as Record<string, Object>;
        if (name) {
            params['name'] = name;
        }
        return PanService.post<Record<string, Object>>('/docs/create', params)
            .then((result: Record<string, Object>) => PanFile.fromJson(panMap(result)));
    }

    static getDocOptions(): Promise<Record<string, Object>> {
        return PanService.post<Record<string, Object>>('/docs/options', {} as Record<string, Object>)
            .then((result: Record<string, Object>) => panMap(result));
    }

    /** 文档编辑配置（H5 也会直接调；此处供宿主需要时使用） */
    static getEditorConfig(fileId: number, platform?: string): Promise<Record<string, Object>> {
        let params: Record<string, Object> = {
            'fileId': fileId,
            'platform': platform ? platform : PanService.platform()
        };
        return PanService.post<Record<string, Object>>('/docs/editor-config', params)
            .then((result: Record<string, Object>) => panMap(result));
    }

    /** 按链接只读预览的配置 */
    static getViewUrl(url: string, name?: string, platform?: string): Promise<Record<string, Object>> {
        let params: Record<string, Object> = {
            'url': url,
            'platform': platform ? platform : PanService.platform()
        };
        if (name) {
            params['name'] = name;
        }
        return PanService.post<Record<string, Object>>('/docs/view-url', params)
            .then((result: Record<string, Object>) => panMap(result));
    }

    /** 把文档转换/另存为可编辑格式 */
    static convertDoc(fileId: number): Promise<PanFile> {
        let params: Record<string, Object> = { 'fileId': fileId };
        return PanService.post<Record<string, Object>>('/docs/convert', params)
            .then((result: Record<string, Object>) => PanFile.fromJson(panMap(result)));
    }

    static isMobileDocEditEnabled(): Promise<boolean> {
        return PanService.getDocOptions().then((options: Record<string, Object>) => options['mobileEdit'] === true);
    }

    static getVersions(fileId: number): Promise<PanVersion[]> {
        let params: Record<string, Object> = { 'fileId': fileId };
        return PanService.post<Record<string, Object>[]>('/versions/list', params)
            .then((list: Record<string, Object>[]) => {
                return panArray(list).map((item: Record<string, Object>) => PanVersion.fromJson(item));
            });
    }

    static restoreVersion(fileId: number, versionNo: number): Promise<void> {
        let params: Record<string, Object> = {
            'fileId': fileId,
            'versionNo': versionNo
        };
        return PanService.post<void>('/versions/restore', params);
    }

    // ---- 工具 ----

    static isOnlineDocName(name: string): boolean {
        return PanDocFormats.isOnlineDocName(name);
    }

    /** 在线文档页面根地址（以 / 结尾），未配置时返回 '' */
    static docBase(): string {
        return Config.getPanDocBase() ?? '';
    }

    static platform(): string {
        return 'mobile';
    }

    static docOpenUrl(fileId: number, platform?: string): string {
        let p = platform ? platform : PanService.platform();
        return `${PanService.docBase()}open?fileId=${fileId}&platform=${p}`;
    }

    /** 按链接只读打开（聊天里的文件消息 / 外部地址），服务端代理取内容 */
    static docViewUrl(url: string, name?: string, platform?: string): string {
        let p = platform ? platform : PanService.platform();
        let result = `${PanService.docBase()}open?url=${encodeURIComponent(url)}&platform=${p}`;
        if (name) {
            result += `&name=${encodeURIComponent(name)}`;
        }
        return result;
    }

    static docLicensesUrl(): string {
        return `${PanService.docBase()}licenses.html`;
    }

    /** 是不是在线文档页面地址，主/备网前缀都认 */
    static isDocUrl(url: string): boolean {
        if (!url) {
            return false;
        }
        let roots: (string | null)[] = [Config.PAN_SERVER_ADDRESS, Config.PAN_SERVER_BACKUP_ADDRESS];
        for (let root of roots) {
            if (!root) {
                continue;
            }
            let b = root.endsWith('/') ? root.substring(0, root.length - 1) : root;
            if (url.startsWith(b + '/doc/')) {
                return true;
            }
        }
        return false;
    }

    /** 生成不冲突的文件名：base(1).ext */
    static uniqueFileName(existing: PanFile[], name: string): string {
        let names = existing.map((f: PanFile) => f.name);
        if (!names.includes(name)) {
            return name;
        }
        let dot = name.lastIndexOf('.');
        let base = dot > 0 ? name.substring(0, dot) : name;
        let ext = dot > 0 ? name.substring(dot) : '';
        let i = 1;
        while (names.includes(`${base}(${i})${ext}`)) {
            i++;
        }
        return `${base}(${i})${ext}`;
    }

    static formatSize(bytes: number): string {
        if (!(bytes >= 0)) {
            return '';
        }
        if (bytes < 1024) {
            return `${bytes} B`;
        }
        if (bytes < 1024 * 1024) {
            return `${(bytes / 1024).toFixed(1)} KB`;
        }
        if (bytes < 1024 * 1024 * 1024) {
            return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
        }
        return `${(bytes / 1024 / 1024 / 1024).toFixed(1)} GB`;
    }
}

export default PanService;
