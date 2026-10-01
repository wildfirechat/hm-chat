/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 在线文档宿主页：WfcWebView + PanDocBridge，承载服务端 doc-web（/doc/open）。
 * setPageHeader 把标题栏交给宿主画；share 按钮由宿主接管跳分享页。
 */

import web_webview from '@ohos.web.webview';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo';
import WfcWebView from '../pages/workspace/WfcWebView';
import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig';
import { isWideScreen } from '../util/navUtil';
import PickMultiContactModal from '../pages/picker/PickMultiContactModal';
import PickMultiGroupModal from '../pages/picker/PickMultiGroupModal';
import PanDocBridge from './panDocBridge';
import PanService from './panService';
import { PanHeaderAction, PanPageHeader } from './panModels';
import { FontSize, Radius } from '../common/design/Tokens';

@Component
export default struct PanDocWebPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State docUrl: string = '';
    @State docTitle: string = '文档';
    @State header: PanPageHeader | null = null;
    private controller: web_webview.WebviewController = new web_webview.WebviewController();
    private bridge?: PanDocBridge;
    private fileId: number = 0;
    private readonlyContextUrl: string = '';
    private readonlyContextName: string = '';

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let platform = isWideScreen() ? 'pc' : 'mobile';
        if (params) {
            this.fileId = (params['fileId'] as number) || 0;
            this.readonlyContextUrl = (params['url'] as string) || '';
            this.readonlyContextName = (params['name'] as string) || '';
        }
        if (this.fileId > 0) {
            this.docUrl = PanService.docOpenUrl(this.fileId, platform);
            this.docTitle = this.readonlyContextName ? this.readonlyContextName : '文档';
        } else if (this.readonlyContextUrl) {
            this.docUrl = PanService.docViewUrl(this.readonlyContextUrl, this.readonlyContextName, platform);
            this.docTitle = this.readonlyContextName ? this.readonlyContextName : '文档';
        }
        this.bridge = new PanDocBridge(this.docUrl, this.controller, this.mainNavPathStack,
            (h: PanPageHeader) => {
                this.header = h;
                if (h.title) {
                    this.docTitle = h.title;
                }
            },
            (id: string) => {
            });
    }

    onShown() {
        let localStorage = LocalStorage.getShared();
        let users = localStorage.get<UserInfo[]>(PickMultiContactModal.PICK_RESULT);
        if (users) {
            localStorage.delete(PickMultiContactModal.PICK_RESULT);
            this.bridge?.onPickContact(users);
        }
        let groups = localStorage.get<GroupInfo[]>(PickMultiGroupModal.PICK_RESULT);
        if (groups) {
            localStorage.delete(PickMultiGroupModal.PICK_RESULT);
            this.bridge?.onPickGroup(groups);
        }
        // 从选人/选群页返回但没有结果 => 已取消，回 -1 避免页面 Promise 挂起
        this.bridge?.onPickCancelled();
    }

    private onHeaderAction(id: string) {
        if (id === 'share' && this.fileId > 0) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PanSharePage, {
                'fileId': this.fileId,
                'name': this.docTitle
            } as Record<string, Object>);
            return;
        }
        this.bridge?.onHeaderActionClicked(id);
    }

    build() {
        NavDestination() {
            WfcWebView({
                url: this.docUrl,
                controller: this.controller,
                dsBridge: this.bridge
            })
                .width('100%')
                .height('100%')
        }
        .title(this.TitleBuilder())
        .hideBackButton(false)
        .backgroundColor($r('app.color.wf_primary_background_color'))
    }

    @Builder
    TitleBuilder() {
        Row() {
            Column({ space: 2 }) {
                Text(this.docTitle)
                    .fontSize(FontSize.md)
                    .fontColor($r('app.color.wf_primary_text'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                if (this.header && this.header.subtitle) {
                    Text(this.header.subtitle)
                        .fontSize(FontSize.xs)
                        .fontColor($r('app.color.wf_tertiary_text'))
                        .maxLines(1)
                }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (this.header) {
                ForEach(this.header.actions, (action: PanHeaderAction) => {
                    Text(action.text)
                        .fontSize(FontSize.sm)
                        .fontColor(action.primary ? $r('app.color.wf_primary_text') : $r('app.color.wf_tertiary_text'))
                        .padding({ left: 8, right: 8 })
                        .onClick(() => {
                            this.onHeaderAction(action.id);
                        })
                }, (action: PanHeaderAction) => action.id)
            }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
    }
}
