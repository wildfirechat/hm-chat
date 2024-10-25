import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import CheckableUserListView from '../../view/CheckableUserListView'
import { loadContactUserInfos } from '../../helper/asyncTaskHelper'
import Organization from '../../api/model/organization'
import Employee from '../../api/model/employee'
import orgServer from '../../api/orgServer'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'
import UserListView from '../../view/UserListView'

@Component
export default struct PickContactModal {
    @State userInfos?: UserInfo[] = undefined
    public static PICK_RESULT: string = 'pickContactResult'
    @Link showPickContactModal: boolean
    onClickUser?: (users: UserInfo) => void

    aboutToAppear() {
        loadContactUserInfos().then((userinfos: UserInfo[]) => {
            this.userInfos = userinfos;
        })
    }

    build() {
        Navigation() {
            Scroll() {
                Column() {
                    if (this.userInfos) {
                        UserListView({
                            userInfos: this.userInfos,
                            showCategory: true,
                            showSearchView: true,
                            onClickUser: this.onClickUser
                        })
                    } else {
                        Text('加载中..')
                    }
                }
                .height('100%')
                .width('100%')
                .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .height('100%')
            .padding({ top: 5 })
        }
        .title('选取联系人')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.START])
    }
}
