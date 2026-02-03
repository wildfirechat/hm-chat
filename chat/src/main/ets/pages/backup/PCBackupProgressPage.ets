//
// PCBackupProgressPage.ets
// hm-chat
//
// PC备份进度页面
// 显示备份到PC端的进度（与iOS保持一致）
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { appNavigationDestinations } from '../mainNavigationConfig'
import type { BackupResult } from '@wfc/client/src/main/ets/wfc/backup'
import { MessageBackupManager } from '@wfc/client/src/main/ets/wfc/backup/messageBackupManager'
import { BackupError } from '@wfc/client/src/main/ets/wfc/backup/backupTypes'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import fs from '@ohos.file.fs'
import http from '@ohos.net.http'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { util } from '@kit.ArkTS'
import BackupRequestNotificationContent from '@wfc/client/src/main/ets/wfc/messages/backup/backupRequestNotificationContent'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import Long from '@wfc/client/src/main/ets/wfc/util/long'

// 会话信息接口
interface ConversationInfoData {
  type: number
  target: string
  line: number
}

// 定义会话数据接口
interface ConversationData {
  conversation: ConversationInfoData
  messageCount: number
}

// 备份请求接口
interface BackupRequestContent {
  conversations: ConversationData[]
  includeMedia: boolean
  timestamp: number
}

// 备份响应接口
class BackupResponseContent {
  type: number = 0
  approved: boolean = false
  ip: string = ''
  port: number = 0
}

