import { config as emojiConfig } from './EmojiAndStickerConfig'
import { Category, Emoji } from './emojis'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import StickerMessageContent from '@wfc/client/src/main/ets/wfc/messages/stickerMessageContent'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { deviceInfo } from '@kit.BasicServicesKit'

const EMOJI_COLS = 8
const STICKER_COLS = 5
const EMOJI_ITEM_H = 44
const STICKER_ITEM_H = 70
const LONG_PRESS_MS = 500
const MOVE_CANCEL_THRESHOLD = 10

@Preview
@Component
export default struct EmojiInputPanelView {
    private emojis: Emoji[] = []
    private emojiAndStickers: Emoji[] = []
    private emojiCategories: Category[] = []
    conversation?: Conversation
    textInputController?: TextInputController
    @State currentCategoryIndex: number = 0
    @Link text: string
    @Link caretPosition: number
    @Prop selectionStart: number
    @Prop selectionEnd: number
    private scroller: Scroller = new Scroller()
    private stickerScrollY: number = 0

    // Notifies ConversationPage of long-press preview state changes.
    // rowY = visual row top Y relative to Grid viewport (row * itemH - scrollOffset).
    // Called with (null,0,0,0) to dismiss.
    onPreviewChange?: (emoji: Emoji | null, col: number, colW: number, rowY: number) => void

    private previewEmoji: Emoji | null = null
    @State private isLongPressing: boolean = false
    private longPressJustEnded: boolean = false
    private longPressTimerId: number = -1
    private touchStartX: number = 0
    private touchStartY: number = 0
    private gridWidth: number = 0

    aboutToAppear() {
        let config = emojiConfig()
        this.emojiCategories = config.emojiCategories as Category[]
        this.emojiAndStickers = config.emojis as Emoji[]
        this.emojis = this.emojiAndStickers
            .filter(emoji => this.emojiCategories.findIndex((c: Category) => c.name === emoji.category) >= 0)
            .filter(emoji => emoji.category === 'Peoples')
    }

    categoryIcon(category: Category): ResourceStr {
        if (category.name === 'Peoples') {
            return $r('app.media.ic_chat_emo')
        }
        let categoryEmojis = this.emojiAndStickers.filter(emoji => emoji.category === category.name)
        return categoryEmojis[0].data
    }

    private updateEmojiPreview(x: number, y: number) {
        const scrollY = this.scroller.currentOffset().yOffset
        const colW = this.gridWidth / EMOJI_COLS
        const col = Math.max(0, Math.min(EMOJI_COLS - 1, Math.floor(x / colW)))
        const row = Math.max(0, Math.floor((y + scrollY) / EMOJI_ITEM_H))
        const idx = row * EMOJI_COLS + col
        if (idx >= 0 && idx < this.emojis.length) {
            this.previewEmoji = this.emojis[idx]
            this.onPreviewChange?.(this.previewEmoji, col, colW, row * EMOJI_ITEM_H - scrollY)
        } else {
            this.previewEmoji = null
            this.onPreviewChange?.(null, 0, 0, 0)
        }
    }

    private updateStickerPreview(x: number, y: number, categoryName: string) {
        const stickers = this.emojiAndStickers.filter(e => e.category === categoryName)
        const colW = this.gridWidth / STICKER_COLS
        const col = Math.max(0, Math.min(STICKER_COLS - 1, Math.floor(x / colW)))
        const row = Math.max(0, Math.floor((y + this.stickerScrollY) / STICKER_ITEM_H))
        const idx = row * STICKER_COLS + col
        if (idx >= 0 && idx < stickers.length) {
            this.previewEmoji = stickers[idx]
            this.onPreviewChange?.(this.previewEmoji, col, colW, row * STICKER_ITEM_H - this.stickerScrollY)
        } else {
            this.previewEmoji = null
            this.onPreviewChange?.(null, 0, 0, 0)
        }
    }

