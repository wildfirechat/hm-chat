import { PortraitAndName } from '../../../common/Types'
import Utils from '../../../common/Utils'
import Conversation from '../../../wfc/model/conversation'

@Preview
@CustomDialog
export default struct ForwardMessageDialog {
    private targetConversations: Conversation[] = []
    private textValue: string = ''
    private forwardMessageDesc: string = ''
    private forwardMessageImageUri: string = ''
    @State targetConversationPortraitAndNames: PortraitAndName[] = []
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
            Flex({
                wrap: FlexWrap.Wrap,
                direction: FlexDirection.Row,
                justifyContent: FlexAlign.Start,
                alignItems: ItemAlign.Center,
            }) {
                ForEach(this.targetConversationPortraitAndNames, (pn: PortraitAndName) => {
                    Image(pn.portrait)
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                        .margin({ top: 10, right: 10 })
                    if (this.targetConversations.length === 1) {
                        Text(pn.name)
                    }
                }, (pn: PortraitAndName, index: number) => index + '')
            }
            .width('100%')

            if (this.forwardMessageDesc) {
                Text(this.forwardMessageDesc)
                    .fontSize(13)
                    .fontColor('#989898')
                    .margin({ top: 15 })
                    .padding({ top: 5, bottom: 5 })
                    .maxLines(3)
                    .width('100%')
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .backgroundColor('#E5E5E5')
            } else {
                Image(this.forwardMessageImageUri)
                    .width('100%')
                    .constraintSize({ maxHeight: 200 })
                    .objectFit(ImageFit.Contain)
            }

            TextInput({ placeholder: '给朋友留言' })
                .height(40)
                .width('100%')
                .margin({ top: 20 })
                .borderRadius(4)
                .onChange((value: string) => {
                    this.textValue = value
                })
            Flex({ justifyContent: FlexAlign.End }) {
                Button('取消')
                    .onClick(() => {
                        this.controller.close()
                        this.cancel()
                    }).backgroundColor(0xffffff).fontColor(Color.Black)
                Button('发送')
                    .onClick(() => {
                        this.controller.close()
                        this.confirm(this.textValue)
                    }).backgroundColor(0xffffff).fontColor(Color.Red)
            }
            .margin({ top: 10 })
        }
        .padding(20)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)

        // dialog默认的borderRadius为24vp，如果需要使用border属性，请和borderRadius属性一起使用。
    }
}