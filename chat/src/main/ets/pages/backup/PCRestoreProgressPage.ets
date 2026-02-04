//
// PCRestoreProgressPage.ets
// hm-chat
//
// PC恢复进度页面
// 显示从PC端恢复的进度（与iOS保持一致）
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { appNavigationDestinations } from '../mainNavigationConfig'
import type { RestoreResult, ConversationMetadata, BackupStatistics } from '@wfc/client/src/main/ets/wfc/backup/backupTypes'
import { MessageBackupManager } from '@wfc/client/src/main/ets/wfc/backup/messageBackupManager'
import { BackupError } from '@wfc/client/src/main/ets/wfc/backup/backupTypes'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import fs from '@ohos.file.fs'
import http from '@ohos.net.http'

// 元数据接口
interface BackupMetadata {
  conversations: ConversationMetadata[]
  statistics: BackupStatistics
}

interface PCBackupInfo {
  name: string
  path: string
  time: string
  deviceName: string
  fileCount: number
  conversationCount: number
  messageCount: number
  mediaFileCount: number
}

@Preview
@Component
export default struct PCRestoreProgressPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State backupInfo: PCBackupInfo | null = null
  @State serverIP: string = ''
  @State serverPort: number = 0
  @State currentStep: string = '准备中...'
  @State detail: string = ''
  @State progress: number = 0
  @State isRestoreComplete: boolean = false
  @State restoreSuccess: boolean = false
  private backupManager: MessageBackupManager = MessageBackupManager.getInstance()
  private tempRestoreDir: string = ''

  async aboutToAppear() {
    this.backupManager.setWfcManager(wfc)
    // 不要在这里调用startRestore，因为此时参数还没有通过onReady传递过来
  }

  async startRestore() {
    try {
      if (!this.backupInfo) {
        showToast('备份信息无效')
        this.mainNavPathStack.pop()
        return
      }

      // 步骤1: 下载元数据
      this.currentStep = '正在下载备份信息'
      this.detail = '正在连接到电脑...'
      await this.downloadMetadata()
    } catch (error) {
      console.error('Restore failed:', JSON.stringify(error))
      this.showError('恢复过程中发生错误')
    }
  }

  async downloadMetadata() {
    try {
      const encodedPath = encodeURIComponent(this.backupInfo!.path)
      const url = `http://${this.serverIP}:${this.serverPort}/restore_metadata?path=${encodedPath}`
      const httpRequest = http.createHttp()

      console.log(`[PCRestoreProgressPage] Fetching metadata from: ${url}`)

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 30000,
        readTimeout: 30000
      })

      console.log(`[PCRestoreProgressPage] Metadata response code: ${response.responseCode}`)

      if (response.responseCode === 200 && typeof response.result === 'string') {
        const metadata = JSON.parse(response.result) as BackupMetadata

        console.log(`[PCRestoreProgressPage] Metadata parsed: ${JSON.stringify(metadata)}`)

        // 显示备份信息
        this.currentStep = '准备恢复'
        this.detail = `共 ${metadata.conversations.length} 个会话，${metadata.statistics.totalMessages} 条消息`

        await this.showConfirmDialog(metadata)
      } else {
        console.error(`[PCRestoreProgressPage] Failed to download metadata, code: ${response.responseCode}`)
        this.showError('下载备份信息失败')
      }
    } catch (error) {
      console.error('[PCRestoreProgressPage] Failed to download metadata:', JSON.stringify(error))
      this.showError('下载备份信息失败')
    }
  }

  async showConfirmDialog(metadata: BackupMetadata): Promise<void> {
    return new Promise((resolve) => {
      AlertDialog.show({
        title: '确认恢复',
        message: `备份时间：${this.backupInfo!.time}\n会话数：${metadata.conversations.length}\n消息数：${metadata.statistics.totalMessages}\n\n恢复将覆盖现有数据，确定要继续吗？`,
        primaryButton: {
          value: '取消',
          action: () => {
            this.mainNavPathStack.pop()
            resolve()
          }
        },
        secondaryButton: {
          value: '开始恢复',
          fontColor: Color.Red,
          action: () => {
            this.downloadAllFiles(metadata)
            resolve()
          }
        }
      })
    })
  }

  async downloadAllFiles(metadata: BackupMetadata) {
    try {
      // 创建临时目录
      const appPath = wfc.getAppPath()
      this.tempRestoreDir = `${appPath}/temp_restore_${Date.now()}`
      fs.mkdirSync(this.tempRestoreDir)

      console.log(`[PCRestoreProgressPage] Downloading files to: ${this.tempRestoreDir}`)

      // 收集需要下载的文件
      const filesToDownload: string[] = []

      // 首先添加metadata.json
      filesToDownload.push('metadata.json')

      // 添加会话文件
      for (const conv of metadata.conversations) {
        const directory = conv.directory
        // 会话的messages.json文件
        filesToDownload.push(`conversations/${directory}/messages.json`)

        // 添加媒体文件
        if (conv.mediaFiles && conv.mediaFiles.length > 0) {
          console.log(`[PCRestoreProgressPage] Found ${conv.mediaFiles.length} media files for ${directory}`)
          for (const mediaFile of conv.mediaFiles) {
            // 媒体文件路径：conversations/{directory}/media/{mediaFile}
            filesToDownload.push(`conversations/${directory}/media/${mediaFile}`)
          }
        }
      }

      const totalFiles = filesToDownload.length
      let downloadedFiles = 0

      console.log(`[PCRestoreProgressPage] Total files to download: ${totalFiles}`)

      this.currentStep = '正在同步文件'
      this.detail = `准备下载 ${totalFiles} 个文件`

      // 顺序下载文件
      for (let i = 0; i < filesToDownload.length; i++) {
        const relativePath = filesToDownload[i]
        const downloadProgress = Math.floor((i / totalFiles) * 50)  // 下载占0-50%
        this.progress = downloadProgress
        this.detail = `下载文件 ${i + 1}/${totalFiles}`

        const success = await this.downloadFile(relativePath)
        if (!success) {
          console.error(`Failed to download file: ${relativePath}`)
          // 继续下载下一个文件
        }

        downloadedFiles = i + 1
      }

      // 所有文件下载完成，开始恢复
      await this.restoreBackup()
    } catch (error) {
      console.error('Failed to download files:', JSON.stringify(error))
      this.showError('下载文件失败')
    }
  }

  async downloadFile(relativePath: string): Promise<boolean> {
    try {
      const fullPath = `${this.backupInfo!.path}/${relativePath}`
      const encodedPath = encodeURIComponent(fullPath)
      const url = `http://${this.serverIP}:${this.serverPort}/restore_file?path=${encodedPath}`

      console.log(`[PCRestoreProgressPage] Downloading: ${relativePath}`)
      console.log(`[PCRestoreProgressPage] URL: ${url}`)

      const httpRequest = http.createHttp()

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 120000,
        readTimeout: 120000
      })

      console.log(`[PCRestoreProgressPage] Response code: ${response.responseCode}`)

      if (response.responseCode === 200 && response.result instanceof ArrayBuffer) {
        // 保存文件到临时目录
        const savePath = `${this.tempRestoreDir}/${relativePath}`

        // 递归创建目录
        const dirs = relativePath.split('/')
        let currentPath = this.tempRestoreDir
        for (let i = 0; i < dirs.length - 1; i++) {
          currentPath = `${currentPath}/${dirs[i]}`
          try {
            fs.mkdirSync(currentPath)
            console.log(`[PCRestoreProgressPage] Created directory: ${currentPath}`)
          } catch (e) {
            // 目录可能已存在，这是正常的
            console.log(`[PCRestoreProgressPage] Directory exists or created: ${currentPath}`)
          }
        }

        // 写入文件
        const file = fs.openSync(savePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
        fs.writeSync(file.fd, response.result)
        fs.closeSync(file)

        console.log(`[PCRestoreProgressPage] Saved to: ${savePath}`)
        return true
      } else {
        console.error(`[PCRestoreProgressPage] Download failed for ${relativePath}, code: ${response.responseCode}`)
      }

      return false
    } catch (error) {
      console.error(`[PCRestoreProgressPage] Failed to download file ${relativePath}:`, JSON.stringify(error))
      return false
    }
  }

  async restoreBackup() {
    try {
      this.currentStep = '正在导入数据'
      this.detail = '正在恢复消息...'

      // 使用备份管理器恢复
      const result = await this.backupManager.restoreFromBackup(
        this.tempRestoreDir,
        wfc.getUserId(),  // 使用用户ID作为密码
        false,  // 不覆盖现有消息
        (progress: number, current: string) => {
          // 恢复占50-100%
          const displayProgress = 50 + Math.floor(progress /2)
          this.progress = displayProgress
          this.detail = current
        }
      )

      this.isRestoreComplete = true
      this.restoreSuccess = result.success

      if (result.success) {
        this.currentStep = '恢复完成'
        this.progress = 100
        this.detail = `已恢复 ${result.messageCount} 条消息`
        await this.showSuccessDialog(result)
      } else {
        this.showError(this.getErrorMessage(result.error))
      }
    } catch (error) {
      console.error('Failed to restore backup:', JSON.stringify(error))
      this.showError('恢复失败')
    }
  }

  async showSuccessDialog(result: RestoreResult) {
    let message = `已成功恢复 ${result.messageCount} 条消息`
    if (result.mediaCount > 0) {
      message += `\n${result.mediaCount} 个媒体文件`
    }

    AlertDialog.show({
      title: '恢复成功',
      message: message,
      confirm: {
        value: '确定',
        action: () => {
          this.mainNavPathStack.popToName(appNavigationDestinations.BackupAndRestorePage)
        }
      }
    })
  }

  showError(message: string) {
    this.isRestoreComplete = true
    this.restoreSuccess = false
    this.currentStep = '恢复失败'
    this.detail = message
    this.progress = 100

    AlertDialog.show({
      title: '恢复失败',
      message: message,
      confirm: {
        value: '确定',
        action: () => {
          this.mainNavPathStack.pop()
        }
      }
    })
  }

  getErrorMessage(errorCode?: BackupError): string {
    if (!errorCode) {
      return '恢复过程中发生错误'
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
      case BackupError.RestoreFailed:
        return '恢复失败'
      default:
        return `未知错误 (错误码: ${errorCode})`
    }
  }

  aboutToDisappear() {
    // 清理临时文件
    if (this.tempRestoreDir && this.tempRestoreDir.length > 0) {
      try {
        // TODO: 删除临时目录
      } catch (error) {
        console.error('Failed to cleanup temp directory:', JSON.stringify(error))
      }
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
          if (!this.isRestoreComplete) {
            Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
              .width('80%')
              .height(4)
              .color('#4CD964')
              .margin({ top: 40 })
          }
        }
        .layoutWeight(1)
        .width('100%')

        // 取消按钮
        if (!this.isRestoreComplete) {
          Button('取消')
            .width('80%')
            .fontSize(16)
            .type(ButtonType.Normal)
            .margin({ bottom: 40 })
            .onClick(() => {
              this.mainNavPathStack.pop()
            })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')
    }
    .title('从电脑恢复')
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      // 接收参数
      const params = context.pathInfo.param as Record<string, Object>
      if (params) {
        if (params['backupInfo']) {
          this.backupInfo = params['backupInfo'] as PCBackupInfo
        }
        if (params['serverIP']) {
          this.serverIP = params['serverIP'] as string
        }
        if (params['serverPort']) {
          this.serverPort = params['serverPort'] as number
        }
      }

      // 参数接收完成后，开始恢复
      this.startRestore()
    })
  }
}
