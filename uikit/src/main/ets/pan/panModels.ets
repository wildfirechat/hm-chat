/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 网盘数据模型。ArkTS 没有反射式的 JSON 映射，全部手工 fromJson。
 * 服务端两代契约并存：主键字段可能是 id（新）或 spaceId/fileId（旧），
 * type/spaceType 可能是字符串枚举（新）或数字（旧），解析时两者都兼容。
 */

export function panStr(v: Object | undefined | null): string {
    if (v === undefined || v === null) {
        return '';
    }
    if (typeof v === 'string') {
        return v as string;
    }
    return v.toString();
}

export function panNum(v: Object | undefined | null): number {
    if (v === undefined || v === null) {
        return 0;
    }
    if (typeof v === 'number') {
        return v as number;
    }
    if (typeof v === 'string') {
        let n = parseInt(v as string);
        return isNaN(n) ? 0 : n;
    }
    return 0;
}

export function panBool(v: Object | undefined | null): boolean {
    if (v === undefined || v === null) {
        return false;
    }
    return v === true;
}

export function panMap(v: Object | undefined | null): Record<string, Object> {
    if (v === undefined || v === null) {
        return {} as Record<string, Object>;
    }
    return v as Record<string, Object>;
}

export function panArray(v: Object | undefined | null): Record<string, Object>[] {
    if (v === undefined || v === null) {
        return [];
    }
    if (Array.isArray(v)) {
        return v as Record<string, Object>[];
    }
    return [];
}

/** 网盘空间类型（字符串枚举，兼容旧版数字） */
export class PanSpaceType {
    static GLOBAL_PUBLIC: string = 'GLOBAL_PUBLIC';
    static USER_PUBLIC: string = 'USER_PUBLIC';
    static USER_PRIVATE: string = 'USER_PRIVATE';
}

export class PanSpace {
    spaceId: number = 0;
    spaceType: string = PanSpaceType.GLOBAL_PUBLIC;
    ownerId: string = '';
    name: string = '';
    totalQuota: number = 0;
    usedQuota: number = 0;
    fileCount: number = 0;
    folderCount: number = 0;
    autoInit: boolean = false;
    createdAt: string = '';
    canManage: boolean = false;

    static fromJson(json: Record<string, Object>): PanSpace {
        let space = new PanSpace();
        space.spaceId = panNum(json['spaceId'] ?? json['id']);
        let rawType = json['spaceType'] ?? json['type'];
        if (typeof rawType === 'string') {
            space.spaceType = (rawType as string).toUpperCase();
        } else if (typeof rawType === 'number') {
            let t = rawType as number;
            space.spaceType = t === 2 ? PanSpaceType.USER_PRIVATE : (t === 1 ? PanSpaceType.USER_PUBLIC : PanSpaceType.GLOBAL_PUBLIC);
        }
        space.ownerId = panStr(json['ownerId']);
        space.name = panStr(json['name']);
        space.totalQuota = panNum(json['totalQuota']);
        space.usedQuota = panNum(json['usedQuota']);
        space.fileCount = panNum(json['fileCount']);
        space.folderCount = panNum(json['folderCount']);
        space.autoInit = panBool(json['autoInit']);
        space.createdAt = panStr(json['createdAt']);
        space.canManage = panBool(json['canManage']);
        return space;
    }

    /** 别人的公共空间只读，其余以服务端校验为准 */
    canWriteByOwner(userId: string): boolean {
        return this.spaceType !== PanSpaceType.USER_PUBLIC || this.ownerId === userId;
    }

    isPrivate(): boolean {
        return this.spaceType === PanSpaceType.USER_PRIVATE;
    }
}

export class PanFile {
    fileId: number = 0;
    spaceId: number = 0;
    parentId: number = 0;
    name: string = '';
    isFolder: boolean = false;
    size: number = 0;
    mimeType: string = '';
    md5: string = '';
    storageUrl: string = '';
    childCount: number = 0;
    creatorId: string = '';
    creatorName: string = '';
    createdAt: string = '';
    updatedAt: string = '';

