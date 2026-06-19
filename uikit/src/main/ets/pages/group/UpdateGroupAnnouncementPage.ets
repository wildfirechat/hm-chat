import { showToast } from '../../common/utils/Toast'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import ModifyGroupInfoType from '@wfc/client/src/main/ets/wfc/model/modifyGroupInfoType'
import appServer from '../../api/appServer';
import AppServerError from '../../api/appServerError';
import { FontSize, Radius } from '../../common/design/Tokens'

@Component
export default struct UpdateGroupAnnouncementPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private groupInfo?: GroupInfo
    @State text: string = ''
    @State placeHolder: string = ''

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo
        if (!this.groupInfo) {
            this.mainNavPathStack.pop()
            return
        }
        appServer.getGroupAnnouncement(this.groupInfo!.target)
            .then(groupAnnouncement => {
                this.placeHolder = groupAnnouncement.text
            })
    }

    build() {
        NavDestination() {
            Column() {
                Text('修改群公告')
                    .fontSize(FontSize.xl)
                    .margin({ top: 40 })
                    .fontColor($r('app.color.wf_primary_text'))

                Text('修改群公告后，将在群里通知其他成员。')
                    .margin({ top: 20 })
                    .fontColor($r('app.color.wf_secondary_text'))

                Divider()
                    .margin({ top: 32 })
                    .strokeWidth(0.4)
                    .color($r('app.color.wf_divider'))

                Row() {
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
                        appServer.updateGroupAnnouncement(wfc.getUserId(), this.groupInfo!.target, this.text.trim())
                            .then(value => {
                                showToast('更新群公告成功')
                                this.mainNavPathStack.pop()
                            })
                            .catch((err: AppServerError) => {
                                showToast('更新群公告失败 ' + err.message);
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
