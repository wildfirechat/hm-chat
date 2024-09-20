import { showToast } from '../../common/utils/Toast'
import wfc from '../../wfc/client/wfc'
import GroupInfo from '../../wfc/model/groupInfo'
import ModifyMyInfoEntry from '../../wfc/model/modifyMyInfoEntry';
import ModifyMyInfoType from '../../wfc/model/modifyMyInfoType';
import UserInfo from '../../wfc/model/userInfo';

@Component
export default struct UpdateUserNickNameOrAliasPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private userInfo: UserInfo = new UserInfo()
    @State text: string = ''
    private placeHolder: string = ''
    private isSelf: boolean = false

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.userInfo = params['userInfo'] as UserInfo

        this.isSelf = this.userInfo.uid === wfc.getUserId()


        if (this.isSelf) {
            this.placeHolder = this.userInfo.displayName
        } else {
            this.placeHolder = this.userInfo.friendAlias ? this.userInfo.friendAlias : '好友备注'
        }
    }

    updateNickNameOrAlias() {
        if (this.isSelf) {
            let entry: ModifyMyInfoEntry = { type: ModifyMyInfoType.Modify_DisplayName, value: this.text.trim() }
            wfc.modifyMyInfo([entry], () => {
                this.mainNavPathStack.pop()
            }, err => {
                showToast('修改个人昵称失败 ' + err)
            })
        } else {
            wfc.setFriendAlias(this.userInfo.uid, this.text.trim(), () => {
                this.mainNavPathStack.pop()
            }, err => {
                showToast('修改个人好友备注失败 ' + err)
            })
        }
    }

    build() {
        NavDestination() {
            Column() {
                Text(this.isSelf ? '昵称' : ' 备注')
                    .fontSize(20)
                    .margin({ top: 40 })

                Text(this.isSelf ? '好名字，可以让朋友更容易记住你' : '为朋友设置一个仅自己可见的备注')
                    .margin({ top: 20 })

                Divider()
                    .margin({ top: 30 })
                    .strokeWidth(0.4)
                    .color('#EDEDED')

                Row() {
                    TextInput({
                        text: $$this.text,
                        placeholder: this.placeHolder
                    })
                        .defaultFocus(true)
                        .borderRadius(2)
                        .backgroundColor(Color.Transparent)
                        .maxLines(1)
                        .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 5, bottom: 5 })

                Divider()
                    .strokeWidth(0.4)
                    .color('#EDEDED')

                Button('完成', {
                    type: ButtonType.Normal,
                    stateEffect: true
                })
                    .enabled(!!this.text.trim() && this.text !== this.placeHolder)
                    .padding({ top: 3, bottom: 3 })
                    .width(160)
                    .borderRadius(6)
                    .margin({ top: 100 })
                    .onClick(() => {
                        this.updateNickNameOrAlias()
                    })
            }
            .padding(30)
        }
        .title('')
        .height('100%')
        .width('100%')
    }
}
