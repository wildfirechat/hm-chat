/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 文件分享管理：列出已分享的人/群，可改权限（通过重新分享覆盖）、移除；可把文档链接卡片发到会话。
 */

import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo';
import { showToast } from '../common/utils/Toast';
import { ShareItem } from '../common/Types';
import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig';
import PickMultiContactModal from '../pages/picker/PickMultiContactModal';
import PickMultiGroupModal from '../pages/picker/PickMultiGroupModal';
import { FontSize, Radius } from '../common/design/Tokens';
import PanService from './panService';
import { PanShare } from './panModels';
import { PanEmptyView } from './panWidgets';

@Component
export default struct PanSharePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State shares: PanShare[] = [];
    @State loading: boolean = true;
    @State error: string = '';
    @State canEdit: boolean = false;
    private fileId: number = 0;
    private fileName: string = '';

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            this.fileId = (params['fileId'] as number) || 0;
            this.fileName = (params['name'] as string) || '文件';
        }
        this.load();
    }

    onShown() {
        let localStorage = LocalStorage.getShared();
        let users = localStorage.get<UserInfo[]>(PickMultiContactModal.PICK_RESULT);
        if (users) {
            localStorage.delete(PickMultiContactModal.PICK_RESULT);
            this.grantUsers(users);
        }
        let groups = localStorage.get<GroupInfo[]>(PickMultiGroupModal.PICK_RESULT);
        if (groups) {
            localStorage.delete(PickMultiGroupModal.PICK_RESULT);
            this.grantGroups(groups);
        }
    }

    load() {
        this.loading = true;
        this.error = '';
        PanService.getShares(this.fileId)
            .then((shares: PanShare[]) => {
                this.shares = shares;
                this.loading = false;
            })
            .catch((e: Error) => {
                this.loading = false;
                this.error = e.message || '加载失败';
            });
    }

    grantUsers(users: UserInfo[]) {
        for (let u of users) {
            PanService.setShare(this.fileId, false, u.uid, this.canEdit)
                .then(() => {
                    this.load();
                })
                .catch((e: Error) => {
                    showToast('授权失败：' + (e.message || ''));
                });
        }
    }

    grantGroups(groups: GroupInfo[]) {
        for (let g of groups) {
            PanService.setShare(this.fileId, true, g.target, this.canEdit)
                .then(() => {
                    this.load();
                })
                .catch((e: Error) => {
                    showToast('授权失败：' + (e.message || ''));
                });
        }
    }

    addMember() {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PickMultiContactPage, {
            'showFavGroup': false
        } as Record<string, Object>);
    }

    addGroup() {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PickMultiGroupPage, {} as Record<string, Object>);
    }

    removeShare(share: PanShare) {
        PanService.removeShare(share.id)
            .then(() => {
                showToast('已移除');
                this.load();
            })
            .catch((e: Error) => {
                showToast('移除失败：' + (e.message || ''));
            });
    }

    sendLinkCard() {
        let item: ShareItem = {
            type: 'link',
            url: PanService.docOpenUrl(this.fileId),
            title: this.fileName
        };
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ShareToConversationPage, {
            'shareItems': [item]
        } as Record<string, Object>);
    }

    shareLabel(share: PanShare): string {
        let who = share.isGroup ? '群' : '用户';
        let name = share.targetName ? share.targetName : share.targetId;
        return `${who}：${name}`;
    }

    build() {
        NavDestination() {
            Column() {
                Row({ space: 12 }) {
                    Text('默认权限')
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.wf_tertiary_text'))
                    Button('可查看')
                        .type(ButtonType.Normal)
                        .fontSize(FontSize.sm)
                        .borderRadius(Radius.sm)
                        .backgroundColor(this.canEdit ? $r('app.color.wf_secondary_background') : $r('app.color.wf_background'))
                        .fontColor(this.canEdit ? $r('app.color.wf_tertiary_text') : $r('app.color.wf_primary_text'))
                        .onClick(() => {
                            this.canEdit = false;
                        })
                    Button('可编辑')
                        .type(ButtonType.Normal)
                        .fontSize(FontSize.sm)
                        .borderRadius(Radius.sm)
                        .backgroundColor(this.canEdit ? $r('app.color.wf_background') : $r('app.color.wf_secondary_background'))
                        .fontColor(this.canEdit ? $r('app.color.wf_primary_text') : $r('app.color.wf_tertiary_text'))
                        .onClick(() => {
                            this.canEdit = true;
                        })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .backgroundColor($r('app.color.wf_secondary_background'))

                if (this.loading) {
                    Column() {
                        LoadingProgress().width(40).height(40)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else if (this.error) {
                    Column() {
                        PanEmptyView({ message: this.error, showRetry: true, onRetry: () => { this.load(); } })
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else if (this.shares.length === 0) {
                    Column() {
                        PanEmptyView({ message: '还没有分享给任何人' })
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else {
                    List() {
                        ForEach(this.shares, (share: PanShare) => {
                            ListItem() {
                                Row({ space: 12 }) {
                                    Column({ space: 4 }) {
                                        Text(this.shareLabel(share))
                                            .fontSize(FontSize.md)
                                            .fontColor($r('app.color.wf_primary_text'))
                                            .maxLines(1)
                                        Text(share.canEdit ? '可编辑' : '可查看')
                                            .fontSize(FontSize.sm)
                                            .fontColor($r('app.color.wf_tertiary_text'))
                                    }
                                    .layoutWeight(1)
                                    .alignItems(HorizontalAlign.Start)
                                    Image($r('app.media.ic_delete'))
                                        .width(20)
                                        .height(20)
                                        .onClick(() => {
                                            this.removeShare(share);
                                        })
                                }
                                .width('100%')
                                .height(60)
                                .padding({ left: 16, right: 16 })
                                .backgroundColor($r('app.color.wf_background'))
                            }
                        }, (share: PanShare) => `${share.id}`)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .divider({ strokeWidth: 0.5, color: $r('app.color.wf_divider') })
                }
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .title('分享')
        .hideBackButton(false)
        .menus(this.ToolbarMenu())
    }

    @Builder
    ToolbarMenu() {
        Row() {
            Image($r('app.media.ic_add_team_member'))
                .width(22)
                .height(22)
                .margin({ right: 18 })
                .onClick(() => {
                    this.addMember();
                })
            Image($r('app.media.ic_chat_add'))
                .width(22)
                .height(22)
                .margin({ right: 18 })
                .onClick(() => {
                    this.addGroup();
                })
            Image($r('app.media.ic_msg_forward'))
                .width(22)
                .height(22)
                .margin({ right: 16 })
                .onClick(() => {
                    this.sendLinkCard();
                })
        }
    }
}
