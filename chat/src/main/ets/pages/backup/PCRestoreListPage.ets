//
// PCRestoreListPage.ets
// hm-chat
//
// PC恢复列表页面
// 显示PC端的备份列表（与iOS保持一致）
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { appNavigationDestinations } from '../mainNavigationConfig'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import http from '@ohos.net.http'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import RestoreRequestNotificationContent from '@wfc/client/src/main/ets/wfc/messages/backup/restoreRequestNotificationContent'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import Long from '@wfc/client/src/main/ets/wfc/util/long'

// 恢复请求接口
interface RestoreRequestContent {
  timestamp: number
}

// 恢复响应类
class RestoreResponseContent {
  type: number = 0
  approved: boolean = false
  ip: string = ''
  port: number = 0
}

// 类型转换辅助函数
function toRestoreResponseContent(content: ESObject | null | undefined): RestoreResponseContent {
  if (!content) {
    return new RestoreResponseContent()
  }
  const result = new RestoreResponseContent()
  // 直接从ESObject中获取属性
  const contentObj = content as Record<string, Object>
  if (contentObj['type'] !== undefined) {
    result.type = contentObj['type'] as number
  }
  if (contentObj['approved'] !== undefined) {
    result.approved = contentObj['approved'] as boolean
  }
  if (contentObj['serverIP'] !== undefined) {
    result.ip = contentObj['serverIP'] as string
  }
  if (contentObj['serverPort'] !== undefined) {
    result.port = contentObj['serverPort'] as number
  }
  return result
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
export default struct PCRestoreListPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State isLoading: boolean = true
  @State isWaitingResponse: boolean = true
  @State backupList: PCBackupInfo[] = []
  @State errorMessage: string = ''
  @State serverIP: string = ''
  @State serverPort: number = 0
  private timeoutTimer: number = -1

  async aboutToAppear() {
    await this.sendRestoreRequest()
  }

  async sendRestoreRequest() {
    // 启动超时计时器（30秒）
    this.timeoutTimer = setTimeout(() => {
      if (this.isWaitingResponse) {
        this.onTimeout()
      }
    }, 30000)

    // 监听PC端响应
    wfc.eventEmitter?.on(EventType.ReceiveMessage, this.onReceiveMessage)

    try {
      // 创建恢复请求通知
      const requestContent: RestoreRequestContent = {
        timestamp: Date.now()
      }

      // 发送恢复请求消息（类型610）
      await this.sendRestoreRequestToPC(wfc.getUserId(), requestContent)
    } catch (error) {
      console.error('Failed to send restore request:', JSON.stringify(error))
      this.showError('发送恢复请求失败')
    }
  }

  async sendRestoreRequestToPC(userId: string, content: RestoreRequestContent): Promise<void> {
    // 创建会话对象（发送给自己，PC端会收到）
    const conversation = new Conversation(0, userId, 0)

    // 创建恢复请求消息内容
    const messageContent = RestoreRequestNotificationContent.create(content.timestamp)

    // 发送消息
    try {
      await wfc.sendConversationMessage(
        conversation,
        messageContent,
        [],
        null,  // preparedCB
        null,  // progressCB
        null,  // uploadedCB
        (messageUid: Long, timestamp: number) => {
          console.log('Restore request sent successfully')
        },
        (errorCode: number) => {
          console.error('Failed to send restore request:', errorCode)
          // 错误在回调中处理，不需要throw
        }
      )
    } catch (error) {
      console.error('Send restore request error:', JSON.stringify(error))
      // 重新抛出Error类型
      throw new Error('发送恢复请求失败')
    }
  }

  onReceiveMessage = (messages: Message[], hasMore: boolean) => {
    if (this.isWaitingResponse) {
      for (const msg of messages) {
        // 检查是否是恢复响应消息（类型611）
        if (msg.messageContent && msg.messageContent.type === 611) {
          const response = toRestoreResponseContent(msg.messageContent as ESObject)
          this.clearTimeout()

          if (response.approved) {
            // PC端同意
            this.onRestoreApproved(response)
          } else {
            // PC端拒绝
            this.onRestoreRejected()
          }
          break
        }
      }
    }
  }

  onRestoreApproved(response: RestoreResponseContent) {
    this.isWaitingResponse = false
    this.serverIP = response.ip
    this.serverPort = response.port

    this.isLoading = true
    this.errorMessage = ''

    // 获取备份列表
    this.fetchBackupList()
  }

  onRestoreRejected() {
    this.isWaitingResponse = false
    this.isLoading = false

    this.errorMessage = '电脑端拒绝了恢复请求'
    this.backupList = []

    setTimeout(() => {
      this.mainNavPathStack.pop()
    }, 2000)
  }

  onTimeout() {
    this.isWaitingResponse = false
    this.isLoading = false

    this.errorMessage = '电脑端未在30秒内响应'
    this.backupList = []

    setTimeout(() => {
      this.mainNavPathStack.pop()
    }, 2000)
  }

  async fetchBackupList() {
    try {
      const url = `http://${this.serverIP}:${this.serverPort}/restore_list`
      const httpRequest = http.createHttp()

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 30000,
        readTimeout: 30000
      })

      if (response.responseCode === 200 && typeof response.result === 'string') {
        const backupList = JSON.parse(response.result) as PCBackupInfo[]
        this.backupList = backupList
        this.isLoading = false
      } else {
        this.showError('获取备份列表失败')
      }
    } catch (error) {
      console.error('Failed to fetch backup list:', JSON.stringify(error))
      this.showError('获取备份列表失败')
    }
  }

  showError(message: string) {
    this.isLoading = false
    this.isWaitingResponse = false
    this.errorMessage = message
    this.backupList = []

    showToast(message)
    setTimeout(() => {
      this.mainNavPathStack.pop()
    }, 2000)
  }

  selectBackup(backup: PCBackupInfo) {
    this.mainNavPathStack.pushPathByName(appNavigationDestinations.PCRestoreProgressPage, {
      'backupInfo': backup,
      'serverIP': this.serverIP,
      'serverPort': this.serverPort
    } as Record<string, Object>)
  }

  formatBackupTime(timeStr: string): string {
    try {
      const date = new Date(timeStr)
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
    } catch (e) {
      return timeStr
    }
  }

  clearTimeout() {
    if (this.timeoutTimer !== -1) {
      clearTimeout(this.timeoutTimer)
      this.timeoutTimer = -1
    }
  }

  aboutToDisappear() {
    this.clearTimeout()
    wfc.eventEmitter?.off(EventType.ReceiveMessage, this.onReceiveMessage)
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

            Text(this.isWaitingResponse ? '正在等待电脑端确认...' : '正在获取备份列表...')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 20 })
          }
          .width('100%')
          .height('100%')
        } else if (this.errorMessage.length > 0) {
          // 错误状态
          Column() {
            Text(this.errorMessage)
              .fontSize(16)
              .fontColor('#FF3B30')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
        } else if (this.backupList.length === 0) {
          // 空列表
          Column() {
            Text('电脑端没有可用的备份')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
        } else {
          // 备份列表
          List({ space: 0 }) {
            ForEach(this.backupList, (backup: PCBackupInfo) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(this.formatBackupTime(backup.time))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)

                    Text(`${backup.deviceName} • ${backup.conversationCount}个会话 • ${backup.messageCount}条消息`)
                      .fontSize(14)
                      .fontColor('#666666')
                      .margin({ top: 4 })

                    if (backup.mediaFileCount > 0) {
                      Text(`${backup.mediaFileCount}个媒体文件 • ${backup.fileCount}个文件`)
                        .fontSize(12)
                        .fontColor('#999999')
                        .margin({ top: 2 })
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding(16)
                .backgroundColor(Color.White)
                .onClick(() => {
                  this.selectBackup(backup)
                })
              }
            }, (backup: PCBackupInfo) => backup.path)
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
    .title('电脑端备份')
    .height('100%')
    .width('100%')
  }
}
