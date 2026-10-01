/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 在线文档首页：最近打开 / 共享给我，两个分段；新建 docx/xlsx/pptx。
 */

import { showToast } from '../common/utils/Toast';
import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig';
import { FontSize, Radius } from '../common/design/Tokens';
import PanService from './panService';
import { PanDocEntry, PanFile } from './panModels';
import { PanEmptyView, panFileIcon, PanNameDialog } from './panWidgets';

@Component
export default struct PanDocsPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State segmentIndex: number = 0;
    @State recent: PanDocEntry[] = [];
    @State shared: PanDocEntry[] = [];
    @State loading: boolean = true;
    @State error: string = '';
    @State mobileEdit: boolean = true;
    private createDialog?: CustomDialogController;

    aboutToAppear() {
        this.load();
        PanService.isMobileDocEditEnabled()
            .then((enabled: boolean) => {
                this.mobileEdit = enabled;
            })
            .catch(() => {
            });
    }

    load() {
        this.loading = true;
        this.error = '';
        PanService.getRecentDocs()
            .then((list: PanDocEntry[]) => {
                this.recent = list;
                this.loading = false;
            })
            .catch((e: Error) => {
                this.loading = false;
                this.error = e.message || '加载失败';
            });
        PanService.getSharedWithMe()
            .then((list: PanDocEntry[]) => {
                this.shared = list;
            })
            .catch(() => {
            });
    }

    currentList(): PanDocEntry[] {
        return this.segmentIndex === 0 ? this.recent : this.shared;
    }

    openEntry(entry: PanDocEntry) {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PanDocWebPage, {
            'fileId': entry.file.fileId,
            'name': entry.file.name
        } as Record<string, Object>);
    }

    newDoc(type: string, defaultName: string) {
        this.createDialog = new CustomDialogController({
            builder: PanNameDialog({
                title: '新建文档',
                defaultValue: defaultName,
                onConfirm: (value: string) => {
                    PanService.createDoc(type, value)
                        .then((file: PanFile) => {
                            this.load();
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PanDocWebPage, {
                                'fileId': file.fileId,
                                'name': file.name
                            } as Record<string, Object>);
                        })
                        .catch((e: Error) => {
                            showToast('新建失败：' + (e.message || ''));
                        });
                }
            }),
            autoCancel: true,
            customStyle: true,
            alignment: DialogAlignment.Center
        });
        this.createDialog.open();
    }

    removeRecent(entry: PanDocEntry) {
        PanService.removeRecentDoc(entry.file.fileId)
            .then(() => {
                this.recent = this.recent.filter((e: PanDocEntry) => e.file.fileId !== entry.file.fileId);
            })
            .catch((e: Error) => {
                showToast('移除失败：' + (e.message || ''));
            });
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    this.SegmentItem('最近打开', 0)
                    this.SegmentItem('共享给我', 1)
                }
                .width('100%')
                .backgroundColor($r('app.color.wf_secondary_background'))

                if (this.loading && this.currentList().length === 0) {
                    Column() {
                        LoadingProgress().width(40).height(40)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else if (this.error && this.currentList().length === 0) {
                    Column() {
                        PanEmptyView({ message: this.error, showRetry: true, onRetry: () => { this.load(); } })
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else if (this.currentList().length === 0) {
                    Column() {
                        PanEmptyView({ message: this.segmentIndex === 0 ? '还没有最近打开的文档' : '还没有人共享文件给你' })
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else {
                    List() {
                        ForEach(this.currentList(), (entry: PanDocEntry) => {
                            ListItem() {
                                Row({ space: 12 }) {
                                    Image(panFileIcon(entry.file.name, false))
                                        .width(40)
                                        .height(40)
                                    Column({ space: 4 }) {
                                        Text(entry.file.name)
                                            .fontSize(FontSize.md)
                                            .fontColor($r('app.color.wf_primary_text'))
                                            .maxLines(1)
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                        Text((entry.canEdit ? '可编辑' : '可查看') + (entry.time ? ' · ' + entry.time : ''))
                                            .fontSize(FontSize.sm)
                                            .fontColor($r('app.color.wf_tertiary_text'))
                                            .maxLines(1)
                                    }
                                    .layoutWeight(1)
                                    .alignItems(HorizontalAlign.Start)
                                }
                                .width('100%')
                                .height(64)
                                .padding({ left: 16, right: 16 })
                                .backgroundColor($r('app.color.wf_background'))
                            }
                            .onClick(() => {
                                this.openEntry(entry);
                            })
                            .bindContextMenu(this.RecentMenu(entry), ResponseType.LongPress, { preview: MenuPreviewMode.NONE })
                        }, (entry: PanDocEntry) => `${entry.file.fileId}`)
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
        .title('在线文档')
        .hideBackButton(false)
        .menus(this.ToolbarMenu())
    }

    @Builder
    SegmentItem(title: string, index: number) {
        Text(title)
            .fontSize(FontSize.md)
            .fontColor(this.segmentIndex === index ? $r('app.color.wf_primary_text') : $r('app.color.wf_tertiary_text'))
            .fontWeight(this.segmentIndex === index ? FontWeight.Medium : FontWeight.Normal)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .onClick(() => {
                this.segmentIndex = index;
            })
    }

    @Builder
    ToolbarMenu() {
        Row() {
            if (this.mobileEdit) {
                Image($r('app.media.ic_add'))
                    .width(22)
                    .height(22)
                    .margin({ right: 18 })
                    .bindMenu(this.CreateTypeMenu())
            }
            Image($r('app.media.refreshing'))
                .width(22)
                .height(22)
                .margin({ right: 16 })
                .onClick(() => {
                    this.load();
                })
        }
    }

    @Builder
    CreateTypeMenu() {
        Menu() {
            MenuItem({ content: '新建文档' })
                .onClick(() => {
                    this.newDoc('docx', '未命名文档');
                })
            MenuItem({ content: '新建表格' })
                .onClick(() => {
                    this.newDoc('xlsx', '未命名表格');
                })
            MenuItem({ content: '新建演示' })
                .onClick(() => {
                    this.newDoc('pptx', '未命名演示');
                })
        }
    }

    @Builder
    RecentMenu(entry: PanDocEntry) {
        Menu() {
            if (this.segmentIndex === 0) {
                MenuItem({ content: '从最近打开中移除' })
                    .onClick(() => {
                        this.removeRecent(entry);
                    })
            }
            MenuItem({ content: entry.canEdit ? '可编辑' : '可查看' })
                .enabled(false)
        }
    }
}
