import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import client from 'marswrapper'
import { config as emojiConfig } from './EmojiAndStickerConfig'
import { Emoji, Category } from './emojis'
import Conversation from '../../../wfc/model/conversation'
import ConversationType from '../../../wfc/model/conversationType'
import { showToast } from '../../../common/utils/Toast'
import StickerMessageContent from '../../../wfc/messages/stickerMessageContent'
import wfc from '../../../wfc/client/wfc'

@Preview
@Component
export default struct EmojiInputPanelView {
    private emojis: Emoji[]
    private emojiAndStickers: Emoji[]
    private emojiCategories: Category[]
    private conversation: Conversation
    @State currentCategoryIndex: number = 0
    @Link text: string

    aboutToAppear() {
        let config = emojiConfig();
        // if (this.conversation.type === ConversationType.SecretChat) {
        // } else {
        this.emojiCategories = config.emojiCategories;
        this.emojiAndStickers = config.emojis
        this.emojis = config.emojis
            .filter(emoji => config.emojiCategories.findIndex(category => category.name === emoji.category) >= 0)
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
                                            // showToast('TODO ' + emoji.data)
                                            this.text = this.text + emoji.data
                                        })
                                    }, (emoji: Emoji, index: number) => index + '')
                                }
                            }
                            .scrollable(ScrollDirection.Vertical)
                            .scrollBar(BarState.Off)
                            .padding({ bottom: 40 })

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
                                            wfc.sendConversationMessage(this.conversation, stickerMessageContent)
                                        })
                                    }, (emoji: Emoji, index: number) => index + '')
                                }
                            }
                            .scrollable(ScrollDirection.Vertical)
                            .scrollBar(BarState.Off)
                            .padding({ top: 10 })
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