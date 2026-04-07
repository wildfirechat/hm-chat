import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'

@Component
export default struct GroupQRCodePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Text('TODO ')
                .width('100%')
                .fontSize(13)
                .fontColor($r('app.color.wf_secondary_text'))
                .padding(10)
                .backgroundColor($r('app.color.wf_secondary_background'))
        }
        .title('群二维码')
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.wf_background'))
    }
}
