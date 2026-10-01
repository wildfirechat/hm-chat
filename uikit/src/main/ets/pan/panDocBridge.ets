/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 在线文档 H5 的 DSBridge 协议实现（独立于工作台的 dsBridge，避免影响既有行为）。
 * 协议要点：
 *  - 同步方法直接返回 JSON 字符串；
 *  - 异步方法通过 _dscbstub 指定的全局回调返回 {code,data}；
 *  - setPageHeader 是常驻回调，参数是裸的按钮 id，且不能 delete window[cb]；
 *  - chooseContacts/chooseGroup 的 data 必须是 JSON 字符串。
 */

import wfc from '@wfc/client';
import common from '@ohos.app.ability.common';
import web_webview from '@ohos.web.webview';
import url from '@ohos.url';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo';
import { showToast } from '../common/utils/Toast';
import { downloadUrlToCache } from '../helper/mediaHelper';
import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig';
import PickMultiContactModal from '../pages/picker/PickMultiContactModal';
import PickMultiGroupModal from '../pages/picker/PickMultiGroupModal';
import { openLocalFile } from './panSave';
import PanService from './panService';
import { PanPageHeader, panMap, panStr } from './panModels';

const SUPPORTED_METHODS: string[] = [
    'getAuthCode', 'setPageHeader', 'downloadFile', 'openUrl',
    'chooseContacts', 'chooseGroup', 'toast', 'close', 'config'
];

export default class PanDocBridge {
    private docUrl: string;
    private controller: web_webview.WebviewController;
    private stack: NavPathStack;
    private onHeader?: (h: PanPageHeader) => void;
    private onHeaderAction?: (id: string) => void;
    private headerCb: string = '';
    private pendingContactCb: string = '';
    private pendingGroupCb: string = '';
    private pickingContact: boolean = false;
    private pickingGroup: boolean = false;

    constructor(docUrl: string, controller: web_webview.WebviewController, stack: NavPathStack,
                onHeader?: (h: PanPageHeader) => void, onHeaderAction?: (id: string) => void) {
        this.docUrl = docUrl;
        this.controller = controller;
        this.stack = stack;
        this.onHeader = onHeader;
        this.onHeaderAction = onHeaderAction;
    }

    private callbackJs(cb: string, code: number, data?: Object | string, complete: boolean = true): void {
        if (!cb) {
            return;
        }
        let ret: Record<string, Object> = {
            'code': code,
            'data': data !== undefined ? data : ''
        };
        let script = `${cb}(${JSON.stringify(ret)});`;
        if (complete) {
            script += `delete window.${cb}`;
        }
        this.controller.runJavaScript(script);
    }

    private callbackRaw(cb: string, arg: string): void {
        if (!cb) {
            return;
        }
        this.controller.runJavaScript(`${cb}(${JSON.stringify(arg)})`);
    }

    private callJs(method: string, args?: Object[]): void {
        let obj: Record<string, Object> = {
            'method': method,
            'data': args ? args : []
        };
        this.controller.runJavaScript(`window._handleMessageFromNative(${JSON.stringify(obj)})`);
    }

    call = (method: string, arg: string): string => {
        let args: Record<string, Object> = {} as Record<string, Object>;
        if (arg) {
            try {
                args = JSON.parse(arg) as Record<string, Object>;
            } catch (e) {
                args = {} as Record<string, Object>;
            }
        }
        let data = args['data'];
        let cb = panStr(args['_dscbstub']);
        switch (method) {
            case '_dsb.hasNativeMethod': {
                let req = panMap(data);
                let name = panStr(req['name']);
                let supported = SUPPORTED_METHODS.includes(name);
                return `{"code":0,"data":${supported ? 'true' : 'false'}}`;
            }
            case 'toast': {
                let msg = typeof data === 'string' ? data as string : panStr(panMap(data)['message']);
                showToast(msg);
                return '{}';
            }
            case 'getAuthCode': {
                let req = panMap(data);
                let appId = panStr(req['appId']) || 'admin';
                let appType = req['appType'] !== undefined ? req['appType'] as number : 2;
                let host = url.URL.parseURL(this.docUrl).hostname;
                wfc.getAuthCode(appId, appType, host, (authCode: string) => {
                    this.callbackJs(cb, 0, authCode);
                }, (err: number) => {
                    this.callbackJs(cb, err);
                });
                return '{"code":-1}';
            }
            case 'setPageHeader': {
                this.headerCb = cb;
                let header = PanPageHeader.fromJson(panMap(data));
                this.onHeader?.(header);
                return '{}';
            }
            case 'downloadFile': {
                this.doDownload(data);
                return '{}';
            }
            case 'openUrl': {
                this.doOpenUrl(data);
                return '{}';
            }
            case 'chooseContacts': {
                this.pendingContactCb = cb;
                this.pickingContact = true;
                this.stack.pushPathByName(uikitNavigationDestinations.PickMultiContactPage, {} as Record<string, Object>);
                return '{"code":-1}';
            }
            case 'chooseGroup': {
                this.pendingGroupCb = cb;
                this.pickingGroup = true;
                this.stack.pushPathByName(uikitNavigationDestinations.PickMultiGroupPage, {} as Record<string, Object>);
                return '{"code":-1}';
            }
            case 'close': {
                this.stack.pop(true);
                this.callbackJs(cb, 0);
                return '{}';
            }
            case 'config': {
                let req = panMap(data);
                wfc.configApplication(panStr(req['appId']), req['appType'] as number,
                    req['timestamp'] as number, panStr(req['nonceStr']), panStr(req['signature']), () => {
                        this.callJs('ready');
                    }, (err: number) => {
                        this.callJs('error', [err + '']);
                    });
                return '{}';
            }
            default: {
                return '{"code":-1}';
            }
        }
    };

