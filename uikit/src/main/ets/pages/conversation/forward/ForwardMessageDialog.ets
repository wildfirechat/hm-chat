import { PortraitAndName } from '../../../common/Types'
import Utils from '../../../common/Utils'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import { LengthUnit } from '@kit.ArkUI'
import { flexButtonSpace } from '../../../common/Styles'

@Preview
@CustomDialog
export default struct ForwardMessageDialog {
    targetConversations: Conversation[] = []
    textValue: string = ''
    forwardMessageDesc: string = ''
    forwardMessageImageUri: string = ''
    @State targetConversationPortraitAndNames: PortraitAndName[] = []
    @State isInputFocused: boolean = false
    controller: CustomDialogController
    // 若尝试在CustomDialog中传入多个其他的Controller，以实现在CustomDialog中打开另一个或另一些CustomDialog，那么此处需要将指向自己的controller放在最后
    cancel: () => void = () => {
    }
    confirm: (text: string) => void = str => {
    }

    aboutToAppear() {
        this.computeState()
    }

    computeState() {
        this.targetConversations.forEach(conversation => {
            Utils.computeConversationItemPortraitAndName(conversation)
                .then(value => {
                    this.targetConversationPortraitAndNames.push(value)
                })
        })
    }

    build() {
        Column() {
            Text('发送给：')
                .fontSize(18)
                .margin({ top: 10, bottom: 10 })
                .width('100%')
                .textAlign(TextAlign.Start)

            List() {
                ForEach(this.targetConversationPortraitAndNames, (pn: PortraitAndName) => {
                    ListItem() {
                        Row() {
                            Image(pn.portrait)
                                .width(40)
                                .height(40)
                                .borderRadius(4)
                                .margin({ right: 10 })
                            Text(pn.name)
                                .fontSize(16)
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .layoutWeight(1)
                        }
                        .width('100%')
                        .padding({ top: 5, bottom: 5 })
                        .alignItems(VerticalAlign.Center)
                    }
                }, (pn: PortraitAndName, index: number) => index + '')
            }
            .scrollBar(BarState.Off)
            .constraintSize({ maxHeight: 150 })
            .width('100%')
            .alignListItem(ListItemAlign.Start)

            if (this.forwardMessageDesc) {
                Text(this.forwardMessageDesc)
                    .fontSize(13)
                    .fontColor('#989898')
                    .margin({ top: 15 })
                    .padding({
                        left: 20,
                        right: 20,
                        top: 10,
                        bottom: 10
                    })
                    .maxLines(3)
                    .borderRadius(4)
                    .width('100%')
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .backgroundColor('#E5E5E5')
            } else {
                Image(this.forwardMessageImageUri)
                    .width('100%')
                    .constraintSize({ maxHeight: 100 })
                    .objectFit(ImageFit.Contain)
                    .margin({ top: 15 })
            }

            Row() {
                TextInput({ placeholder: '给朋友留言' })
                    .height(40)
                    .layoutWeight(1)
                    .borderRadius(4)
                    .backgroundColor('#F5F5F5')
                    .onChange((value: string) => {
                        this.textValue = value
                    })
                    .onFocus(() => {
                        this.isInputFocused = true
                    })
                    .onBlur(() => {
                        this.isInputFocused = false
                    })

                if (this.isInputFocused) {
                    Button('发送')
                        .type(ButtonType.Normal)
                        .height(30)
                        .width(60)
                        .borderRadius(4)
                        .onClick(() => {
                            this.controller.close()
                            this.confirm(this.textValue)
                        })
                        .fontColor(Color.White)
                        .margin({ left: 10 })
                }
            }
            .width('100%')
            .margin({ top: 20 })


            if (!this.isInputFocused) {
                Flex({ justifyContent: FlexAlign.End, space: flexButtonSpace }) {
                    Button('取消')
                        .onClick(() => {
                            this.controller.close()
                            this.cancel()
                        })
                        .backgroundColor(Color.White)
                        .fontColor(Color.Black)
                        .fontSize(16)
                        .padding({ left: 20, right: 20 })

                    Button('发送')
                        .type(ButtonType.Normal)
                        .height(30)
                        .width(60)
                        .borderRadius(4)
                        .onClick(() => {
                            this.controller.close()
                            this.confirm(this.textValue)
                        })
                        .fontColor(Color.White)
                }
                .margin({ top: 20 })
            }
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .padding(20)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
    }
}
