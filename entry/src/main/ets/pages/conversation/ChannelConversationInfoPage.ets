@Entry
@Component
export default struct ChannelConversationInfoPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    build() {
        NavDestination() {
            Text('TODO ConversationInfo')
        }
        .title('频道会话详情')
        .height('100%')
        .width('100%')
    }
}
