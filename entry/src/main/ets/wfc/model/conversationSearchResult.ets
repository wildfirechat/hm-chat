/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import Conversation from "./conversation";
import Message from "../messages/message";
import Long from '../util/long';

export default class ConversationSearchResult {
    conversation?: Conversation;
    //only matchCount == 1, load the message
    matchMessage: Message | null = null;
    timestamp = 0;
    matchCount = 0;

    static fromProtoConversationSearchResult(obj: Record<string, Object>) {
        let conversationSearchResult = new ConversationSearchResult();
        if (obj.conversation) {
            let conv = obj.conversation as Conversation
            conversationSearchResult.conversation = new Conversation(conv.conversationType !== undefined ? conv.conversationType : conv.type, conv.target, conv.line);
        } else {
            conversationSearchResult.conversation = new Conversation(obj.conversationType as number, obj.target as string, obj.line as number);
        }
        conversationSearchResult.matchCount = obj.marchedCount as number;
        if (obj.marchedCount === 1) {
            conversationSearchResult.matchMessage = Message.fromProtoMessage(obj.marchedMessage as Record<string, Object>);
        }
        conversationSearchResult.timestamp = Number(obj.timestamp);

        return conversationSearchResult;
    }
}
