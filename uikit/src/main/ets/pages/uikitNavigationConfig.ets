import ChannelListPage from './channel/ChannelListPage'
import ChatroomListPage from './chatroom/ChatroomListPage'
import FriendRequestListPage from './contact/FriendRequestListPage'
import ChannelConversationInfoPage from './conversation/ChannelConversationInfoPage'
import ConversationPage from './conversation/ConversationPage'
import ForwardMessagePage from './conversation/forward/ForwardMessagePage'
import GroupConversationInfoPage from './conversation/GroupConversationInfoPage'
import CompositeMessagePreviewPage from './conversation/CompositeMessagePreviewPage'
import SingleConversationInfoPage from './conversation/SingleConversationInfoPage'
import FavGroupListPage from './group/FavGroupListPage'
import GroupInfoPage from './group/GroupInfoPage'
import GroupManagePage from './group/GroupManagePage'
import GroupManagerListPage from './group/GroupManagerListPage'
import GroupMemberMuteOrAllowListPage from './group/GroupMemberMuteOrAllowListPage'
import GroupQRCodePage from './group/GroupQRCodePage'
import UpdateGroupAnnouncementPage from './group/UpdateGroupAnnouncementPage'
import UpdateGroupNamePage from './group/UpdateGroupNamePage'
import UpdateGroupRemarkNamePage from './group/UpdateGroupRemarkPage'
import UpdateMyGroupAliasNamePage from './group/UpdateMyGroupAliasPage'
import FavRecordPage from './me/FavRecordPage'
import FileRecordPortalPage from './me/FileRecordPortalPage'
import MessageAndNotificationPage from './me/MessageAndNotificaitonPage'
import PCLoginPage from './pc/PCLoginPage'
import WebViewPage from './misc/WebViewPage'
import OrganizationTreePage from './organization/OrganizationTreePage'
import PickOrganizationMemberPage from './organization/PickOrganizationMemberPage'
import PickMultiContactPage from './picker/PickMultiContactPage'
import SearchConversationMessagePage from './search/SearchConversationMessagePage'
import SearchPortalPage from './search/SearchPortalPage'
import SearchUserPage from './search/SearchUserPage'
import UpdateUserInfoPage from './user/UpdateUserInfoPage'
import UserInfoPage from './user/UserInfoPage'
import TextMessageContentView from './conversation/message/TextMessageContentView'
import TextMessagePreviewPage from './conversation/TextMessagePreviewPage'
import PCSessionPage from './pc/PCSessionPage'
import UpdateUserNickNameOrAliasPage from './user/UpdateUserNickNameOrAliasPage'
import SingleVideoCallPage from './voip/SingleVideoCallPage'
import SingleAudioCallPage from './voip/SingleAudioCallPage'
import MultiAudioCallPage from './voip/MultiAudioCallPage'
import MultiVideoCallPage from './voip/MultiVideoCallPage'
import GroupMemberPermissionPage from './group/GroupMemberPermissionPage'
import GroupMemberListPage from './group/GroupMemberListPage'
import GroupJoinRequestListPage from './group/GroupJoinRequestListPage'
import ChatroomConversationInfoPage from './conversation/ChatroomConversationInfoPage'
import FileRecordPage from './me/FileRecordPage'
import ConferenceInfoPage from './voip/conference/ConferenceInfoPage'
import ConferencePortalPage from './voip/conference/ConferencePortalPage'
import ConferencePage from './voip/conference/ConferencePage'
import StartConferencePage from './voip/conference/StartConferencePage'
import OrderConferencePage from './voip/conference/OrderConferencePage'
import ConferenceParticipantListPage from './voip/conference/ConferenceParticipantListPage'

export const UIKIT_NAV_DESTINATION_PREFIX = 'uikit-';