    private doDownload(data: Object | undefined): void {
        let fileUrl = typeof data === 'string' ? data as string : panStr(panMap(data)['url']);
        if (!fileUrl) {
            showToast('下载地址为空');
            return;
        }
        let maybeContext = AppStorage.get<common.UIAbilityContext>('context');
        if (!maybeContext) {
            return;
        }
        let context: common.UIAbilityContext = maybeContext;
        let name = panStr(panMap(data)['name']);
        downloadUrlToCache(context, fileUrl, name).then((path: string) => {
            openLocalFile(context, path, name ? name : '文件');
        }).catch((e: Error) => {
            showToast('下载失败：' + (e.message || ''));
        });
    }

    private doOpenUrl(data: Object | undefined): void {
        let targetUrl = '';
        let name = '';
        if (typeof data === 'string') {
            targetUrl = data as string;
        } else {
            let map = panMap(data);
            targetUrl = panStr(map['url']);
            name = panStr(map['name']);
        }
        if (!targetUrl) {
            return;
        }
        if (PanService.isDocUrl(targetUrl)) {
            this.stack.pushPathByName(uikitNavigationDestinations.PanDocWebPage, {
                'url': targetUrl,
                'name': name
            } as Record<string, Object>);
            return;
        }
        if (targetUrl.startsWith('http://') || targetUrl.startsWith('https://')) {
            this.stack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                'url': targetUrl,
                'title': name
            } as Record<string, Object>);
            return;
        }
        let context = AppStorage.get<common.UIAbilityContext>('context');
        context?.startAbility({ action: 'ohos.want.action.viewData', uri: targetUrl });
    }

    /** 来自宿主的标题栏按钮回调 */
    onHeaderActionClicked(id: string): void {
        this.onHeaderAction?.(id);
        this.callbackRaw(this.headerCb, id);
    }

    onPickContact(users: UserInfo[]): void {
        if (!this.pickingContact) {
            return;
        }
        this.pickingContact = false;
        let list: Record<string, Object>[] = users.map((u: UserInfo) => {
            return {
                'uid': u.uid,
                'name': u.name,
                'displayName': u.displayName,
                'portrait': u.portrait
            } as Record<string, Object>;
        });
        this.callbackJs(this.pendingContactCb, 0, JSON.stringify(list));
        this.pendingContactCb = '';
    }

    onPickGroup(groups: GroupInfo[]): void {
        if (!this.pickingGroup) {
            return;
        }
        this.pickingGroup = false;
        let list: Record<string, Object>[] = groups.map((g: GroupInfo) => {
            return {
                'gid': g.target,
                'target': g.target,
                'name': g.name,
                'portrait': g.portrait
            } as Record<string, Object>;
        });
        this.callbackJs(this.pendingGroupCb, 0, JSON.stringify(list));
        this.pendingGroupCb = '';
    }

    /** 页面被取消选择时（返回但无结果）回 -1，避免页面 Promise 挂起 */
    onPickCancelled(): void {
        if (this.pickingContact) {
            this.pickingContact = false;
            this.callbackJs(this.pendingContactCb, -1);
            this.pendingContactCb = '';
        }
        if (this.pickingGroup) {
            this.pickingGroup = false;
            this.callbackJs(this.pendingGroupCb, -1);
            this.pendingGroupCb = '';
        }
    }
}
