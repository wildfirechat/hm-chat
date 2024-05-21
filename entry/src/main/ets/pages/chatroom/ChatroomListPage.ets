import Conversation from '../../wfc/model/conversation';
import ConversationType from '../../wfc/model/conversationType';
import { navigationDestinations } from '../navigationConfig';

@Entry
@Component
export default struct ChatroomListPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
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
        NavDestination() {
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
                            this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                                'conversation': new Conversation(ConversationType.ChatRoom, chatroom.roomId, 0)
                            } as Record<string, Object>)

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
        .height('100%')
        .width('100%')
    }
}

interface ChatroomItem {
    title: string,
    roomId: string
}
