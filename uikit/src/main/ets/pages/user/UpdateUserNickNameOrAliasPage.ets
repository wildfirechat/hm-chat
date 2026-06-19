import { showToast } from '../../common/utils/Toast'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import ModifyMyInfoEntry from '@wfc/client/src/main/ets/wfc/model/modifyMyInfoEntry';
import ModifyMyInfoType from '@wfc/client/src/main/ets/wfc/model/modifyMyInfoType';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import { FontSize, Radius } from '../../common/design/Tokens'

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
                    .fontSize(FontSize.xl)
                    .margin({ top: 40 })

                Text(this.isSelf ? '好名字，可以让朋友更容易记住你' : '为朋友设置一个仅自己可见的备注')
                    .margin({ top: 20 })

                Divider()
                    .margin({ top: 32 })
                    .strokeWidth(0.4)
                    .color($r('app.color.wf_divider'))

                Row() {
                    TextInput({
                        text: $$this.text,
                        placeholder: this.placeHolder
                    })
                        .defaultFocus(true)
                        .borderRadius(Radius.xs)
                        .backgroundColor(Color.Transparent)
                        .maxLines(1)
                        .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 4, bottom: 4 })

                Divider()
                    .strokeWidth(0.4)
                    .color($r('app.color.wf_divider'))

                Button('完成', {
                    type: ButtonType.Normal,
                    stateEffect: true
                })
                    .enabled(!!this.text.trim() && this.text !== this.placeHolder)
                    .padding({ top: 4, bottom: 4 })
                    .width(160)
                    .borderRadius(Radius.md)
                    .margin({ top: 100 })
                    .onClick(() => {
                        this.updateNickNameOrAlias()
                    })
            }
            .padding(32)
        }
        .title('')
        .height('100%')
        .width('100%')
    }
}
