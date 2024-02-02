@Entry
@Component
export struct ChannelInfoPage {
    build() {
        Navigation() {
            Text('TODO ConversationInfo')
        }
        .title('频道详情')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
    }
}
