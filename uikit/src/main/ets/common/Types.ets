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
    type: string,
    url: string,
    thumbnail: string
}

export interface MMMediaEntry {
    message: Message,
    type: string,
    url: string,
    thumbnail: string,
    videoController?: VideoController
}

export interface SearchModule {
    tag: 'user' | 'contact' | 'group' | 'channel' | 'message' | 'conversation' | 'conversationMessage',
    onSearchResultItemClick: (value: object) => void
}

export interface PortraitAndName {
    portrait: string,
    name: string
}

export interface VideoDurationAndThumbnail {
    duration: number,
    thumbnail: string,
}
