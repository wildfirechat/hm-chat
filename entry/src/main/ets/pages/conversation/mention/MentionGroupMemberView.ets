import MentionGroupMemberListView from '../../../view/MentionGroupMemberListView'
import UserInfo from '../../../wfc/model/userInfo'

@Builder
export default function MentionGroupMemberView(groupId: string, onClickUser: (userinfo: UserInfo) => void) {
    MentionGroupMemberListView({
        showCategory: true,
        showSearchView: true,
        groupId: groupId,
        onClickUser: onClickUser
    })
        .width('100%')
        .height('100%')
        .padding({
            top: 5
        })
}