export class uikitNavigationDestinations {
    static SearchPortalPage = UIKIT_NAV_DESTINATION_PREFIX + 'searchPortalPage'
    static ConversationPage = UIKIT_NAV_DESTINATION_PREFIX + 'conversationPage'
    static SingleConversationInfoPage = UIKIT_NAV_DESTINATION_PREFIX + 'singleConversationInfoPage'
    static GroupConversationInfoPage = UIKIT_NAV_DESTINATION_PREFIX + 'groupConversationInfo'
    static ChannelConversationInfoPage = UIKIT_NAV_DESTINATION_PREFIX + 'channelConversationInfoPage'
    static ChatroomConversationInfoPage = UIKIT_NAV_DESTINATION_PREFIX + 'chatroomConversationInfoPage'
    static UserInfoPage = UIKIT_NAV_DESTINATION_PREFIX + 'userInfoPage'
    static FriendRequestListPage = UIKIT_NAV_DESTINATION_PREFIX + 'friendRequestListPage'
    static SearchUserPage = UIKIT_NAV_DESTINATION_PREFIX + 'searchUserPage'
    static FavGroupListPage = UIKIT_NAV_DESTINATION_PREFIX + 'favGroupListPage'
    static ChannelListPage = UIKIT_NAV_DESTINATION_PREFIX + 'channelListPage'
    static ChatroomListPage = UIKIT_NAV_DESTINATION_PREFIX + 'chatroomListPage'
    static WebViewPage = UIKIT_NAV_DESTINATION_PREFIX + 'webViewPage'
    static PickMultiContactPage = UIKIT_NAV_DESTINATION_PREFIX + 'pickContactPage'
    static SearchConversationMessagePage = UIKIT_NAV_DESTINATION_PREFIX + 'searchConversationMessagePage'
    static UpdateUserInfoPage = UIKIT_NAV_DESTINATION_PREFIX + 'updateUserInfoPage'
    static UpdateGroupAnnouncementPage = UIKIT_NAV_DESTINATION_PREFIX + 'updateGroupAnnouncementPage'
    static UpdateGroupNamePage = UIKIT_NAV_DESTINATION_PREFIX + 'updateGroupNamePage'
    static UpdateGroupRemarkPage = UIKIT_NAV_DESTINATION_PREFIX + 'updateGroupRemarkPage'
    static UpdateMyGroupAliasPage = UIKIT_NAV_DESTINATION_PREFIX + 'updateMyGroupAliasPage'
    static GroupQRCodePage = UIKIT_NAV_DESTINATION_PREFIX + 'groupQRCodePage'
    static GroupManagePage = UIKIT_NAV_DESTINATION_PREFIX + 'groupManagePage'
    static GroupManagerListPage = UIKIT_NAV_DESTINATION_PREFIX + 'groupManagerListPage'
    static GroupMemberMuteOrAllowListPage = UIKIT_NAV_DESTINATION_PREFIX + 'groupMemberMuteOrAllowListPage'
    static AccountPage = UIKIT_NAV_DESTINATION_PREFIX + 'accountPage'
    static FavRecordPage = UIKIT_NAV_DESTINATION_PREFIX + 'favRecordPage'
    static FileRecordPortalPage = UIKIT_NAV_DESTINATION_PREFIX + 'fileRecordPortalPage'
    static FileRecordPage = UIKIT_NAV_DESTINATION_PREFIX + 'fileRecordPage'
    static NotificationPage = UIKIT_NAV_DESTINATION_PREFIX + 'messageAndNotificationPage'
    static CompositeMessagePreviewPage = UIKIT_NAV_DESTINATION_PREFIX + 'compositeMessagePreviewPage'
    static OrganizationTreePage = UIKIT_NAV_DESTINATION_PREFIX + 'organizationTreePage'
    static PickOrganizationMemberPage = UIKIT_NAV_DESTINATION_PREFIX + 'pickOrganizationMemberPage'
    static ForwardMessagePage = UIKIT_NAV_DESTINATION_PREFIX + 'forwardMessagePage'
    static GroupInfoPage = UIKIT_NAV_DESTINATION_PREFIX + 'groupInfoPage'
    static PCLoginPage = UIKIT_NAV_DESTINATION_PREFIX + 'pcLoginPage'
    static TextMessagePreviewPage = UIKIT_NAV_DESTINATION_PREFIX + 'textMessagePreviewPage'
    static PCSessionPage = UIKIT_NAV_DESTINATION_PREFIX + 'pcSessionPage'
    static UpdateUserNickNameOrAliasPage = UIKIT_NAV_DESTINATION_PREFIX + 'updateUserNickNameOrAliasPage'
    static ResetPasswordPage = UIKIT_NAV_DESTINATION_PREFIX + 'resetPasswordPage'
    static ChangePasswordPage = UIKIT_NAV_DESTINATION_PREFIX + 'changePasswordPage'
    static SingleAudioCallPage = UIKIT_NAV_DESTINATION_PREFIX + 'singleAudioCallPage'
    static SingleVideoCallPage = UIKIT_NAV_DESTINATION_PREFIX + 'singleVideoCallPage'
    static MultiAudioCallPage = UIKIT_NAV_DESTINATION_PREFIX + 'multiAudioCallPage'
    static MultiVideoCallPage = UIKIT_NAV_DESTINATION_PREFIX + 'multiVideoCallPage'
    static ConferencePage = UIKIT_NAV_DESTINATION_PREFIX + 'conferencePage'
    static GroupMemberPermissionPage = UIKIT_NAV_DESTINATION_PREFIX + 'groupMemberPermissionPage'
    static GroupMemberListPage = UIKIT_NAV_DESTINATION_PREFIX + 'groupMemberListPage'
    static ConferenceInfoPage = UIKIT_NAV_DESTINATION_PREFIX + 'conferenceInfoPage'
    static ConferencePortalPage = UIKIT_NAV_DESTINATION_PREFIX + 'conferencePortalPage'
    static StartConferencePage = UIKIT_NAV_DESTINATION_PREFIX + 'startConferencePage'
    static OrderConferencePage = UIKIT_NAV_DESTINATION_PREFIX + 'orderConferencePage'
    static ConferenceParticipantListPage = UIKIT_NAV_DESTINATION_PREFIX + 'conferenceParticipantListPage'
    static GroupJoinRequestListPage = UIKIT_NAV_DESTINATION_PREFIX + 'groupJoinRequestListPage'
}

