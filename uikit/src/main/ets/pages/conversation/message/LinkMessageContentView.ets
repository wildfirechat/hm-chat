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
        Row() {
            Column() {
                Text(this.linkMessageContent().title)
                    .constraintSize({ maxWidth: 150 })
                    .maxLines(1)
                    .fontSize(18)
                Text(this.linkMessageContent().contentDigest)
                    .margin({ top: 10 })
                    .constraintSize({ maxWidth: 150 })
                    .maxLines(3)
                    .fontColor('#c8969696')
            }
            .padding(10)

            Image(this.linkMessageContent().thumbnail)
                .width(60)
                .height(60)
                .objectFit(ImageFit.CENTER)
                .borderRadius(4)
        }
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .borderRadius(4)
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