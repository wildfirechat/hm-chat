@Entry
@Component
export default struct ChatroomConversationInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    build() {
        NavDestination() {
            Text('TODO ConversationInfo')
        }
        .title('聊天室会话详情')
        .height('100%')
        .width('100%')
    }
}
