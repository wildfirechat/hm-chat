//
// BackupListPage.ets
// hm-chat
//
// 本地备份列表页面
// 显示所有可用的本地备份
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { appNavigationDestinations } from '../mainNavigationConfig'
import type { BackupInfo } from '@wfc/client/src/main/ets/wfc/backup'
import { MessageBackupManager } from '@wfc/client/src/main/ets/wfc/backup/messageBackupManager'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import fs from '@ohos.file.fs'

interface BackupInfoWithPath extends BackupInfo {
  backupPath: string;
}

@Preview
@Component
export default struct BackupListPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State backupList: BackupInfoWithPath[] = []
  @State isLoading: boolean = true
  private backupManager: MessageBackupManager = MessageBackupManager.getInstance()

  async aboutToAppear() {
    this.backupManager.setWfcManager(wfc)
    await this.loadBackupList()
  }

  async loadBackupList(): Promise<void> {
    try {
      this.isLoading = true

      // 使用应用文件目录
      const appPath: string = wfc.getAppPath()
      const backupRoot: string = `${appPath}/backups`

      console.log(`[BackupListPage] Loading backups from: ${backupRoot}`)
      console.log(`[BackupListPage] App path: ${appPath}`)

      // 检查备份根目录是否存在
      try {
        const stat = fs.statSync(backupRoot)
        console.log(`[BackupListPage] Backup root directory exists: ${stat.isDirectory()}`)
      } catch (e) {
        console.log(`[BackupListPage] Backup root directory does not exist: ${backupRoot}`)
      }

      // 获取备份目录列表（按文件系统顺序）
      const dirs = await this.getBackupDirectories(backupRoot)
      console.log(`[BackupListPage] Found ${dirs.length} directories starting with 'backup_'`)

      // 检查每个目录是否有效
      const backupListWithPath: BackupInfoWithPath[] = []
      for (let i = 0; i < dirs.length; i++) {
        const dir = dirs[i]
        console.log(`[BackupListPage] Checking backup: ${dir}`)
        const info = await this.backupManager.getBackupInfo(dir)
        if (info) {
          const backupInfo: BackupInfoWithPath = {
            format: info.format,
            isEncrypted: info.isEncrypted,
            version: info.version,
            backupTime: info.backupTime,
            userId: info.userId,
            deviceName: info.deviceName,
            totalConversations: info.totalConversations,
            totalMessages: info.totalMessages,
            mediaFileCount: info.mediaFileCount,
            mediaTotalSize: info.mediaTotalSize,
            hasPasswordHint: info.hasPasswordHint,
            backupPath: dir
          }
          backupListWithPath.push(backupInfo)
          console.log(`[BackupListPage] Added valid backup: ${dir}, backupTime: ${info.backupTime}`)
        } else {
          console.log(`[BackupListPage] Skipping corrupted backup: ${dir}`)
        }
      }

      // 检查是否有损坏的备份
      const validBackups = backupListWithPath.length
      const totalBackups = dirs.length
      if (totalBackups > validBackups) {
        console.log(`[BackupListPage] Warning: Found ${totalBackups - validBackups} corrupted backups`)
        showToast(`发现${totalBackups - validBackups}个损坏的备份，建议删除`)
      }

      // 按时间倒序排列
      this.backupList = backupListWithPath.sort((a: BackupInfoWithPath, b: BackupInfoWithPath): number => {
        return b.backupTime.localeCompare(a.backupTime)
      })

      console.log(`Loaded ${this.backupList.length} backups`)
    } catch (error) {
      console.error('Failed to load backup list:', JSON.stringify(error))
      showToast('加载备份列表失败')
    } finally {
      this.isLoading = false
    }
  }

  async getBackupDirectories(backupRoot: string): Promise<string[]> {
    const dirs: string[] = []
    try {
      const files = fs.listFileSync(backupRoot)
      console.log(`[BackupListPage] All files/dirs in backup root: ${JSON.stringify(files)}`)
      for (const file of files) {
        console.log(`[BackupListPage] Checking file: ${file}, starts with 'backup_': ${file.startsWith('backup_')}`)
        if (file.startsWith('backup_')) {
          dirs.push(`${backupRoot}/${file}`)
          console.log(`[BackupListPage] Added backup dir: ${backupRoot}/${file}`)
        }
      }
    } catch (error) {
      console.error('[BackupListPage] Failed to get backup directories:', JSON.stringify(error))
    }
    return dirs
  }

  formatDate(isoString: string): string {
    try {
      const date = new Date(isoString)
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
    } catch (e) {
      return isoString
    }
  }

  formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`
    }
  }

  selectBackup(backupInfo: BackupInfoWithPath): void {
    console.log(`[BackupListPage] selectBackup called`)
    console.log(`[BackupListPage] Selected backupPath: ${backupInfo.backupPath}`)
    console.log(`[BackupListPage] Selected backupTime: ${backupInfo.backupTime}`)
    console.log(`[BackupListPage] Full backupInfo:`, JSON.stringify(backupInfo))

    this.mainNavPathStack.pushPathByName(appNavigationDestinations.RestoreOptionsPage, {
      'backupInfo': backupInfo
    } as Record<string, Object>)
  }

  async deleteBackup(backupInfo: BackupInfoWithPath): Promise<void> {
    AlertDialog.show({
      title: '删除备份',
      message: `确定要删除 ${this.formatDate(backupInfo.backupTime)} 的备份吗？`,
      primaryButton: {
        value: '取消',
        action: () => {
          // 不做任何事
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: Color.Red,
        action: async () => {
          try {
            await this.backupManager.deleteBackup(backupInfo.backupPath)
            await this.loadBackupList()
            showToast('删除成功')
          } catch (error) {
            console.error('Failed to delete backup:', JSON.stringify(error))
            showToast('删除失败')
          }
        }
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isLoading) {
          // 加载中
          Column() {
            Progress({ value: 0, total: 100, type: ProgressType.Ring })
              .width(50)
              .height(50)
              .margin({ top: 100 })
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 20 })
          }
          .width('100%')
          .height('100%')
        } else if (this.backupList.length === 0) {
          // 空列表
          Column() {
            Text('暂无本地备份')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
        } else {
          // 备份列表
          List({ space: 0 }) {
            ForEach(this.backupList, (info: BackupInfoWithPath) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(`${this.formatDate(info.backupTime)}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                    Text(`${info.deviceName} · ${info.totalConversations}个会话 · ${info.totalMessages}条消息`)
                      .fontSize(14)
                      .fontColor('#666666')
                      .margin({ top: 4 })
                    if (info.mediaFileCount > 0) {
                      Text(`${info.mediaFileCount}个媒体文件 · ${this.formatFileSize(info.mediaTotalSize)}`)
                        .fontSize(12)
                        .fontColor('#999999')
                        .margin({ top: 2 })
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  // 删除按钮
                  Image($r('app.media.ic_delete'))
                    .width(24)
                    .height(24)
                    .fillColor('#FF3B30')
                    .margin({ left: 10 })
                    .onClick(() => {
                      this.deleteBackup(info)
                    })
                }
                .width('100%')
                .padding(16)
                .backgroundColor(Color.White)
                .onClick(() => {
                  this.selectBackup(info)
                })
              }
            }, (info: BackupInfoWithPath) => info.backupPath)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(Color.White)
          .divider({
            strokeWidth: 1,
            color: '#F7F7F7',
            startMargin: 16,
            endMargin: 16
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')
    }
    .title('本地备份')
    .height('100%')
    .width('100%')
  }
}
