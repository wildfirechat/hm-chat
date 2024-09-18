/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import TextMessageContent from '../messages/textMessageContent'
import PTextMessageContent from '../messages/ptextMessageContent'
import ImageMessageContent from '../messages/imageMessageContent';

import MessageContentType from '../messages/messageContentType';

import PersistFlag from '../messages/persistFlag';
import TipNotificationMessageContent from '../messages/notification/tipNotification';
import UnknownMessageContent from '../messages/unknownMessageContent';
import UnsupportMessageContent from '../messages/unsupportMessageConten';
import ChangeGroupNameNotification from '../messages/notification/changeGroupNameNotification';
import KickoffGroupMemberNotification from '../messages/notification/kickoffGroupMemberNotification';
import KickoffGroupMemberVisiableNotification from '../messages/notification/kickoffGroupMemberVisiableNotification';
import AddGroupMemberNotification from '../messages/notification/addGroupMemberNotification';
import ChangeGroupPortraitNotification from '../messages/notification/changeGroupPortraitNotification';
import CreateGroupNotification from '../messages/notification/createGroupNotification';
import DismissGroupNotification from '../messages/notification/dismissGroupNotification';
import ModifyGroupAliasNotification from '../messages/notification/modifyGroupAliasNotification';
import ModifyGroupExtraNotification from '../messages/notification/modifyGroupExtraNotification';
import ModifyGroupMemberExtraNotification from '../messages/notification/modifyGroupMemberExtraNotification';
import QuitGroupNotification from '../messages/notification/quitGroupNotification';
import QuitGroupVisiableNotification from '../messages/notification/quitGroupVisiableNotification';
import TransferGroupOwnerNotification from '../messages/notification/transferGroupOwnerNotification';
import FileMessageContent from '../messages/fileMessageContent';
import VideoMessageContent from '../messages/videoMessageContent';
import StickerMessageContent from '../messages/stickerMessageContent';
import SoundMessageContent from '../messages/soundMessageContent';
import TypingMessageContent from '../messages/typingMessageContent';
import RecallMessageNotification from '../messages/notification/recallMessageNotification';
import DeleteMessageContent from '../messages/deleteMessageContent';

import CallStartMessageContent from '../av/messages/callStartMessageContent';
import CallAnswerMessageContent from '../av/messages/callAnswerMessageContent';
import CallAnswerTMessageContent from '../av/messages/callAnswerTMessageContent';
import CallByeMessageContent from '../av/messages/callByeMessageContent';
import CallSignalMessageContent from '../av/messages/callSignalMessageContent';
import CallModifyMessageContent from '../av/messages/callModifyMessageContent';
import AddParticipantsMessageContent from "../av/messages/addParticipantsMessageContent";
import MuteVideoMessageContent from "../av/messages/muteVideoMessageContent";
import GroupJoinTypeNotificationContent from "../messages/notification/groupJoinTypeNotificationContent";
import GroupMuteNotificationContent from "../messages/notification/groupMuteNotificationContent";
import GroupSetManagerNotificationContent from "../messages/notification/groupSetManagerNotificationContent";
import GroupPrivateChatNotificationContent from "../messages/notification/groupPrivateChatNotificationContent";
import LocationMessageContent from "../messages/locationMessageContent";
import MuteGroupMemberNotification from '../messages/notification/muteGroupMemberNotification'
import AllowGroupMemberNotification from '../messages/notification/allowGroupMemberNotification'
import CardMessageContent from '../messages/cardMessageContent'
import CompositeMessageContent from "../messages/compositeMessageContent";
import ConferenceInviteMessageContent from "../av/messages/conferenceInviteMessageContent";
import ConferenceChangeModeContent from "../av/messages/conferenceChangeModeContent";
import ConferenceKickoffMemberMessageContent from "../av/messages/conferenceKickoffMemberMessageContent";
import MarkUnreadMessageContent from "../messages/markUnreadMessageContent";
import LinkMessageContent from "../messages/linkMessageContent";
import FriendAddedNotification from "../messages/notification/friendAddedNotification";
import FriendGreetingNotification from "../messages/notification/friendGreetingNotification";
import StartSecretChatNotification from "../messages/notification/startSecretChatNotification";
import MultiCallOngoingMessageContent from "../av/messages/multiCallOngoingMessageContent";
import JoinCallRequestMessageContent from "../av/messages/joinCallRequestMessageContent";
import RichNotificationMessageContent from "../messages/notification/richNotificationMessageContent";
import ArticlesMessageContent from "../messages/articlesMessageContent";
import ConferenceCommandMessageContent from "../av/messages/conferenceCommandMessageContent";
import ChannelMenuEventMessageContent from "../messages/channelMenuEventMessageContent";
import EnterChannelChatMessageContent from "../messages/enterChannelChatMessageContent";
import LeaveChannelChatMessageContent from "../messages/leaveChannelChatMessageContent";
import ModifyGroupSettingNotification from "../messages/notification/modifyGroupSettingNotification";
import MessageContent from '../messages/messageContent';
import { DEFAULT } from '@ohos/hypium';
import PCLoginRequestMessageContent from '../messages/pcLoginRequestMessageContent';

