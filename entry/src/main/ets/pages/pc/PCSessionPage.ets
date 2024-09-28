import { showToast } from '../../common/utils/Toast'
import Config from '@wfc/client/src/main/ets/config'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import PCOnlineInfo from '@wfc/client/src/main/ets/wfc/model/pcOnlineInfo'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct PCSessionPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    public pcOnineInfo?: PCOnlineInfo
    @State isMuteWhenPCOnLine: boolean = false

    aboutToAppear() {
        this.isMuteWhenPCOnLine = wfc.isMuteNotificationWhenPcOnline()
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.pcOnineInfo = params['pcOnlineInfo'] as PCOnlineInfo
    }

    build() {
        NavDestination() {
            Column() {
                Image($r('app.media.pc'))
                    .height(200)

                Text(`${this.pcOnineInfo?.platform?.getPlatFormName()} 已登录`)

                Row() {
                    Column() {
                        Image(this.isMuteWhenPCOnLine ? $r('app.media.ic_turn_off_ringer_hover') : $r('app.media.ic_turn_off_ringer'))
                            .width(40)
                            .height(40)
                            .borderRadius(20)

                        Text(this.isMuteWhenPCOnLine ? '手机已静音' : '静音')
                            .fontSize(14)
                            .fontColor('#7E7E7E')
                            .margin({ top: 10 })
                    }
                    .width(120)
                    .onClick(() => {
                        wfc.muteNotificationWhenPcOnline(!this.isMuteWhenPCOnLine, () => {
                            this.isMuteWhenPCOnLine = !this.isMuteWhenPCOnLine
                        }, err => {
                            showToast('设置失败 ' + err)
                        })
                    })

                    Column() {
                        Image($r('app.media.ic_file_transfer_helper'))
                            .width(40)
                            .height(40)
                        Text('传文件')
                            .fontSize(14)
                            .fontColor('#7E7E7E')
                            .margin({ top: 10 })
                    }
                    .width(120)
                    .onClick(() => {
                        this.mainNavPathStack.replacePathByName(navigationDestinations.ConversationPage, {
                            'conversation': new Conversation(ConversationType.Single, Config.FILE_HELPER_ID, 0)
                        } as Record<string, Object>)
                    })
                }
                .width('100%')
                .margin({ top: 60 })
                .justifyContent(FlexAlign.SpaceAround)


                Blank()
                Column() {
                    Button(`退出${this.pcOnineInfo?.platform.getPlatFormName()}登录`, { type: ButtonType.Normal, stateEffect: true })
                        .backgroundColor(0x317aff)
                        .borderRadius(8)
                        .height(40)
                        .focusable(true)
                        .focusOnTouch(true)
                        .type(ButtonType.Normal)
                        .width('100%')
                        .borderRadius(4)
                        .onClick(() => {
                            wfc.kickoffPCClient(this.pcOnineInfo?.clientId!, () => {
                                this.mainNavPathStack.pop()
                            }, err => {
                                showToast('操作失败 ' + err)
                            })
                        })
                }
                .padding({ bottom: 50, left: 30, right: 30 })
                .width('100%')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
        }
        .title('已登录的设备')
        .height('100%')
        .width('100%')
        .onShown(() => {
            // this.onPageShow()
        })
    }
}
