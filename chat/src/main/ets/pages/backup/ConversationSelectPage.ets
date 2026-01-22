//
// ConversationSelectPage.ets
// hm-chat
//
// 会话选择页面
// 用于备份时选择要备份的会话
//

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import { appNavigationDestinations } from '../mainNavigationConfig'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'

// 会话项包装类，包含选中状态
@Observed
class ConversationItem {
  conversationInfo: ConversationInfo
  portrait: string = ''
  isSelected: boolean = false

  constructor(convInfo: ConversationInfo) {
    this.conversationInfo = convInfo
  }
}

@Preview
@Component
export default struct ConversationSelectPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  @State conversationItems: ConversationItem[] = []
  @State selectAll: boolean = false
  private target: string = 'local' // 'local' or 'pc'
  private includeMedia: boolean = false

  aboutToAppear() {
    // 获取所有会话
    const types = [ConversationType.Single, ConversationType.Group, ConversationType.ChatRoom]
    const conversationList = wfc.getConversationInfoList(types, [0])
    console.log(`Loaded ${conversationList.length} conversations`)

    // 创建会话项数组并加载头像
    this.conversationItems = conversationList.map(convInfo => {
      const item = new ConversationItem(convInfo)
      item.portrait = convInfo.portrait()
      return item
    })
  }

  toggleSelectAll(): void {
    this.selectAll = !this.selectAll

    // 直接更新每个会话项的选中状态
    const newItems = this.conversationItems.map(item => {
      const newItem = new ConversationItem(item.conversationInfo)
      newItem.portrait = item.portrait
      newItem.isSelected = this.selectAll
      return newItem
    })

    this.conversationItems = newItems
  }

  toggleSelection(item: ConversationItem): void {
    // 创建新的会话项数组，只修改被点击的项
    const newItems = this.conversationItems.map(i => {
      if (i === item) {
        const newItem = new ConversationItem(i.conversationInfo)
        newItem.portrait = i.portrait
        newItem.isSelected = !i.isSelected
        return newItem
      }
      return i
    })

    this.conversationItems = newItems

    // 更新全选状态
    this.selectAll = newItems.every(i => i.isSelected)
  }

  getSelectedConversations(): ConversationInfo[] {
    return this.conversationItems
      .filter(item => item.isSelected)
      .map(item => item.conversationInfo)
  }

  getSelectedCount(): number {
    return this.conversationItems.filter(item => item.isSelected).length
  }

  onNext() {
    const selectedCount = this.getSelectedCount()
    if (selectedCount === 0) {
      showToast('请至少选择一个会话')
      return
    }

    const selected = this.getSelectedConversations()

    // 跳转到备份选项页面
    this.mainNavPathStack.pushPathByName(appNavigationDestinations.BackupOptionsPage, {
      'selectedConversations': selected,
      'target': this.target,
      'includeMedia': this.includeMedia
    } as Record<string, Object>)
  }

  build() {
    NavDestination() {
      Column() {
        // 全选按钮
        Row() {
          Text('全选')
            .fontSize(16)
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.selectAll })
            .onChange(() => {
              this.toggleSelectAll()
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)

        // 会话列表
        List({ space: 0 }) {
          ForEach(this.conversationItems, (item: ConversationItem, index: number) => {
            ListItem() {
              ConversationItemView({
                item: item,
                onCheckChange: () => {
                  this.toggleSelection(item)
                }
              })
            }
          }, (item: ConversationItem, index: number) => `${index}`)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(Color.White)
        .divider({
          strokeWidth: 1,
          color: '#F7F7F7',
          startMargin: 72,
          endMargin: 0
        })

        // 底部按钮
        Row() {
          Text(`已选择 ${this.getSelectedCount()} 个会话`)
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)

          Button('下一步')
            .fontSize(16)
            .borderRadius(4)
            .margin({ left: 10 })
            .onClick(() => {
              this.onNext()
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
      }
      .width('100%')
      .height('100%')
    }
    .title('选择会话')
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      // 接收传递过来的参数
      const params = context.pathInfo.param as Record<string, Object>
      if (params) {
        if (params['target']) {
          this.target = params['target'] as string
        }
        if (params['includeMedia']) {
          this.includeMedia = params['includeMedia'] as boolean
        }
      }
    })
  }

  @Builder
  ConversationItemForBackup(item: ConversationItem, onCheckChange: () => void) {
    Row() {
      // 复选框
      Checkbox()
        .select(item.isSelected)
        .enabled(true)
        .margin({ right: 12 })

      // 会话头像
      Image(item.portrait)
        .width(48)
        .height(48)
        .borderRadius(4)
        .alt($r('app.media.avatar_def'))
        .margin({ right: 12 })

      // 会话信息
      Column() {
        Text(item.conversationInfo.title())
          .fontSize(16)
          .fontColor('#1d1d1d')
          .maxLines(1)
          .layoutWeight(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.getMessageCount(item.conversationInfo)}条消息`)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
    .onClick(() => {
      onCheckChange()
    })
  }

  getMessageCount(conversationInfo: ConversationInfo): number {
    // 从数据库获取会话的消息总数
    return wfc.getMessageCount(conversationInfo.conversation)
  }
}

// 子组件，使用 @ObjectLink 接收 ConversationItem
@Component
struct ConversationItemView {
  @ObjectLink item: ConversationItem
  onCheckChange: () => void = () => {}

  build() {
    Row() {
      // 复选框
      Checkbox()
        .select(this.item.isSelected)
        .enabled(true)
        .margin({ right: 12 })

      // 会话头像
      Image(this.item.portrait)
        .width(48)
        .height(48)
        .borderRadius(4)
        .alt($r('app.media.avatar_def'))
        .margin({ right: 12 })

      // 会话信息
      Column() {
        Text(this.item.conversationInfo.title())
          .fontSize(16)
          .fontColor('#1d1d1d')
          .maxLines(1)
          .layoutWeight(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${wfc.getMessageCount(this.item.conversationInfo.conversation)}条消息`)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
    .onClick(() => {
      this.onCheckChange()
    })
  }
}
