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
import ChatroomConversationInfoPage from './conversation/ChatroomConversationInfoPage'
import FileRecordPage from './me/FileRecordPage'
import ConferenceInfoPage from './voip/conference/ConferenceInfoPage'
import ConferencePortalPage from './voip/conference/ConferencePortalPage'
import ConferencePage from './voip/conference/ConferencePage'
import StartConferencePage from './voip/conference/StartConferencePage'
import OrderConferencePage from './voip/conference/OrderConferencePage'
import ConferenceParticipantListPage from './voip/conference/ConferenceParticipantListPage'

export class navigationDestinations {
    static SearchPortalPage = 'searchPortalPage'
    static ConversationPage = 'conversationPage'
    static SingleConversationInfoPage = 'singleConversationInfoPage'
    static GroupConversationInfoPage = 'groupConversationInfo'
    static ChannelConversationInfoPage = 'channelConversationInfoPage'
    static ChatroomConversationInfoPage = 'chatroomConversationInfoPage'
    static UserInfoPage = 'userInfoPage'
    static FriendRequestListPage = 'friendRequestListPage'
    static SearchUserPage = 'searchUserPage'
    static FavGroupListPage = 'favGroupListPage'
    static ChannelListPage = 'channelListPage'
    static ChatroomListPage = 'chatroomListPage'
    static WebViewPage = 'webViewPage'
    static PickMultiContactPage = 'pickContactPage'
    static SearchConversationMessagePage = 'searchConversationMessagePage'
    static UpdateUserInfoPage = 'updateUserInfoPage'
    static UpdateGroupAnnouncementPage = 'updateGroupAnnouncementPage'
    static UpdateGroupNamePage = 'updateGroupNamePage'
    static UpdateGroupRemarkPage = 'updateGroupRemarkPage'
    static UpdateMyGroupAliasPage = 'updateMyGroupAliasPage'
    static GroupQRCodePage = 'groupQRCodePage'
    static GroupManagePage = 'groupManagePage'
    static GroupManagerListPage = 'groupManagerListPage'
    static GroupMemberMuteOrAllowListPage = 'groupMemberMuteOrAllowListPage'
    static AccountPage = 'accountPage'
    static FavRecordPage = 'favRecordPage'
    static FileRecordPortalPage = 'fileRecordPortalPage'
    static FileRecordPage = 'fileRecordPage'
    static NotificationPage = 'messageAndNotificationPage'
    static CompositeMessagePreviewPage = 'compositeMessagePreviewPage'
    static OrganizationTreePage = 'organizationTreePage'
    static PickOrganizationMemberPage = 'pickOrganizationMemberPage'
    static ForwardMessagePage = 'forwardMessagePage'
    static GroupInfoPage = 'groupInfoPage'
    static PCLoginPage = 'pcLoginPage'
    static TextMessagePreviewPage = 'textMessagePreviewPage'
    static PCSessionPage = 'pcSessionPage'
    static UpdateUserNickNameOrAliasPage = 'updateUserNickNameOrAliasPage'
    static ResetPasswordPage = 'resetPasswordPage'
    static ChangePasswordPage = 'changePasswordPage'
    static SingleAudioCallPage = 'singleAudioCallPage'
    static SingleVideoCallPage = 'singleVideoCallPage'
    static MultiAudioCallPage = 'multiAudioCallPage'
    static MultiVideoCallPage = 'multiVideoCallPage'
    static ConferencePage = 'conferencePage'
    static GroupMemberPermissionPage = 'groupMemberPermissionPage'
    static GroupMemberListPage = 'groupMemberListPage'
    static ConferenceInfoPage = 'conferenceInfoPage'
    static ConferencePortalPage = 'conferencePortalPage'
    static StartConferencePage = 'startConferencePage'
    static OrderConferencePage = 'orderConferencePage'
    static ConferenceParticipantListPage = 'conferenceParticipantListPage'
}

