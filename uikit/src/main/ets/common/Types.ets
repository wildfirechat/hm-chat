import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import UserOnlineState from '@wfc/client/src/main/ets/wfc/model/userOnlineState'

export interface UIUserInfo {
    showCategory: boolean,
    category: string,
    userInfo: UserInfo
    onlineState?: UserOnlineState
}

export interface MediaEntry {
    type: 'image' | 'video',
    url: string,
    thumbnail: string
}

// 其他应用通过系统分享发到本应用的单条内容。纯数据结构，便于经
// LocalStorage / NavPathStack 参数传递（不含方法）。
export interface ShareItem {
    type: 'text' | 'image' | 'video' | 'file',
    text?: string,     // type === 'text'
    filePath?: string, // 已拷贝到本应用沙箱的本地绝对路径
    name?: string,
    size?: number
}

export interface MMMediaEntry {
    message: Message,
    type: 'image' | 'video',
    url: string,
    thumbnail: string,
    videoController?: VideoController
}

export interface SearchModule {
    tag: 'user' | 'contact' | 'group' | 'channel' | 'message' | 'conversation' | 'conversationMessage' | 'employee',
    onSearchResultItemClick: (value: object) => void
}

export interface PortraitAndName {
    portrait: string,
    name: string
}

export interface PortraitNameAndUnreadJoinGroupRequestCount {
    portrait: string,
    name: string,
    unreadJoinGroupRequestCount?: number
}

export interface VideoDurationAndThumbnail {
    duration: number,
    thumbnail: string,
}
