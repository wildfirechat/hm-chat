import UserInfo from '../wfc/model/userInfo'

export declare type UIUserInfo = {
    showCategory: boolean,
    category: string,
    userInfo: UserInfo
}

export declare type MediaEntry = {
    type: string,
    url: string,
    thumbnail: string
}

export declare type SearchModule = {
    tag: 'user' | 'contact' | 'group' | 'channel' | 'message',
    onSearchResultItemClick: (value: object) => void
}

export declare type PortraitAndName = {
    portrait: string,
    name: string
}
