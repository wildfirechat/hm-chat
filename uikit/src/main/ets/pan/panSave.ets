/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 「存到网盘」与本地文件打开/下载的公共逻辑。
 */

import Config from '@wfc/client/src/main/ets/config';
import { filePreview } from '@kit.PreviewKit';
import { fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { showToast } from '../common/utils/Toast';
import { downloadUrlToCache } from '../helper/mediaHelper';
import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig';
import PanService from './panService';
import { PanFile } from './panModels';

export interface PanSaveOptions {
    name: string;
    size: number;
    storageUrl: string;
    mimeType?: string;
    openAfter?: boolean;
}

/** 用系统预览器打开沙箱里的文件；不支持预览时静默返回 */
export async function openLocalFile(context: Context, filePath: string, title: string): Promise<void> {
    try {
        let uri = fileUri.getUriFromPath(filePath);
        let canPreview = await filePreview.canPreview(context, uri);
        if (!canPreview) {
            showToast('已下载，暂不支持预览');
            return;
        }
        let ext = filePath.substring(filePath.lastIndexOf('.'));
        let typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(ext);
        let typeObj = uniformTypeDescriptor.getTypeDescriptor(typeId);
        let mimeTypes = typeObj.mimeTypes;
        filePreview.openPreview(context, {
            title: title,
            uri: uri,
            mimeType: mimeTypes[0],
        });
    } catch (e) {
        showToast('无法打开文件');
    }
}

/** 下载网盘文件并交给系统预览 */
export function downloadPanFile(context: Context, fileId: number, name: string): void {
    showToast('开始下载');
    PanService.getFileDownloadUrl(fileId)
        .then((url: string) => {
            if (!url) {
                showToast('无法获取下载地址');
                return;
            }
            return downloadUrlToCache(context, url, name).then((path: string) => {
                openLocalFile(context, path, name);
            });
        })
        .catch((e: Error) => {
            showToast('下载失败：' + (e.message || ''));
        });
}

/** 在线文档格式优先用内置文档页打开，否则下载预览 */
export function openPanFile(context: Context, navStack: NavPathStack, file: PanFile): void {
    if (file.canOpenOnline()) {
        navStack.pushPathByName(uikitNavigationDestinations.PanDocWebPage, {
            'fileId': file.fileId,
            'name': file.name
        } as Record<string, Object>);
    } else {
        downloadPanFile(context, file.fileId, file.name);
    }
}

/**
 * 把一个存储地址（聊天里的文件消息）保存到「我的网盘」个人空间根目录。
 * copy=true 由服务端把物理文件拷进网盘 bucket。
 */
export function saveFileMessageToMyPan(context: Context, navStack: NavPathStack, options: PanSaveOptions): void {
    let storageUrl = options.storageUrl ? Config.urlRedirect(options.storageUrl) : '';
    if (!storageUrl) {
        showToast('文件地址为空');
        return;
    }
    showToast('正在保存到我的网盘…');
    PanService.saveFileToMyPan(options.name, options.size, storageUrl, options.mimeType)
        .then((file: PanFile) => {
            showToast('已保存到我的网盘');
            if (options.openAfter) {
                if (file.canOpenOnline()) {
                    navStack.pushPathByName(uikitNavigationDestinations.PanDocWebPage, {
                        'fileId': file.fileId,
                        'name': file.name
                    } as Record<string, Object>);
                } else {
                    downloadPanFile(context, file.fileId, file.name);
                }
            }
        })
        .catch((e: Error) => {
            showToast('保存到我的网盘失败：' + (e.message || ''));
        });
}
