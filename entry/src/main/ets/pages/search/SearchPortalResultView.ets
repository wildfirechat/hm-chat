import { showToast } from '../../common/utils/Toast'
import UserInfo from '../../wfc/model/userInfo'
import wfc from '../../wfc/client/wfc'
import ChannelInfo from '../../wfc/model/channelInfo'
import GroupSearchResult from '../../wfc/model/groupSearchResult'
import SearchType from '../../wfc/model/searchType'
import { SearchModule } from '../../common/Types'
import Message from '../../wfc/messages/message'
import ConversationSearchResult from '../../wfc/model/conversationSearchResult'
import ConversationType from '../../wfc/model/conversationType'
import Conversation from '../../wfc/model/conversation'
import Utils from '../../common/Utils'
import { drawing } from '@kit.ArkGraphics2D'

@Component
@Preview
export default struct SearchResultView {
    @State userSearchResults: UserInfo[] = []
    @State expandUserSearchResult: boolean = false
    @State contactSearchResults: UserInfo[] = []
    @State expandContactSearchResult: boolean = false
    @State groupSearchResults: GroupSearchResult[] = []
    @State expandGroupSearchResult: boolean = false
    @State channelSearchResults: ChannelInfo[] = []
    @State expandChannelSearchResult: boolean = false
    @State conversationSearchResults: ConversationSearchResultWrapper[] = []
    @State expandConversationSearchResults: boolean = false
    @Prop @Watch('onSearchKeywordUpdate') keyword: string
    private searchModules: SearchModule[] = []

    aboutToAppear() {
        if (this.keyword) {
            this.onSearchKeywordUpdate('keyword')
        }
    }

    onSearchKeywordUpdate(propName: string): void {
        let keyword = this.keyword.trim()
        this.expandGroupSearchResult = false
        this.expandContactSearchResult = false
        this.expandChannelSearchResult = false

        if (keyword.length === 0) {
            this.userSearchResults = []
            this.contactSearchResults = []
            this.groupSearchResults = []
            this.channelSearchResults = []
            this.conversationSearchResults = []
        } else {
            if (this.searchModules.length === 1) {
                // 只有一个搜索模块时，全部展开
                this.expandUserSearchResult = true
                this.expandContactSearchResult = true
                this.expandGroupSearchResult = true
                this.expandChannelSearchResult = true
                this.expandConversationSearchResults = true
            }
            this.searchModules.forEach(module => {
                switch (module.tag) {
                    case 'conversation':
                        this.searchConversation(keyword)
                        break
                    case 'contact':
                        this.contactSearchResults = wfc.searchFriends(keyword)
                        break
                    case 'group':
                        this.groupSearchResults = wfc.searchGroups(keyword)
                        break
                    case 'channel':
                        wfc.searchChannel(keyword, false, (key: string, channelInfos: ChannelInfo[]) => {
                            if (key === keyword) {
                                this.channelSearchResults = channelInfos
                            }
                        }, err => {
                            showToast('搜索频道失败 ' + err)
                        })
                        break
                    case 'user':
                        wfc.searchUser(keyword, SearchType.General, 0, (keyword, userInfos) => {
                            if (this.keyword === keyword) {
                                this.userSearchResults = userInfos
                            }
                        }, err => {
                            showToast('搜索用户失败' + err)
                        })
                        break
                    case 'message':
                    // TODO
                        break
                    default:
                        break
                }
            })
        }
    }

    private async searchConversation(keyword: string) {
        this.conversationSearchResults = await Promise.all(wfc.searchConversation(keyword, [ConversationType.Single, ConversationType.Group], [0])
            .map(async result => {
                let portraitAndName = await Utils.computeConversationItemPortraitAndName(result.conversation!)
                let resultWrapper = {
                    conversationSearchResult: result,
                    portrait: portraitAndName.portrait,
                    title: portraitAndName.name,
                    desc: result.matchCount > 1 ? `${result.matchCount}条记录` : result.matchMessage?.messageContent.digest(result.matchMessage)
                } as ConversationSearchResultWrapper
                return resultWrapper
            }))
    }

