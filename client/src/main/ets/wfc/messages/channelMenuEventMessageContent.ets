import ChannelMenu from '../model/channelMenu';
import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";

export default class ChannelMenuEventMessageContent extends MessageContent {
    menu?: ChannelMenu

    constructor(menu?: ChannelMenu) {
        super(MessageContentType.Channel_Menu_Event);
        this.menu = menu;
    }

    encode() {
        let payload = super.encode();
        payload.content = JSON.stringify(this.menu);
        return payload;
    }
}
