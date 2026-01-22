//
// RestoreOptionsPage.ets
// hm-chat
//
// 恢复选项页面
// 显示备份详细信息并开始恢复（与iOS保持一致）
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { appNavigationDestinations } from '../mainNavigationConfig'
import type { BackupInfo } from '@wfc/client/src/main/ets/wfc/backup'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'

interface BackupInfoWithPath extends BackupInfo {
  backupPath: string;
}

@Preview
@Component
export default struct RestoreOptionsPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State backupInfo: BackupInfoWithPath | null = null

  formatDate(isoString: string): string {
    try {
      const date = new Date(isoString)
      return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日 ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
    } catch (e) {
      return isoString
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

  startRestore() {
    // 使用当前用户ID作为密码
    const userId = wfc.getUserId()

    console.log(`[RestoreOptionsPage] startRestore called`)
    console.log(`[RestoreOptionsPage] backupInfo: ${this.backupInfo ? this.backupInfo.backupPath : 'null'}`)

    // 确认对话框（与iOS一致）
    AlertDialog.show({
      title: '确认恢复',
      message: '恢复将覆盖现有数据，确定要继续吗？',
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
          console.log(`[RestoreOptionsPage] User confirmed, navigating to RestoreProgressPage`)
          console.log(`[RestoreOptionsPage] Passing backupPath: ${this.backupInfo?.backupPath}`)
          this.mainNavPathStack.pushPathByName(appNavigationDestinations.RestoreProgressPage, {
            'backupInfo': this.backupInfo,
            'password': userId  // 使用用户ID作为密码
          } as Record<string, Object>)
        }
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        if (this.backupInfo) {
          // 备份信息Section
          Column() {
            // 备份时间
            Row() {
              Text('备份时间')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              Text(this.formatDate(this.backupInfo.backupTime))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
            }
            .width('100%')
            .padding(16)

            Divider()
              .color('#F7F7F7')

            // 备份设备
            Row() {
              Text('备份设备')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              Text(this.backupInfo.deviceName)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
            }
            .width('100%')
            .padding(16)

            Divider()
              .color('#F7F7F7')

            // 会话数量
            Row() {
              Text('会话数量')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              Text(`${this.backupInfo.totalConversations}`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
            }
            .width('100%')
            .padding(16)

            Divider()
              .color('#F7F7F7')

            // 消息数量
            Row() {
              Text('消息数量')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              Text(`${this.backupInfo.totalMessages}`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
            }
            .width('100%')
            .padding(16)

            if (this.backupInfo.mediaFileCount > 0) {
              Divider()
                .color('#F7F7F7')

              // 媒体文件
              Row() {
                Text('媒体文件')
                  .fontSize(16)
                  .fontColor('#666666')
                  .width(100)
                Text(`${this.backupInfo.mediaFileCount} (${this.formatFileSize(this.backupInfo.mediaTotalSize)})`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(16)
            }

            // 调试信息 - 显示备份路径
            Divider()
              .color('#F7F7F7')

            Row() {
              Text('备份路径')
                .fontSize(14)
                .fontColor('#999999')
                .width(100)
              Text(this.backupInfo.backupPath)
                .fontSize(12)
                .fontColor('#999999')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding(16)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(8)

          // 开始恢复按钮
          Button('开始恢复')
            .width('100%')
            .fontSize(16)
            .margin({ top: 30 })
            .onClick(() => {
              this.startRestore()
            })
        }
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .backgroundColor('#EDEDED')
    }
    .title('恢复选项')
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      // 接收路由参数
      const params = context.pathInfo.param as Record<string, Object>
      console.log(`[RestoreOptionsPage] onReady, params:`, JSON.stringify(params))
      if (params && params['backupInfo']) {
        this.backupInfo = params['backupInfo'] as BackupInfoWithPath
        console.log(`[RestoreOptionsPage] Received backupInfo, backupPath: ${this.backupInfo.backupPath}`)
      } else {
        console.log(`[RestoreOptionsPage] No backupInfo in params`)
      }
    })
  }
}
