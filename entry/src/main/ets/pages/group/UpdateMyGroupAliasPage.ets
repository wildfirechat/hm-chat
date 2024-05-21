import { showToast } from '../../common/utils/Toast'
import wfc from '../../wfc/client/wfc'
import GroupInfo from '../../wfc/model/groupInfo'
import ModifyGroupInfoType from '../../wfc/model/modifyGroupInfoType'

@Component
export default struct UpdateMyGroupAliasPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private groupInfo: GroupInfo = new GroupInfo()
    @State text: string = ''
    private placeHolder: string = ''

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo
        let userInfo = wfc.getUserInfo(wfc.getUserId(), false, this.groupInfo.target)
        this.text = userInfo.groupAlias ? userInfo.groupAlias : userInfo.displayName;
        this.placeHolder = ''
    }

    build() {
        NavDestination() {
            Column() {
                Text('我在群里的昵称')
                    .fontSize(20)
                    .margin({ top: 40 })

                Text('昵称修改后，只会在此群内显示，群内成员都可以看见。')
                    .textAlign(TextAlign.Center)
                    .margin({ top: 20 })


                Divider()
                    .margin({ top: 30 })
                    .strokeWidth(0.4)
                    .color('#EDEDED')

                Row() {
                    Image(this.groupInfo.portrait)
                        .draggable(false)
                        .backgroundColor(Color.Gray)
                        .borderRadius(4)
                        .width(40)
                        .height(40)

                    TextInput({
                        text: $$this.text,
                        placeholder: this.placeHolder
                    })
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
                        wfc.modifyGroupAlias(this.groupInfo.target, this.text.trim(), [0], null, () => {
                            showToast('修改我的群昵称成功')
                            this.mainNavPathStack.pop()
                        }, err => {
                            showToast('修改我的群昵称失败' + err)
                        })

                    })
            }
            .padding(30)
        }
        .title('')
        .height('100%')
        .width('100%')
    }
}
