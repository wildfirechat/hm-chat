/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import Long from '../util/long';
import Conversation from './conversation';

export default class FileRecord {
    userId = '';
    conversation?: Conversation;
    messageUid = Long.ZERO;
    name = '';
    url = '';
    size = 0;
    downloadCount = 0;
    timestamp = 0;
}
