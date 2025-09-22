import Conversation from "@wfc/client/src/main/ets/wfc/model/conversation";
import ConversationType from "@wfc/client/src/main/ets/wfc/model/conversationType";
import OptionItemView from "../../view/OptionItemView";
import { navigationDestinations } from "../navigationConfig";

@Component
export default struct ChannelConversationInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    build() {
        NavDestination() {
            // Text('TODO ConversationInfo')
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
                                this.mainNavPathStack.popToName(navigationDestinations.ConversationPage)
                                this.mainNavPathStack.replacePathByName(navigationDestinations.ConversationPage, {
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
        .title('频道会话详情')
        .height('100%')
        .width('100%')
    }
}
