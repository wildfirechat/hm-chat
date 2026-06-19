import { showToast } from '../../common/utils/Toast'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { FontSize, Radius } from '../../common/design/Tokens'

@Component
export default struct UpdateGroupRemarkPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private groupInfo: GroupInfo = new GroupInfo()
    @State text: string = ''
    private placeHolder: string = ''

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo
        this.text = this.groupInfo.remark
        this.placeHolder = '备注'
    }

    build() {
        NavDestination() {
            Column() {
                Text('备注')
                    .fontSize(FontSize.xl)
                    .margin({ top: 40 })
                    .fontColor($r('app.color.wf_primary_text'))

                Text('群聊的备注，仅自己可见')
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

                Text(`群聊名称：${this.groupInfo.name}`)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .fontSize(FontSize.sm)
                    .maxLines(1)
                    .ellipsisMode(EllipsisMode.START)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 12 })

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
                        wfc.setGroupRemark(this.groupInfo.target, this.text.trim(), () => {
                            showToast('修改群备注成功')
                            this.mainNavPathStack.pop()
                        }, err => {
                            showToast('修改群备注失败' + err)
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
