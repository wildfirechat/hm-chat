import { showToast } from '../../../common/utils/Toast'
import ConferenceInviteMessageContent from '../../../wfc/av/messages/conferenceInviteMessageContent'
import wfc from '../../../wfc/client/wfc'
import CardMessageContent from '../../../wfc/messages/cardMessageContent'
import Message from '../../../wfc/messages/message'
import { navigationDestinations } from '../../navigationConfig'

@Component
export default struct CardMessageContentView {
    @Link message: Message
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear(): void {
        let content = this.message.messageContent as CardMessageContent
    }

    cardMessageContent() {
        return this.message.messageContent as CardMessageContent
    }

    desc() {
        let desc = '名片';
        switch (this.cardMessageContent().cardType) {
            case 0:
                desc = '个人名片'
                break;
            case 1:
                desc = '群组名片'
                break;
            case 2:
                desc = '聊天室名'
                break;
            case 3:
                desc = '频道名片'
                break;
            default:
                break;
        }
        return desc
    }

    showCardInfo() {
        let cardMsg = this.cardMessageContent()
        switch (cardMsg.cardType) {
            case 0:
                this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, {
                    'userInfo': wfc.getUserInfo(cardMsg.target)
                } as Record<string, Object>)
                break;
        // case 1:
        //     break;
        // case 2:
        //     break;
        // case 3:
        //     break;
            default:
                showToast('TODO')
                break;
        }
    }

    build() {
        Column() {
            Row() {
                Image(this.cardMessageContent().portrait)
                    .width(50)
                    .height(50)
                    .margin(10)
                Column() {
                    Text(this.cardMessageContent().displayName)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .fontSize(18)
                        .maxLines(1)
                    // Text(this.conferenceInviteMessageContent().desc)
                    //     .fontSize(12)
                    //     .maxLines(1)
                }
                .padding({ right: 10 })
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(HorizontalAlign.Start)
            }
            .justifyContent(FlexAlign.Start)

            Divider()
                .margin({ left: 10, right: 10, bottom: 10 })
            Text(this.desc())
                .maxLines(1)
                .fontSize(12)
                .margin({ left: 10, bottom: 10 })
        }
        .onClick(() => {
            this.showCardInfo()
        })
        .width(200)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(4)
    }
}