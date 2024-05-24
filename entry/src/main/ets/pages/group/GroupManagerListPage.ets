import OptionItemView from '../../view/OptionItemView'
import wfc from '../../wfc/client/wfc'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct GroupManagerListPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Column()
            Text('TODO')
                .backgroundColor(Color.White)
        }
        .title('管理员列表')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
