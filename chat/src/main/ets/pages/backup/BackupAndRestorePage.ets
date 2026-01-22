//
// BackupAndRestorePage.ets
// hm-chat
//
// 备份与恢复主页面
// 提供创建备份和恢复备份的入口
//

import OptionItemView from '@wfc/uikit/src/main/ets/view/OptionItemView'
import { appNavigationDestinations } from '../mainNavigationConfig'

@Preview
@Component
export default struct BackupAndRestorePage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack

  build() {
    NavDestination() {
      Column() {
        // 创建备份
        OptionItemView({
          icon: $r('app.media.ic_settings_file'),
          title: '创建备份',
          showDivider: false
        })
          .onClick(() => {
            this.mainNavPathStack.pushPathByName(appNavigationDestinations.BackupTargetPage, {} as Record<string, Object>)
          })

        // 恢复备份
        OptionItemView({
          icon: $r('app.media.ic_settings_file'),
          title: '恢复备份',
          showDivider: false
        })
          .margin({ top: 10 })
          .onClick(() => {
            this.mainNavPathStack.pushPathByName(appNavigationDestinations.RestoreSourcePage, {} as Record<string, Object>)
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EDEDED')
    }
    .title('备份与恢复')
    .height('100%')
    .width('100%')
  }
}
