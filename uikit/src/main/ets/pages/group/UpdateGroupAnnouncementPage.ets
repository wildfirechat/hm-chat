import { showToast } from '../../common/utils/Toast'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import ModifyGroupInfoType from '@wfc/client/src/main/ets/wfc/model/modifyGroupInfoType'
import appServer from '../../api/appServer';
import AppServerError from '../../api/appServerError';

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
                    .fontSize(20)
                    .margin({ top: 40 })

                Text('修改群公告后，将在群里通知其他成员。')
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
            .padding(30)
        }
        .title('')
        .height('100%')
        .width('100%')
    }
}
