/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */


export default class Platform {
    static PlatformType_UNSET = 0
    static PlatformType_iOS = 1
    static PlatformType_Android = 2
    static PlatformType_Windows = 3
    static PlatformType_OSX = 4
    static PlatformType_WEB = 5
    static PlatformType_WX = 6
    static PlatformType_Linux = 7
    static PlatformType_iPad = 8
    static PlatformType_APad = 9
    static PlatformType_Harmony = 10
    static PlatformType_Harmony_Pad = 11
    static PlatformType_Harmony_PC = 12
    platform = Platform.PlatformType_UNSET

    constructor(platform: number) {
        this.platform = platform
    }

    public getPlatFormName(): string {
        let platFormName = "PC";
        switch (this.platform) {
            case Platform.PlatformType_iOS:
                platFormName = "iOS";
                break;
            case Platform.PlatformType_Android:
                platFormName = "Android";
                break;
            case Platform.PlatformType_Windows:
                platFormName = "Windows";
                break;
            case Platform.PlatformType_OSX:
                platFormName = "Mac";
                break;
            case Platform.PlatformType_Linux:
                platFormName = "Linux";
                break;
            case Platform.PlatformType_WEB:
                platFormName = "Web";
                break;
            case Platform.PlatformType_WX:
                platFormName = "小程序";
                break;
            case Platform.PlatformType_iPad:
                platFormName = "iPad";
                break;
            case Platform.PlatformType_APad:
                platFormName = "Android 平板";
                break;
            case Platform.PlatformType_Harmony:
                platFormName = "鸿蒙手机";
                break;
            case Platform.PlatformType_Harmony_Pad:
                platFormName = "鸿蒙Pad";
                break;
            case Platform.PlatformType_Harmony_PC:
                platFormName = "鸿蒙PC";
                break;
            default:
                break;
        }
        return platFormName;
    }
}
