import MentionGroupMemberListView from '../../../view/MentionGroupMemberListView'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'

@Builder
export default function MentionGroupMemberView(groupId: string, onClickGroupMemberUser: (userinfo: UserInfo) => void, onClickRobotUser: (userinfo: UserInfo) => void, onClickMentionAll: VoidCallback) {
    MentionGroupMemberListView({
        showCategory: true,
        showSearchView: true,
        groupId: groupId,
        onClickGroupMemberUser: onClickGroupMemberUser,
        onClickRobotMemberUser: onClickRobotUser,
        onClickMentionAll: onClickMentionAll
    })
        .width('100%')
        .height('100%')
        .padding({
            top: 5
        })
}
