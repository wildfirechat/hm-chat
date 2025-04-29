import { BackupExtensionAbility, BundleVersion, ReadTextOptions } from '@kit.CoreFileKit';
import { contextConstant } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { JSON, util, xml } from '@kit.ArkTS';

const TAG = `BackupExtensionAbility`;

/**
 * serviceExt进程入口
 */
export default class BackupExtension extends BackupExtensionAbility {
    onBackup() {
        console.log(TAG, `onBackup ok`);
    }

    /**
     * 数据恢复处理接口。接口是同步接口，其内部所有的异步操作请进行同步等待。
     *
     * @param bundleVersion 版本信息
     */
    async onRestore(bundleVersion: BundleVersion): Promise<void> {
        console.log(TAG, `onRestore ${JSON.stringify(bundleVersion)}`);
        if (bundleVersion.name.startsWith("0.0.0.0")) {
            this.context.area = contextConstant.AreaMode.EL2;

            // 设置要迁移APK包的包名, 需要替换为需要迁移的APK的，下面为示例
            let apkPackageName = "cn.wildfirechat.chat";
            // 鸿蒙版本包名
            let hapPackageName = 'cn.wildfirechat.messenger.open';

            let ceSourcePath = this.context.backupDir + `restore/${apkPackageName}/ce/`;

            // 其中<USERID>当前固定为100, 参考文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/app-sandbox-directory-V5#应用沙箱路径和真实物理路径的对应关系
            const userId = 100;

            // 定义要迁移的APK沙箱目录
            //let apkSourcePath = ceSourcePath + "data/user/" + userId + "/" + apkPackageName + "/";
            let apkSourcePath = ceSourcePath;
            let filesDirPath = apkSourcePath + "/files/"
            console.log(TAG, apkSourcePath, fs.accessSync(ceSourcePath))
            if (fs.accessSync(ceSourcePath)) {
                // 需要迁移 files/{用户id} 目录
                let fileNames = fs.listFileSync(filesDirPath)
                console.log(TAG, 'fileNames', fileNames.length)
                let dataDirName = ''
                for (const name of fileNames) {
                    let stat = fs.statSync(filesDirPath + name)
                    if (stat.isDirectory() && name !== 'xlog' && name !== 'sticker') {
                        dataDirName = name;
                        break
                    }
                }

                const clientIdFileName = '.wfcClientId'
                const wildfirechatDir = 'wildfirechat/'
                const dataDir = 'data/'

                // 迁移 APK 沙箱目录 files 文件夹下的文件及文件夹到目标文件夹
                const fileDestDir = this.context.getApplicationContext().filesDir + "/";
                console.log(TAG, "fileDestDir: " + fileDestDir);
                console.log(TAG, "start to move db folder");
                await this.moveDirToTargetDir(filesDirPath + dataDirName, fileDestDir + wildfirechatDir + dataDir);
                console.log(TAG, "end to move db folder");
                console.log(TAG, "start to move file");
                await this.moveFileToTargetPath(filesDirPath + clientIdFileName, fileDestDir + wildfirechatDir + 'uuid');
                console.log(TAG, "start to move file");

                // preference
                // shared_prefs -> preference

                // config.xml
                // WFC_OK_HTTP_COOKIES.xml

                const configPath = apkSourcePath + 'shared_prefs/config.xml'
                const cookiePath = apkSourcePath + 'shared_prefs/WFC_OK_HTTP_COOKIES.xml'

                let prefsArrayBuffer = new ArrayBuffer(1024 * 2);
                let prefsXmlSerializer = new xml.XmlSerializer(prefsArrayBuffer, "utf-8");
                prefsXmlSerializer.setDeclaration()
                prefsXmlSerializer.startElement('preferences')
                prefsXmlSerializer.setAttributes('version', '1.0')
                let stat = fs.statSync(configPath);
                let readTextOptions: ReadTextOptions = {
                    offset: 0,
                    length: stat.size,
                    encoding: 'utf-8'
                };

                let configStr = fs.readTextSync(configPath, readTextOptions);
                let textEncoder = new util.TextEncoder();
                let arrbuffer = textEncoder.encodeInto(configStr);
                let parser = new xml.XmlPullParser(arrbuffer.buffer as ArrayBuffer, 'UTF-8')

                let found = false
                let tagFunc = (key: string, value: string) => {
                    if (found) {
                        found = false
                        prefsXmlSerializer.setText(value)
                        prefsXmlSerializer.endElement()
                    }
                    return true
                }
                let attrFunc = (key: string, value: string) => {
                    if (value === 'id') {
                        prefsXmlSerializer.startElement('string')
                        prefsXmlSerializer.setAttributes('key', 'userId')
                        found = true
                    } else if (value === 'token') {
                        prefsXmlSerializer.startElement('string')
                        prefsXmlSerializer.setAttributes('key', 'token')
                        found = true
                    } else if (value.startsWith('authToken:')) {
                        prefsXmlSerializer.startElement('string')
                        prefsXmlSerializer.setAttributes('key', value)
                        found = true
                    }
                    return true
                }
                let options: xml.ParseOptions = {
                    supportDoctype: true,
                    ignoreNameSpace: false,
                    tagValueCallbackFunction: tagFunc,
                    attributeValueCallbackFunction: attrFunc
                }
                parser.parse(options)

                stat = fs.statSync(cookiePath);
                readTextOptions.length = stat.size
                let cookieStr = fs.readTextSync(cookiePath, readTextOptions);
                textEncoder = new util.TextEncoder();
                arrbuffer = textEncoder.encodeInto(cookieStr);
                parser = new xml.XmlPullParser(arrbuffer.buffer as ArrayBuffer, 'UTF-8')

                parser.parse(options)

                prefsXmlSerializer.endElement()

                const prefsDestDir = this.context.getApplicationContext().preferencesDir + "/";
                let prefsFile = fs.openSync(prefsDestDir + 'wfcstore', fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
                fs.writeSync(prefsFile.fd, prefsArrayBuffer, {
                    length: prefsArrayBuffer.byteLength
                })
                fs.close(prefsFile)
            }
            console.log(TAG, `HarmonyOS to HarmonyOS NEXT scenario`);
        } else {
            // 在此处实现从HarmonyOS NEXT设备迁移到HarmonyOS NEXT设备后，应用数据的处理。无特殊要求，可以空实现
            // 涉及异步操作请进行同步等待
            console.log(TAG, `Other scenario`);
        }
    }

    async moveFileToTargetPath(sourcePath: string, destPath: string) {
        try {
            // 若mode为0，移动位置存在同名文件时，强制移动覆盖。
            await fs.moveFile(sourcePath, destPath);
        } catch (e) {
            console.log(TAG, "moveFileToTargetPath: " + JSON.stringify(e));
        }
    }

    async moveDirToTargetDir(sourceDir: string, destDir: string) {
        if (fs.accessSync(sourceDir)) {
            if (!fs.accessSync(destDir)) {
                fs.mkdirSync(destDir, true);
            }
        }
        try {
            // mode为2，文件级别强制覆盖。目标文件夹下存在与源文件夹名冲突的文件夹，若冲突文件夹下存在同名文件，则强制覆盖冲突文件夹下所有同名文件，未冲突文件将继续保留。
            console.log(TAG, sourceDir + " to " + destDir);
            await fs.moveDir(sourceDir, destDir, 2);
        } catch (e) {
            console.log(TAG, "moveDirToTargetDir: " + JSON.stringify(e));
        }
    }

    getTargetDestDir(): string {
        const filesDir = this.context.getApplicationContext().filesDir;
        console.log(TAG, "getTargetDestDir: " + filesDir);
        let lastPosition = filesDir.lastIndexOf('/files');
        return lastPosition != -1 ? filesDir.substring(0, lastPosition) : filesDir;
    }
}