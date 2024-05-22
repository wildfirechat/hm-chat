import OptionItemView from '../../view/OptionItemView'
import wfc from '../../wfc/client/wfc'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct AccountPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
    }

    build() {
        NavDestination() {
            Column() {
                OptionItemView({
                    title: '修改密码',
                    showDivider: false
                })
            }
            .width('100%')
            .height('100%')
        }
        .title('账号与安全')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
