import UserInfo from '../../wfc/model/userInfo'
import SearchResultView from './SearchPortalResultView'
import { SearchModule } from '../../common/Types'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
@Preview
export default struct SearchUserPage {
    @State keyword: string = ''
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private searchModules: SearchModule[] = [
        {
            tag: 'user',
            onSearchResultItemClick: value => {
                let userInfo = value as UserInfo
                this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, {
                    'userInfo': userInfo
                } as Record<string, Object>)
            }
        },
    ]

    build() {
        NavDestination() {
            Column() {
                Row() {
                    TextInput({ placeholder: '搜索...' })
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
                            this.mainNavPathStack.pop(true)
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
                    .focusable(true)
            }
            .height('100%')
            .width('100%')
        }
        .width('100%')
        .height('100%')
        .hideTitleBar(true)
    }
}