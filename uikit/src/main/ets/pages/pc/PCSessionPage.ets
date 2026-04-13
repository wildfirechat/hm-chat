import { showToast } from '../../common/utils/Toast'
import Config from '@wfc/client/src/main/ets/config'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import PCOnlineInfo from '@wfc/client/src/main/ets/wfc/model/pcOnlineInfo'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'

@Component
export default struct PCSessionPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    public pcOnineInfo?: PCOnlineInfo
    @State isMuteWhenPCOnLine: boolean = false
    @State isLockPC: boolean = false

    aboutToAppear() {
        this.isMuteWhenPCOnLine = wfc.isMuteNotificationWhenPcOnline()
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.pcOnineInfo = params['pcOnlineInfo'] as PCOnlineInfo
        if (this.pcOnineInfo) {
            this.isLockPC = wfc.isLockPCClient(this.pcOnineInfo.clientId)
        }
    }

    onSettingUpdate = () => {
        this.checkPCOnlineStatus()
    }

    checkPCOnlineStatus() {
        if (!this.pcOnineInfo) {
            return
        }
        let infos = wfc.getPCOnlineInfos()
        let pcStillOnline = false
        for (let info of infos) {
            if (info.clientId === this.pcOnineInfo.clientId) {
                pcStillOnline = true
                break
            }
        }
        if (!pcStillOnline) {
            this.mainNavPathStack.pop()
        }
    }

    build() {
        NavDestination() {
            Column() {
                // PC 图标
                Image($r('app.media.pc'))
                    .width(120)
                    .height(120)
                    .margin({ top: 30 })

                // 状态文字
                Text(`${this.pcOnineInfo?.platform?.getPlatFormName()} 已登录`)
                    .fontSize(16)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .margin({ top: 16 })

                // 功能列表
                Column() {
                    // 静音
                    Row() {
                        Text('手机静音')
                            .fontSize(16)
                            .fontColor($r('app.color.wf_primary_text'))
                            .layoutWeight(1)

                        Toggle({ type: ToggleType.Switch, isOn: this.isMuteWhenPCOnLine })
                            .selectedColor($r('app.color.wf_primary'))
                            .onChange((isOn: boolean) => {
                                wfc.muteNotificationWhenPcOnline(isOn, () => {
                                    this.isMuteWhenPCOnLine = isOn
                                }, err => {
                                    showToast('设置失败 ' + err)
                                })
                            })
                    }
                    .width('100%')
                    .height(56)
                    .padding({ left: 16, right: 16 })

                    Divider()
                        .strokeWidth(1)
                        .color($r('app.color.wf_divider'))
                        .margin({ left: 16 })

                    // 锁定
                    Row() {
                        Text('锁定电脑')
                            .fontSize(16)
                            .fontColor($r('app.color.wf_primary_text'))
                            .layoutWeight(1)

                        Toggle({ type: ToggleType.Switch, isOn: this.isLockPC })
                            .selectedColor($r('app.color.wf_primary'))
                            .onChange((isOn: boolean) => {
                                wfc.lockPCClient(this.pcOnineInfo!.clientId, isOn, () => {
                                    this.isLockPC = isOn
                                }, err => {
                                    showToast('设置失败 ' + err)
                                })
                            })
                    }
                    .width('100%')
                    .height(56)
                    .padding({ left: 16, right: 16 })

                    Divider()
                        .strokeWidth(1)
                        .color($r('app.color.wf_divider'))
                        .margin({ left: 16 })

                    // 文件助手
                    Row() {
                        Text('传文件')
                            .fontSize(16)
                            .fontColor($r('app.color.wf_primary_text'))
                            .layoutWeight(1)

                        Text('>')
                            .fontSize(18)
                            .fontColor($r('app.color.wf_tertiary_text'))
                    }
                    .width('100%')
                    .height(56)
                    .padding({ left: 16, right: 16 })
                    .onClick(() => {
                        this.mainNavPathStack.replacePathByName(uikitNavigationDestinations.ConversationPage, {
                            'conversation': new Conversation(ConversationType.Single, Config.FILE_HELPER_ID, 0)
                        } as Record<string, Object>)
                    })
                }
                .width('100%')
                .backgroundColor($r('app.color.wf_background'))
                .margin({ top: 30 })

                Blank()

                // 退出登录按钮
                Button(`退出${this.pcOnineInfo?.platform.getPlatFormName()}登录`, { type: ButtonType.Normal, stateEffect: true })
                    .backgroundColor(0xFA5151)
                    .fontColor(Color.White)
                    .fontSize(16)
                    .height(44)
                    .borderRadius(5)
                    .width('90%')
                    .margin({ bottom: 40 })
                    .onClick(() => {
                        wfc.kickoffPCClient(this.pcOnineInfo?.clientId!, () => {
                            this.mainNavPathStack.pop()
                        }, err => {
                            showToast('操作失败 ' + err)
                        })
                    })
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .title('已登录的设备')
        .height('100%')
        .width('100%')
        .onReady(() => {
            // 页面显示时：添加监听并检查PC状态
            wfc.eventEmitter?.on(EventType.SettingUpdate, this.onSettingUpdate)
            this.checkPCOnlineStatus()
        })
        .onHidden(() => {
            // 页面隐藏时：移除监听
            wfc.eventEmitter?.off(EventType.SettingUpdate, this.onSettingUpdate)
        })
    }
}
