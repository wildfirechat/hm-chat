/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import ChannelInfo from "./channelInfo";

export default class NullChannelInfo extends ChannelInfo {
    constructor(channelId: string) {
        super()
        this.channelId = channelId;
        this.name = `<${channelId}>`
    }
}
