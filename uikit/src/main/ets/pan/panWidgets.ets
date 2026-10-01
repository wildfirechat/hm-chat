/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 网盘共享 UI 小组件：文件图标、空态、命名对话框。
 */

import { FontSize, Radius } from '../common/design/Tokens'

/** 按文件名/扩展名返回文件图标资源（文件夹用文件夹图标） */
export function panFileIcon(name: string, isFolder: boolean): Resource {
    if (isFolder) {
        return $r('app.media.ic_pan_folder');
    }
    let ext = '';
    if (name) {
        let idx = name.lastIndexOf('.');
        ext = idx > 0 ? name.substring(idx + 1).toLowerCase() : '';
    }
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].includes(ext)) {
        return $r('app.media.ic_file_type_image');
    }
    if (['mp4', 'avi', 'mov', 'mkv', 'wmv', 'mpeg', 'rmvb'].includes(ext)) {
        return $r('app.media.ic_file_type_video');
    }
    if (['mp3', 'wav', 'aac', 'flac', 'amr'].includes(ext)) {
        return $r('app.media.ic_file_type_audio');
    }
    if (ext === 'pdf') {
        return $r('app.media.ic_file_type_pdf');
    }
    if (['doc', 'docx'].includes(ext)) {
        return $r('app.media.ic_file_type_word');
    }
    if (['xls', 'xlsx', 'csv'].includes(ext)) {
        return $r('app.media.ic_file_type_xls');
    }
    if (['ppt', 'pptx'].includes(ext)) {
        return $r('app.media.ic_file_type_ppt');
    }
    if (['htm', 'html'].includes(ext)) {
        return $r('app.media.ic_file_type_html');
    }
    if (['txt', 'md'].includes(ext)) {
        return $r('app.media.ic_file_type_text');
    }
    if (['zip', 'rar', '7z', 'gz', 'tar'].includes(ext)) {
        return $r('app.media.ic_file_type_zip');
    }
    if (ext === 'xml') {
        return $r('app.media.ic_file_type_xml');
    }
    if (['exe', 'apk', 'bat'].includes(ext)) {
        return $r('app.media.ic_file_type_exe');
    }
    return $r('app.media.ic_file_type_unknown');
}

/** 网盘空态/错误态 */
@Component
export struct PanEmptyView {
    @Prop message: string = ''
    @Prop showRetry: boolean = false
    onRetry?: () => void

    build() {
        Column() {
            Image($r('app.media.img_error'))
                .width(80)
                .height(80)
                .objectFit(ImageFit.Contain)
            Text(this.message)
                .fontSize(FontSize.sm)
                .fontColor($r('app.color.wf_tertiary_text'))
                .margin({ top: 12 })
                .textAlign(TextAlign.Center)
            if (this.showRetry) {
                Button('重试')
                    .type(ButtonType.Normal)
                    .fontSize(FontSize.sm)
                    .borderRadius(Radius.sm)
                    .margin({ top: 16 })
                    .onClick(() => {
                        this.onRetry?.()
                    })
            }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }
}

/**
 * 命名对话框：新建文件夹 / 重命名 / 新建文档共用。
 * 用法：new CustomDialogController({ builder: PanNameDialog({...}) })
 */
@CustomDialog
export struct PanNameDialog {
    controller: CustomDialogController
    title: string = '新建文件夹'
    placeholder: string = '请输入名称'
    defaultValue: string = ''
    confirmText: string = '确定'
    onConfirm?: (value: string) => void
    @State value: string = ''

    aboutToAppear() {
        this.value = this.defaultValue
    }

    build() {
        Column() {
            Text(this.title)
                .fontSize(FontSize.md)
                .fontColor($r('app.color.wf_primary_text'))
                .padding(20)

            TextInput({ placeholder: this.placeholder, text: this.value })
                .fontSize(FontSize.sm)
                .borderRadius(Radius.sm)
                .fontColor($r('app.color.wf_primary_text'))
                .placeholderColor($r('app.color.wf_tertiary_text'))
                .maxLines(1)
                .maxLength(120)
                .onChange((v: string) => {
                    this.value = v
                })

            Row() {
                Button('取消')
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .type(ButtonType.Normal)
                    .buttonStyle(ButtonStyleMode.TEXTUAL)
                    .onClick(() => {
                        this.controller.close()
                    })
                Button(this.confirmText)
                    .enabled(!!this.value)
                    .type(ButtonType.Normal)
                    .buttonStyle(ButtonStyleMode.TEXTUAL)
                    .onClick(() => {
                        this.onConfirm?.(this.value)
                        this.controller.close()
                    })
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
            .margin({ top: 20 })
        }
        .padding({ top: 12, bottom: 12, left: 20, right: 20 })
        .margin({ left: 40, right: 40 })
    }
}
