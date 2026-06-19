import { showToast } from '../../common/utils/Toast'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import ModifyGroupInfoType from '@wfc/client/src/main/ets/wfc/model/modifyGroupInfoType'
import { FontSize, Radius } from '../../common/design/Tokens'

@Component
export default struct UpdateGroupNamePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private groupInfo: GroupInfo = new GroupInfo()
    @State text: string = ''
    private placeHolder: string = ''

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo
        this.text = this.groupInfo.name
        this.placeHolder = this.groupInfo.name
    }

    build() {
        NavDestination() {
            Column() {
                Text('修改群聊名称')
                    .fontSize(FontSize.xl)
                    .margin({ top: 40 })
                    .fontColor($r('app.color.wf_primary_text'))

                Text('修改群聊名称后，将在群里通知其他成员。')
                    .margin({ top: 20 })
                    .fontColor($r('app.color.wf_secondary_text'))

                Divider()
                    .margin({ top: 32 })
                    .strokeWidth(0.4)
                    .color($r('app.color.wf_divider'))

                Row() {
                    Image(this.groupInfo.portrait)
                        .draggable(false)
                        .backgroundColor($r('app.color.wf_secondary_background'))
                        .borderRadius(Radius.sm)
                        .width(40)
                        .height(40)

                    TextInput({
                        text: $$this.text,
                        placeholder: this.placeHolder
                    })
                        .borderRadius(Radius.xs)
                        .backgroundColor(Color.Transparent)
                        .fontColor($r('app.color.wf_primary_text'))
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
                        wfc.modifyGroupInfo(this.groupInfo.target, ModifyGroupInfoType.Modify_Group_Name, this.text.trim(), [0], null, () => {
                            showToast('修改群名称成功')
                            this.mainNavPathStack.pop()
                        }, err => {
                            showToast('修改群名称失败 ' + err)
                        })

                    })
            }
            .padding(32)
        }
        .title('')
        .height('100%')
        .width('100%')
    }
}
