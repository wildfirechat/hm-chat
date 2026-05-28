import wfc from '@wfc/client';
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import { showToast } from '../../../common/utils/Toast';
import { parseTextLinks, TextSegment, normalizeUrl, isHttpUrl } from '../../../common/utils/TextLinkParser';
import { common } from '@kit.AbilityKit';
import { uikitNavigationDestinations } from '../../uikitNavigationConfig';
import { MessageContextMenuItem } from './MessageContextMenuItem';
import Config from '@wfc/client/src/main/ets/config';

@Component
export default struct TextMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message
    @Prop textPadding: Length | Padding = 10
    @Prop menuItems: MessageContextMenuItem[] = []
    @State selectionStart: number = -1
    @State selectionEnd: number = -1
    @Link selectedText:string
    // 延迟取消选择的定时器 ID
    private clearSelectionTimerId: number = -1

    quoteInfoDesc() {
        let quoteInfo = (this.message.messageContent as TextMessageContent).quoteInfo
        return `${quoteInfo?.userDisplayName}: ${quoteInfo?.messageDigest}`
    }

    showQuoteMessage() {
        let quoteInfo = (this.message.messageContent as TextMessageContent).quoteInfo
        let messageUid = quoteInfo!.messageUid
        let msg = wfc.getMessageByUid(messageUid)
        if (msg) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.TextMessagePreviewPage, {
                'message': msg
            } as Record<string, object>)
        } else {
            showToast('引用的消息本地不存在')
        }
    }

    getTextContent(): string {
        return this.message.messageContent.digest(this.message)
    }

    build() {
        if ((this.message.messageContent as TextMessageContent).quoteInfo) {
            Column() {
                if (Config.OPEN_LINK_POLICY === 0) {
                    Text(this.getTextContent())
                        .padding(this.textPadding)
                        .constraintSize({ minHeight: 40 })
                        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                        .fontColor($r('app.color.wf_primary_text'))
                        .borderRadius(4)
                        .enableDataDetector(true)
                        .dataDetectorConfig({
                            types: [TextDataDetectorType.URL, TextDataDetectorType.PHONE_NUMBER, TextDataDetectorType.EMAIL]
                        })
                        .copyOption(this.menuItems.length > 0 ? CopyOptions.InApp : CopyOptions.None)
                        .textSelectable(this.menuItems.length > 0 ? TextSelectableMode.SELECTABLE_UNFOCUSABLE : TextSelectableMode.UNSELECTABLE)
                        .selection(this.selectionStart, this.selectionEnd)
                        .onTextSelectionChange((start, end) => {
                            if (this.clearSelectionTimerId !== -1) {
                                clearTimeout(this.clearSelectionTimerId)
                                this.clearSelectionTimerId = -1
                            }
                            this.selectedText = this.getTextContent().substring(start, end)
                        })
                        .bindSelectionMenu(TextSpanType.TEXT, this.SelectionMenuBuilder, TextResponseType.LONG_PRESS, {
                            onAppear: () => {
                                this.selectionStart = 0
                                this.selectionEnd = this.getTextContent().length
                            },
                            onDisappear: () => {
                            },
                            onMenuShow: () => {
                                if (this.clearSelectionTimerId !== -1) {
                                    clearTimeout(this.clearSelectionTimerId)
                                    this.clearSelectionTimerId = -1
                                }
                            },
                            onMenuHide: () => {
                                this.clearSelectionTimerId = setTimeout(() => {
                                    this.selectionStart = -1
                                    this.selectionEnd = -1
                                    this.clearSelectionTimerId = -1
                                }, 100)
                            }
                        })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.TextMessagePreviewPage, {
                                'message': this.message
                            } as Record<string, object>)
                        })
                } else {
                    Text() {
                        ForEach(parseTextLinks(this.getTextContent()), (segment: TextSegment, index: number) => {
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
                        .padding(this.textPadding)
                        .constraintSize({ minHeight: 40 })
                        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                        .fontColor($r('app.color.wf_primary_text'))
                        .borderRadius(4)
                        .copyOption(this.menuItems.length > 0 ? CopyOptions.InApp : CopyOptions.None)
                        .textSelectable(this.menuItems.length > 0 ? TextSelectableMode.SELECTABLE_UNFOCUSABLE : TextSelectableMode.UNSELECTABLE)
                        .selection(this.selectionStart, this.selectionEnd)
                        .onTextSelectionChange((start, end) => {
                            if (this.clearSelectionTimerId !== -1) {
                                clearTimeout(this.clearSelectionTimerId)
                                this.clearSelectionTimerId = -1
                            }
                            this.selectedText = this.getTextContent().substring(start, end)
                        })
                        .bindSelectionMenu(TextSpanType.TEXT, this.SelectionMenuBuilder, TextResponseType.LONG_PRESS, {
                            onAppear: () => {
                                this.selectionStart = 0
                                this.selectionEnd = this.getTextContent().length
                            },
                            onDisappear: () => {
                            },
                            onMenuShow: () => {
                                if (this.clearSelectionTimerId !== -1) {
                                    clearTimeout(this.clearSelectionTimerId)
                                    this.clearSelectionTimerId = -1
                                }
                            },
                            onMenuHide: () => {
                                this.clearSelectionTimerId = setTimeout(() => {
                                    this.selectionStart = -1
                                    this.selectionEnd = -1
                                    this.clearSelectionTimerId = -1
                                }, 100)
                            }
                        })
                        .onClick(() => {
                            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.TextMessagePreviewPage, {
                                'message': this.message
                            } as Record<string, object>)
                        })
                }

                Text(this.quoteInfoDesc())
                    .padding(this.textPadding)
                    .margin({ top: 8 })
                    .constraintSize({ minHeight: 40 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .backgroundColor($r('app.color.wf_primary_background_color'))
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .borderRadius(4)
                    .onClick(() => {
                        this.showQuoteMessage()
                    })
            }
            .alignItems(this.message.direction === 0 ? HorizontalAlign.End : HorizontalAlign.Start)

        } else {
            if (Config.OPEN_LINK_POLICY === 0) {
                Text(this.getTextContent())
                    .padding(this.textPadding)
                    .constraintSize({ minHeight: 40 })
                    .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                    .fontColor($r('app.color.wf_primary_text'))
                    .borderRadius(4)
                    .enableDataDetector(true)
                    .dataDetectorConfig({
                        types: [TextDataDetectorType.URL, TextDataDetectorType.PHONE_NUMBER, TextDataDetectorType.EMAIL]
                    })
                    .copyOption(this.menuItems.length > 0 ? CopyOptions.InApp : CopyOptions.None)
                    .textSelectable(this.menuItems.length > 0 ? TextSelectableMode.SELECTABLE_UNFOCUSABLE : TextSelectableMode.UNSELECTABLE)
                    .selection(this.selectionStart, this.selectionEnd)
                    .onTextSelectionChange((start, end) => {
                        if (this.clearSelectionTimerId !== -1) {
                            clearTimeout(this.clearSelectionTimerId)
                            this.clearSelectionTimerId = -1
                        }
                        this.selectedText = this.getTextContent().substring(start, end)
                    })
                    .bindSelectionMenu(TextSpanType.TEXT, this.SelectionMenuBuilder, TextResponseType.LONG_PRESS, {
                        onAppear: () => {
                            this.selectionStart = 0
                            this.selectionEnd = this.getTextContent().length
                        },
                        onDisappear: () => {
                        },
                        onMenuShow: () => {
                        },
                        onMenuHide: () => {
                            this.clearSelectionTimerId = setTimeout(() => {
                                this.selectionStart = -1
                                this.selectionEnd = -1
                                this.clearSelectionTimerId = -1
                            }, 100)
                        }
                    })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.TextMessagePreviewPage, {
                            'message': this.message
                        } as Record<string, object>)
                    })
            } else {
                Text() {
                    ForEach(parseTextLinks(this.getTextContent()), (segment: TextSegment, index: number) => {
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
                    .padding(this.textPadding)
                    .constraintSize({ minHeight: 40 })
                    .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                    .fontColor($r('app.color.wf_primary_text'))
                    .borderRadius(4)
                    .copyOption(this.menuItems.length > 0 ? CopyOptions.InApp : CopyOptions.None)
                    .textSelectable(this.menuItems.length > 0 ? TextSelectableMode.SELECTABLE_UNFOCUSABLE : TextSelectableMode.UNSELECTABLE)
                    .selection(this.selectionStart, this.selectionEnd)
                    .onTextSelectionChange((start, end) => {
                        if (this.clearSelectionTimerId !== -1) {
                            clearTimeout(this.clearSelectionTimerId)
                            this.clearSelectionTimerId = -1
                        }
                        this.selectedText = this.getTextContent().substring(start, end)
                    })
                    .bindSelectionMenu(TextSpanType.TEXT, this.SelectionMenuBuilder, TextResponseType.LONG_PRESS, {
                        onAppear: () => {
                            this.selectionStart = 0
                            this.selectionEnd = this.getTextContent().length
                        },
                        onDisappear: () => {
                        },
                        onMenuShow: () => {
                        },
                        onMenuHide: () => {
                            this.clearSelectionTimerId = setTimeout(() => {
                                this.selectionStart = -1
                                this.selectionEnd = -1
                                this.clearSelectionTimerId = -1
                            }, 100)
                        }
                    })
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.TextMessagePreviewPage, {
                            'message': this.message
                        } as Record<string, object>)
                    })
            }
        }
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

    @Builder
    SelectionMenuBuilder() {
        Column() {
            Grid() {
                ForEach(this.menuItems, (menuItem: MessageContextMenuItem) => {
                    GridItem() {
                        Column({ space: 8 }) {
                            Image(menuItem.icon)
                                .objectFit(ImageFit.Contain)
                                .width(24)
                                .height(24)
                            Text(menuItem.title)
                                .fontSize(13)
                                .fontColor(Color.White)
                        }
                        .justifyContent(FlexAlign.Center)
                        .width(60)
                        .height(70)
                        .onClick(() => {
                            // 先取消选择
                            this.selectionStart = -1
                            this.selectionEnd = -1
                            // 再执行菜单操作
                            menuItem.action()
                        })
                        .stateStyles({
                            normal: {
                                .backgroundColor(Color.Transparent)
                            },
                            pressed: {
                                .backgroundColor($r('app.color.c_gray'))
                            }
                        })
                    }
                }, (menuItem: MessageContextMenuItem) => menuItem.tag)
            }
            .columnsTemplate('1fr '.repeat(Math.min(this.menuItems.length, 5)).trim())
            .rowsTemplate(this.getRowsTemplate())
            .width(Math.min(this.menuItems.length, 5) * 60 + 20)
            .height(this.getMenuHeight())
        }
        .backgroundColor($r('app.color.wf_message_context_memu_background'))
        .borderRadius(8)
        .padding({
            left: 10,
            right: 10,
            top: 10,
            bottom: 10
        })
    }

    getRowsTemplate(): string {
        let rowCount = Math.ceil(this.menuItems.length / 5)
        return '1fr '.repeat(rowCount).trim()
    }

    getMenuHeight(): number {
        let rowCount = Math.ceil(this.menuItems.length / 5)
        return rowCount * 70
    }
}