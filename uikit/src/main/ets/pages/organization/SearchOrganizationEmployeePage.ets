import Employee from '../../api/model/employee'
import orgServer from '../../api/orgServer'
import { showToast } from '../../common/utils/Toast'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'

@Component
export default struct SearchOrganizationEmployeePage {
    @State keyword: string = ''
    @State searchResults: Employee[] = []
    @State isSearching: boolean = false
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private orgId: number = 0
    private searchTimer: number = -1

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.orgId = params['orgId'] as number
    }

    onSearchKeywordChange(keyword: string) {
        this.keyword = keyword
        if (this.searchTimer !== -1) {
            clearTimeout(this.searchTimer)
        }
        let trimmedKeyword = keyword.trim()
        if (trimmedKeyword.length === 0) {
            this.searchResults = []
            this.isSearching = false
            return
        }
        this.searchTimer = setTimeout(() => {
            this.doSearch(trimmedKeyword)
        }, 300)
    }

    async doSearch(keyword: string) {
        this.isSearching = true
        try {
            let results = await orgServer.searchEmployee(this.orgId, keyword)
            if (this.keyword.trim() === keyword) {
                this.searchResults = results
            }
        } catch (err) {
            showToast('搜索失败 ' + err)
        } finally {
            this.isSearching = false
        }
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    TextInput({ placeholder: '搜索员工' })
                        .type(InputType.Normal)
                        .layoutWeight(1)
                        .borderRadius(4)
                        .onChange((value: string) => {
                            this.onSearchKeywordChange(value)
                        })
                    Text('取消')
                        .padding(5)
                        .margin({ left: 10 })
                        .fontColor($r('app.color.wf_primary'))
                        .onClick(() => {
                            this.mainNavPathStack.pop(true)
                        })
                }
                .padding(10)
                .width('100%')

                if (this.searchResults.length > 0) {
                    List() {
                        ForEach(this.searchResults, (employee: Employee) => {
                            ListItem() {
                                Row() {
                                    Image(employee.portraitUrl)
                                        .alt($r('app.media.avatar_def'))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Text(employee.name)
                                        .maxLines(1)
                                        .padding({ left: 10 })
                                        .fontColor($r('app.color.wf_primary_text'))
                                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                                }
                                .height(60)
                                .width('100%')
                                .padding({ left: 10, right: 10 })
                                .justifyContent(FlexAlign.Start)
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor($r('app.color.wf_divider'))
                                    },
                                    normal: {
                                        .backgroundColor($r('app.color.wf_background'))
                                    }
                                })
                                .onClick(() => {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                                        'userInfo': orgServer.employeeToUserInfo(employee)
                                    } as Record<string, Object>)
                                })
                            }
                        }, (employee: Employee) => employee.employeeId)
                    }
                    .width('100%')
                    .layoutWeight(1)
                } else {
                    Column() {
                        if (this.isSearching) {
                            Text('搜索中...')
                                .fontColor($r('app.color.wf_tertiary_text'))
                        } else if (this.keyword.trim().length > 0) {
                            Text('未找到相关员工')
                                .fontColor($r('app.color.wf_tertiary_text'))
                        } else {
                            Text('输入关键词搜索员工')
                                .fontColor($r('app.color.wf_tertiary_text'))
                        }
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                }
            }
            .height('100%')
            .width('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .width('100%')
        .height('100%')
        .hideTitleBar(true)
    }
}
