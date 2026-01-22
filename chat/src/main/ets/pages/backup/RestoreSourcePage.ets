//
// RestoreSourcePage.ets
// hm-chat
//
// 恢复来源选择页面
// 选择从本地或电脑端恢复（与iOS保持一致）
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import { appNavigationDestinations } from '../mainNavigationConfig'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'

@Preview
@Component
export default struct RestoreSourcePage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State isPCOnline: boolean = false

  aboutToAppear() {
    this.checkPCOnlineStatus()
  }

  checkPCOnlineStatus() {
    // 检查PC是否在线
    const pcOnlineInfos = wfc.getPCOnlineInfos()
    this.isPCOnline = pcOnlineInfos && pcOnlineInfos.length > 0
  }

  selectLocalRestore() {
    // 跳转到本地备份列表
    this.mainNavPathStack.pushPathByName(appNavigationDestinations.BackupListPage, {} as Record<string, Object>)
  }

  selectPCRestore() {
    if (!this.isPCOnline) {
      showToast('电脑端未在线')
      return
    }

    // 跳转到PC端恢复列表
    this.mainNavPathStack.pushPathByName(appNavigationDestinations.PCRestoreListPage, {} as Record<string, Object>)
  }

  build() {
    NavDestination() {
      Column() {
        // 从本地恢复
        OptionItemView({
          icon: $r('app.media.ic_settings_file'),
          title: '从本地恢复',
          showDivider: false
        })
          .onClick(() => {
            this.selectLocalRestore()
          })

        // 从电脑端恢复
        OptionItemView({
          icon: $r('app.media.ic_settings_file'),
          title: '从电脑端恢复',
          showDivider: false
        })
          .margin({ top: 10 })
          .opacity(this.isPCOnline ? 1.0 : 0.4)
          .onClick(() => {
            this.selectPCRestore()
          })

        // 提示信息
        Text(this.isPCOnline ? '提示：从电脑端恢复需要电脑端在线' : '提示：电脑端未在线，无法从电脑端恢复')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20 })
          .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')
    }
    .title('选择恢复来源')
    .height('100%')
    .width('100%')
  }
}