    static fromJson(json: Record<string, Object>): PanFile {
        let file = new PanFile();
        file.fileId = panNum(json['fileId'] ?? json['id']);
        file.spaceId = panNum(json['spaceId']);
        file.parentId = panNum(json['parentId']);
        file.name = panStr(json['name']);
        let rawType = json['type'];
        if (typeof rawType === 'number') {
            file.isFolder = (rawType as number) === 1;
        } else {
            file.isFolder = panStr(rawType).toUpperCase() === 'FOLDER';
        }
        file.size = panNum(json['size']);
        file.mimeType = panStr(json['mimeType']);
        file.md5 = panStr(json['md5']);
        file.storageUrl = panStr(json['storageUrl']);
        file.childCount = panNum(json['childCount']);
        file.creatorId = panStr(json['creatorId']);
        file.creatorName = panStr(json['creatorName']);
        file.createdAt = panStr(json['createdAt']);
        file.updatedAt = panStr(json['updatedAt']);
        return file;
    }

    extension(): string {
        if (this.isFolder) {
            return '';
        }
        let idx = this.name.lastIndexOf('.');
        return idx > 0 ? this.name.substring(idx + 1).toLowerCase() : '';
    }

    canOpenOnline(): boolean {
        return !this.isFolder && PanDocFormats.isOnlineDocName(this.name);
    }
}

/** 在线文档能打开的格式，与服务端 DocsService 的 WORD / CELL / SLIDE / PDF 四组一致 */
export class PanDocFormats {
    static WORD: string[] = ['doc', 'docx', 'docm', 'dot', 'dotx', 'dotm', 'odt', 'ott', 'rtf', 'txt',
        'wps', 'wpt', 'fodt', 'mht', 'mhtml', 'htm', 'html', 'epub', 'fb2'];
    static CELL: string[] = ['xls', 'xlsx', 'xlsm', 'xlt', 'xltx', 'xltm', 'xlsb', 'ods', 'ots', 'csv',
        'et', 'ett', 'fods'];
    static SLIDE: string[] = ['ppt', 'pptx', 'pptm', 'pot', 'potx', 'potm', 'pps', 'ppsx', 'ppsm',
        'odp', 'otp', 'dps', 'dpt', 'fodp'];
    static PDF: string[] = ['pdf', 'djvu', 'xps', 'oxps'];
    // 可编辑格式，仅用于本地提示，真正权限由服务端 editor-config 决定
    static EDITABLE: string[] = ['docx', 'docm', 'xlsx', 'xlsm', 'pptx', 'pptm'];

    static isOnlineDocName(name: string): boolean {
        if (!name) {
            return false;
        }
        let idx = name.lastIndexOf('.');
        if (idx <= 0 || idx === name.length - 1) {
            return false;
        }
        let ext = name.substring(idx + 1).toLowerCase();
        return PanDocFormats.WORD.includes(ext) || PanDocFormats.CELL.includes(ext)
            || PanDocFormats.SLIDE.includes(ext) || PanDocFormats.PDF.includes(ext);
    }

    static isEditableDocName(name: string): boolean {
        if (!name) {
            return false;
        }
        let idx = name.lastIndexOf('.');
        if (idx <= 0 || idx === name.length - 1) {
            return false;
        }
        return PanDocFormats.EDITABLE.includes(name.substring(idx + 1).toLowerCase());
    }

    static kind(name: string): string {
        if (!name) {
            return 'other';
        }
        let idx = name.lastIndexOf('.');
        let ext = idx > 0 ? name.substring(idx + 1).toLowerCase() : '';
        if (PanDocFormats.WORD.includes(ext)) {
            return 'word';
        }
        if (PanDocFormats.CELL.includes(ext)) {
            return 'cell';
        }
        if (PanDocFormats.SLIDE.includes(ext)) {
            return 'slide';
        }
        if (PanDocFormats.PDF.includes(ext)) {
            return 'pdf';
        }
        return 'other';
    }
}

