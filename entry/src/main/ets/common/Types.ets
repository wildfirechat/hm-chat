import UserInfo from '../wfc/model/userInfo'
import UserOnlineState from '../wfc/model/userOnlineState'

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

export interface SearchModule {
    tag: 'user' | 'contact' | 'group' | 'channel' | 'message' | 'conversation' | 'conversationMessage',
    onSearchResultItemClick: (value: object) => void
}

export interface PortraitAndName {
    portrait: string,
    name: string
}
