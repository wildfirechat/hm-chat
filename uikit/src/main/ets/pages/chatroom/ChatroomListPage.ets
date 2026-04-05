import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType';
import { uikitNavigationDestinations } from '../uikitNavigationConfig';

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
                                .fillColor($r('app.color.wf_icon_color'))
                            Text(chatroom.title)
                                .maxLines(1)
                                .padding({ left: 10 })
                                .fontColor($r('app.color.wf_primary_text'))
                        }
                        .height(60)
                        .width('100%')
                        .padding({ left: 10, right: 10 })
                        .backgroundColor($r('app.color.wf_background'))
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                                'conversation': new Conversation(ConversationType.ChatRoom, chatroom.roomId, 0)
                            } as Record<string, Object>)

                        })
                    }
                    .stateStyles({
                        pressed: {
                            .backgroundColor($r('app.color.wf_item_pressed'))
                        },
                        normal: {
                            .backgroundColor($r('app.color.wf_background'))
                        }
                    })
                }, (chatroom: ChatroomItem) => chatroom.roomId)
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
            .divider({
                strokeWidth: 1,
                color: $r('app.color.wf_divider'),
                startMargin: 60
            })
        }
        .title('聊天室列表')
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.wf_primary_background_color'))
    }
}

interface ChatroomItem {
    title: string,
    roomId: string
}
