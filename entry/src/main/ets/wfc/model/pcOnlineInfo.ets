/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */
import Platform from '../client/platform'


export default class PCOnlineInfo {
    /**
     * PC在线类型
     * <p>
     * - PC_Online: PC客户端在线
     * - Web_Online: Web客户端在线
     * - WX_Online: WX小程序客户端在线
     * - Pad_Online: Pad客户端在线
     */
    static PC_Online = 0
    static Web_Online = 1
    static WX_Online = 2
    static Pad_Online = 3

    type = PCOnlineInfo.PC_Online;
    platform = new Platform(0)
    isOnline = false;
    clientId = ''
    clientName = '';
    timestamp = 0;

    static infoFromStr(value: string, type: number): PCOnlineInfo | null {
        if (!value) {
            return null;
        }
        let parts = value.split("|");
        if (parts.length >= 4) {
            let info = new PCOnlineInfo();
            info.type = type;
            info.timestamp = Number(parts[0]);
            info.platform = new Platform(Number(parts[1]))
            info.clientId = parts[2];
            info.clientName = parts[3];
            info.isOnline = true;
            return info;
        }

        return null;
    }
}
