import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import client from 'marswrapper'
import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import router from '@ohos.router'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import { showToast } from '../../common/utils/Toast'
import CheckableUserItemView from '../../view/CheckableUserItemView'
import CheckableUserListView from '../../view/CheckableUserListView'

@Entry
@Component
export default struct PickUserPage {
    @State message: string = 'Hello ContactList'
    @State checkedUsers: UserInfo[] = []
    private userInfos: UserInfo[] = []
    private initialCheckedUserIds: string[] = []
    private uncheckableUserIds: string[] = []
    public static TAG: string = 'pickUser'
    public static PICKER_RESULT: string = 'pickerResult'

    aboutToAppear() {
        let friendUserIds = wfc.getMyFriendList()
        this.userInfos = wfc.getUserInfos(friendUserIds, '')
        this.initialCheckedUserIds = friendUserIds
        this.checkedUsers = this.userInfos.filter((info: UserInfo) => {
            return this.initialCheckedUserIds.indexOf(info.uid) >= 0
        })
    }

    onCheckUser = (info: UserInfo, checked?: boolean) => {
        let index = this.checkedUsers.findIndex(checkedUser => checkedUser.uid === info.uid)
        if (checked) {
            if (index < 0) {
                this.checkedUsers.push(info)
            }
        } else {
            if (index >= 0) {
                this.checkedUsers.splice(index, 1)
            } else {
                this.checkedUsers.push(info)
            }
        }
    }

    build() {
        Navigation() {
            Scroll() {
                Column() {
                    Text('Tes' + this.checkedUsers.length)

                    CheckableUserListView({
                        checkedUsers: $checkedUsers,
                        userInfos: this.userInfos,
                        // uncheckableUserIds: this.initialCheckedUserIds,
                        showCategory: true,
                        showSearchView: true
                    })
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
        .menus(this.NavigationMenus())
    }

    @Builder NavigationMenus() {
        Row() {
            Button('确定')
                .type(ButtonType.Normal)
                .height(30)
                .width(60)
                .fontSize(14)
                .borderRadius(4)
                    // .backgroundColor(Color.Blue)
                    // TODO
                .onClick(() => {
                    let options: router.RouterOptions = {
                        url: '',
                        params: {
                            tag: PickUserPage.TAG,
                            result: this.checkedUsers,
                        }
                    }
                    router.back(options)
                })
        }
    }
}
