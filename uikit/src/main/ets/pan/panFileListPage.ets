/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 网盘文件列表：面包屑、新建文件夹、上传、文件长按操作（打开/下载/分享/移动/复制/重命名/删除）。
 */

import wfc from '@wfc/client';
import MessageContentMediaType from '@wfc/client/src/main/ets/wfc/messages/messageContentMediaType';
import { showToast } from '../common/utils/Toast';
import { copyFileUri, fileNameFromFileUri, fileSize } from '../common/utils/FileUtil';
import { selectFiles } from '../helper/mediaHelper';
import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig';
import { FontSize, Radius } from '../common/design/Tokens';
import PanService, { PanCreateFileParams } from './panService';
import { PanFile, PanSpace } from './panModels';
import { PanEmptyView, panFileIcon, PanNameDialog } from './panWidgets';
import { downloadPanFile, openPanFile } from './panSave';
import PanDestinationPickPage from './panDestinationPickPage';

interface PanMenuItem {
    title: string,
    action: () => void
}

@Component
export default struct PanFileListPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private space: PanSpace = new PanSpace();
    @State spaceName: string = '网盘';
    @State files: PanFile[] = [];
    @State folderStack: PanFile[] = [];
    @State loading: boolean = true;
    @State error: string = '';
    @State canWrite: boolean = false;
    @State uploading: boolean = false;
    @State uploadName: string = '';
    @State uploadProgress: number = 0;
    private nameDialog?: CustomDialogController;
    private pendingFile?: PanFile;
    private pendingMode: string = '';
    private uploadedNames: string[] = [];

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params && params['space']) {
            this.space = params['space'] as PanSpace;
        }
        this.spaceName = this.space.name ? this.space.name : '网盘';
        this.canWrite = this.space.canWriteByOwner(wfc.getUserId());
        this.load();
    }

    onShown() {
        // 从目标选择页返回，执行移动/复制
        let result = LocalStorage.getShared().get<Record<string, Object>>(PanDestinationPickPage.PICK_RESULT);
        if (result && this.pendingFile) {
            LocalStorage.getShared().delete(PanDestinationPickPage.PICK_RESULT);
            let targetSpaceId = result['spaceId'] as number;
            let targetParentId = result['parentId'] as number;
            let file = this.pendingFile;
            let mode = this.pendingMode;
            this.pendingFile = undefined;
            this.pendingMode = '';
            let task: Promise<PanFile> = mode === 'copy'
                ? PanService.copyFile(file.fileId, targetSpaceId, targetParentId)
                : PanService.moveFile(file.fileId, targetSpaceId, targetParentId);
            task.then(() => {
                showToast(mode === 'copy' ? '复制成功' : '移动成功');
                this.load();
            }).catch((e: Error) => {
                showToast((mode === 'copy' ? '复制失败：' : '移动失败：') + (e.message || ''));
            });
        }
    }

    currentParentId(): number {
        return this.folderStack.length > 0 ? this.folderStack[this.folderStack.length - 1].fileId : 0;
    }

    load() {
        this.loading = true;
        this.error = '';
        PanService.getSpaceFiles(this.space.spaceId, this.currentParentId())
            .then((files: PanFile[]) => {
                this.files = files;
                this.loading = false;
            })
            .catch((e: Error) => {
                this.loading = false;
                this.error = e.message || '加载失败';
            });
        PanService.checkSpaceWrite(this.space.spaceId)
            .then((w: boolean) => {
                this.canWrite = w;
            })
            .catch(() => {
            });
    }

    openFile(file: PanFile) {
        if (file.isFolder) {
            this.folderStack.push(file);
            this.load();
        } else {
            openPanFile(getContext(this), this.mainNavPathStack, file);
        }
    }

    openOnline(file: PanFile) {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PanDocWebPage, {
            'fileId': file.fileId,
            'name': file.name
        } as Record<string, Object>);
    }

    openShare(file: PanFile) {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PanSharePage, {
            'fileId': file.fileId,
            'name': file.name
        } as Record<string, Object>);
    }

    askNewFolder() {
        this.nameDialog = new CustomDialogController({
            builder: PanNameDialog({
                title: '新建文件夹',
                defaultValue: '',
                onConfirm: (value: string) => {
                    PanService.createFolder(this.space.spaceId, value, this.currentParentId())
                        .then(() => {
                            showToast('创建成功');
                            this.load();
                        })
                        .catch((e: Error) => {
                            showToast('创建失败：' + (e.message || ''));
                        });
                }
            }),
            autoCancel: true,
            customStyle: true,
            alignment: DialogAlignment.Center
        });
        this.nameDialog.open();
    }

    askRename(file: PanFile) {
        this.nameDialog = new CustomDialogController({
            builder: PanNameDialog({
                title: '重命名',
                defaultValue: file.name,
                onConfirm: (value: string) => {
                    PanService.renameFile(file.fileId, value)
                        .then(() => {
                            showToast('已重命名');
                            this.load();
                        })
                        .catch((e: Error) => {
                            showToast('重命名失败：' + (e.message || ''));
                        });
                }
            }),
            autoCancel: true,
            customStyle: true,
            alignment: DialogAlignment.Center
        });
        this.nameDialog.open();
    }

    confirmDelete(file: PanFile) {
        AlertDialog.show({
            title: '删除',
            message: `确定删除「${file.name}」吗？`,
            primaryButton: {
                value: '删除',
                fontColor: Color.Red,
                action: () => {
                    PanService.deleteFile(file.fileId)
                        .then(() => {
                            showToast('已删除');
                            this.load();
                        })
                        .catch((e: Error) => {
                            showToast('删除失败：' + (e.message || ''));
                        });
                }
            },
            secondaryButton: {
                value: '取消',
                action: () => {
                }
            }
        });
    }

    startMoveOrCopy(file: PanFile, mode: string) {
        this.pendingFile = file;
        this.pendingMode = mode;
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PanDestinationPickPage, {
            'spaceId': this.space.spaceId,
            'excludeFileId': file.fileId,
            'mode': mode
        } as Record<string, Object>);
    }

    uploadFiles() {
        selectFiles(9).then((uris: string[]) => {
            if (!uris || uris.length === 0) {
                return;
            }
            this.uploadedNames = [];
            this.uploadNext(uris, 0);
        }).catch((e: Error) => {
            showToast('选择文件失败');
        });
    }

    uploadNext(uris: string[], index: number) {
        if (index >= uris.length) {
            this.uploading = false;
            this.uploadName = '';
            this.uploadProgress = 0;
            this.load();
            return;
        }
        let uri = uris[index];
        let name = fileNameFromFileUri(uri);
        let context = getContext(this);
        let cachePath = context.getApplicationContext().cacheDir + '/' + new Date().getTime() + '_' + name;
        try {
            copyFileUri(uri, cachePath);
        } catch (e) {
            this.uploadNext(uris, index + 1);
            return;
        }
        let size = fileSize(cachePath);
        let names = this.files.concat(this.uploadedNames.map((n: string) => {
            let f = new PanFile();
            f.name = n;
            return f;
        }));
        let uniqueName = PanService.uniqueFileName(names, name);
        this.uploadedNames.push(uniqueName);
        this.uploading = true;
        this.uploadName = uniqueName;
        this.uploadProgress = 0;
        wfc.uploadMediaFile(cachePath, MessageContentMediaType.File, (remoteUrl: string) => {
            let p: PanCreateFileParams = {
                spaceId: this.space.spaceId,
                name: uniqueName,
                size: size,
                storageUrl: remoteUrl,
                parentId: this.currentParentId(),
                copy: true
            };
            PanService.createFile(p)
                .then(() => {
                    this.uploadNext(uris, index + 1);
                })
                .catch((e: Error) => {
                    showToast('保存文件记录失败：' + (e.message || ''));
                    this.uploadNext(uris, index + 1);
                });
        }, (err: number) => {
            showToast('上传失败：' + err);
            this.uploadNext(uris, index + 1);
        }, (sent: number, total: number) => {
            this.uploadProgress = total > 0 ? Math.floor(sent * 100 / total) : 0;
        });
    }

    fileMenuItems(file: PanFile): PanMenuItem[] {
        let items: PanMenuItem[] = [];
        if (file.isFolder) {
            items.push({
                title: '打开',
                action: () => {
                    this.openFile(file);
                }
            });
        } else {
            if (file.canOpenOnline()) {
                items.push({
                    title: '在线打开',
                    action: () => {
                        this.openOnline(file);
                    }
                });
            }
            items.push({
                title: '下载',
                action: () => {
                    downloadPanFile(getContext(this), file.fileId, file.name);
                }
            });
        }
        if (this.canWrite) {
            items.push({
                title: '移动到',
                action: () => {
                    this.startMoveOrCopy(file, 'move');
                }
            });
            items.push({
                title: '复制到',
                action: () => {
                    this.startMoveOrCopy(file, 'copy');
                }
            });
        }
        if (this.space.canManage) {
            items.push({
                title: '分享',
                action: () => {
                    this.openShare(file);
                }
            });
            items.push({
                title: '重命名',
                action: () => {
                    this.askRename(file);
                }
            });
            items.push({
                title: '删除',
                action: () => {
                    this.confirmDelete(file);
                }
            });
        }
        return items;
    }

    build() {
        NavDestination() {
            Column() {
                this.Breadcrumb()
                if (this.uploading) {
                    Row({ space: 8 }) {
                        Text(`上传中 ${this.uploadName}`)
                            .fontSize(FontSize.sm)
                            .fontColor($r('app.color.wf_tertiary_text'))
                            .layoutWeight(1)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Progress({ value: this.uploadProgress, total: 100, type: ProgressType.Linear })
                            .width(120)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                    .backgroundColor($r('app.color.wf_secondary_background'))
                }
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
                } else if (this.files.length === 0) {
                    Column() {
                        PanEmptyView({ message: '此文件夹为空' })
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else {
                    List() {
                        ForEach(this.files, (file: PanFile) => {
                            ListItem() {
                                Row({ space: 12 }) {
                                    Image(panFileIcon(file.name, file.isFolder))
                                        .width(40)
                                        .height(40)
                                    Column({ space: 4 }) {
                                        Text(file.name)
                                            .fontSize(FontSize.md)
                                            .fontColor($r('app.color.wf_primary_text'))
                                            .maxLines(1)
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                        if (!file.isFolder) {
                                            Text(PanService.formatSize(file.size))
                                                .fontSize(FontSize.sm)
                                                .fontColor($r('app.color.wf_tertiary_text'))
                                        }
                                    }
                                    .layoutWeight(1)
                                    .alignItems(HorizontalAlign.Start)
                                    Image($r('app.media.ic_public_arrow_right'))
                                        .width(18)
                                        .height(18)
                                }
                                .width('100%')
                                .height(64)
                                .padding({ left: 16, right: 16 })
                                .backgroundColor($r('app.color.wf_background'))
                            }
                            .onClick(() => {
                                this.openFile(file);
                            })
                            .bindContextMenu(this.FileMenu(file), ResponseType.LongPress, { preview: MenuPreviewMode.NONE })
                        }, (file: PanFile) => `${file.fileId}-${file.name}`)
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
        .title(this.spaceName)
        .hideBackButton(false)
        .backgroundColor($r('app.color.wf_primary_background_color'))
        .menus(this.ToolbarMenu())
    }

    @Builder
    Breadcrumb() {
        Scroll() {
            Row({ space: 4 }) {
                Text(this.spaceName)
                    .fontSize(FontSize.sm)
                    .fontColor($r('app.color.wf_primary_text'))
                    .onClick(() => {
                        this.folderStack = [];
                        this.load();
                    })
                ForEach(this.folderStack, (folder: PanFile) => {
                    Row({ space: 4 }) {
                        Image($r('app.media.ic_public_arrow_right'))
                            .width(12)
                            .height(12)
                        Text(folder.name)
                            .fontSize(FontSize.sm)
                            .fontColor($r('app.color.wf_primary_text'))
                            .maxLines(1)
                            .onClick(() => {
                                let idx = this.folderStack.indexOf(folder);
                                this.folderStack = this.folderStack.slice(0, idx + 1);
                                this.load();
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

    @Builder
    ToolbarMenu() {
        Row() {
            if (this.canWrite) {
                Image($r('app.media.ic_add'))
                    .width(22)
                    .height(22)
                    .margin({ right: 18 })
                    .onClick(() => {
                        this.askNewFolder();
                    })
                Image($r('app.media.ic_pan_upload'))
                    .width(22)
                    .height(22)
                    .fillColor($r('app.color.wf_primary_text'))
                    .margin({ right: 16 })
                    .onClick(() => {
                        this.uploadFiles();
                    })
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
    FileMenu(file: PanFile) {
        Menu() {
            ForEach(this.fileMenuItems(file), (item: PanMenuItem) => {
                MenuItem({ content: item.title })
                    .onClick(item.action)
            }, (item: PanMenuItem) => item.title)
        }
    }
}
