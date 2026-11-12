/**
 * 文件下载进度对话框。
 *
 * 进度通过 AppStorage 传递（fileDownloadPercent / fileDownloadName），
 * 这样任何页面打开这个对话框时都能实时刷新，不用把 controller 里的状态一层层传进来。
 */
import { FontSize, Radius } from '../common/design/Tokens'

@CustomDialog
export default struct FileDownloadDialog {
    controller?: CustomDialogController
    @StorageLink('fileDownloadPercent') percent: number = 0
    @StorageLink('fileDownloadName') fileName: string = ''

    build() {
        Column() {
            LoadingProgress()
                .width(40)
                .height(40)
                .color($r('app.color.wf_primary'))
            Text(this.fileName ? this.fileName : '正在下载')
                .fontSize(FontSize.md)
                .fontColor($r('app.color.wf_primary_text'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 240 })
                .margin({ top: 12 })
            Progress({ value: this.percent, total: 100, type: ProgressType.Linear })
                .width(240)
                .margin({ top: 12 })
            Text(Math.floor(this.percent) + '%')
                .fontSize(FontSize.sm)
                .fontColor($r('app.color.wf_tertiary_text'))
                .margin({ top: 8 })
        }
        .padding(24)
        .borderRadius(Radius.md)
        .backgroundColor($r('app.color.wf_background'))
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
    }
}
