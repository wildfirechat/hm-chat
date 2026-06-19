import { showToast } from '../../../common/utils/Toast'
import ConferenceInviteMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/conferenceInviteMessageContent'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import CardMessageContent from '@wfc/client/src/main/ets/wfc/messages/cardMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'
import { FontSize, Radius } from '../../../common/design/Tokens'

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
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
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
                    .width(52)
                    .height(52)
                    .margin(12)
                Column() {
                    Text(this.cardMessageContent().displayName)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .fontSize(FontSize.lg)
                        .maxLines(1)
                    // Text(this.conferenceInviteMessageContent().desc)
                    //     .fontSize(FontSize.xs)
                    //     .maxLines(1)
                }
                .padding({ right: 12 })
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(HorizontalAlign.Start)
            }
            .justifyContent(FlexAlign.Start)

            Divider()
                .margin({ left: 12, right: 12, bottom: 12 })
            Text(this.desc())
                .maxLines(1)
                .fontSize(FontSize.xs)
                .margin({ left: 12, bottom: 12 })
        }
        .onClick(() => {
            this.showCardInfo()
        })
        .width(200)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor($r('app.color.wf_background'))
        .borderRadius(Radius.sm)
    }
}