import { showToast } from '../../common/utils/Toast'
import Config from '@wfc/client/src/main/ets/config'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import PCOnlineInfo from '@wfc/client/src/main/ets/wfc/model/pcOnlineInfo'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import { FontSize, Radius } from '../../common/design/Tokens'
import { pcPlatformSymbol, pcDeviceName, isPcDesktopDevice } from '../../common/utils/pcOnlineUtil'

/**
 * 已登录的设备页（微信风格）。
 * 路由参数：{ pcOnlineInfos: PCOnlineInfo[] } —— 全部在线设备。
 * 每台设备一张卡片，第一张默认展开；点击卡片展开、其余收起（手风琴）。
 * 卡片头部：小图标 + 类型名 + 设备名灰字 + 箭头；展开区顶部大图标居中 + 名称，下方为功能列表。
 */
@Component
export default struct PCSessionPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State pcOnlineInfos: PCOnlineInfo[] = []
    // 当前展开的卡片下标，-1 表示全部收起
    @State expandedIndex: number = 0
    // 每台设备的锁定状态（与 pcOnlineInfos 下标一一对应）
    @State lockStates: boolean[] = []
    @State isMuteWhenPCOnLine: boolean = false

    aboutToAppear() {
        this.isMuteWhenPCOnLine = wfc.isMuteNotificationWhenPcOnline()
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let infos = params ? params['pcOnlineInfos'] : undefined
        if (Array.isArray(infos)) {
            let list = infos as Object[]
            let result: PCOnlineInfo[] = []
            list.forEach(item => {
                if (item instanceof PCOnlineInfo) {
                    result.push(item)
                }
            })
            if (result.length > 0) {
                // 过滤掉本机（按 clientId），平板等新平台不会在已登录设备列表里看到自己
                this.pcOnlineInfos = this.filterOutSelf(result)
            }
        }
        if (this.pcOnlineInfos.length === 0) {
            // 兼容旧参数（单设备）
            let info = params ? params['pcOnlineInfo'] : undefined
            if (info instanceof PCOnlineInfo && info.clientId !== wfc.getClientId()) {
                this.pcOnlineInfos = [info]
            }
        }
        this.syncLockStates()
    }

    // 过滤掉本机（按 clientId）
    private filterOutSelf(infos: PCOnlineInfo[]): PCOnlineInfo[] {
        let selfClientId = wfc.getClientId()
        return infos.filter((info: PCOnlineInfo) => info.clientId !== selfClientId)
    }

    onSettingUpdate = () => {
        this.checkPCOnlineStatus()
    }

    checkPCOnlineStatus() {
        // 过滤掉本机（按 clientId）：刷新后的列表也不应包含自己
        let infos = this.filterOutSelf(wfc.getPCOnlineInfos())
        this.pcOnlineInfos = infos
        if (infos.length === 0) {
            this.mainNavPathStack.pop()
            return
        }
        if (this.expandedIndex >= infos.length) {
            this.expandedIndex = 0
        }
        this.syncLockStates()
    }

    // 同步每台设备的锁定状态
    private syncLockStates() {
        let states: boolean[] = []
        this.pcOnlineInfos.forEach(info => {
            states.push(wfc.isLockPCClient(info.clientId))
        })
        this.lockStates = states
    }

    // 点击卡片：展开当前、收起其它；点击已展开的卡片则收起
    private toggleExpand(index: number) {
        this.expandedIndex = this.expandedIndex === index ? -1 : index
    }

    // 退出某台设备登录
    private kickoffDevice(info: PCOnlineInfo) {
        wfc.kickoffPCClient(info.clientId, () => {
            showToast('已退出登录')
            this.checkPCOnlineStatus()
        }, err => {
            showToast('操作失败 ' + err)
        })
    }

    // 手机通知（全局开关，改变手机静音状态）
    private toggleMute(value: boolean) {
        wfc.muteNotificationWhenPcOnline(value, () => {
            this.isMuteWhenPCOnLine = value
        }, err => {
            showToast('设置失败 ' + err)
        })
    }

    build() {
        NavDestination() {
            Scroll() {
                Column({ space: 12 }) {
                    ForEach(this.pcOnlineInfos, (info: PCOnlineInfo, index: number) => {
                        this.buildDeviceCard(info, index)
                    }, (info: PCOnlineInfo, index: number) => {
                        return `${info.type}-${info.platform.platform}-${info.clientId}`
                    })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .align(Alignment.Top)
            .backgroundColor($r('app.color.wf_primary_background_color'))
        }
        .title('已登录的设备')
        .height('100%')
        .width('100%')
        .onReady(() => {
            // 页面显示时：添加监听并检查设备状态
            wfc.eventEmitter?.on(EventType.SettingUpdate, this.onSettingUpdate)
            this.checkPCOnlineStatus()
        })
        .onHidden(() => {
            // 页面隐藏时：移除监听
            wfc.eventEmitter?.off(EventType.SettingUpdate, this.onSettingUpdate)
        })
    }

    // 单台设备卡片（微信风格）：头部小图标+名称+灰字+箭头，展开区大图标居中+功能列表
    @Builder
    private buildDeviceCard(info: PCOnlineInfo, index: number) {
        Column() {
            // 卡片头部：小图标 + 类型名 + 设备名灰字 + 右侧箭头
            Row() {
                SymbolGlyph(pcPlatformSymbol(info))
                    .fontSize(FontSize.lg)
                    .fontColor([$r('app.color.wf_primary_text')])

                Column() {
                    Text(pcDeviceName(info))
                        .fontSize(FontSize.md)
                        .fontColor($r('app.color.wf_primary_text'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (info.clientName && info.clientName.length > 0 && info.clientName.toLowerCase() !== 'unknown') {
                        Text(info.clientName)
                            .fontSize(FontSize.xs)
                            .fontColor($r('app.color.wf_tertiary_text'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 12 })

                SymbolGlyph($r('sys.symbol.chevron_down'))
                    .fontSize(FontSize.sm)
                    .fontColor([$r('app.color.wf_tertiary_text')])
                    .rotate({ angle: this.expandedIndex === index ? 180 : 0 })
            }
            .width('100%')
            .height(68)
            .padding({ left: 16, right: 16 })
            .onClick(() => this.toggleExpand(index))

            // 展开内容
            if (this.expandedIndex === index) {
                Column() {
                    // 大图标居中 + 类型名 + 设备名灰字
                    Column() {
                        SymbolGlyph(pcPlatformSymbol(info))
                            .fontSize(56)
                            .fontColor([$r('app.color.wf_primary_text')])
                        Text(pcDeviceName(info))
                            .fontSize(FontSize.lg)
                            .fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.wf_primary_text'))
                            .margin({ top: 12 })
                        if (info.clientName && info.clientName.length > 0 && info.clientName.toLowerCase() !== 'unknown') {
                            Text(info.clientName)
                                .fontSize(FontSize.sm)
                                .fontColor($r('app.color.wf_tertiary_text'))
                                .margin({ top: 6 })
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                    }
                    .width('100%')
                    .padding({ top: 20, bottom: 16 })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    Divider()
                        .strokeWidth(0.5)
                        .color($r('app.color.wf_divider'))

                    // 手机通知（全局）
                    Row() {
                        Text('手机通知')
                            .fontSize(FontSize.md)
                            .fontColor($r('app.color.wf_primary_text'))
                            .layoutWeight(1)
                        Toggle({ type: ToggleType.Switch, isOn: this.isMuteWhenPCOnLine })
                            .selectedColor($r('app.color.wf_primary'))
                            .onChange((isOn: boolean) => this.toggleMute(isOn))
                    }
                    .width('100%')
                    .height(56)
                    .padding({ left: 16, right: 16 })

                    Divider()
                        .strokeWidth(0.5)
                        .color($r('app.color.wf_divider'))
                        .margin({ left: 16 })

                    // 锁定（仅桌面电脑类设备）
                    if (isPcDesktopDevice(info)) {
                        Row() {
                            Text('锁定')
                                .fontSize(FontSize.md)
                                .fontColor($r('app.color.wf_primary_text'))
                                .layoutWeight(1)
                            Toggle({ type: ToggleType.Switch, isOn: this.lockStates[index] ?? false })
                                .selectedColor($r('app.color.wf_primary'))
                                .onChange((isOn: boolean) => {
                                    wfc.lockPCClient(info.clientId, isOn, () => {
                                        this.lockStates[index] = isOn
                                    }, err => {
                                        showToast('设置失败 ' + err)
                                    })
                                })
                        }
                        .width('100%')
                        .height(56)
                        .padding({ left: 16, right: 16 })

                        Divider()
                            .strokeWidth(0.5)
                            .color($r('app.color.wf_divider'))
                            .margin({ left: 16 })
                    }

                    // 传文件
                    Row() {
                        Text('传文件')
                            .fontSize(FontSize.md)
                            .fontColor($r('app.color.wf_primary_text'))
                            .layoutWeight(1)
                        Text('>')
                            .fontSize(FontSize.lg)
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

                    Divider()
                        .strokeWidth(0.5)
                        .color($r('app.color.wf_divider'))
                        .margin({ left: 16 })

                    // 退出该设备登录
                    Row() {
                        Text(`退出${pcDeviceName(info)}登录`)
                            .fontSize(FontSize.md)
                            .fontColor(0xFA5151)
                    }
                    .width('100%')
                    .height(52)
                    .justifyContent(FlexAlign.Center)
                    .onClick(() => this.kickoffDevice(info))
                }
                .width('100%')
            }
        }
        .width('100%')
        .backgroundColor($r('app.color.wf_background'))
        .borderRadius(Radius.md)
        .clip(true)
    }
}
