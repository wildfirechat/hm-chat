import { showToast } from '../../common/utils/Toast'
import OptionItemView from '../../view/OptionItemView'
import wfc from '../../wfc/client/wfc'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct FileRecordPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            OptionItemView({
                title: '所有文件',
                showDivider: false
            })
                .margin({ top: 10 })
                .onClick(() => {
                    showToast('todo')
                })
            OptionItemView({
                title: '我的文件',
                showDivider: false
            })
                .margin({ top: 10 })
                .onClick(() => {
                    showToast('todo')
                })
            OptionItemView({
                title: '会话文件',
                showDivider: false
            })
                .margin({ top: 10 })
                .onClick(() => {
                    showToast('todo')
                })
            OptionItemView({
                title: '用户文件',
                showDivider: false
            })
                .margin({ top: 10 })
                .onClick(() => {
                    showToast('todo')
                })

        }
        .title('文件记录')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
