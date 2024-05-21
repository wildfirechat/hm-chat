import { showToast } from '../../common/utils/Toast'
import wfc from '../../wfc/client/wfc'
import GroupInfo from '../../wfc/model/groupInfo'
import ModifyGroupInfoType from '../../wfc/model/modifyGroupInfoType'

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
                    .fontSize(20)
                    .margin({ top: 40 })

                Text('群聊的备注，仅自己可见')
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

                Text(`群聊名称：${this.groupInfo.name}`)
                    .fontColor('#838383')
                    .fontSize(13)
                    .maxLines(1)
                    .ellipsisMode(EllipsisMode.START)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 10 })

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
                        wfc.setGroupRemark(this.groupInfo.target, this.text.trim(), () => {
                            showToast('修改群备注成功')
                            this.mainNavPathStack.pop()
                        }, err => {
                            showToast('修改群备注失败' + err)
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
