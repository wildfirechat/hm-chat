import router from '@ohos.router'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'

@Entry
@Component
struct FavGroupListPage {
    @State chatroomList: ChatroomItem[] = [
        {
            title: '野火IM 聊天室1',
            roomId: 'chatroom1'
        },
        {
            title: '野火IM 聊天室2',
            roomId: 'chatroom2'
        },
        {
            title: '野火IM 聊天室3',
            roomId: 'chatroom3'
        }
    ]

    onPageShow() {
    }

    build() {
        Navigation() {
            List() {
                ForEach(this.chatroomList, (chatroom: ChatroomItem) => {
                    ListItem() {
                        Row() {
                            Image($r('app.media.ic_chatroom'))
                                .alt($r('app.media.ic_chatroom'))
                                .width(20)
                                .height(20)
                                .borderRadius(4)
                            Text(chatroom.title)
                                .maxLines(1)
                                .padding({ left: 10 })
                        }
                        .height(60)
                        .width('100%')
                        .padding({ left: 10, right: 10 })
                        .onClick(() => {
                            router.replaceUrl({
                                url: 'pages/conversation/ConversationPage',
                                params: {
                                    conversation: new Conversation(ConversationType.ChatRoom, chatroom.roomId, 0)
                                }
                            }, router.RouterMode.Standard)
                        })
                    }
                }, (chatroom: ChatroomItem) => chatroom.roomId)
            }
            .width('100%')
            .height('100%')
            .divider({
                strokeWidth: 1,
                startMargin: 60
            })
        }
        .title('聊天室列表')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
    }
}

interface ChatroomItem {
    title: string,
    roomId: string
}
