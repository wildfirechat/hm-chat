import fs from '@ohos.file.fs';

export function copyFileUri(fileUri: string, dstPath: string) {
    let srcFile = fs.openSync(fileUri);
    let dstFile = fs.openSync(dstPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.copyFileSync(srcFile.fd, dstFile.fd);
    fs.closeSync(srcFile);
    fs.closeSync(dstFile);
}

export function fileSize(file: string): number {
    let stat = fs.statSync(file)
    return stat.size;
}

export function fileNameFromFileUri(fileUri: string) {
    if (!fileUri) {
        return ''
    }
    return fileUri.substring(fileUri.lastIndexOf('/') + 1)
}

export function exist(file: string): boolean {
    try {
        fs.statSync(file)
        return true;
    } catch (e) {
        console.error(e)
    }
    return false
}