    private onEmojiGridTouch(event: TouchEvent) {
        const touch = event.touches[0]
        if (event.type === TouchType.Down) {
            this.longPressJustEnded = false
            this.touchStartX = touch.x
            this.touchStartY = touch.y
            this.longPressTimerId = setTimeout(() => {
                this.isLongPressing = true
                this.updateEmojiPreview(touch.x, touch.y)
            }, LONG_PRESS_MS) as number
        } else if (event.type === TouchType.Move) {
            const dx = touch.x - this.touchStartX
            const dy = touch.y - this.touchStartY
            if (!this.isLongPressing && Math.sqrt(dx * dx + dy * dy) > MOVE_CANCEL_THRESHOLD) {
                clearTimeout(this.longPressTimerId)
            }
            if (this.isLongPressing) {
                if (touch.y < 0) {
                    this.isLongPressing = false
                    this.previewEmoji = null
                    this.onPreviewChange?.(null, 0, 0, 0)
                } else {
                    event.stopPropagation()
                    this.updateEmojiPreview(touch.x, touch.y)
                }
            }
        } else if (event.type === TouchType.Up) {
            clearTimeout(this.longPressTimerId)
            this.longPressJustEnded = this.isLongPressing
            this.isLongPressing = false
            this.previewEmoji = null
            this.onPreviewChange?.(null, 0, 0, 0)
        } else if (event.type === TouchType.Cancel) {
            clearTimeout(this.longPressTimerId)
            this.isLongPressing = false
            this.previewEmoji = null
            this.onPreviewChange?.(null, 0, 0, 0)
        }
    }

    private onStickerGridTouch(event: TouchEvent, categoryName: string) {
        const touch = event.touches[0]
        if (event.type === TouchType.Down) {
            this.longPressJustEnded = false
            this.touchStartX = touch.x
            this.touchStartY = touch.y
            this.longPressTimerId = setTimeout(() => {
                this.isLongPressing = true
                this.updateStickerPreview(touch.x, touch.y, categoryName)
            }, LONG_PRESS_MS) as number
        } else if (event.type === TouchType.Move) {
            const dx = touch.x - this.touchStartX
            const dy = touch.y - this.touchStartY
            if (!this.isLongPressing && Math.sqrt(dx * dx + dy * dy) > MOVE_CANCEL_THRESHOLD) {
                clearTimeout(this.longPressTimerId)
            }
            if (this.isLongPressing) {
                if (touch.y < 0) {
                    this.isLongPressing = false
                    this.previewEmoji = null
                    this.onPreviewChange?.(null, 0, 0, 0)
                } else {
                    event.stopPropagation()
                    this.updateStickerPreview(touch.x, touch.y, categoryName)
                }
            }
        } else if (event.type === TouchType.Up) {
            clearTimeout(this.longPressTimerId)
            this.longPressJustEnded = this.isLongPressing
            this.isLongPressing = false
            this.previewEmoji = null
            this.onPreviewChange?.(null, 0, 0, 0)
        } else if (event.type === TouchType.Cancel) {
            clearTimeout(this.longPressTimerId)
            this.isLongPressing = false
            this.previewEmoji = null
            this.onPreviewChange?.(null, 0, 0, 0)
        }
    }

    // Number of UTF-16 code units the character before the caret occupies.
    // Returns 2 for a surrogate pair (emoji), 1 otherwise.
    private deleteLengthBeforeCaret(): number {
        const pos = this.caretPosition
        if (pos >= 2) {
            const low = this.text.charCodeAt(pos - 1)
            const high = this.text.charCodeAt(pos - 2)
            if (low >= 0xDC00 && low <= 0xDFFF && high >= 0xD800 && high <= 0xDBFF) {
                return 2
            }
        }
        return 1
    }

    private insertEmoji(data: string) {
        this.text = this.text.slice(0, this.selectionStart) + data + this.text.slice(this.selectionEnd)
        this.caretPosition = this.selectionStart + data.length
        this.selectionStart = this.caretPosition
        this.selectionEnd = this.caretPosition
    }

