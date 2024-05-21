import wfc from '../../wfc/client/wfc'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct UpdateGroupAnnouncementPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Text('TODO ')
                .width('100%')
                .fontSize(13)
                .fontColor('#989898')
                .padding(10)
                .backgroundColor('#E5E5E5')

        }
        .title('更新群公告')
        .height('100%')
        .width('100%')
    }
}
