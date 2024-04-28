import { config as emojiConfig } from './EmojiAndStickerConfig'
import { Category, Emoji } from './emojis'
import Conversation from '../../../wfc/model/conversation'
import StickerMessageContent from '../../../wfc/messages/stickerMessageContent'
import wfc from '../../../wfc/client/wfc'

@Preview
@Component
export default struct EmojiInputPanelView {
    private emojis: Emoji[] = []
    private emojiAndStickers: Emoji[] = []
    private emojiCategories: Category[] = []
    private conversation?: Conversation
    @State currentCategoryIndex: number = 0
    @Link text: string
    @Link caretPosition: number
    @Prop selectionStart: number
    @Prop selectionEnd: number

    aboutToAppear() {
        let config = emojiConfig();
        // if (this.conversation.type === ConversationType.SecretChat) {
        // } else {
        this.emojiCategories = config.emojiCategories as Category[];
        this.emojiAndStickers = config.emojis as Emoji[]
        this.emojis = this.emojiAndStickers
            .filter(emoji => this.emojiCategories.findIndex((category: Category) => category.name === emoji.category) >= 0)
            .filter(emoji => emoji.category === 'Peoples')
        // }

    }

    // 由于不支持 svg，否则 category.icon 即可
    categoryIcon(category: Category): ResourceStr {
        if (category.name === 'Peoples') {
            return $r('app.media.ic_chat_emo')
        }
        let categoryEmojis = this.emojiAndStickers.filter(emoji => emoji.category === category.name)
        return categoryEmojis[0].data
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
                    .width(44)
                    .height(40)
                    .borderRadius(4)
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(this.currentCategoryIndex === index ? '#E5E5E5' : Color.White)
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

            Stack() {
                Swiper() {
                    ForEach(this.emojiCategories, (category: Category) => {
                        if (category.name === 'Peoples') {
                            Scroll() {
                                Flex({
                                    direction: FlexDirection.Row,
                                    justifyContent: FlexAlign.SpaceAround,
                                    wrap: FlexWrap.Wrap,
                                    alignItems: ItemAlign.Start
                                }) {
                                    ForEach(this.emojis, (emoji: Emoji) => {
                                        Row() {
                                            Text(emoji.data)
                                                .fontSize(22)
                                        }
                                        .width(44)
                                        .height(44)
                                        .borderRadius(4)
                                        .alignItems(VerticalAlign.Center)
                                        .justifyContent(FlexAlign.Center)
                                        .stateStyles({
                                            pressed: {
                                                .backgroundColor('#E5E5E5')
                                            },
                                            normal: {
                                                .backgroundColor(Color.White)
                                            }
                                        })
                                        .onClick(() => {
                                            this.text = this.text.slice(0, this.selectionStart) + emoji.data + this.text.slice(this.selectionEnd)
                                            this.caretPosition = this.selectionStart + emoji.data.length;
                                            this.selectionStart = this.selectionStart + emoji.data.length
                                            this.selectionEnd = this.selectionStart;
                                        })
                                    }, (emoji: Emoji, index: number) => index + '')
                                }
                            }
                            .scrollable(ScrollDirection.Vertical)
                            .scrollBar(BarState.Off)
                            .padding({ bottom: 40 })
                            .height('100%')

                        } else {
                            Scroll() {
                                Flex({
                                    direction: FlexDirection.Row,
                                    justifyContent: FlexAlign.SpaceAround,
                                    wrap: FlexWrap.Wrap,
                                    alignItems: ItemAlign.Start
                                }) {
                                    ForEach(this.emojiAndStickers.filter(emoji => emoji.category === category.name), (emoji: Emoji) => {
                                        Row() {
                                            Image(emoji.data)
                                                .height(64)
                                                .width(64)
                                                .draggable(false)
                                        }
                                        .width(70)
                                        .height(70)
                                        .borderRadius(4)
                                        .alignItems(VerticalAlign.Center)
                                        .justifyContent(FlexAlign.Center)
                                        .stateStyles({
                                            pressed: {
                                                .backgroundColor('#E5E5E5')
                                            },
                                            normal: {
                                                .backgroundColor(Color.White)
                                            }
                                        })
                                        .onClick(() => {
                                            let stickerMessageContent = new StickerMessageContent('', emoji.data, 200, 200)
                                            wfc.sendConversationMessage(this.conversation!, stickerMessageContent)
                                        })
                                    }, (emoji: Emoji, index: number) => index + '')
                                }
                                .height('100%')
                            }
                            .scrollable(ScrollDirection.Vertical)
                            .scrollBar(BarState.Off)
                            .padding({ top: 10 })
                            .height('100%')
                        }
                    }, (category: Category, index: number) => index + '')
                }
                .index(this.currentCategoryIndex)
                .loop(false)
                .indicator(false)
                .cachedCount(1)
                .onChange(index => {
                    this.currentCategoryIndex = index
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
                    .backgroundColor(Color.Red)
                    .borderRadius(4)
                    .stateStyles({
                        pressed: {
                            .backgroundColor('#E5E5E5')
                        },
                        normal: {
                            .backgroundColor(Color.White)
                        }
                    })
                    .alignSelf(ItemAlign.End)
                    .onClick(() => {
                        // TODO 不能处理 unicode 字符
                        // FIXME
                        // if (this.caretPosition > 0) {
                        //     let char = this.text.charAt(this.caretPosition - 1)
                        //     this.text = this.text.substring(0, this.caretPosition - 1) + this.text.substring(this.caretPosition);
                        //     this.caretPosition = this.caretPosition - char.length;
                        // }
                    })
                }
            }
            .layoutWeight(1)
            .alignContent(Alignment.BottomEnd)
        }
        .padding(10)
        .width('100%')
        .height('100%')
    }
}

