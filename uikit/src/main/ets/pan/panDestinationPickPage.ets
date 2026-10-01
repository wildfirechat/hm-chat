/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 移动/复制目标文件夹选择：先选空间，再进目录树，选定当前目录返回 {spaceId,parentId}。
 */

import { showToast } from '../common/utils/Toast';
import { FontSize, Radius } from '../common/design/Tokens';
import PanService from './panService';
import { PanFile, PanSpace } from './panModels';
import { PanEmptyView, panFileIcon } from './panWidgets';

@Component
export default struct PanDestinationPickPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    public static PICK_RESULT: string = 'panDestinationPickResult';
    @State spaces: PanSpace[] = [];
    @State selectedSpace: PanSpace | null = null;
    @State folders: PanFile[] = [];
    @State folderStack: PanFile[] = [];
    @State loading: boolean = true;
    @State error: string = '';
    private excludeFileId: number = 0;
    private mode: string = 'move';

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            this.excludeFileId = (params['excludeFileId'] as number) || 0;
            this.mode = (params['mode'] as string) || 'move';
        }
        PanService.getVisibleSpaces()
            .then((spaces: PanSpace[]) => {
                this.spaces = spaces.filter((s: PanSpace) => s.canWriteByOwner('') || s.spaceType !== 'USER_PUBLIC');
                this.loading = false;
            })
            .catch((e: Error) => {
                this.loading = false;
                this.error = e.message || '加载失败';
            });
    }

    currentParentId(): number {
        return this.folderStack.length > 0 ? this.folderStack[this.folderStack.length - 1].fileId : 0;
    }

    selectSpace(space: PanSpace) {
        this.selectedSpace = space;
        this.folderStack = [];
        this.loadFolders();
    }

    loadFolders() {
        let space = this.selectedSpace;
        if (!space) {
            return;
        }
        this.loading = true;
        PanService.getSpaceFiles(space.spaceId, this.currentParentId())
            .then((files: PanFile[]) => {
                this.folders = files.filter((f: PanFile) => f.isFolder && f.fileId !== this.excludeFileId);
                this.loading = false;
            })
            .catch((e: Error) => {
                this.loading = false;
                this.error = e.message || '加载失败';
            });
    }

    confirm() {
        let space = this.selectedSpace;
        if (!space) {
            return;
        }
        let result = {
            'spaceId': space.spaceId,
            'parentId': this.currentParentId()
        } as Record<string, Object>;
        LocalStorage.getShared().setOrCreate<Record<string, Object>>(PanDestinationPickPage.PICK_RESULT, result);
        this.mainNavPathStack.pop(true);
    }

    build() {
        NavDestination() {
            Column() {
                if (this.loading) {
                    Column() {
                        LoadingProgress().width(40).height(40)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else if (this.error) {
                    Column() {
                        PanEmptyView({ message: this.error, showRetry: true, onRetry: () => { this.loadFolders(); } })
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else if (!this.selectedSpace) {
                    List() {
                        ForEach(this.spaces, (space: PanSpace) => {
                            ListItem() {
                                Row({ space: 12 }) {
                                    Image($r('app.media.ic_pan_drive')).width(36).height(36)
                                    Text(space.name)
                                        .fontSize(FontSize.md)
                                        .fontColor($r('app.color.wf_primary_text'))
                                        .layoutWeight(1)
                                        .maxLines(1)
                                    Image($r('app.media.ic_public_arrow_right')).width(18).height(18)
                                }
                                .width('100%')
                                .height(60)
                                .padding({ left: 16, right: 16 })
                                .backgroundColor($r('app.color.wf_background'))
                            }
                            .onClick(() => {
                                this.selectSpace(space);
                            })
                        }, (space: PanSpace) => `${space.spaceId}`)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .divider({ strokeWidth: 0.5, color: $r('app.color.wf_divider') })
                } else {
                    this.Breadcrumb()
                    if (this.folders.length === 0) {
                        Column() {
                            PanEmptyView({ message: '此目录下没有子文件夹' })
                        }
                        .width('100%')
                        .layoutWeight(1)
                        .justifyContent(FlexAlign.Center)
                    } else {
                        List() {
                            ForEach(this.folders, (folder: PanFile) => {
                                ListItem() {
                                    Row({ space: 12 }) {
                                        Image(panFileIcon(folder.name, true)).width(36).height(36)
                                        Text(folder.name)
                                            .fontSize(FontSize.md)
                                            .fontColor($r('app.color.wf_primary_text'))
                                            .layoutWeight(1)
                                            .maxLines(1)
                                        Image($r('app.media.ic_public_arrow_right')).width(18).height(18)
                                    }
                                    .width('100%')
                                    .height(60)
                                    .padding({ left: 16, right: 16 })
                                    .backgroundColor($r('app.color.wf_background'))
                                }
                                .onClick(() => {
                                    this.folderStack.push(folder);
                                    this.loadFolders();
                                })
                            }, (folder: PanFile) => `${folder.fileId}`)
                        }
                        .width('100%')
                        .layoutWeight(1)
                        .divider({ strokeWidth: 0.5, color: $r('app.color.wf_divider') })
                    }
                }
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .title(this.mode === 'copy' ? '复制到' : '移动到')
        .hideBackButton(false)
        .menus(this.ConfirmMenu())
    }

    @Builder
    ConfirmMenu() {
        Row() {
            Button(this.selectedSpace ? '选择此目录' : '请选择空间')
                .enabled(!!this.selectedSpace)
                .type(ButtonType.Normal)
                .fontSize(FontSize.sm)
                .borderRadius(Radius.sm)
                .margin({ right: 16 })
                .onClick(() => {
                    this.confirm();
                })
        }
    }

    @Builder
    Breadcrumb() {
        Scroll() {
            Row({ space: 4 }) {
                Text(this.selectedSpace ? this.selectedSpace.name : '')
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_primary_text'))
                    .onClick(() => {
                        this.folderStack = [];
                        this.loadFolders();
                    })
                ForEach(this.folderStack, (folder: PanFile) => {
                    Row({ space: 4 }) {
                        Image($r('app.media.ic_public_arrow_right')).width(12).height(12)
                        Text(folder.name)
                            .fontSize(FontSize.sm)
                            .fontColor($r('app.color.wf_primary_text'))
                            .maxLines(1)
                            .onClick(() => {
                                let idx = this.folderStack.indexOf(folder);
                                this.folderStack = this.folderStack.slice(0, idx + 1);
                                this.loadFolders();
                            })
                    }
                }, (folder: PanFile) => `${folder.fileId}`)
            }
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .backgroundColor($r('app.color.wf_secondary_background'))
    }
}