@Builder
export function UIKitPageMap(name: string) {
    // TODO add more
    // TODO FIXME 参数使用 NavDestination.onReady 处理，而不是 aboutToAppear
    if (name == uikitNavigationDestinations.SearchPortalPage) {
        SearchPortalPage()
    } else if (name == uikitNavigationDestinations.ConversationPage) {
        ConversationPage()
    } else if (name === uikitNavigationDestinations.SingleConversationInfoPage) {
        SingleConversationInfoPage()
    } else if (name === uikitNavigationDestinations.GroupConversationInfoPage) {
        GroupConversationInfoPage()
    } else if (name === uikitNavigationDestinations.ChannelConversationInfoPage) {
        ChannelConversationInfoPage()
    } else if (name === uikitNavigationDestinations.ChatroomConversationInfoPage) {
        ChatroomConversationInfoPage()
    } else if (name === uikitNavigationDestinations.UserInfoPage) {
        UserInfoPage()
    } else if (name === uikitNavigationDestinations.FriendRequestListPage) {
        FriendRequestListPage();
    } else if (name === uikitNavigationDestinations.SearchUserPage) {
        SearchUserPage();
    } else if (name === uikitNavigationDestinations.FavGroupListPage) {
        FavGroupListPage();
    } else if (name === uikitNavigationDestinations.ChannelListPage) {
        ChannelListPage();
    } else if (name === uikitNavigationDestinations.ChatroomListPage) {
        ChatroomListPage()
    } else if (name === uikitNavigationDestinations.WebViewPage) {
        WebViewPage()
    } else if (name === uikitNavigationDestinations.PickMultiContactPage) {
        PickMultiContactPage()
    } else if (name === uikitNavigationDestinations.SearchConversationMessagePage) {
        SearchConversationMessagePage()
    } else if (name === uikitNavigationDestinations.UpdateUserInfoPage) {
        UpdateUserInfoPage()
    } else if (name === uikitNavigationDestinations.UpdateGroupAnnouncementPage) {
        UpdateGroupAnnouncementPage()
    } else if (name === uikitNavigationDestinations.UpdateGroupNamePage) {
        UpdateGroupNamePage()
    } else if (name === uikitNavigationDestinations.UpdateGroupRemarkPage) {
        UpdateGroupRemarkNamePage()
    } else if (name === uikitNavigationDestinations.UpdateMyGroupAliasPage) {
        UpdateMyGroupAliasNamePage()
    } else if (name === uikitNavigationDestinations.GroupQRCodePage) {
        GroupQRCodePage()
    } else if (name === uikitNavigationDestinations.GroupManagePage) {
        GroupManagePage()
    } else if (name === uikitNavigationDestinations.GroupManagerListPage) {
        GroupManagerListPage()
    } else if (name === uikitNavigationDestinations.GroupMemberMuteOrAllowListPage) {
        GroupMemberMuteOrAllowListPage()
    } else if (name === uikitNavigationDestinations.FavRecordPage) {
        FavRecordPage()
    } else if (name === uikitNavigationDestinations.FileRecordPortalPage) {
        FileRecordPortalPage()
    } else if (name === uikitNavigationDestinations.FileRecordPage) {
        FileRecordPage()
    } else if (name === uikitNavigationDestinations.NotificationPage) {
        MessageAndNotificationPage()
    } else if (name === uikitNavigationDestinations.CompositeMessagePreviewPage) {
        CompositeMessagePreviewPage()
    } else if (name === uikitNavigationDestinations.TextMessagePreviewPage) {
        TextMessagePreviewPage()
    } else if (name === uikitNavigationDestinations.OrganizationTreePage) {
        OrganizationTreePage()
    } else if (name === uikitNavigationDestinations.PickOrganizationMemberPage) {
        PickOrganizationMemberPage()
    } else if (name === uikitNavigationDestinations.ForwardMessagePage) {
        ForwardMessagePage()
    } else if (name === uikitNavigationDestinations.GroupInfoPage) {
        GroupInfoPage()
    } else if (name === uikitNavigationDestinations.PCLoginPage) {
        PCLoginPage()
    } else if (name === uikitNavigationDestinations.PCSessionPage) {
        PCSessionPage()
    } else if (name === uikitNavigationDestinations.UpdateUserNickNameOrAliasPage) {
        UpdateUserNickNameOrAliasPage()
    } else if (name === uikitNavigationDestinations.GroupMemberPermissionPage) {
        GroupMemberPermissionPage()
    } else if (name === uikitNavigationDestinations.GroupMemberListPage) {
        GroupMemberListPage()
    } else if (name === uikitNavigationDestinations.SingleVideoCallPage) {
        SingleVideoCallPage()
    } else if (name === uikitNavigationDestinations.SingleAudioCallPage) {
        SingleAudioCallPage()
    } else if (name === uikitNavigationDestinations.MultiAudioCallPage) {
        MultiAudioCallPage()
    } else if (name === uikitNavigationDestinations.MultiVideoCallPage) {
        MultiVideoCallPage()
    } else if (name === uikitNavigationDestinations.ConferencePortalPage) {
        ConferencePortalPage()
    } else if (name === uikitNavigationDestinations.ConferenceInfoPage) {
        ConferenceInfoPage()
    } else if (name === uikitNavigationDestinations.ConferencePage) {
        ConferencePage()
    } else if (name === uikitNavigationDestinations.StartConferencePage) {
        StartConferencePage()
    } else if (name === uikitNavigationDestinations.OrderConferencePage) {
        OrderConferencePage()
    } else if (name === uikitNavigationDestinations.ConferenceParticipantListPage) {
        ConferenceParticipantListPage()
    } else if (name === uikitNavigationDestinations.GroupJoinRequestListPage) {
        GroupJoinRequestListPage()
    } else {
        NavDestination() {
            Column() {
                Text('UIKIT Nav destination not found')
            }
            .width('100%')
            .height('100%')
        }
    }
}
