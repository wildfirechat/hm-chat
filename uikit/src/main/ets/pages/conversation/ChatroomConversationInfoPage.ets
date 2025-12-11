import Conversation from "@wfc/client/src/main/ets/wfc/model/conversation";
import ConversationType from "@wfc/client/src/main/ets/wfc/model/conversationType";
import OptionItemView from "../../view/OptionItemView";
import { uikitNavigationDestinations } from "../uikitNavigationConfig";

@Component
export default struct ChatroomConversationInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    build() {
        NavDestination() {
            // Text('聊天室会话')
            OptionItemView({ title: '举报' })
                .onClick(event => {
                    AlertDialog.show({
                        title: "举报",
                        message: $r("app.string.complaint"),
                        primaryButton: {
                            value: "举报",
                            fontColor: Color.Red,
                            action: () => {
                                let conversation = new Conversation(ConversationType.Single, 'cgc8c8VV', 0)
                                this.mainNavPathStack.popToName(uikitNavigationDestinations.ConversationPage)
                                this.mainNavPathStack.replacePathByName(uikitNavigationDestinations.ConversationPage, {
                                    'conversation': conversation
                                } as Record<string, Object>)
                            },
                        },
                        secondaryButton: {
                            value: '取消',
                            action: () => {

                            }
                        }
                    })
                })
        }
        .title('聊天室会话详情')
        .height('100%')
        .width('100%')
    }
}
