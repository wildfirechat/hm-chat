//
// RestoreProgressPage.ets
// hm-chat
//
// 恢复进度页面
// 显示恢复进度，支持取消操作（与iOS保持一致）
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { appNavigationDestinations } from '../mainNavigationConfig'
import type { BackupInfo, RestoreResult } from '@wfc/client/src/main/ets/wfc/backup'
import { MessageBackupManager } from '@wfc/client/src/main/ets/wfc/backup/messageBackupManager'
import { BackupError } from '@wfc/client/src/main/ets/wfc/backup/backupTypes'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'

interface BackupInfoWithPath extends BackupInfo {
  backupPath: string;
}

@Preview
@Component
export default struct RestoreProgressPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State backupInfo: BackupInfoWithPath | null = null
  @State password: string = ''
  @State progress: number = 0
  @State currentStep: string = '准备中...'
  @State detail: string = ''
  @State isRestoreComplete: boolean = false
  @State restoreSuccess: boolean = false
  @State shouldStartRestore: boolean = false
  @State progressColor: string = '#4CD964'  // 默认绿色
  private backupManager: MessageBackupManager = MessageBackupManager.getInstance()
  private cancelled: boolean = false

  async aboutToAppear() {
    this.backupManager.setWfcManager(wfc)
    // 等待路由参数加载完成
    setTimeout(() => {
      this.shouldStartRestore = true
      this.startRestore()
    }, 100)
  }

  async startRestore() {
    if (!this.shouldStartRestore) {
      return
    }

    try {
      if (!this.backupInfo) {
        showToast('备份信息无效')
        this.mainNavPathStack.pop()
        return
      }

      // 如果没有传入密码，使用当前用户ID作为密码
      let restorePassword = this.password
      if (!restorePassword || restorePassword.length === 0) {
        restorePassword = wfc.getUserId()
      }

      console.log(`Starting restore from: ${this.backupInfo.backupPath}`)
      console.log(`Encrypted: ${this.backupInfo.isEncrypted}`)
      console.log(`Using password: ${restorePassword ? 'Yes' : 'No'}`)

      // 开始恢复
      const result = await this.backupManager.restoreFromBackup(
        this.backupInfo.backupPath,
        this.backupInfo.isEncrypted ? restorePassword : undefined,
        false, // 不覆盖现有消息
        (progress: number, current: string) => {
          // 进度回调
          this.progress = progress
          this.currentStep = current
          console.log(`Restore progress: ${this.progress}%, ${current}`)
        }
      )

      // 恢复完成
      this.isRestoreComplete = true
      this.restoreSuccess = result.success

      if (result.success) {
        this.currentStep = '恢复完成'
        this.progressColor = '#4CD964'  // 绿色
        await this.showSuccessDialog(result)
      } else {
        this.currentStep = '恢复失败'
        this.progressColor = '#FF3B30'  // 红色
        this.detail = this.getErrorMessage(result.error)
        await this.showFailureDialog()
      }
    } catch (error) {
      console.error('Restore failed:', JSON.stringify(error))
      this.isRestoreComplete = true
      this.restoreSuccess = false
      this.currentStep = '恢复失败'
      this.progressColor = '#FF3B30'  // 红色
      this.detail = '恢复过程中发生错误'
      await this.showFailureDialog()
    }
  }

  async showSuccessDialog(result: RestoreResult) {
    // iOS风格的成功对话框
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

  async showFailureDialog() {
    AlertDialog.show({
      title: '恢复失败',
      message: this.detail || '恢复过程中发生错误',
      confirm: {
        value: '确定',
        action: () => {
          this.mainNavPathStack.pop()
        }
      }
    })
  }

  cancelRestore() {
    if (this.isRestoreComplete) {
      this.mainNavPathStack.pop()
      return
    }

    AlertDialog.show({
      title: '确认取消',
      message: '确定要取消恢复吗？',
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
              .color(this.progressColor)
              .margin({ top: 40 })
          } else if (!this.restoreSuccess) {
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
        Button(this.isRestoreComplete ? '完成' : '取消恢复')
          .width('80%')
          .fontSize(16)
          .type(ButtonType.Normal)
          .margin({ bottom: 40 })
          .onClick(() => {
            if (this.isRestoreComplete) {
              this.mainNavPathStack.pop()
            } else {
              this.cancelRestore()
            }
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')
    }
    .title('恢复进度')
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      // 接收路由参数
      const params = context.pathInfo.param as Record<string, Object>
      console.log(`[RestoreProgressPage] onReady, params:`, JSON.stringify(params))
      if (params) {
        if (params['backupInfo']) {
          this.backupInfo = params['backupInfo'] as BackupInfoWithPath
          console.log(`[RestoreProgressPage] Received backupInfo, backupPath: ${this.backupInfo.backupPath}`)
        }
        if (params['password']) {
          this.password = params['password'] as string
          console.log(`[RestoreProgressPage] Received password`)
        }
      } else {
        console.log(`[RestoreProgressPage] No params`)
      }
      console.log(`[RestoreProgressPage] Final backupInfo: ${this.backupInfo ? this.backupInfo.backupPath : 'null'}`)
    })
  }
}