@Builder
export function UIKitPageMap(name: string) {
    // TODO add more
    // TODO FIXME 参数使用 NavDestination.onReady 处理，而不是 aboutToAppear
    if (name == navigationDestinations.SearchPortalPage) {
        SearchPortalPage()
    } else if (name == navigationDestinations.ConversationPage) {
        ConversationPage()
    } else if (name === navigationDestinations.SingleConversationInfoPage) {
        SingleConversationInfoPage()
    } else if (name === navigationDestinations.GroupConversationInfoPage) {
        GroupConversationInfoPage()
    } else if (name === navigationDestinations.ChannelConversationInfoPage) {
        ChannelConversationInfoPage()
    } else if (name === navigationDestinations.ChatroomConversationInfoPage) {
        ChatroomConversationInfoPage()
    } else if (name === navigationDestinations.UserInfoPage) {
        UserInfoPage()
    } else if (name === navigationDestinations.FriendRequestListPage) {
        FriendRequestListPage();
    } else if (name === navigationDestinations.SearchUserPage) {
        SearchUserPage();
    } else if (name === navigationDestinations.FavGroupListPage) {
        FavGroupListPage();
    } else if (name === navigationDestinations.ChannelListPage) {
        ChannelListPage();
    } else if (name === navigationDestinations.ChatroomListPage) {
        ChatroomListPage()
    } else if (name === navigationDestinations.WebViewPage) {
        WebViewPage()
    } else if (name === navigationDestinations.PickMultiContactPage) {
        PickMultiContactPage()
    } else if (name === navigationDestinations.SearchConversationMessagePage) {
        SearchConversationMessagePage()
    } else if (name === navigationDestinations.UpdateUserInfoPage) {
        UpdateUserInfoPage()
    } else if (name === navigationDestinations.UpdateGroupAnnouncementPage) {
        UpdateGroupAnnouncementPage()
    } else if (name === navigationDestinations.UpdateGroupNamePage) {
        UpdateGroupNamePage()
    } else if (name === navigationDestinations.UpdateGroupRemarkPage) {
        UpdateGroupRemarkNamePage()
    } else if (name === navigationDestinations.UpdateMyGroupAliasPage) {
        UpdateMyGroupAliasNamePage()
    } else if (name === navigationDestinations.GroupQRCodePage) {
        GroupQRCodePage()
    } else if (name === navigationDestinations.GroupManagePage) {
        GroupManagePage()
    } else if (name === navigationDestinations.GroupManagerListPage) {
        GroupManagerListPage()
    } else if (name === navigationDestinations.GroupMemberMuteOrAllowListPage) {
        GroupMemberMuteOrAllowListPage()
    } else if (name === navigationDestinations.FavRecordPage) {
        FavRecordPage()
    } else if (name === navigationDestinations.FileRecordPortalPage) {
        FileRecordPortalPage()
    } else if (name === navigationDestinations.FileRecordPage) {
        FileRecordPage()
    } else if (name === navigationDestinations.NotificationPage) {
        MessageAndNotificationPage()
    } else if (name === navigationDestinations.CompositeMessagePreviewPage) {
        CompositeMessagePreviewPage()
    } else if (name === navigationDestinations.TextMessagePreviewPage) {
        TextMessagePreviewPage()
    } else if (name === navigationDestinations.OrganizationTreePage) {
        OrganizationTreePage()
    } else if (name === navigationDestinations.PickOrganizationMemberPage) {
        PickOrganizationMemberPage()
    } else if (name === navigationDestinations.ForwardMessagePage) {
        ForwardMessagePage()
    } else if (name === navigationDestinations.GroupInfoPage) {
        GroupInfoPage()
    } else if (name === navigationDestinations.PCLoginPage) {
        PCLoginPage()
    } else if (name === navigationDestinations.PCSessionPage) {
        PCSessionPage()
    } else if (name === navigationDestinations.UpdateUserNickNameOrAliasPage) {
        UpdateUserNickNameOrAliasPage()
    } else if (name === navigationDestinations.GroupMemberPermissionPage) {
        GroupMemberPermissionPage()
    } else if (name === navigationDestinations.GroupMemberListPage) {
        GroupMemberListPage()
    } else if (name === navigationDestinations.SingleVideoCallPage) {
        SingleVideoCallPage()
    } else if (name === navigationDestinations.SingleAudioCallPage) {
        SingleAudioCallPage()
    } else if (name === navigationDestinations.MultiAudioCallPage) {
        MultiAudioCallPage()
    } else if (name === navigationDestinations.MultiVideoCallPage) {
        MultiVideoCallPage()
    } else if (name === navigationDestinations.ConferencePortalPage) {
        ConferencePortalPage()
    } else if (name === navigationDestinations.ConferenceInfoPage) {
        ConferenceInfoPage()
    } else if (name === navigationDestinations.ConferencePage) {
        ConferencePage()
    } else if (name === navigationDestinations.StartConferencePage) {
        StartConferencePage()
    } else if (name === navigationDestinations.OrderConferencePage) {
        OrderConferencePage()
    } else if (name === navigationDestinations.ConferenceParticipantListPage) {
        ConferenceParticipantListPage()
    }
}
