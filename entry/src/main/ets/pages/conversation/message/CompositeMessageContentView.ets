import Message from '../../../wfc/messages/message'

@Component
export default struct CompositeMessageContentView {
    @Link message: Message

    build() {
        Text('TODO组合消息')
            .margin({ top: 4 })
            .padding(10)
            .constraintSize({ minHeight: 40 })
            .backgroundColor(Color.White)
            .borderRadius(4)
    }
}