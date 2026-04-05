import { UIUserInfo } from '../common/Types'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'

let isChangeTriggeredByClick: boolean = false

@Preview
@Component
export default struct CheckableUserItemView {
    enable: boolean = true
    initialChecked: boolean = false
    paddingLeft: number = 10
    paddingRight: number = 10
    uiUserInfo: UIUserInfo = {} as UIUserInfo;
    onCheckUser?: (userInfo: UserInfo, checked: boolean) => void
    @State _checked: boolean = false
    @Link checkedUsers: UserInfo[]

    aboutToAppear() {
        this._checked = this.checkedUsers.findIndex(info => this.uiUserInfo.userInfo.uid === info.uid) >= 0
    }

    isChecked() {
        return this.checkedUsers.findIndex(info => this.uiUserInfo.userInfo.uid === info.uid) >= 0
    }

    build() {
        Column() {
            if (this.uiUserInfo.showCategory) {
                Row() {
                    Text(this.uiUserInfo.category)
                        .width('100%')
                        .fontSize(13)
                        .fontColor($r('app.color.wf_secondary_text'))
                }
                .height(30)
                .padding({ left: 10 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.wf_primary_background_color'))
            }
            Row() {
                Checkbox()
                    .select(this.isChecked() || this.initialChecked)
                    .enabled(this.enable)
                    .onChange((value: boolean) => {
                        if (isChangeTriggeredByClick) {
                            isChangeTriggeredByClick = false
                            return
                        }
                        this._checked = value
                        this.onCheckUser && this.onCheckUser(this.uiUserInfo.userInfo, this._checked)
                    })
                    .responseRegion({
                        x: 0,
                        y: 0,
                        width: 0,
                        height: 0
                    })
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
                    .fontColor($r('app.color.wf_primary_text'))
            }
            .width('100%')
            .height(60)
            .padding({ left: this.paddingLeft, right: this.paddingRight })
            .onClick(event => {
                if (this.enable) {
                    isChangeTriggeredByClick = true
                    this._checked = !this._checked
                    this.onCheckUser && this.onCheckUser(this.uiUserInfo.userInfo, this._checked)
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