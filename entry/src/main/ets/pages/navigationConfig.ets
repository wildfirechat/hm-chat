import ChannelListPage from './channel/ChannelListPage'
import ChatroomListPage from './chatroom/ChatroomListPage'
import FriendRequestListPage from './contact/FriendRequestListPage'
import ChannelConversationInfoPage from './conversation/ChannelConversationInfoPage'
import ConversationFileRecordPage from './conversation/ConversationFileRecordPage'
import ConversationPage from './conversation/ConversationPage'
import ForwardMessagePage from './conversation/forward/ForwardMessagePage'
import GroupConversationInfoPage from './conversation/GroupConversationInfoPage'
import PreviewCompositeMessagePage from './conversation/PreviewCompositeMessagePage'
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
import AboutPage from './me/AboutPage'
import AccountPage from './me/AccountPage'
import FavRecordPage from './me/FavRecordPage'
import FileRecordPage from './me/FileRecordPage'
import MessageAndNotificationPage from './me/MessageAndNotificaitonPage'
import SettingPage from './me/SettingPage'
import PCLoginPage from './misc/PCLoginPage'
import WebViewPage from './misc/WebViewPage'
import OrganizationTreePage from './organization/OrganizationTreePage'
import PickOrganizationMemberPage from './organization/PickOrganizationMemberPage'
import PickContactPage from './picker/PickContactPage'
import SearchConversationMessagePage from './search/SearchConversationMessagePage'
import SearchPortalPage from './search/SearchPortalPage'
import SearchUserPage from './search/SearchUserPage'
import UpdateUserInfoPage from './user/UpdateUserInfoPage'
import UserInfoPage from './user/UserInfoPage'


export class navigationDestinations {
    static SearchPortalPage = 'searchPortalPage'
    static ConversationPage = 'conversationPage'
    static SingleConversationInfoPage = 'singleConversationInfoPage'
    static GroupConversationInfoPage = 'groupConversationInfo'
    static ChannelConversationInfoPage = 'channelConversationInfoPage'
    static UserInfoPage = 'userInfoPage'
    static FriendRequestListPage = 'friendRequestListPage'
    static SearchUserPage = 'searchUserPage'
    static FavGroupListPage = 'favGroupListPage'
    static ChannelListPage = 'channelListPage'
    static ChatroomListPage = 'chatroomListPage'
    static WebViewPage = 'webViewPage'
    static PickContactPage = 'pickContactPage'
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
    static FileRecordPage = 'fileRecordPage'
    static ConversationFileRecordPage = 'conversationFileRecordPage'
    static NotificationPage = 'messageAndNotificationPage'
    static SettingPage = 'settingPage'
    static AboutPage = 'aboutPage'
    static PreviewCompositeMessagePage = 'previewCompositeMessagePage'
    static OrganizationTreePage = 'organizationTreePage'
    static PickOrganizationMemberPage = 'pickOrganizationMemberPage'
    static ForwardMessagePage = 'forwardMessagePage'
    static GroupInfoPage = 'groupInfoPage'
    static PCLoginPage = 'pcLoginPage'
}

@Builder
export function PagesMap(name: string) {
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
    } else if (name === navigationDestinations.PickContactPage) {
        PickContactPage()
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
    } else if (name === navigationDestinations.AccountPage) {
        AccountPage()
    } else if (name === navigationDestinations.FavRecordPage) {
        FavRecordPage()
    } else if (name === navigationDestinations.FileRecordPage) {
        FileRecordPage()
    } else if (name === navigationDestinations.ConversationFileRecordPage) {
        ConversationFileRecordPage()
    } else if (name === navigationDestinations.NotificationPage) {
        MessageAndNotificationPage()
    } else if (name === navigationDestinations.SettingPage) {
        SettingPage()
    } else if (name === navigationDestinations.AboutPage) {
        AboutPage()
    } else if (name === navigationDestinations.PreviewCompositeMessagePage) {
        PreviewCompositeMessagePage()
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
    }
}