// 类型转换辅助函数
function toBackupResponseContent(content: ESObject | null | undefined): BackupResponseContent {
  if (!content) {
    return new BackupResponseContent()
  }
  const result = new BackupResponseContent()
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

@Preview
@Component
export default struct PCBackupProgressPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State conversations: ConversationInfo[] = []
  @State includeMedia: boolean = false
  @State password: string = ''
  @State passwordHint: string = ''
  @State currentStep: string = '正在等待电脑端响应...'
  @State detail: string = '请在电脑端确认备份请求'
  @State isWaitingResponse: boolean = true
  @State isCreatingBackup: boolean = false
  @State isUploading: boolean = false
  @State isComplete: boolean = false
  @State serverIP: string = ''
  @State serverPort: number = 0
  @State uploadProgress: number = 0
  @State totalFiles: number = 0
  @State uploadedFiles: number = 0
  private backupManager: MessageBackupManager = MessageBackupManager.getInstance()
  private tempBackupDir: string = ''
  private timeoutTimer: number = -1

  async aboutToAppear() {
    this.backupManager.setWfcManager(wfc)
  }

  async startBackupRequest() {
    // 启动超时计时器（30秒）
    this.timeoutTimer = setTimeout(() => {
      if (this.isWaitingResponse) {
        this.onTimeout()
      }
    }, 30000)

    // 监听PC端响应
    wfc.eventEmitter?.on(EventType.ReceiveMessage, this.onReceiveMessage)

    // 准备并发送备份请求
    const userId = wfc.getUserId()

    // 构建会话列表数据
    const conversationsData: ConversationData[] = []
    for (const convInfo of this.conversations) {
      const conv = convInfo.conversation
      const messageCount = wfc.getMessageCount(conv)

      const convData: ConversationInfoData = {
        type: conv.type,
        target: conv.target,
        line: conv.line
      }

      const data: ConversationData = {
        conversation: convData,
        messageCount: messageCount
      }
      conversationsData.push(data)
    }

    // 创建备份请求通知
    const requestContent: BackupRequestContent = {
      conversations: conversationsData,
      includeMedia: this.includeMedia,
      timestamp: Date.now()
    }

    try {
      // 发送备份请求消息（类型613）
      await this.sendBackupRequest(userId, requestContent)
    } catch (error) {
      console.error('Failed to send backup request:', JSON.stringify(error))
      this.showError('发送备份请求失败')
    }
  }

  async sendBackupRequest(userId: string, content: BackupRequestContent): Promise<void> {
    // 创建会话对象（发送给自己，PC端会收到）
    const conversation = new Conversation(0, userId, 0)

    // 创建备份请求消息内容
    const messageContent = new BackupRequestNotificationContent()
    messageContent.conversationsJson = JSON.stringify(content.conversations)
    messageContent.includeMedia = content.includeMedia
    messageContent.timestamp = content.timestamp

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
          console.log('Backup request sent successfully')
        },
        (errorCode: number) => {
          console.error('Failed to send backup request:', errorCode)
          // 错误在回调中处理，不需要throw
        }
      )
    } catch (error) {
      console.error('Send backup request error:', JSON.stringify(error))
      // 重新抛出Error类型
      throw new Error('发送备份请求失败')
    }
  }

  onReceiveMessage = (messages: Message[], hasMore: boolean) => {
    if (this.isWaitingResponse) {
      for (const msg of messages) {
        // 检查是否是备份响应消息（类型612）
        if (msg.messageContent && msg.messageContent.type === 612) {
          const response = toBackupResponseContent(msg.messageContent as ESObject)
          this.clearTimeout()

          if (response.approved) {
            // PC端同意
            this.onBackupApproved(response)
          } else {
            // PC端拒绝
            this.onBackupRejected()
          }
          break
        }
      }
    }
  }

  onBackupApproved(response: BackupResponseContent) {
    this.isWaitingResponse = false
    this.serverIP = response.ip
    this.serverPort = response.port

    console.log(`[PCBackupProgressPage] Backup approved, IP: ${this.serverIP}, Port: ${this.serverPort}`)

    this.currentStep = '电脑端已同意备份'
    this.detail = `正在创建备份数据... 服务器: ${this.serverIP}:${this.serverPort}`

    // 验证IP和端口
    if (!this.serverIP || this.serverIP.length === 0) {
      console.error('[PCBackupProgressPage] Server IP is empty!')
      this.showError('服务器地址无效')
      return
    }
    if (this.serverPort <= 0 || this.serverPort > 65535) {
      console.error(`[PCBackupProgressPage] Invalid port: ${this.serverPort}`)
      this.showError('服务器端口无效')
      return
    }

    // 开始创建备份并上传
    this.createAndUploadBackup()
  }

  onBackupRejected() {
    this.isWaitingResponse = false
    this.isComplete = true

    this.currentStep = '备份请求被拒绝'
    this.detail = '电脑端拒绝了备份请求'

    setTimeout(() => {
      this.mainNavPathStack.pop()
    }, 2000)
  }

  onTimeout() {
    this.isWaitingResponse = false
    this.isComplete = true

    this.currentStep = '请求超时'
    this.detail = '电脑端未在30秒内响应'

    setTimeout(() => {
      this.mainNavPathStack.pop()
    }, 2000)
  }

  async createAndUploadBackup() {
    try {
      this.isCreatingBackup = true
      this.isWaitingResponse = false

      // 创建临时备份目录路径
      const appPath = wfc.getAppPath()
      this.tempBackupDir = `${appPath}/temp_backup_upload_${Date.now()}`

      console.log(`[PCBackupProgressPage] Starting backup to: ${this.tempBackupDir}`)

      // 创建备份（messageBackupManager会自动创建所需目录）
      const result = await this.backupManager.createBackup(
        this.tempBackupDir,
        this.conversations,
        this.password || undefined,
        this.passwordHint || undefined,
        (progress: number, current: string) => {
          this.detail = `正在备份: ${current}`
        }
      )

      console.log(`[PCBackupProgressPage] Backup result: ${JSON.stringify(result)}`)
      this.isCreatingBackup = false

      if (result.success) {
        // 备份创建成功，开始上传
        console.log(`[PCBackupProgressPage] Backup created successfully, starting upload...`)
        await this.uploadBackupToPC()
      } else {
        console.error(`[PCBackupProgressPage] Backup creation failed: ${result.error}`)
        this.showError(this.getBackupErrorMessage(result.error))
      }
    } catch (error) {
      console.error('[PCBackupProgressPage] Failed to create backup:', JSON.stringify(error))
      this.showError('创建备份失败')
    }
  }

  getBackupErrorMessage(errorCode?: number): string {
    if (!errorCode) {
      return '创建备份失败'
    }

    switch (errorCode) {
      case 1001:
        return '备份文件不存在'
      case 1002:
        return '备份格式无效'
      case 1003:
        return '文件读写错误'
      case 1004:
        return '存储空间不足'
      case 1005:
        return '用户取消'
      case 3001:
        return '加密失败'
      case 3002:
        return '解密失败'
      case 3003:
        return '密码错误'
      case 3004:
        return '密码无效'
      case 4001:
        return '恢复失败'
      default:
        return `创建备份失败 (错误码: ${errorCode})`
    }
  }

  async uploadBackupToPC() {
    try {
      this.isUploading = true
      this.currentStep = '正在上传备份到电脑端...'

      // 收集所有需要上传的文件
      const filesToUpload = this.collectFiles(this.tempBackupDir)
      this.totalFiles = filesToUpload.length
      this.detail = `共 ${this.totalFiles} 个文件等待上传`

      // 顺序上传文件
      for (let i = 0; i < filesToUpload.length; i++) {
        if (!this.isUploading) break

        const filePath = filesToUpload[i]
        const relativePath = filePath.substring(this.tempBackupDir.length + 1)

        const progress = Math.floor((i / this.totalFiles) * 100)
        this.currentStep = `正在上传... ${progress}%`
        this.detail = `文件 ${i + 1}/${this.totalFiles}`

        const success = await this.uploadFile(filePath, relativePath)
        if (!success) {
          this.showError('上传文件失败')
          return
        }

        this.uploadedFiles = i + 1
      }

      // 所有文件上传完成
      await this.sendCompletionRequest()
      this.onUploadSuccess()
    } catch (error) {
      console.error('Failed to upload backup:', JSON.stringify(error))
      this.showError('上传备份失败')
    }
  }

  collectFiles(dirPath: string): string[] {
    const files: string[] = []
    const items = fs.listFileSync(dirPath)

    for (const item of items) {
      const fullPath = `${dirPath}/${item}`
      const stat = fs.statSync(fullPath)

      if (stat.isDirectory()) {
        const subFiles = this.collectFiles(fullPath)
        files.push(...subFiles)
      } else {
        files.push(fullPath)
      }
    }

    return files
  }

  async uploadFile(filePath: string, relativePath: string): Promise<boolean> {
    try {
      const url = `http://${this.serverIP}:${this.serverPort}/backup`
      console.log(`[PCBackupProgressPage] Uploading file: ${relativePath} to ${url}`)

      const httpRequest = http.createHttp()

      // 读取文件数据
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY)
      const stat = fs.statSync(filePath)
      const buffer = new ArrayBuffer(stat.size)
      fs.readSync(file.fd, buffer)
      fs.closeSync(file)

      console.log(`[PCBackupProgressPage] File size: ${stat.size} bytes`)

      // 构建二进制协议数据
      const bodyData = this.buildUploadBody(relativePath, new Uint8Array(buffer))

      console.log(`[PCBackupProgressPage] Request body size: ${bodyData.byteLength} bytes`)

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/octet-stream'
        },
        extraData: bodyData,
        connectTimeout: 60000,
        readTimeout: 60000
      })

      console.log(`[PCBackupProgressPage] Upload response code: ${response.responseCode}`)

      if (response.responseCode !== 200) {
        console.error(`[PCBackupProgressPage] Upload failed, response: ${JSON.stringify(response)}`)
      }

      return response.responseCode === 200
    } catch (error) {
      console.error(`[PCBackupProgressPage] Failed to upload file ${relativePath}:`, JSON.stringify(error))
      return false
    }
  }

  buildUploadBody(relativePath: string, fileData: Uint8Array): ArrayBuffer {
    // 协议格式: [4字节路径长度(小端序)][路径UTF8][8字节文件长度(小端序)][文件数据]
    const textEncoder = new util.TextEncoder()
    const pathBytes = textEncoder.encodeInto(relativePath)
    const pathLength = pathBytes.byteLength
    const fileLength = fileData.byteLength

    const totalLength = 4 + pathLength + 8 + fileLength
    const result = new Uint8Array(totalLength)
    let offset = 0

    // 写入路径长度（4字节，小端序）
    const view = new DataView(result.buffer)
    view.setUint32(offset, pathLength, true)  // true = 小端序
    offset += 4

    // 写入路径
    result.set(pathBytes, offset)
    offset += pathLength

    // 写入文件长度（8字节，小端序）
    // 使用两个32位来模拟64位
    view.setUint32(offset, fileLength & 0xFFFFFFFF, true)
    offset += 4
    view.setUint32(offset, Math.floor(fileLength / 0x100000000), true)
    offset += 4

    // 写入文件数据
    result.set(fileData, offset)

    return result.buffer
  }

  async sendCompletionRequest(): Promise<void> {
    try {
      const url = `http://${this.serverIP}:${this.serverPort}/backup_complete`
      const httpRequest = http.createHttp()

      // 构建请求体：[4字节文件数(小端序)]
      const body = new ArrayBuffer(4)
      const view = new DataView(body)
      view.setUint32(0, this.uploadedFiles, true)  // 小端序

      await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/octet-stream'
        },
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 10000
      })

      console.log('Backup completion sent to PC')
    } catch (error) {
      console.error('Failed to send completion:', JSON.stringify(error))
    }
  }

  onUploadSuccess() {
    this.isUploading = false
    this.isComplete = true

    this.currentStep = '备份完成！'

    AlertDialog.show({
      title: '备份成功',
      message: '备份已成功上传到电脑端',
      confirm: {
        value: '确定',
        action: () => {
          this.mainNavPathStack.popToName(appNavigationDestinations.BackupAndRestorePage)
        }
      }
    })
  }

  showError(message: string) {
    this.isComplete = true
    this.isWaitingResponse = false
    this.isCreatingBackup = false
    this.isUploading = false

    this.currentStep = '操作失败'
    this.detail = message

    AlertDialog.show({
      title: '备份失败',
      message: message,
      confirm: {
        value: '确定',
        action: () => {
          this.mainNavPathStack.pop()
        }
      }
    })
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

    // 清理临时文件
    if (this.tempBackupDir && this.tempBackupDir.length > 0) {
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
          // 状态
          Text(this.currentStep)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 60 })

          // 详情
          Text(this.detail)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 20 })

          // 上传进度
          if (this.isUploading && this.totalFiles > 0) {
            Progress({ value: this.uploadedFiles, total: this.totalFiles, type: ProgressType.Linear })
              .width('80%')
              .height(4)
              .color('#007AFF')
              .margin({ top: 40 })
          }

          // 等待响应时的活动指示器
          if (this.isWaitingResponse) {
            Progress({ value: 0, total: 100, type: ProgressType.Ring })
              .width(50)
              .height(50)
              .margin({ top: 40 })
          }
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // 取消按钮
        if (!this.isComplete) {
          Button('取消')
            .width('80%')
            .fontSize(16)
            .type(ButtonType.Normal)
            .margin({ bottom: 40 })
            .onClick(() => {
              this.isUploading = false
              this.mainNavPathStack.pop()
            })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')
    }
    .title('备份到电脑')
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      // 接收参数
      const params = context.pathInfo.param as Record<string, Object>
      if (params) {
        if (params['conversations']) {
          this.conversations = params['conversations'] as ConversationInfo[]
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
      }
      this.startBackupRequest()
    })
  }
}
