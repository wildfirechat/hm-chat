@Entry
@Component
export default struct GroupMemberListPage {
    build() {
        Navigation() {
            Text('TODO')
        }
        .title('群成员列表')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
    }
}