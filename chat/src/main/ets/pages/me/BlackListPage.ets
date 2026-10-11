import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast'
import { FontSize } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import { trustedMediaSrc } from '@wfc/uikit/src/main/ets/util/trustedMedia'

@Preview
@Component
export default struct BlackListPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State blackUserIds: string[] = []

    aboutToAppear() {
        this.blackUserIds = wfc.getBlackList()
    }

    private removeFromBlackList(userId: string, index: number) {
        wfc.setBlackList(userId, false, () => {
            this.blackUserIds.splice(index, 1)
            this.blackUserIds = this.blackUserIds.slice()
        }, (err: number) => {
            showToast('网络错误')
        })
    }

    @Builder
    deleteButton(userId: string, index: number) {
        Button('删除', { type: ButtonType.Normal })
            .backgroundColor($r('app.color.wf_danger'))
            .fontColor(Color.White)
            .height('100%')
            .onClick(() => {
                this.removeFromBlackList(userId, index)
            })
    }

    build() {
        NavDestination() {
            Column() {
                if (this.blackUserIds.length === 0) {
                    Text('暂无黑名单用户')
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.wf_tertiary_text'))
                        .margin({ top: 48 })
                } else {
                    List() {
                        ForEach(this.blackUserIds, (userId: string, index: number) => {
                            ListItem() {
                                Row() {
                                    Image(trustedMediaSrc(wfc.getUserInfo(userId).portrait))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Text(wfc.getUserInfo(userId).displayName)
                                        .fontSize(FontSize.md)
                                        .fontColor($r('app.color.wf_primary_text'))
                                        .margin({ left: 12 })
                                }
                                .width('100%')
                                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                            }
                            .swipeAction({ end: this.deleteButton(userId, index) })
                        }, (userId: string) => userId)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .divider({ strokeWidth: 0.6, color: $r('app.color.wf_divider'), startMargin: 66 })
                }
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .title('黑名单')
        .height('100%')
        .width('100%')
    }
}
