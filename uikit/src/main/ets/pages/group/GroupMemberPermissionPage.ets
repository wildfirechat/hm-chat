import { showToast } from '../../common/utils/Toast'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import ModifyGroupInfoType from '@wfc/client/src/main/ets/wfc/model/modifyGroupInfoType'
import appServer from '../../api/appServer';
import AppServerError from '../../api/appServerError';

@Component
export default struct GroupMemberPermissionPage {
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
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    Text('允许普通成员发起临时会话')
                    Toggle({ type: ToggleType.Switch, isOn: this.groupInfo!.privateChat === 0 })
                        .onChange(isOn => {
                            wfc.modifyGroupInfo(this.groupInfo!.target, ModifyGroupInfoType.Modify_Group_PrivateChat, isOn ? '0' : '1', [], null, () => {
                                this.mainNavPathStack.pop()
                                showToast('设置成功')
                            }, err => {
                                showToast('设置允许普通成员发起临时会话失败 ' + err)
                            })
                        })
                }
                .justifyContent(FlexAlign.SpaceBetween)
                .width('100%')
                .height(56)
                .backgroundColor(Color.White)
                .padding({ left: 10, right: 10 })
            }
        }
        .title('群成员权限')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
