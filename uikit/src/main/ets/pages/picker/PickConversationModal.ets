import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import ConversationInfoItemView from '../../view/ConversationInfoItemView'
import SearchResultView from '../search/SearchPortalResultView'
import { SearchModule } from '../../common/Types'

@Component
@Preview
export default struct PickConversationModal {
    @State keyword: string = ''
    @State recentConversationInfos: ConversationInfo[] = [];
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    onClickConversation?: (conversationInfo: ConversationInfo) => void

    aboutToAppear() {
        this.recentConversationInfos = wfc.getConversationInfoList([0, 1, 2, 3], [0, 1]);
    }

    private searchModules: SearchModule[] = [
        {
            tag: 'conversation',
            onSearchResultItemClick: value => {
                let conversationInfo = value as ConversationInfo
                this.onClickConversation?.(conversationInfo)
            }
        },
    ]

    build() {
        Navigation() {
            Column() {
                Row() {
                    TextInput({ placeholder: '搜索...' })
                        .type(InputType.Normal)
                        .layoutWeight(1)
                        .borderRadius(4)
                        .onChange((value: string) => {
                            this.keyword = value
                        })
                }
                .padding(10)
                .width('100%')

                Stack() {
                    Column() {
                        List() {
                            ListItem() {
                                Text('最近聊天')
                                    .fontColor('#989898')
                                    .fontSize(13)
                                    .width('100%')
                                    .height(40)
                                    .backgroundColor($r('app.color.wf_secondary_background'))
                                    .padding({ left: 10, right: 10 })
                            }

                            ForEach(this.recentConversationInfos, (info: ConversationInfo, index: number) => {
                                ListItem() {
                                    ConversationInfoItemView({
                                        conversationInfo: info,
                                        basicMode: true
                                    })
                                        .onClick(() => {
                                            this.onClickConversation?.(info)
                                        })
                                }
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor($r('app.color.wf_item_pressed'))
                                    },
                                    normal: {
                                        .backgroundColor($r('app.color.wf_background'))
                                    }
                                })
                            }, (info: ConversationInfo) => info.conversation.type + info.conversation.target + '-' + info.conversation.line)
                        }
                    }
                    .height('100%')

                    if (this.keyword) {
                        SearchResultView({
                            keyword: this.keyword,
                            searchModules: this.searchModules
                        })
                            .height('100%')
                            .backgroundColor(Color.White)
                    }
                }
                .width('100%')
                .layoutWeight(1)
            }
            .height('100%')
            .width('100%')
        }
        .backgroundColor($r('app.color.wf_background'))
        .title('选择一个聊天')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
    }
}
