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
import { timeFormat } from '../../util/helper'

@Component
@Preview
export default struct SearchConversationMessageResultView {
    @State conversationMessageSearchResults: MessageResultWrapper[] = []
    @Prop @Watch('onSearchKeywordUpdate') keyword: string
    private searchModules: SearchModule[] = []
    private conversation?: Conversation

    aboutToAppear() {
        if (this.keyword) {
            this.onSearchKeywordUpdate('keyword')
        }
    }

    onSearchKeywordUpdate(propName: string): void {
        let keyword = this.keyword.trim()

        if (keyword.length === 0) {
            // do nothing
            this.conversationMessageSearchResults = []
        } else {
            this.searchModules.forEach(module => {
                switch (module.tag) {
                    case 'conversationMessage':
                        this.searchConversationMessage(keyword)
                        break
                    default:
                        break
                }
            })
        }
    }

    // private searchConversationMessage(keyword: string) {
    //     this.conversationMessageSearchResults = wfc.searchMessage(this.conversation!, keyword)
    // }
    private async searchConversationMessage(keyword: string) {
        this.conversationMessageSearchResults = await Promise.all(wfc.searchMessage(this.conversation!, keyword)
            .map(async msg => {
                let portraitAndName = await Utils.computeConversationItemPortraitAndName(msg.conversation!)
                let resultWrapper = {
                    message: msg,
                    senderPortrait: portraitAndName.portrait,
                    senderName: portraitAndName.name,
                    digest: msg.messageContent.digest(msg),
                    timestamp: timeFormat(msg.timestamp)
                } as MessageResultWrapper
                return resultWrapper
            }))
    }

    @Builder
    conversationMessageSearchResultBuilder() {
        if (this.conversationMessageSearchResults.length > 0) {
            this.searchResultCategoryHeader('聊天记录')
        }
        ForEach(this.conversationMessageSearchResults, (resultWrapper: MessageResultWrapper) => {
            ListItem() {
                Row() {
                    Image(resultWrapper.senderPortrait)
                        .alt($r('app.media.avatar_def'))
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                    Column() {
                        Text(resultWrapper.senderName)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                        Text(resultWrapper.digest)
                            .fontSize(12)
                            .margin({ top: 5 })
                            .fontColor('#B3B3B3')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .padding({ left: 10 })

                    Blank()
                    Text(resultWrapper.timestamp)
                        .fontSize(11)
                        .alignSelf(ItemAlign.Start)
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
                let conversationSearchModule = this.searchModules.filter(m => m.tag === 'conversationMessage')[0]
                conversationSearchModule.onSearchResultItemClick(resultWrapper.message)
            })
        }, (resultWrapper: MessageResultWrapper) => resultWrapper.message.messageId + '')
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
        if (this.conversationMessageSearchResults.length) {
            List() {
                this.conversationMessageSearchResultBuilder()
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

interface MessageResultWrapper {
    message: Message,
    senderPortrait: string,
    senderName: string,
    digest: string
    timestamp: string
}