export default class MessageConfig {
    static getMessageContentFlag(type: number) {
        let flag = PersistFlag.No_Persist;
        for (const content of MessageConfig.MessageContents) {
            if (content.type === type) {
                flag = content.flag;
            }
        }
        return flag;
    }

    static getMessageContentPersitFlag(type: number) {
        for (const content of MessageConfig.MessageContents) {
            if (content.type === type) {
                return content.flag;
            }
        }
        return -1;
    }

    static registerMessageContent(name: string, flag: number, type: number, clazz: Promise<typeof import("../messages/messageContent")>) {
        // TODO validate args

        MessageConfig.MessageContents.push(
            {
                name: name,
                flag: flag,
                type: type,
                contentClazz: clazz,
            }
        );

    }

    static newMessageContent(type: number): MessageContent {
        let content: MessageContent
        switch (type) {
            case MessageContentType.Unknown:
                content = new UnknownMessageContent()
                break
            case MessageContentType.Text:
                content = new TextMessageContent()
                break
            case MessageContentType.Image:
                content = new ImageMessageContent()
                break
            case MessageContentType.P_Text:
                content = new PTextMessageContent()
                break
            case MessageContentType.Voice:
                content = new SoundMessageContent()
                break
            case MessageContentType.Image:
                content = new ImageMessageContent()
                break
            case MessageContentType.Location:
                content = new LocationMessageContent()
                break
            case MessageContentType.File:
                content = new FileMessageContent()
                break
            case MessageContentType.Video:
                content = new VideoMessageContent()
                break
            case MessageContentType.Sticker:
                content = new StickerMessageContent()
                break
            case MessageContentType.Link:
                content = new LinkMessageContent()
                break
            case MessageContentType.UserCard:
                content = new CardMessageContent()
                break
            case MessageContentType.Composite_Message:
                content = new CompositeMessageContent()
                break
            case MessageContentType.Tip_Notification:
                content = new TipNotificationMessageContent()
                break
            case MessageContentType.Typing:
                content = new TypingMessageContent()
                break
            case MessageContentType.Friend_Added:
                content = new FriendGreetingNotification()
                break
            case MessageContentType.Friend_Greeting:
                content = new FriendAddedNotification()
                break
            case MessageContentType.AddGroupMember_Notification:
                content = new AddGroupMemberNotification()
                break
            case MessageContentType.ChangeGroupName_Notification:
                content = new ChangeGroupNameNotification()
                break
            case MessageContentType.ChangeGroupPortrait_Notification:
                content = new ChangeGroupPortraitNotification()
                break
            case MessageContentType.CreateGroup_Notification:
                content = new CreateGroupNotification()
                break
            case MessageContentType.DismissGroup_Notification:
                content = new DismissGroupNotification()
                break
            case MessageContentType.KickOffGroupMember_Notification:
                content = new KickoffGroupMemberNotification()
                break
            case MessageContentType.KickOffGroupMember_Visible_Notification:
                content = new KickoffGroupMemberVisiableNotification()
                break
            case MessageContentType.ModifyGroupAlias_Notification:
                content = new ModifyGroupAliasNotification()
                break
            case MessageContentType.ModifyGroupExtra_Notification:
                content = new ModifyGroupExtraNotification()
                break
            case MessageContentType.ModifyGroupMemberExtra_Notification:
                content = new ModifyGroupMemberExtraNotification()
                break
            case MessageContentType.QuitGroup_Notification:
                content = new QuitGroupNotification()
                break
            case MessageContentType.QuitGroup_Visible_Notification:
                content = new QuitGroupVisiableNotification()
                break
            case MessageContentType.TransferGroupOwner_Notification:
                content = new TransferGroupOwnerNotification()
                break
            case MessageContentType.ChangeJoinType_Notification:
                content = new GroupJoinTypeNotificationContent()
                break
            case MessageContentType.MuteGroup_Notification:
                content = new GroupMuteNotificationContent()
                break
            case MessageContentType.ChangePrivateChat_Notification:
                content = new GroupPrivateChatNotificationContent()
                break
            case MessageContentType.SetGroupManager_Notification:
                content = new GroupSetManagerNotificationContent()
                break
            case MessageContentType.MuteGroupMember_Notification:
                content = new MuteGroupMemberNotification()
                break
            case MessageContentType.AllowGroupMember_Notification:
                content = new AllowGroupMemberNotification()
                break
            case MessageContentType.ModifyGroupSetting_Notification:
                content = new ModifyGroupSettingNotification()
                break
            case MessageContentType.RecallMessage_Notification:
                content = new RecallMessageNotification()
                break
            case MessageContentType.DeleteMessage_Notification:
                content = new DeleteMessageContent()
                break
            case MessageContentType.VOIP_CONTENT_TYPE_START:
                content = new CallStartMessageContent()
                break
            case MessageContentType.VOIP_CONTENT_TYPE_ACCEPT:
                content = new CallAnswerMessageContent()
                break
            case MessageContentType.VOIP_CONTENT_TYPE_ACCEPT_T:
                content = new CallAnswerTMessageContent()
                break
            case MessageContentType.VOIP_CONTENT_TYPE_END:
                content = new CallByeMessageContent()
                break
            case MessageContentType.VOIP_CONTENT_TYPE_SIGNAL:
                content = new CallSignalMessageContent()
                break
            case MessageContentType.VOIP_CONTENT_TYPE_MODIFY:
                content = new CallModifyMessageContent()
                break
            case MessageContentType.VOIP_CONTENT_TYPE_ADD_PARTICIPANT:
                content = new AddParticipantsMessageContent()
                break

            case MessageContentType.VOIP_CONTENT_TYPE_MUTE_VIDEO:
                content = new MuteVideoMessageContent()
                break
            case MessageContentType.CONFERENCE_CONTENT_TYPE_INVITE:
                content = new ConferenceInviteMessageContent()
                break
            case MessageContentType.CONFERENCE_CONTENT_TYPE_CHANGE_MODE:
                content = new ConferenceChangeModeContent()
                break
            case MessageContentType.CONFERENCE_CONTENT_TYPE_KICKOFF_MEMBER:
                content = new ConferenceKickoffMemberMessageContent()
                break
            case MessageContentType.VOIP_Multi_Call_Ongoing:
                content = new MultiCallOngoingMessageContent()
                break
            case MessageContentType.VOIP_Join_Call_Request:
                content = new JoinCallRequestMessageContent()
                break
            case MessageContentType.Mark_Unread_Sync:
                content = new MarkUnreadMessageContent()
                break
            case MessageContentType.StartSecretChat_Notification:
                content = new StartSecretChatNotification()
                break
            case MessageContentType.Rich_Notification:
                content = new RichNotificationMessageContent()
                break
            case MessageContentType.Articles:
                content = new ArticlesMessageContent()
                break
            case MessageContentType.Channel_Menu_Event:
                content = new ChannelMenuEventMessageContent()
                break
            case MessageContentType.Enter_Channel_Chat:
                content = new EnterChannelChatMessageContent()
                break
            case MessageContentType.Leave_Channel_Chat:
                content = new LeaveChannelChatMessageContent()
                break
            case MessageContentType.CONFERENCE_CONTENT_TYPE_COMMAND:
                content = new ConferenceCommandMessageContent()
                break
            case MessageContentType.PC_Login_Request:
                content = new PCLoginRequestMessageContent()
                break
            default:
                content = new UnknownMessageContent()
                break
        }
        return content;
    }

