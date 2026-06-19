import { UIUserInfo } from '../common/Types'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import { FontSize, Radius, scaledSize, LayoutScale } from '../common/design/Tokens'

@Preview
@Component
export default struct UserItemView {
    @StorageProp('fontScale') fontScale: number = 1.0;
    enable?: boolean = true
    paddingLeft: number = 10
    paddingRight: number = 10
    uiUserInfo: UIUserInfo = {} as UIUserInfo;
    onClickUser?: (userInfo: UserInfo) => void

    aboutToAppear() {
    }

    build() {
        Column() {
            if (this.uiUserInfo.showCategory) {
                Row() {
                    Text(this.uiUserInfo.category)
                        .width('100%')
                        .fontSize(FontSize.sm)
                        .fontColor($r('app.color.wf_secondary_text'))
                }
                .height(32)
                .padding({ left: 12 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.wf_secondary_background'))
            }
            Row() {
                Image(this.uiUserInfo.userInfo.portrait)
                    .alt($r('app.media.avatar_def'))
                    .width(scaledSize(40, this.fontScale))
                    .height(scaledSize(40, this.fontScale))
                    .borderRadius(Radius.sm)
                    .margin({ left: 12, right: 12 })
                Text(this.uiUserInfo.userInfo.displayName)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontSize(FontSize.sm)
                    .layoutWeight(1)
                    .fontColor($r('app.color.wf_primary_text'))
            }
            .width('100%')
            // 用 minHeight，放大字体时随内容撑高
            .constraintSize({ minHeight: scaledSize(60, this.fontScale, LayoutScale.row) })
            .padding({ left: this.paddingLeft, right: this.paddingRight, top: 8, bottom: 8 })
            .onClick(event => {
                if (this.enable) {
                    this.onClickUser && this.onClickUser(this.uiUserInfo.userInfo)
                }
            })
            .stateStyles({
                pressed: {
                    .backgroundColor($r('app.color.wf_item_pressed'))
                },
                normal: {
                    .backgroundColor($r('app.color.wf_background'))
                }
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
    }
}