//
// BackupTargetPage.ets
// hm-chat
//
// 备份目标选择页面
// 选择备份到本地或电脑端（与iOS保持一致）
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import { appNavigationDestinations } from '../mainNavigationConfig'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'

@Preview
@Component
export default struct BackupTargetPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State selectedConversations: ConversationInfo[] = []
  @State includeMedia: boolean = false
  @State isPCOnline: boolean = false
  private target: string = 'local'

  aboutToAppear() {
    this.checkPCOnlineStatus()
  }

  checkPCOnlineStatus() {
    // 检查PC是否在线
    const pcOnlineInfos = wfc.getPCOnlineInfos()
    this.isPCOnline = pcOnlineInfos && pcOnlineInfos.length > 0
  }

  selectLocalBackup() {
    // 跳转到会话选择页面，目标为本地
    this.mainNavPathStack.pushPathByName(appNavigationDestinations.ConversationSelectPage, {
      'target': 'local',
      'includeMedia': this.includeMedia
    } as Record<string, Object>)
  }

  selectPCBackup() {
    if (!this.isPCOnline) {
      showToast('电脑端未在线')
      return
    }

    // 跳转到会话选择页面，目标为PC
    this.mainNavPathStack.pushPathByName(appNavigationDestinations.ConversationSelectPage, {
      'target': 'pc',
      'includeMedia': this.includeMedia
    } as Record<string, Object>)
  }

  build() {
    NavDestination() {
      Column() {
        // 备份到本地
        OptionItemView({
          icon: $r('app.media.ic_settings_file'),
          title: '备份到本地',
          showDivider: false
        })
          .onClick(() => {
            this.selectLocalBackup()
          })

        // 备份到电脑端
        OptionItemView({
          icon: $r('app.media.ic_settings_file'),
          title: '备份到电脑端',
          showDivider: false
        })
          .margin({ top: 10 })
          .opacity(this.isPCOnline ? 1.0 : 0.4)
          .onClick(() => {
            this.selectPCBackup()
          })

        // 提示信息
        Text(this.isPCOnline ? '提示：备份到电脑端需要电脑端在线' : '提示：电脑端未在线，无法备份到电脑端')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20 })
          .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')
    }
    .title('选择备份位置')
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      // 接收参数
      const params = context.pathInfo.param as Record<string, Object>
      if (params) {
        if (params['selectedConversations']) {
          this.selectedConversations = params['selectedConversations'] as ConversationInfo[]
        }
        if (params['includeMedia']) {
          this.includeMedia = params['includeMedia'] as boolean
        }
      }
    })
  }
}
