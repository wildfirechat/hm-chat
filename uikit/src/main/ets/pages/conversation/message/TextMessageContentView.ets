import wfc from '@wfc/client';
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import { showToast } from '../../../common/utils/Toast';
import { parseTextLinks, TextSegment, normalizeUrl, isHttpUrl } from '../../../common/utils/TextLinkParser';
import { common } from '@kit.AbilityKit';
import { uikitNavigationDestinations } from '../../uikitNavigationConfig';
import { MessageContextMenuItem } from './MessageContextMenuItem';
import Config from '@wfc/client/src/main/ets/config';
import MMMessagePreviewDialog from '../../mm/MMMessagePreviewDialog';
import { downloadMedia } from '../../../helper/mediaHelper';
import { filePreview } from '@kit.PreviewKit';
import { fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { TextStyleToken, FontSize, Radius } from '../../../common/design/Tokens'

@Component
export default struct TextMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message
    @Prop textPadding: Length | Padding = 10
    @Prop menuItems: MessageContextMenuItem[] = []
    @Prop clearBackGround: boolean = false
    @State selectionStart: number = -1
    @State selectionEnd: number = -1
    @Link selectedText:string
    // 延迟取消选择的定时器 ID
    private clearSelectionTimerId: number = -1
    private mmPreviewDialogController?: CustomDialogController

    quoteInfoDesc() {
        let quoteInfo = (this.message.messageContent as TextMessageContent).quoteInfo
        return `${quoteInfo?.userDisplayName}: ${quoteInfo?.messageDigest}`
    }

    showQuoteMessage() {
        let quoteInfo = (this.message.messageContent as TextMessageContent).quoteInfo
        let messageUid = quoteInfo!.messageUid
        let msg = wfc.getMessageByUid(messageUid)
        if (!msg) {
            showToast('引用的消息本地不存在')
            return
        }
        let type = msg.messageContent.type
        if (type === MessageContentType.Text || type === MessageContentType.P_Text
            || type === MessageContentType.Streaming_Text_Generated || type === MessageContentType.Streaming_Text_Generating) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.TextMessagePreviewPage, {
                'message': msg
            } as Record<string, object>)
        } else if (type === MessageContentType.Image || type === MessageContentType.Video) {
            this.mmPreviewDialogController = new CustomDialogController({
                builder: MMMessagePreviewDialog({
                    message: msg,
                    index: 0,
                    controller: this.mmPreviewDialogController,
                }),
                alignment: DialogAlignment.TopStart,
                autoCancel: false,
                customStyle: true,
            })
            this.mmPreviewDialogController.open()
        } else if (type === MessageContentType.File) {
            let fileContent = msg.messageContent as FileMessageContent
            let ext = fileContent.name.substring(fileContent.name.lastIndexOf('.') + 1).toLowerCase()
            if (Config.DISABLED_RECEIVE_FILE_TYPES.includes(ext)) {
                showToast('禁止打开此类型')
                return
            }
            let context = getContext(this)
            downloadMedia(context, msg.messageUid, fileContent.remotePath)
                .then(async filePath => {
                    let canPreview = await filePreview.canPreview(context, fileUri.getUriFromPath(filePath))
                    if (canPreview) {
                        let uri = fileUri.getUriFromPath(filePath)
                        let typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(filePath.substring(filePath.lastIndexOf('.')))
                        let typeObj = uniformTypeDescriptor.getTypeDescriptor(typeId)
                        filePreview.openPreview(context, {
                            title: fileContent.name,
                            uri: uri,
                            mimeType: typeObj.mimeTypes[0],
                        })
                    }
                })
        } else if (type === MessageContentType.Composite_Message) {
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.CompositeMessagePreviewPage, {
                'message': msg
            } as Record<string, object>)
        } else {
            showToast('不支持预览此类型消息')
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
                        .constraintSize({ minHeight: 40, maxWidth: 560 })
                        .backgroundColor(this.clearBackGround ? Color.Transparent : this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                        .fontColor($r('app.color.wf_primary_text')).fontSize(TextStyleToken.messageText)
                        .borderRadius(Radius.sm)
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
                        .constraintSize({ minHeight: 40, maxWidth: 560 })
                        .backgroundColor(this.clearBackGround ? Color.Transparent : this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                        .fontColor($r('app.color.wf_primary_text')).fontSize(TextStyleToken.messageText)
                        .borderRadius(Radius.sm)
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
                    .constraintSize({ minHeight: 40, maxWidth: 560 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .backgroundColor($r('app.color.wf_primary_background_color'))
                    .fontColor($r('app.color.wf_tertiary_text')).fontSize(TextStyleToken.messageQuote)
                    .borderRadius(Radius.sm)
                    .onClick(() => {
                        this.showQuoteMessage()
                    })
            }
            .alignItems(this.message.direction === 0 ? HorizontalAlign.End : HorizontalAlign.Start)

        } else {
            if (Config.OPEN_LINK_POLICY === 0) {
                Text(this.getTextContent())
                    .padding(this.textPadding)
                    .constraintSize({ minHeight: 40, maxWidth: 560 })
                    .backgroundColor(this.clearBackGround ? Color.Transparent : this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                    .fontColor($r('app.color.wf_primary_text')).fontSize(TextStyleToken.messageText)
                    .borderRadius(Radius.sm)
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
                    .constraintSize({ minHeight: 40, maxWidth: 560 })
                    .backgroundColor(this.clearBackGround ? Color.Transparent : this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
                    .fontColor($r('app.color.wf_primary_text')).fontSize(TextStyleToken.messageText)
                    .borderRadius(Radius.sm)
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
                                .fontSize(FontSize.sm)
                                .fontColor(Color.White)
                        }
                        .justifyContent(FlexAlign.Center)
                        .width(60)
                        .height(72)
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
        .borderRadius(Radius.lg)
        .padding({ left: 12,
            right: 12,
            top: 12,
            bottom: 12 })
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