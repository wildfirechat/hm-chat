import Conversation from "@wfc/client/src/main/ets/wfc/model/conversation"
import Utils from "../common/Utils"

@Preview
// TODO 暂不支持 reuse
// @Reusable
@Component
export default struct ConversationPortraitView {
    conversation?: Conversation
    alt: string | Resource | PixelMap = $r('app.media.avatar_def')
    @State conversationItemPortrait: string = ''

    aboutToAppear() {
        if (this.conversation) {
            Utils.computeConversationItemPortraitNameAndUnReadJoinGroupRequestCount(this.conversation, false)
                .then(value => {
                    this.conversationItemPortrait = value.portrait
                })
        }
    }

    build() {
        Image(this.conversationItemPortrait)
            .alt(this.alt)
            .draggable(false)
            .borderRadius(4)
            .width('100%')
            .height('100%')
    }
}