//
// BackupProgressPage.ets
// hm-chat
//
// 备份进度页面
// 显示备份进度，支持取消操作（与iOS保持一致）
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { appNavigationDestinations } from '../mainNavigationConfig'
import type { BackupResult } from '@wfc/client/src/main/ets/wfc/backup'
import { MessageBackupManager } from '@wfc/client/src/main/ets/wfc/backup/messageBackupManager'
import { BackupError } from '@wfc/client/src/main/ets/wfc/backup/backupTypes'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import fs from '@ohos.file.fs'

@Preview
@Component
export default struct BackupProgressPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State conversations: ConversationInfo[] = []
  @State target: string = 'local'
  @State includeMedia: boolean = false
  @State password: string = ''
  @State passwordHint: string = ''
  @State progress: number = 0
  @State currentStep: string = '准备中...'
  @State detail: string = ''
  @State isBackupComplete: boolean = false
  @State backupSuccess: boolean = false
  @State progressColor: string = '#007AFF'  // 默认蓝色
  private backupManager: MessageBackupManager = MessageBackupManager.getInstance()
  private cancelled: boolean = false

  aboutToAppear() {
    // 设置WfcManager
    this.backupManager.setWfcManager(wfc)
  }

  async startBackup() {
    try {
      // 使用应用文件目录存放备份
      // 注意：应用卸载后此目录会被删除，如需保留备份请手动导出
      const appPath: string = wfc.getAppPath()
      const backupRoot: string = `${appPath}/backups`

      console.log(`[BackupProgressPage] App path: ${appPath}`)
      console.log(`[BackupProgressPage] Backup root: ${backupRoot}`)

      // 创建备份根目录
      try {
        fs.mkdirSync(backupRoot)
        console.log(`[BackupProgressPage] Backup root directory created: ${backupRoot}`)
      } catch (err) {
        // 目录可能已存在，忽略错误
        console.log(`[BackupProgressPage] Backup directory may already exist: ${JSON.stringify(err)}`)
      }

      // 生成备份文件夹名称（与iOS端保持一致：backup_yyyy-MM-dd_HH-mm-ss）
      const now = new Date()
      const year: number = now.getFullYear()
      const month: string = String(now.getMonth() + 1).padStart(2, '0')
      const day: string = String(now.getDate()).padStart(2, '0')
      const hour: string = String(now.getHours()).padStart(2, '0')
      const minute: string = String(now.getMinutes()).padStart(2, '0')
      const second: string = String(now.getSeconds()).padStart(2, '0')
      const folderName: string = `backup_${year}-${month}-${day}_${hour}-${minute}-${second}`
      const backupDir = `${backupRoot}/${folderName}`

      console.log(`[BackupProgressPage] Folder name: ${folderName}`)
      console.log(`[BackupProgressPage] Backup directory: ${backupDir}`)
      console.log(`[BackupProgressPage] Conversations: ${this.conversations.length}`)
      console.log(`[BackupProgressPage] Include media: ${this.includeMedia}`)

      // 使用用户ID作为默认密码
      const backupPassword = this.password && this.password.length > 0 ? this.password : wfc.getUserId()
      console.log(`[BackupProgressPage] Using password for backup: ${backupPassword ? 'Yes (length=' + backupPassword.length + ')' : 'No'}`)

      // 开始备份
      const result = await this.backupManager.createBackup(
        backupDir,
        this.conversations,
        backupPassword,  // 始终使用密码（用户输入或用户ID）
        this.passwordHint || undefined,
        (progress: number, current: string) => {
          // 进度回调
          this.progress = progress
          this.currentStep = current
          console.log(`Backup progress: ${this.progress}%, ${current}`)
        }
      )

      // 备份完成
      this.isBackupComplete = true
      this.backupSuccess = result.success

      console.log(`[BackupProgressPage] Backup completed, success: ${result.success}`)
      console.log(`[BackupProgressPage] Backup path: ${result.backupPath}`)

      if (result.success) {
        this.currentStep = '备份完成'
        this.progressColor = '#4CD964'  // 绿色
        this.detail = `已备份 ${result.messageCount} 条消息`
        if (result.mediaCount > 0) {
          this.detail += `\n${result.mediaCount} 个媒体文件 (${this.formatFileSize(result.mediaSize)})`
        }
        console.log(`[BackupProgressPage] Backup successful, path: ${result.backupPath}`)
        await this.showSuccessDialog(result)
      } else {
        this.currentStep = '备份失败'
        this.progressColor = '#FF3B30'  // 红色
        this.detail = this.getErrorMessage(result.error)
        await this.showFailureDialog()
      }
    } catch (error) {
      console.error('Backup failed:', JSON.stringify(error))
      this.isBackupComplete = true
      this.backupSuccess = false
      this.currentStep = '备份失败'
      this.progressColor = '#FF3B30'  // 红色
      this.detail = '备份过程中发生错误'
      await this.showFailureDialog()
    }
  }

  formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`
    }
  }

  async showSuccessDialog(result: BackupResult) {
    // iOS风格的成功对话框
    let message = `已成功备份 ${result.messageCount} 条消息`
    if (result.mediaCount > 0) {
      message += `\n${result.mediaCount} 个媒体文件 (${this.formatFileSize(result.mediaSize)})`
    }

    AlertDialog.show({
      title: '备份完成',
      message: message,
      confirm: {
        value: '确定',
        action: () => {
          this.mainNavPathStack.popToName(appNavigationDestinations.BackupAndRestorePage)
        }
      }
    })
  }

  async showFailureDialog() {
    AlertDialog.show({
      title: '备份失败',
      message: this.detail || '备份过程中发生错误',
      confirm: {
        value: '确定',
        action: () => {
          this.mainNavPathStack.pop()
        }
      }
    })
  }

  cancelBackup() {
    if (this.isBackupComplete) {
      this.mainNavPathStack.pop()
      return
    }

    AlertDialog.show({
      title: '确认取消',
      message: '确定要取消备份吗？',
      primaryButton: {
        value: '取消',
        action: () => {
          // 不做任何事
        }
      },
      secondaryButton: {
        value: '确定',
        fontColor: Color.Red,
        action: () => {
          this.backupManager.cancel()
          this.cancelled = true
          this.currentStep = '正在取消...'
          this.progressColor = '#FF9500'  // 橙色
          // 等待取消完成
          setTimeout(() => {
            this.mainNavPathStack.pop()
          }, 1000)
        }
      }
    })
  }

  /**
   * 获取错误消息（与iOS保持一致）
   */
  getErrorMessage(errorCode?: BackupError): string {
    if (!errorCode) {
      return '备份过程中发生错误'
    }

    switch (errorCode) {
      case BackupError.FileNotFound:
        return '备份文件不存在'
      case BackupError.InvalidFormat:
        return '备份格式无效'
      case BackupError.IOError:
        return '文件读写错误'
      case BackupError.OutOfSpace:
        return '存储空间不足'
      case BackupError.Cancelled:
        return '用户取消'
      case BackupError.EncryptionFailed:
        return '加密失败'
      case BackupError.DecryptionFailed:
        return '解密失败'
      case BackupError.WrongPassword:
        return '密码错误，请检查后重试'
      case BackupError.InvalidPassword:
        return '密码无效'
      default:
        return `未知错误 (错误码: ${errorCode})`
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 进度信息
        Column() {
          // 百分比
          Text(`${this.progress}%`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 60 })

          // 状态
          Text(this.currentStep)
            .fontSize(18)
            .margin({ top: 20 })

          // 详情
          Text(this.detail)
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 10 })

          // 进度条
          if (!this.isBackupComplete) {
            Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
              .width('80%')
              .height(4)
              .color(this.progressColor)
              .margin({ top: 40 })
          } else if (!this.backupSuccess) {
            // 失败时显示红色进度条
            Progress({ value: 100, total: 100, type: ProgressType.Linear })
              .width('80%')
              .height(4)
              .color(this.progressColor)
              .margin({ top: 40 })
          }
        }
        .layoutWeight(1)
        .width('100%')

        // 取消按钮
        Button(this.isBackupComplete ? '完成' : '取消备份')
          .width('80%')
          .fontSize(16)
          .type(ButtonType.Normal)
          .margin({ bottom: 40 })
          .onClick(() => {
            if (this.isBackupComplete) {
              this.mainNavPathStack.pop()
            } else {
              this.cancelBackup()
            }
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')
    }
    .title('创建备份')
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      // 接收传递过来的参数
      const params = context.pathInfo.param as Record<string, Object>
      if (params) {
        if (params['conversations']) {
          this.conversations = params['conversations'] as ConversationInfo[]
        }
        if (params['target']) {
          this.target = params['target'] as string
        }
        if (params['includeMedia']) {
          this.includeMedia = params['includeMedia'] as boolean
        }
        if (params['password']) {
          this.password = params['password'] as string
        }
        if (params['passwordHint']) {
          this.passwordHint = params['passwordHint'] as string
        }
        // 启动备份
        this.startBackup()
      }
    })
  }
}
