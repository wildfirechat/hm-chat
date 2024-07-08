import BasicDataSource from '../../common/BasicDataSource'
import { get } from '../../helper/httpHelper'
import { timeFormat } from '../../util/helper'
import wfc from '../../wfc/client/wfc'
import CompositeMessageContent from '../../wfc/messages/compositeMessageContent'
import Message from '../../wfc/messages/message'
import Conversation from '../../wfc/model/conversation'
import Long from '../../wfc/util/long'
import { eq } from '../../wfc/util/longUtil'
import CompositeMessageContentContainerView from './message/CompositeMessageContentContainerView'
import { http } from '@kit.NetworkKit'

@Entry
@Component
export default struct PreviewCompositeMessagePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private message?: Message;
    private conversation?: Conversation
    private compositeMessageDataSource?: CompositeMessageDataSource
    @State enableMultiCheck: boolean = false
    @State quotedMessage?: Message = undefined
    @State title: string = '组合消息'

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.message = params['message'] as Message;
        this.conversation = this.message?.conversation;
        this.compositeMessageDataSource = new CompositeMessageDataSource()

        let compositeMessageContent: CompositeMessageContent = this.message.messageContent as CompositeMessageContent;
        this.compositeMessageDataSource.setMessages(compositeMessageContent.messages)
        this.title = compositeMessageContent.title;

        this.loadMediaCompositeMessageContent();
    }

    build() {
        NavDestination() {
            Text('TODO 时间区间')
                .width('100%')
                .fontSize(13)
                .fontColor('#989898')
                .padding(10)
                .visibility(Visibility.None)
                .backgroundColor('#E5E5E5')
            List() {
                LazyForEach(this.compositeMessageDataSource,
                    (msg: Message, index: number) => {
                        ListItem() {
                            Column() {
                                Row() {
                                    Image(wfc.getUserInfo(msg.from).portrait)
                                        .width(40)
                                        .height(40)
                                        .margin(10)
                                        .borderRadius(4)
                                        .visibility(this.showPortrait(index) ? Visibility.Visible : Visibility.Hidden)
                                        .enabled(false)
                                    Column() {
                                        Row() {
                                            Text(wfc.getUserDisplayName(msg.from))
                                                .fontSize(12)
                                                .padding({ bottom: 2 })
                                            Text(timeFormat(msg.timestamp))
                                                .fontSize(12)
                                                .fontColor('#b4b4b4')
                                                .padding(10)
                                        }
                                        .width('100%')
                                        .justifyContent(FlexAlign.SpaceBetween)

                                        CompositeMessageContentContainerView({ message: msg })
                                    }
                                    .justifyContent(FlexAlign.Start)
                                    .alignItems(HorizontalAlign.Start)
                                    .layoutWeight(1)
                                }
                                .width('100%')
                                .justifyContent(FlexAlign.Start)
                                .alignItems(VerticalAlign.Top)
                            }
                            .width('100%')
                            .alignItems(HorizontalAlign.Center)
                        }
                        .padding({ bottom: 10 })
                    },
                    (msg: Message) => this.messageItemKey(msg))

            }
            .scrollBar(BarState.Off)
            .width('100%')
            .height('100%')
            .padding({ right: 10 })
            .divider({ strokeWidth: 1, startMargin: 60 })

        }
        .title(this.title)
        .height('100%')
        .width('100%')
    }

    showPortrait(index: number) {
        if (index === 0) {
            return true
        } else {
            let preMsg = this.compositeMessageDataSource?.getData(index - 1)
            let curMsg = this.compositeMessageDataSource?.getData(index);
            if (preMsg?.from === curMsg?.from) {
                return false;
            } else {
                return true;
            }
        }
    }

    // why?
    // forEach 需要 key 变化，对应项才会更新
    messageItemKey(message: Message) {
        let key: string = message.messageContent.type + '-' + message.messageId + '-' + message.status
        return key
    }

    loadMediaCompositeMessageContent() {
        let compositeMessageContent: CompositeMessageContent = this.message?.messageContent as CompositeMessageContent;
        if (compositeMessageContent.remotePath) {
            get(compositeMessageContent.remotePath, undefined, undefined, http.HttpDataType.STRING)
                .then((data) => {
                    compositeMessageContent._decodeMessages(data as string)
                    this.compositeMessageDataSource?.setMessages(compositeMessageContent.messages)
                })
        }
    }
}

class CompositeMessageDataSource extends BasicDataSource<Message> {
    private messages: Message[] = []

    setMessages(messages: Message[]): void {
        this.messages = messages
        this.notifyDataReload()
    }

    insertMessages(index: number, messages: Message[]) {
        this.messages.splice(0, 0, ...messages)
        this.notifyDataReload();
    }

    appendMessages(messages: Message[]) {
        this.messages = this.messages.concat(messages)
        this.notifyDataReload();
    }

    removeMessageById(messageId: number) {
        let index = this.messages.findIndex(msg => msg.messageId === messageId);
        if (index >= 0) {
            this.messages.splice(index, 1)
            this.notifyDataDelete(index)
        }
    }

    removeMessageByUid(messageUid: Long) {
        let index = this.messages.findIndex(msg => eq(msg.messageUid, messageUid));
        if (index >= 0) {
            this.messages.splice(index, 1)
            this.notifyDataDelete(index)
        }
    }

    updateMessage(message: Message) {
        if (message.messageId !== 0) {
            let index = this.messages.findIndex(msg => msg.messageId === message.messageId);
            if (index >= 0) {
                this.messages[index] = message;
                this.notifyDataChange(index);
            }
        }
    }

    public totalCount(): number {
        return this.messages.length
    }

    public getData(index: number): Message {
        return this.messages[index]
    }
}
