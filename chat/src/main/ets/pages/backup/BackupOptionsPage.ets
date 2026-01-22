//
// BackupOptionsPage.ets
// hm-chat
//
// 备份选项页面
// 设置备份选项（是否包含媒体文件）并开始备份
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { appNavigationDestinations } from '../mainNavigationConfig'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'

@Preview
@Component
export default struct BackupOptionsPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State selectedConversations: ConversationInfo[] = []
  @State target: string = 'local'
  @State includeMedia: boolean = false

  onStartBackup() {
    if (this.selectedConversations.length === 0) {
      showToast('请至少选择一个会话')
      return
    }

    // 使用当前用户ID作为默认密码
    const userId = wfc.getUserId()
    const password = userId || ''

    // 根据目标选择不同的进度页面
    if (this.target === 'pc') {
      // PC备份
      this.mainNavPathStack.pushPathByName(appNavigationDestinations.PCBackupProgressPage, {
        'conversations': this.selectedConversations,
        'includeMedia': this.includeMedia,
        'password': password,
        'passwordHint': ''
      } as Record<string, Object>)
    } else {
      // 本地备份
      this.mainNavPathStack.pushPathByName(appNavigationDestinations.BackupProgressPage, {
        'conversations': this.selectedConversations,
        'target': this.target,
        'includeMedia': this.includeMedia,
        'password': password,
        'passwordHint': ''
      } as Record<string, Object>)
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 已选择的会话信息
        Column() {
          Text(`已选择 ${this.selectedConversations.length} 个会话`)
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .padding(16)
        }
        .width('100%')
        .backgroundColor(Color.White)

        // 是否包含媒体文件
        Row() {
          Text('包含媒体文件')
            .fontSize(16)
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.includeMedia })
            .onChange((isOn: boolean) => {
              this.includeMedia = isOn
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .margin({ top: 10 })

        // 开始备份按钮
        Button('开始备份')
          .width('100%')
          .fontSize(16)
          .margin({ top: 30 })
          .onClick(() => {
            this.onStartBackup()
          })
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .backgroundColor('#EDEDED')
    }
    .title('备份选项')
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      // 接收传递过来的参数
      const params = context.pathInfo.param as Record<string, Object>
      if (params) {
        if (params['selectedConversations']) {
          this.selectedConversations = params['selectedConversations'] as ConversationInfo[]
        }
        if (params['target']) {
          this.target = params['target'] as string
        }
        if (params['includeMedia']) {
          this.includeMedia = params['includeMedia'] as boolean
        }
      }
    })
  }
}