    build() {
        Column() {
            List() {
                ForEach(this.emojiCategories, (category: Category, index: number) => {
                    ListItem() {
                        Image(this.categoryIcon(category))
                            .alt(category.icon)
                            .width(24)
                            .height(24)
                    }
                    .padding(8)
                    .borderRadius(4)
                    .stateStyles({
                        pressed: {
                            .backgroundColor($r('app.color.wf_item_pressed'))
                        },
                        normal: {
                            .backgroundColor(this.currentCategoryIndex === index ? $r('app.color.wf_item_pressed') : Color.Transparent)
                        }
                    })
                    .onClick(() => {
                        this.currentCategoryIndex = index
                    })
                }, (category: Category, index: number) => index + '')
            }
            .listDirection(Axis.Horizontal)
            .alignListItem(ListItemAlign.Center)
            .width('100%')
            .height(40)
            .padding({ left: 10, right: 10 })

            Stack() {
                Swiper() {
                    ForEach(this.emojiCategories, (category: Category) => {
                        if (category.name === 'Peoples') {
                            Grid(this.scroller) {
                                ForEach(this.emojis, (emoji: Emoji) => {
                                    GridItem() {
                                        Text(emoji.data)
                                            .fontSize(22)
                                    }
                                    .width(EMOJI_ITEM_H)
                                    .height(EMOJI_ITEM_H)
                                    .borderRadius(4)
                                    .align(Alignment.Center)
                                    .stateStyles({
                                        pressed: {
                                            .backgroundColor($r('app.color.wf_item_pressed'))
                                        },
                                        normal: {
                                            .backgroundColor(Color.Transparent)
                                        }
                                    })
                                    .onClick(() => {
                                        if (this.longPressJustEnded) {
                                            this.longPressJustEnded = false
                                            return
                                        }
                                        this.insertEmoji(emoji.data)
                                    })
                                }, (emoji: Emoji, index: number) => index + '')
                            }
                            .enableScrollInteraction(!this.isLongPressing)
                            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
                            .scrollBar(BarState.Off)
                            .padding({ bottom: 40 })
                            .edgeEffect(EdgeEffect.Spring)
                            .height('100%')
                            .onAreaChange((_, newArea) => {
                                this.gridWidth = newArea.width as number
                            })
                            .onTouch((event: TouchEvent) => {
                                this.onEmojiGridTouch(event)
                            })

                        } else {
                            Grid() {
                                ForEach(this.emojiAndStickers.filter(e => e.category === category.name), (emoji: Emoji) => {
                                    GridItem() {
                                        Image(emoji.data)
                                            .height(64)
                                            .width(64)
                                            .draggable(false)
                                    }
                                    .width(STICKER_ITEM_H)
                                    .height(STICKER_ITEM_H)
                                    .borderRadius(4)
                                    .stateStyles({
                                        pressed: {
                                            .backgroundColor($r('app.color.wf_item_pressed'))
                                        },
                                        normal: {
                                            .backgroundColor(Color.Transparent)
                                        }
                                    })
                                    .onClick(() => {
                                        if (this.longPressJustEnded) {
                                            this.longPressJustEnded = false
                                            return
                                        }
                                        let stickerMessageContent = new StickerMessageContent('', emoji.data, 200, 200)
                                        wfc.sendConversationMessage(this.conversation!, stickerMessageContent)
                                    })
                                }, (emoji: Emoji, index: number) => index + '')
                            }
                            .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
                            .enableScrollInteraction(!this.isLongPressing)
                            .scrollBar(BarState.Off)
                            .padding({ top: 10 })
                            .height('100%')
                            .edgeEffect(EdgeEffect.Spring, {
                                alwaysEnabled: true,
                            })
                            .onAreaChange((_, newArea) => {
                                this.gridWidth = newArea.width as number
                            })
                            .onScrollIndex((first: number) => {
                                this.stickerScrollY = Math.floor(first / STICKER_COLS) * STICKER_ITEM_H
                            })
                            .onTouch((event: TouchEvent) => {
                                this.onStickerGridTouch(event, category.name)
                            })
                        }
                    }, (category: Category, index: number) => index + '')
                }
                .index(this.currentCategoryIndex)
                .loop(false)
                .indicator(false)
                .cachedCount(1)
                .disableSwipe(this.isLongPressing)
                .onChange(index => {
                    this.currentCategoryIndex = index
                    this.stickerScrollY = 0
                })

                if (this.currentCategoryIndex === 0) {
                    Row() {
                        Image($r('app.media.ic_emoji_del'))
                            .width(20)
                            .height(20)
                    }
                    .width(60)
                    .height(40)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(VerticalAlign.Center)
                    .borderRadius(4)
                    .stateStyles({
                        pressed: {
                            .backgroundColor($r('app.color.wf_item_pressed'))
                        },
                        normal: {
                            .backgroundColor($r('app.color.wf_background'))
                        }
                    })
                    .alignSelf(ItemAlign.End)
                    .onClick(() => {
                        if (this.caretPosition <= 0) {
                            return
                        }
                        // Emoji are UTF-16 surrogate pairs (2 code units). Delete the
                        // full code point before the caret, not a single code unit,
                        // otherwise half the pair is left behind as a garbled char.
                        const deleteLen = this.deleteLengthBeforeCaret()
                        if (deviceInfo.sdkApiVersion >= 15) {
                            this.textInputController?.deleteText(
                                {
                                    start: this.caretPosition - deleteLen,
                                    end: this.caretPosition
                                }
                            )
                        } else {
                            this.text = this.text.substring(0, this.caretPosition - deleteLen) + this.text.substring(this.caretPosition);
                            this.caretPosition = this.caretPosition - deleteLen;
                        }
                    })
                }
            }
            .padding(10)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .alignContent(Alignment.BottomEnd)
        }
        .width('100%')
        .height('100%')
    }
}
