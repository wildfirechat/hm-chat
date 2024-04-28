import { showToast } from '../../common/utils/Toast'
import UserInfo from '../../wfc/model/userInfo'
import ChannelInfo from '../../wfc/model/channelInfo'
import SearchResultView from './SearchResultView'
import GroupInfo from '../../wfc/model/groupInfo'
import { SearchModule } from '../../common/Types'


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
                this.mainNavPathStack.pushPathByName('userInfo', {
                    'userInfo': userInfo
                } as Record<string, Object>)
            }
        },
        {
            tag: 'group',
            onSearchResultItemClick: value => {
                let groupInfo = value as GroupInfo
                showToast('TODO group')
            }
        },
        {
            tag: 'channel',
            onSearchResultItemClick: value => {
                let channelInfo = value as ChannelInfo
                showToast('TODO channel')
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