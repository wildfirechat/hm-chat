import { UIUserInfo } from '../common/Types'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'


@Preview
@Component
export default struct UserItemView {
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
                        .fontSize(13)
                        .fontColor('#828282')
                }
                .height(30)
                .padding({ left: 10 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor('#EDEDED')
            }
            Row() {
                Image(this.uiUserInfo.userInfo.portrait)
                    .alt($r('app.media.avatar_def'))
                    .width(40)
                    .height(40)
                    .borderRadius(4)
                    .margin({ left: 10, right: 10 })
                Text(this.uiUserInfo.userInfo.displayName)
                    .maxLines(1)
                    .fontSize(15)
                    .layoutWeight(1)
            }
            .width('100%')
            .height(60)
            .padding({ left: this.paddingLeft, right: this.paddingRight })
            .onClick(event => {
                if (this.enable) {
                    this.onClickUser && this.onClickUser(this.uiUserInfo.userInfo)
                }
            })
            .stateStyles({
                pressed: {
                    .backgroundColor('#E5E5E5')
                },
                normal: {
                    .backgroundColor(Color.White)
                }
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
    }
}