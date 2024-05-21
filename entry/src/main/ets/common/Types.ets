import UserInfo from '../wfc/model/userInfo'

export interface UIUserInfo {
    showCategory: boolean,
    category: string,
    userInfo: UserInfo
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
