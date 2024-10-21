import wfc from "@wfc/client";
import GroupInfo from "@wfc/client/src/main/ets/wfc/model/groupInfo";
import GroupMember from "@wfc/client/src/main/ets/wfc/model/groupMember";
import GroupMemberType from "@wfc/client/src/main/ets/wfc/model/groupMemberType";
import { showToast } from "../../common/utils/Toast";
import { navigationDestinations } from "../navigationConfig";

@Entry
@Component
export default struct GroupMemberListPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State groupInfo?: GroupInfo = undefined
    @State groupMembers: GroupMember[] = []
    private groupMember?: GroupMember

    aboutToAppear(): void {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.groupInfo = params['groupInfo'] as GroupInfo;

        wfc.getGroupMembersEx(this.groupInfo.target, true, groupMembers => {
            this.groupMembers = groupMembers
        }, err => {
            showToast('获取群成员失败')
        })
        this.groupMember = wfc.getGroupMember(this.groupInfo.target, wfc.getUserId())
    }

    build() {
        NavDestination() {
            Scroll() {
                Column() {
                    Flex({
                        justifyContent: FlexAlign.Start,
                        alignContent: FlexAlign.SpaceAround,
                        wrap: FlexWrap.Wrap
                    }) {
                        ForEach(this.groupMembers, (groupMember: GroupMember) => {
                            Column() {
                                Image(groupMember.getPortrait())
                                    .width(48)
                                    .height(48)
                                    .borderRadius(4)
                                Text(groupMember.getName())
                                    .maxLines(1)
                                    .fontColor('#7E7E7E')
                                    .fontSize(12)
                                    .margin({ top: 5 })
                            }
                            .onClick(() => {
                                if (this.groupInfo!.privateChat === 1 && [GroupMemberType.Owner, GroupMemberType.Manager].indexOf(this.groupMember!.type) === -1) {
                                    showToast('禁止私聊')
                                } else {
                                    this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, {
                                        'userInfo': wfc.getUserInfo(groupMember.memberId)
                                    } as Record<string, Object>)
                                }
                            })
                            .width('20%')
                            .padding(8)
                            .justifyContent(FlexAlign.Center)
                            .alignItems(HorizontalAlign.Center)
                        }, (groupMember: GroupMember) => groupMember.memberId + '-' + groupMember.updateDt)

                    }
                    .padding(10)
                    .width('100%')
                    .backgroundColor(Color.White)
                }
            }
            .scrollBar(BarState.Off)
            .width('100%')
            .height('100%')
            .backgroundColor('#EDEDED')
        }
        .title('群成员列表')
        .height('100%')
        .width('100%')
    }
}