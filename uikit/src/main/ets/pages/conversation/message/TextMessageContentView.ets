import wfc from '@wfc/client';
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import TextMessageContent from '@wfc/client/src/main/ets/wfc/messages/textMessageContent'
import { showToast } from '../../../common/utils/Toast';
import { uikitNavigationDestinations } from '../../uikitNavigationConfig';
import { MessageContextMenuItem } from './MessageContextMenuItem';

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
                Text(this.getTextContent())
                    .padding(this.textPadding)
                    .constraintSize({ minHeight: 40 })
                    .backgroundColor(Color.White)
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
                            // 菜单出现时全选文本
                            this.selectionStart = 0
                            this.selectionEnd = this.getTextContent().length
                        },
                        onDisappear: () => {
                        },
                        onMenuShow: () => {
                            // 菜单重新显示，取消延迟清除
                            if (this.clearSelectionTimerId !== -1) {
                                clearTimeout(this.clearSelectionTimerId)
                                this.clearSelectionTimerId = -1
                            }
                        },
                        onMenuHide: () => {
                            // 菜单隐藏，延迟取消选择（如果是拖动手柄，菜单会重新显示，定时器会被取消）
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

                Text(this.quoteInfoDesc())
                    .padding(this.textPadding)
                    .margin({ top: 8 })
                    .constraintSize({ minHeight: 40 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .backgroundColor('#E7E7E7')
                    .borderRadius(4)
                    .onClick(() => {
                        this.showQuoteMessage()
                    })
            }
            .alignItems(this.message.direction === 0 ? HorizontalAlign.End : HorizontalAlign.Start)

        } else {
            Text(this.getTextContent())
                .padding(this.textPadding)
                .constraintSize({ minHeight: 40 })
                .backgroundColor(Color.White)
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
                        // 菜单出现时全选文本
                        this.selectionStart = 0
                        this.selectionEnd = this.getTextContent().length
                    },
                    onDisappear: () => {
                    },
                    onMenuShow: () => {
                        // 菜单重新显示，取消延迟清除
                    },
                    onMenuHide: () => {
                        // 菜单隐藏，延迟取消选择（如果是拖动手柄，菜单会重新显示，定时器会被取消）
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
                                .fontColor('#FFFFFF')
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
                                .backgroundColor('#444444')
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
        .backgroundColor('#4c4c4c')
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