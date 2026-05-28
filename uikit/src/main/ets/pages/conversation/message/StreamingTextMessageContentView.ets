import Config from '@wfc/client/src/main/ets/config'
import Message from "@wfc/client/src/main/ets/wfc/messages/message";
import StreamingTextGeneratingMessageContent from "@wfc/client/src/main/ets/wfc/messages/streamingTextGeneratingMessageContent";
import StreamingTextGeneratedMessageContent from "@wfc/client/src/main/ets/wfc/messages/streamingTextGeneratedMessageContent";
import { showToast } from '../../../common/utils/Toast';
import { parseTextLinks, TextSegment, normalizeUrl, isHttpUrl } from '../../../common/utils/TextLinkParser';
import { common } from '@kit.AbilityKit';
import { uikitNavigationDestinations } from '../../uikitNavigationConfig';

@Component
export default struct StreamingTextMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message

    streamingMessageContent() {
        if (this.message.messageContent instanceof StreamingTextGeneratingMessageContent) {
            return (this.message.messageContent as StreamingTextGeneratingMessageContent).text
        } else if (this.message.messageContent instanceof StreamingTextGeneratedMessageContent) {
            return (this.message.messageContent as StreamingTextGeneratedMessageContent).text
        }
        return ''
    }

    isGenerated() {
        return this.message.messageContent instanceof StreamingTextGeneratedMessageContent;
    }

    build() {
        Column() {
            if (Config.OPEN_LINK_POLICY === 0) {
                Text(this.streamingMessageContent())
                    .constraintSize({ minHeight: 40 })
                    .padding(10)
                    .enableDataDetector(true)
                    .dataDetectorConfig({
                        types: [TextDataDetectorType.URL, TextDataDetectorType.PHONE_NUMBER, TextDataDetectorType.EMAIL]
                    })
            } else {
                Text() {
                    ForEach(parseTextLinks(this.streamingMessageContent()), (segment: TextSegment, index: number) => {
                        if (segment.isUrl) {
                            Span(segment.text)
                                .fontColor($r('app.color.wf_link'))
                                .decoration({ type: TextDecorationType.Underline })
                                .onClick(() => {
                                    this.handleLinkClick(segment.text)
                                })
                        } else {
                            Span(segment.text)
                        }
                    }, (segment: TextSegment, index: number) => index.toString())
                }
                    .constraintSize({ minHeight: 40 })
                    .padding(10)
            }

            if (!this.isGenerated()) {
                LoadingProgress().width(20).height(20)
            } else {
                Text('本内容由 AI 生成')
                    .fontSize(12)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .padding({left: 10, top: 5, bottom: 5})
            }
        }
        .borderRadius(4)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .alignItems(HorizontalAlign.Start)
    }

    handleLinkClick(url: string) {
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
                        this.openUrl(url)
                    }
                },
                secondaryButton: {
                    value: '关闭',
                    action: () => {}
                }
            })
            return
        }
        this.openUrl(url)
    }

    openUrl(url: string) {
        let normalizedUrl = normalizeUrl(url);
        if (isHttpUrl(normalizedUrl)) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                'url': normalizedUrl,
                'title': ''
            } as Record<string, Object>)
        } else {
            let context = getContext(this) as common.UIAbilityContext;
            context.startAbility({ action: 'ohos.want.action.viewData', uri: normalizedUrl });
        }
    }
}