export class PanShareSource {
    isGroup: boolean = false;
    groupName: string = '';
    sharerName: string = '';

    static fromJson(json: Record<string, Object>): PanShareSource {
        let s = new PanShareSource();
        s.isGroup = panStr(json['targetType']) === 'GROUP';
        s.groupName = panStr(json['targetName']);
        s.sharerName = panStr(json['createdByName']);
        return s;
    }
}

/** 文档首页的一行：最近打开或共享给我的一个文件 */
export class PanDocEntry {
    file: PanFile = new PanFile();
    canEdit: boolean = false;
    time: string = '';
    sources: PanShareSource[] = [];

    static fromRecent(json: Record<string, Object>): PanDocEntry {
        let entry = new PanDocEntry();
        entry.file = PanFile.fromJson(panMap(json['file']));
        entry.canEdit = panStr(json['permission']) === 'EDIT';
        entry.time = panStr(json['openedAt']);
        return entry;
    }

    static fromShared(json: Record<string, Object>): PanDocEntry {
        let entry = new PanDocEntry();
        entry.file = PanFile.fromJson(panMap(json['file']));
        entry.canEdit = panStr(json['permission']) === 'EDIT';
        entry.time = panStr(json['sharedAt']);
        let list = panArray(json['sources']);
        entry.sources = list.map((item: Record<string, Object>) => PanShareSource.fromJson(item));
        return entry;
    }
}

/** 文件的一条分享 */
export class PanShare {
    id: number = 0;
    isGroup: boolean = false;
    targetId: string = '';
    targetName: string = '';
    canEdit: boolean = false;
    sharerName: string = '';
    time: string = '';

    static fromJson(json: Record<string, Object>): PanShare {
        let s = new PanShare();
        s.id = panNum(json['id']);
        s.isGroup = panStr(json['targetType']) === 'GROUP';
        s.targetId = panStr(json['targetId']);
        s.targetName = panStr(json['targetName']);
        s.canEdit = panStr(json['permission']) === 'EDIT';
        s.sharerName = panStr(json['createdByName']);
        s.time = panStr(json['createdAt']);
        return s;
    }
}

export class PanVersion {
    versionNo: number = 0;
    size: number = 0;
    editorName: string = '';
    source: string = '';
    createdAt: string = '';
    createdByName: string = '';

    static fromJson(json: Record<string, Object>): PanVersion {
        let v = new PanVersion();
        v.versionNo = panNum(json['versionNo']);
        v.size = panNum(json['size']);
        v.editorName = panStr(json['editorName']);
        v.source = panStr(json['source']);
        v.createdAt = panStr(json['createdAt']);
        v.createdByName = panStr(json['createdByName']);
        return v;
    }
}

/** 文档 H5 交给宿主标题栏画的页头 */
export class PanHeaderAction {
    id: string = '';
    text: string = '';
    icon: string = '';
    primary: boolean = false;

    static fromJson(json: Record<string, Object>): PanHeaderAction {
        let a = new PanHeaderAction();
        a.id = panStr(json['id']);
        a.text = panStr(json['text']);
        a.icon = panStr(json['icon']);
        a.primary = panBool(json['primary']);
        return a;
    }
}

export class PanPageHeader {
    title: string = '';
    subtitle: string = '';
    actions: PanHeaderAction[] = [];

    static fromJson(json: Record<string, Object>): PanPageHeader {
        let h = new PanPageHeader();
        h.title = panStr(json['title']);
        h.subtitle = panStr(json['subtitle']);
        let list = panArray(json['actions']);
        h.actions = list.map((item: Record<string, Object>) => PanHeaderAction.fromJson(item));
        return h;
    }
}
