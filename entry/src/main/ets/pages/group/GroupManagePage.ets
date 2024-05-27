import OptionItemView from '../../view/OptionItemView'
import wfc from '../../wfc/client/wfc'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct GroupManagePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private groupInfo?: GroupInfo

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo

    }

    build() {
        NavDestination() {
            Column() {
                Column() {
                    Text('成员管理')
                        .textAlign(TextAlign.Start)
                        .backgroundColor('#EDEDED')
                        .padding({ left: 10, top: 5, bottom: 5 })
                        .width('100%')
                    OptionItemView({
                        title: '管理员',
                        showDivider: true,
                    })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(navigationDestinations.GroupManagerListPage, {
                                'groupInfo': this.groupInfo
                            } as Record<string, Object>)
                        })
                    OptionItemView({
                        title: '设置禁言',
                        showDivider: true,
                    })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(navigationDestinations.GroupMemberMuteOrAllowListPage, {
                                'groupInfo': this.groupInfo
                            } as Record<string, Object>)
                        })
                    OptionItemView({
                        title: '成员权限',
                        showDivider: false,
                    })
                }

                Column() {
                    Text('群基本设置')
                        .textAlign(TextAlign.Start)
                        .backgroundColor('#EDEDED')
                        .padding({ left: 10, top: 15, bottom: 5 })
                        .width('100%')
                    OptionItemView({
                        title: '加群方式',
                        desc: '不限制加入',
                        showDivider: true,
                        showRightArrow: false
                    })
                    OptionItemView({
                        title: '查找方式',
                        desc: '不允许查找',
                        showDivider: true,
                        showRightArrow: false
                    })
                    OptionItemView({
                        title: '群历史消息',
                        desc: '不允许新成员查看历史消息',
                        showDivider: false,
                        showRightArrow: false
                    })
                }
            }
            .backgroundColor(Color.White)
        }
        .title('群管理')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
