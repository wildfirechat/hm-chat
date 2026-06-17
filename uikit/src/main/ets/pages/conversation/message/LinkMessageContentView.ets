import Config from '@wfc/client/src/main/ets/config'
import LinkMessageContent from "@wfc/client/src/main/ets/wfc/messages/linkMessageContent";
import Message from "@wfc/client/src/main/ets/wfc/messages/message";
import { uikitNavigationDestinations } from "../../uikitNavigationConfig";
import { showToast } from '../../../common/utils/Toast';
import { isHttpUrl } from '../../../common/utils/TextLinkParser';
import { common } from '@kit.AbilityKit';

@Component
export default struct LinkMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message

    linkMessageContent() {
        return this.message.messageContent as LinkMessageContent
    }

    build() {
        Column() {
            Text(this.linkMessageContent().title ? this.linkMessageContent().title : this.linkMessageContent().url)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.wf_primary_text'))
                .lineHeight(21)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .textAlign(TextAlign.Start)

            Row() {
                Text(this.linkMessageContent().contentDigest ? this.linkMessageContent().contentDigest : this.linkMessageContent().url)
                    .fontSize(13)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .lineHeight(18)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                    .textAlign(TextAlign.Start)

                Image(this.linkMessageContent().thumbnail ? this.linkMessageContent().thumbnail : $r('app.media.ic_file_type_html'))
                    .alt($r('app.media.ic_file_type_html'))
                    .width(40)
                    .height(40)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(4)
                    .backgroundColor($r('app.color.wf_image_placeholder_bg'))
                    .margin({ left: 10 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ top: 10 })
        }
        .width(240)
        .padding(12)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor($r('app.color.wf_background'))
        .borderRadius(8)
        .shadow({ radius: 6, color: '#14000000', offsetX: 0, offsetY: 1 })
        .onClick(() => {
            this.openLink(this.linkMessageContent().url, this.linkMessageContent().title)
        })
    }

    openLink(url: string, title: string) {
        if (Config.OPEN_LINK_POLICY === 2) {
            showToast('禁止打开外部链接')
            return
        }
        if (Config.OPEN_LINK_POLICY === 1) {
            AlertDialog.show({
                title: '提示',
                message: '谨防钓鱼网站或者带毒网站，只有确认已知安全的链接才可以打开。请确实该链接是否是已知安全的？',
                primaryButton: {
                    value: '确认安全',
                    action: () => {
                        this.doOpenLink(url, title)
                    }
                },
                secondaryButton: {
                    value: '关闭',
                    action: () => {}
                }
            })
            return
        }
        this.doOpenLink(url, title)
    }

    doOpenLink(url: string, title: string) {
        if (isHttpUrl(url)) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                'url': url,
                'title': title
            } as Record<string, Object>)
        } else {
            let context = getContext(this) as common.UIAbilityContext;
            context.startAbility({ action: 'ohos.want.action.viewData', uri: url });
        }
    }
}