    @Builder
    userSearchResultBuilder() {
        if (this.userSearchResults.length > 0) {
            this.searchResultCategoryHeader('用户')
        }
        ForEach(this.expandUserSearchResult ? this.userSearchResults : this.userSearchResults.slice(0, 5), (userInfo: UserInfo) => {
            ListItem() {
                Row() {
                    Image(userInfo.portrait)
                        .alt($r('app.media.avatar_def'))
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                    Text(userInfo.displayName)
                        .padding({ left: 10 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .padding(10)
            }
            .stateStyles({
                pressed: {
                    .backgroundColor('#E5E5E5')
                },
                normal: {
                    .backgroundColor(Color.White)
                }
            })
            .onClick(() => {
                let userSearchModule = this.searchModules.filter(m => m.tag === 'user')[0]
                userSearchModule.onSearchResultItemClick(userInfo)
            })
        }, (userInfo: UserInfo) => userInfo.uid)

        if (!this.expandUserSearchResult && this.userSearchResults.length > 5) {
            this.searchResultCategoryFooter(`展开剩余${this.userSearchResults.length - 5}项`, () => {
                this.expandUserSearchResult = true
            })
        }
    }

    @Builder
    contactSearchResultBuilder() {
        if (this.contactSearchResults.length > 0) {
            this.searchResultCategoryHeader('联系人')
        }
        ForEach(this.expandContactSearchResult ? this.contactSearchResults : this.contactSearchResults.slice(0, 5), (userInfo: UserInfo) => {
            ListItem() {
                Row() {
                    Image(userInfo.portrait)
                        .alt($r('app.media.avatar_def'))
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                    Text(userInfo.displayName)
                        .padding({ left: 10 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .padding(10)
            }
            .stateStyles({
                pressed: {
                    .backgroundColor('#E5E5E5')
                },
                normal: {
                    .backgroundColor(Color.White)
                }
            })
            .onClick(() => {
                let contactSearchModule = this.searchModules.filter(m => m.tag === 'contact')[0]
                contactSearchModule.onSearchResultItemClick(userInfo)
            })
        }, (userInfo: UserInfo) => userInfo.uid)

        if (!this.expandContactSearchResult && this.contactSearchResults.length > 5) {
            this.searchResultCategoryFooter(`展开剩余${this.contactSearchResults.length - 5}项`, () => {
                this.expandContactSearchResult = true
            })
        }
    }

    @Builder
    groupSearchResultBuilder() {
        if (this.groupSearchResults.length > 0) {
            this.searchResultCategoryHeader('群组')
        }
        ForEach(this.expandGroupSearchResult ? this.groupSearchResults : this.groupSearchResults.slice(0, 5), (groupSearchResult: GroupSearchResult) => {
            ListItem() {
                Row() {
                    Image(groupSearchResult.groupInfo!.portrait)
                        .alt($r('app.media.avatar_def'))
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                    Column() {
                        Text(groupSearchResult.groupInfo.name)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                        Text(groupSearchResult.matchType === 1 ? '群成员名包含：' + this.keyword : '群名称包含：' + this.keyword)
                            .fontSize(12)
                            .margin({ top: 5 })
                            .fontColor('#B3B3B3')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .padding({ left: 10 })
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .padding(10)
            }
            .stateStyles({
                pressed: {
                    .backgroundColor('#E5E5E5')
                },
                normal: {
                    .backgroundColor(Color.White)
                }
            })
            .onClick(() => {
                let groupSearchModule = this.searchModules.filter(m => m.tag === 'group')[0]
                groupSearchModule.onSearchResultItemClick(groupSearchResult.groupInfo)
            })
        }, (groupSearchResult: GroupSearchResult) => groupSearchResult.groupInfo.target)

        if (!this.expandGroupSearchResult && this.groupSearchResults.length > 5) {
            this.searchResultCategoryFooter(`展开剩余${this.groupSearchResults.length - 5}项`, () => {
                this.expandGroupSearchResult = true
            })
        }
    }

    @Builder
    channelSearchResultBuilder() {
        if (this.channelSearchResults.length > 0) {
            this.searchResultCategoryHeader('频道')
        }
        ForEach(this.expandChannelSearchResult ? this.channelSearchResults : this.channelSearchResults.slice(0, 5), (channelInfo: ChannelInfo) => {
            ListItem() {
                Row() {
                    Image(channelInfo.portrait)
                        .alt($r('app.media.ic_channel_1'))
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                    Text(channelInfo.name)
                        .padding({ left: 10 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .padding(10)
            }
            .stateStyles({
                pressed: {
                    .backgroundColor('#E5E5E5')
                },
                normal: {
                    .backgroundColor(Color.White)
                }
            })
            .onClick(() => {
                let channelSearchModule = this.searchModules.filter(m => m.tag === 'channel')[0]
                channelSearchModule.onSearchResultItemClick(channelInfo)
            })
        }, (channelInfo: ChannelInfo) => channelInfo.channelId)

        if (!this.expandChannelSearchResult && this.channelSearchResults.length > 5) {
            this.searchResultCategoryFooter(`展开剩余${this.channelSearchResults.length - 5}项`, () => {
                this.expandChannelSearchResult = true
            })
        }
    }

    conversationSearchResultKey(result: ConversationSearchResult) {
        let conv = result.conversation!
        return conv.type + '-' + conv.target + '-' + conv.line
    }

    @Builder
    conversationSearchResultBuilder() {
        if (this.conversationSearchResults.length > 0) {
            this.searchResultCategoryHeader('聊天记录')
        }
        ForEach(this.expandConversationSearchResults ? this.conversationSearchResults : this.conversationSearchResults.slice(0, 5), (resultWrapper: ConversationSearchResultWrapper) => {
            ListItem() {
                Row() {
                    Image(resultWrapper.portrait)
                        .alt($r('app.media.avatar_def'))
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                    Column() {
                        Text(resultWrapper.title)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                        Text(resultWrapper.desc)
                            .fontSize(12)
                            .margin({ top: 5 })
                            .fontColor('#B3B3B3')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .padding({ left: 10 })
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .padding(10)
            }
            .stateStyles({
                pressed: {
                    .backgroundColor('#E5E5E5')
                },
                normal: {
                    .backgroundColor(Color.White)
                }
            })
            .onClick(() => {
                let conversationSearchModule = this.searchModules.filter(m => m.tag === 'conversation')[0]
                conversationSearchModule.onSearchResultItemClick(resultWrapper.conversationSearchResult)
            })
        }, (resultWrapper: ConversationSearchResultWrapper) => this.conversationSearchResultKey(resultWrapper.conversationSearchResult))

        if (!this.expandConversationSearchResults && this.conversationSearchResults.length > 5) {
            this.searchResultCategoryFooter(`展开剩余${this.channelSearchResults.length - 5}项`, () => {
                this.expandConversationSearchResults = true
            })
        }
    }

    @Builder
    searchResultCategoryHeader(title: string) {
        Text(title)
            .padding({ left: 10 })
            .width('100%')
            .height(32)
            .fontColor('#828282')
            .fontSize(13)
            .backgroundColor('#EDEDED')
    }

    @Builder
    searchResultCategoryFooter(title: string, action: () => void) {
        Text(title)
            .padding({ left: 10 })
            .width('100%')
            .height(32)
            .fontColor('#5B6E8E')
            .fontSize(13)
            .onClick(action)
    }

    build() {
        if (this.userSearchResults.length + this.contactSearchResults.length + this.groupSearchResults.length + this.channelSearchResults.length) {
            List() {
                this.userSearchResultBuilder()
                this.contactSearchResultBuilder()
                this.groupSearchResultBuilder()
                this.conversationSearchResultBuilder()
                this.channelSearchResultBuilder()
            }
        } else {
            Column() {
                Text(this.keyword ? '搜索结果为空' : '输入关键词开始搜索')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
        }
    }
}

interface ConversationSearchResultWrapper {
    conversationSearchResult: ConversationSearchResult
    portrait: string,
    title: string,
    desc: string
}