import wfc from '../../wfc/client/wfc'
import EventType from '../../wfc/client/wfcEvent'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'

@Component
export default struct PickFavGroupModal {
    @State favGroupList: GroupInfo[] = []
    public static PICK_RESULT: string = 'pickSingleFavGroupResult'
    @Link showPickFavGroupModal: boolean
    @Link checkedFavGroupInfo: GroupInfo

    aboutToAppear() {
        this.favGroupList = wfc.getFavGroupList()
        wfc.eventEmitter?.on(EventType.GroupInfosUpdate, this.onGroupUpdateListener)
    }

    aboutToDisappear(): void {
        wfc.eventEmitter?.off(EventType.GroupInfosUpdate, this.onGroupUpdateListener)
    }

    onGroupUpdateListener() {
        this.favGroupList = wfc.getFavGroupList()
    }

    build() {
        Navigation() {
            Text('保存到通讯录的群组')
                .width('100%')
                .fontSize(13)
                .fontColor('#989898')
                .padding(10)
                .backgroundColor('#E5E5E5')

            List() {
                ForEach(this.favGroupList, (groupInfo: GroupInfo) => {
                    ListItem() {
                        Row() {
                            Image(groupInfo.portrait)
                                .alt($r('app.media.ic_group_chat'))
                                .width(40)
                                .height(40)
                                .borderRadius(4)
                            Text(groupInfo.name)
                                .layoutWeight(1)
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .ellipsisMode(EllipsisMode.END)
                                .padding({ left: 10, right: 10 })
                        }
                        .height(60)
                        .width('100%')
                        .padding({ left: 10, right: 10 })
                        .onClick(() => {
                            this.checkedFavGroupInfo = groupInfo
                            this.showPickFavGroupModal = false
                        })
                    }
                }, (groupInfo: GroupInfo) => groupInfo.target + groupInfo.updateDt)
            }
            .width('100%')
            .height('100%')
            .divider({
                strokeWidth: 1,
                startMargin: 60
            })
        }
        .title('群列表')
        .titleMode(NavigationTitleMode.Mini)
        .navBarPosition(NavBarPosition.Start)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
    }
}
