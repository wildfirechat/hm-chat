import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import { FontSize } from '../../common/design/Tokens'

@Component
export default struct GroupConversationMessageReceiptPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Text('TODO ')
                .width('100%')
                .fontSize(FontSize.sm)
                .fontColor('#989898')
                .padding(12)
                .backgroundColor('#E5E5E5')

        }
        .title('消息阅读状态')
        .height('100%')
        .width('100%')
    }
}
