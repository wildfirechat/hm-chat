import wfc from '../../wfc/client/wfc'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import GroupInfo from '../../wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct FavGroupListPage {
    @State favGroupList: GroupInfo[] = []
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        this.favGroupList = wfc.getFavGroupList()
    }

    build() {
        NavDestination() {
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
                                .maxLines(1)
                                .padding({ left: 10 })
                        }
                        .height(60)
                        .width('100%')
                        .padding({ left: 10, right: 10 })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                                'conversation': new Conversation(ConversationType.Group, groupInfo.target, 0)
                            } as Record<string, Object>)
                        })
                    }
                }, (groupInfo: GroupInfo) => groupInfo.target)
            }
            .width('100%')
            .height('100%')
            .divider({
                strokeWidth: 1,
                startMargin: 60
            })
        }
        .title('群列表')
        .height('100%')
        .width('100%')
    }
}
