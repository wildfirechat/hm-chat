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
import ConversationInfoDataSource from '@wfc/uikit/src/main/ets/pages/datasource/ConversationInfoDataSource'
import CheckableConversationInfoItemView from '@wfc/uikit/src/main/ets/view/CheckableConversationInfoItemView'

@Preview
@Component
export default struct ConversationSelectPage {
  @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
  private conversationInfoDataSource: ConversationInfoDataSource = new ConversationInfoDataSource()
  private conversationInfos: ConversationInfo[] = []
  @State checkedConversations: Conversation[] = []
  @State selectAll: boolean = false
  private target: string = 'local' // 'local' or 'pc'
  private includeMedia: boolean = false

  aboutToAppear() {
    // 获取所有会话
    const types = [ConversationType.Single, ConversationType.Group, ConversationType.ChatRoom]
    const conversationList = wfc.getConversationInfoList(types, [0])
    console.log(`Loaded ${conversationList.length} conversations`)

    this.conversationInfos = conversationList
    this.conversationInfoDataSource.setConversationInfos(conversationList)
    this.checkedConversations = []
    this.selectAll = false
  }

  toggleSelectAll(): void {
    this.selectAll = !this.selectAll
    if (this.selectAll) {
      this.checkedConversations = this.conversationInfos.map(info => info.conversation)
    } else {
      this.checkedConversations = []
    }
  }

  toggleSelection(conversation: Conversation): void {
    let index = this.checkedConversations.findIndex(c => Conversation.equal(c, conversation))
    if (index >= 0) {
      this.checkedConversations.splice(index, 1)
    } else {
      this.checkedConversations.push(conversation)
    }

    this.selectAll = this.checkedConversations.length === this.conversationInfos.length
  }

  getSelectedConversations(): ConversationInfo[] {
    return this.conversationInfos.filter(info =>
      this.checkedConversations.findIndex(c => Conversation.equal(c, info.conversation)) >= 0
    )
  }

  getSelectedCount(): number {
    return this.checkedConversations.length
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
          LazyForEach(this.conversationInfoDataSource, (info: ConversationInfo, index: number) => {
            ListItem() {
              CheckableConversationInfoItemView({
                checkedConversations: $checkedConversations,
                conversationInfo: info,
                basicMode: true,
                enableCheck: true
              })
                .onClick(() => {
                  this.toggleSelection(info.conversation)
                })
            }
          }, (info: ConversationInfo) => info.conversation.type + info.conversation.target + '-' + info.conversation.line)
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
}
