import { showToast } from '../../common/utils/Toast'
import UserInfo from '../../wfc/model/userInfo'
import ChannelInfo from '../../wfc/model/channelInfo'
import SearchResultView from './SearchPortalResultView'
import GroupInfo from '../../wfc/model/groupInfo'
import { SearchModule } from '../../common/Types'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import { inputMethod } from '@kit.IMEKit'
import ConversationSearchResult from '../../wfc/model/conversationSearchResult'
import { navigationDestinations } from '../navigationConfig'


@Entry
@Component
@Preview
export default struct SearchPortalPage {
    @State keyword: string = ''
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private searchModules: SearchModule[] = [
        {
            tag: 'contact',
            onSearchResultItemClick: value => {
                let userInfo = value as UserInfo
                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                    'conversation': new Conversation(ConversationType.Single, userInfo.uid, 0)
                } as Record<string, Object>)
            }
        },
        {
            tag: 'group',
            onSearchResultItemClick: value => {
                let groupInfo = value as GroupInfo
                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                    'conversation': new Conversation(ConversationType.Group, groupInfo.target, 0)
                } as Record<string, Object>)
            }
        },
        {
            tag: 'conversation',
            onSearchResultItemClick: value => {
                let conversationSearchResult = value as ConversationSearchResult
                if (conversationSearchResult.matchCount > 1) {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.SearchConversationMessagePage, {
                        'keyword': this.keyword,
                        'conversation': conversationSearchResult.conversation!
                    } as Record<string, Object>)
                } else {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                        'conversation': conversationSearchResult.conversation!
                    } as Record<string, Object>)
                }
            }
        },
        {
            tag: 'channel',
            onSearchResultItemClick: value => {
                let channelInfo = value as ChannelInfo
                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                    'conversation': new Conversation(ConversationType.Channel, channelInfo.channelId, 0)
                } as Record<string, Object>)
            }
        },
    ]

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        // TODO
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    TextInput({ placeholder: '搜索...', text: $$this.keyword })
                        .type(InputType.Normal)
                        .layoutWeight(1)
                        .borderRadius(4)
                        .enableKeyboardOnFocus(true)
                        .onChange((value: string) => {
                            this.keyword = value
                        })
                    Text('取消')
                        .padding(5)
                        .margin({ left: 10 })
                        .onClick(() => {
                            this.mainNavPathStack.pop()
                        })
                }
                .padding(10)
                .width('100%')

                SearchResultView({
                    keyword: this.keyword,
                    searchModules: this.searchModules
                })
                    .onTouch(event => {
                        inputMethod.getController().stopInputSession()
                    })
                    .focusable(true)
                    .focusOnTouch(true)
                    .width('100%')
                    .layoutWeight(1)
            }
            .height('100%')
            .width('100%')
        }
        .height('100%')
        .width('100%')
        .onReady((ctx: NavDestinationContext) => {

        })

        // .onReady((ctx: NavDestinationContext) => {
        //     // 在NavDestination中能够拿到传来的NavPathInfo和当前所处的NavPathStack
        //     try {
        //         this.name = ctx?.pathInfo?.name;
        //         this.paramNum = (ctx?.pathInfo?.param as PageParam)?.num;
        //         this.stack = ctx.pathStack;
        //     } catch (e) {
        //         console.log(`testTag onReady catch exception: ${JSON.stringify(e)}`)
        //     }
        // })
        .mode(NavDestinationMode.STANDARD)
        .hideTitleBar(true)
    }
}