    static MessageContents: MessageContentConfig[] = [
        {
            name: 'unknown',
            flag: PersistFlag.Persist,
            type: MessageContentType.Unknown,
        },
        {
            name: 'text',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Text,
        },
        {
            name: 'ptext',
            flag: PersistFlag.Persist,
            type: MessageContentType.P_Text,
        },
        {
            name: 'voice',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Voice,
        },
        {
            name: 'image',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Image,
        },
        {
            name: 'location',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Location,
        },
        {
            name: 'file',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.File,
        },
        {
            name: 'video',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Video,
        },
        {
            name: 'sticker',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Sticker,
        },
        {
            name: 'link',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Link,
        },
        {
            name: 'userCard',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.UserCard,
        },
        {
            name: 'compositeMessage',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Composite_Message,
        },
        {
            name: 'tip',
            flag: PersistFlag.Persist,
            type: MessageContentType.Tip_Notification,
        },
        {
            name: 'typing',
            flag: PersistFlag.Transparent,
            type: MessageContentType.Typing,
        },
        {
            name: 'friendGreeting',
            flag: PersistFlag.Persist,
            type: MessageContentType.Friend_Added,
        },
        {
            name: 'friendAdded',
            flag: PersistFlag.Persist,
            type: MessageContentType.Friend_Greeting,
        },
        {
            name: 'addGroupMemberNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.AddGroupMember_Notification,
        },
        {
            name: 'changeGroupNameNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.ChangeGroupName_Notification,
        },
        {
            name: 'changeGroupPortraitNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.ChangeGroupPortrait_Notification,
        },
        {
            name: 'createGroupNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.CreateGroup_Notification,
        },
        {
            name: 'dismissGroupNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.DismissGroup_Notification,
        },
        {
            name: 'kickoffGroupMemberNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.KickOffGroupMember_Notification,
        },
        {
            name: 'kickoffGroupMemberVisiableNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.KickOffGroupMember_Visible_Notification,
        },
        {
            name: 'modifyGroupAliasNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.ModifyGroupAlias_Notification,
        },
        {
            name: 'modifyGroupExtraNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.ModifyGroupExtra_Notification,
        },
        {
            name: 'modifyGroupMemberExtraNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.ModifyGroupMemberExtra_Notification,
        },
        {
            name: 'quitGroupNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.QuitGroup_Notification,
        },
        {
            name: 'quitGroupVisiableNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.QuitGroup_Visible_Notification,
        },
        {
            name: 'transferGroupOwnerNotification',
            flag: PersistFlag.Persist,
            type: MessageContentType.TransferGroupOwner_Notification,
        },
        {
            name: 'groupJoinTypeNotificationContent',
            flag: PersistFlag.Persist,
            type: MessageContentType.ChangeJoinType_Notification,
        },
        {
            name: 'groupMuteNotificationContent',
            flag: PersistFlag.Persist,
            type: MessageContentType.MuteGroup_Notification,
        },
        {
            name: 'groupPrivateChatNotificationContent',
            flag: PersistFlag.Persist,
            type: MessageContentType.ChangePrivateChat_Notification,
        },
        {
            name: 'groupSetManagerNotificationContent',
            flag: PersistFlag.Persist,
            type: MessageContentType.SetGroupManager_Notification,
        },
        {
            name: 'muteGroupMemberNotificationContent',
            flag: PersistFlag.Persist,
            type: MessageContentType.MuteGroupMember_Notification,
        },
        {
            name: 'allowGroupMemberNotificationContent',
            flag: PersistFlag.Persist,
            type: MessageContentType.AllowGroupMember_Notification,
        },
        {
            name: 'modifyGroupSettingNotificationContent',
            flag: PersistFlag.No_Persist,
            type: MessageContentType.ModifyGroupSetting_Notification,
        },
        {
            name: 'recall',
            flag: PersistFlag.Persist,
            type: MessageContentType.RecallMessage_Notification,
        },
        {
            name: 'delete',
            flag: PersistFlag.No_Persist,
            type: MessageContentType.DeleteMessage_Notification,
        },
        {
            name: 'callStartMessageContent',
            flag: PersistFlag.Persist,
            type: MessageContentType.VOIP_CONTENT_TYPE_START,
        },
        {
            name: 'callAnswerMessageContent',
            flag: PersistFlag.No_Persist,
            type: MessageContentType.VOIP_CONTENT_TYPE_ACCEPT,
        },
        {
            name: 'callAnswerTMessageContent',
            flag: PersistFlag.Transparent,
            type: MessageContentType.VOIP_CONTENT_TYPE_ACCEPT_T,
        },
        {
            name: 'callByeMessageContent',
            flag: PersistFlag.No_Persist,
            type: MessageContentType.VOIP_CONTENT_TYPE_END,
        },
        {
            name: 'callSignalMessageContent',
            flag: PersistFlag.Transparent,
            type: MessageContentType.VOIP_CONTENT_TYPE_SIGNAL,
        },
        {
            name: 'callModifyMessageContent',
            flag: PersistFlag.No_Persist,
            type: MessageContentType.VOIP_CONTENT_TYPE_MODIFY,
        },
        {
            name: 'callAddParticipant',
            flag: PersistFlag.Persist,
            type: MessageContentType.VOIP_CONTENT_TYPE_ADD_PARTICIPANT,
        },
        {
            name: 'callMuteVideo',
            flag: PersistFlag.No_Persist,
            type: MessageContentType.VOIP_CONTENT_TYPE_MUTE_VIDEO,
        },
        {
            name: 'conferenceInvite',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.CONFERENCE_CONTENT_TYPE_INVITE,
        },
        {
            name: 'conferenceChangeMode',
            flag: PersistFlag.Transparent,
            type: MessageContentType.CONFERENCE_CONTENT_TYPE_CHANGE_MODE,
        },
        {
            name: 'conferenceKickoffMember',
            flag: PersistFlag.Transparent,
            type: MessageContentType.CONFERENCE_CONTENT_TYPE_KICKOFF_MEMBER,
        },
        {
            name: 'multiCallOngoing',
            flag: PersistFlag.Transparent,
            type: MessageContentType.VOIP_Multi_Call_Ongoing,
        },
        {
            name: 'joinCallRequest',
            flag: PersistFlag.Transparent,
            type: MessageContentType.VOIP_Join_Call_Request,
        },
        {
            name: 'markUnreadMessage',
            flag: PersistFlag.No_Persist,
            type: MessageContentType.Mark_Unread_Sync,
        },
        {
            name: 'startSecretChat',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.StartSecretChat_Notification,
        },
        {
            name: 'richNotification',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Rich_Notification,
        },
        {
            name: 'articlesMessageContent',
            flag: PersistFlag.Persist_And_Count,
            type: MessageContentType.Articles,
        },
        {
            name: 'channelMenuEventMessageContent',
            flag: PersistFlag.Transparent,
            type: MessageContentType.Channel_Menu_Event,
        },
        {
            name: 'enterChannelChatMessageContent',
            flag: PersistFlag.Transparent,
            type: MessageContentType.Enter_Channel_Chat,
        },
        {
            name: 'leaveChannelChatMessageContent',
            flag: PersistFlag.Transparent,
            type: MessageContentType.Leave_Channel_Chat,
        },
        {
            name: 'conferenceCommandMessageContent',
            flag: PersistFlag.Transparent,
            type: MessageContentType.CONFERENCE_CONTENT_TYPE_COMMAND,
        },
        {
            name: 'pcLoginRequestMessageContent',
            flag: PersistFlag.No_Persist,
            type: MessageContentType.PC_Login_Request,
        }

    ];
}

export class MessageContentConfig {
    name = '';
    flag = 0;
    type = 0
    contentClazz?: Object
}
