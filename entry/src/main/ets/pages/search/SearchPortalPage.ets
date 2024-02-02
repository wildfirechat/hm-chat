import { showToast } from '../../common/utils/Toast'
import UserInfo from '../../wfc/model/userInfo'
import router from '@ohos.router'
import ChannelInfo from '../../wfc/model/channelInfo'
import SearchResultView from './SearchResultView'
import GroupInfo from '../../wfc/model/groupInfo'
import { SearchModule } from '../../common/Types'


@Entry
@Component
@Preview
export default struct SearchPortalPage {
    @State keyword: string = ''
    private searchModules: SearchModule[] = [
        {
            tag: 'contact',
            onSearchResultItemClick: value => {
                let userInfo = value as UserInfo
                router.pushUrl({
                    url: 'pages/user/UserInfoPage',
                    params: {
                        userInfo: userInfo
                    }
                }, router.RouterMode.Standard)
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
        const params = router.getParams();
    }

    build() {
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
                        router.back()
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
}