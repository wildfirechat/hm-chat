import SearchResultView from './SearchPortalResultView'
import { SearchModule } from '../../common/Types'
import { inputMethod } from '@kit.IMEKit'
import ConversationSearchResult from '../../wfc/model/conversationSearchResult'
import Conversation from '../../wfc/model/conversation'
import SearchConversationMessageResultView from './SearchConversationMessageResultView'
import Message from '../../wfc/messages/message'
import { navigationDestinations } from '../navigationConfig'


@Entry
@Component
@Preview
export default struct SearchConversationMessagePage {
    @State keyword: string = ''
    private conversation?: Conversation
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private searchModules: SearchModule[] = [
        {
            tag: 'conversationMessage',
            onSearchResultItemClick: value => {
                // TODO
                // 跳转到对应消息
                let message = value as Message
                this.mainNavPathStack.pushPathByName(navigationDestinations.ConversationPage, {
                    'conversation': this.conversation,
                    'focusMessageId': message.messageId
                } as Record<string, Object>)
            }
        },
    ]

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.keyword = params['keyword'] as string
        this.conversation = params['conversation'] as Conversation
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    TextInput({ placeholder: '会话消息搜索...', text: $$this.keyword })
                        .type(InputType.Normal)
                        .layoutWeight(1)
                        .borderRadius(4)
                        .enableKeyboardOnFocus(false)
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

                SearchConversationMessageResultView({
                    keyword: this.keyword,
                    conversation: this.conversation,
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
        // .onReady((ctx: NavDestinationContext) => {
        //
        // })

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