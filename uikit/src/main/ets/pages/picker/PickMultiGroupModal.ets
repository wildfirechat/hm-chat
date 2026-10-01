/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 多选群（文档分享用）：从已保存到通讯录的群里多选。
 */

import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { FontSize, Radius } from '../../common/design/Tokens'

@Component
export default struct PickMultiGroupModal {
    @State favGroupList: GroupInfo[] = []
    @State checkedTargets: string[] = []
    public static PICK_RESULT: string = 'pickGroupResult'
    @Link showPickGroupModal: boolean

    aboutToAppear() {
        this.favGroupList = wfc.getFavGroupList()
        wfc.eventEmitter?.on(EventType.GroupInfosUpdate, this.onGroupUpdateListener)
    }

    aboutToDisappear(): void {
        wfc.eventEmitter?.off(EventType.GroupInfosUpdate, this.onGroupUpdateListener)
    }

    onGroupUpdateListener = () => {
        this.favGroupList = wfc.getFavGroupList()
    }

    checkedGroups(): GroupInfo[] {
        return this.favGroupList.filter((g: GroupInfo) => this.checkedTargets.includes(g.target))
    }

    build() {
        Navigation() {
            List() {
                ForEach(this.favGroupList, (groupInfo: GroupInfo) => {
                    ListItem() {
                        Row() {
                            Image(groupInfo.portrait)
                                .alt($r('app.media.ic_group_chat'))
                                .width(40)
                                .height(40)
                                .borderRadius(Radius.sm)
                            Text(groupInfo.name)
                                .layoutWeight(1)
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .padding({ left: 12, right: 12 })
                            Checkbox({ name: groupInfo.target, group: 'pan-pick-group' })
                                .select(this.checkedTargets.includes(groupInfo.target))
                                .onChange((checked: boolean) => {
                                    if (checked) {
                                        if (!this.checkedTargets.includes(groupInfo.target)) {
                                            this.checkedTargets.push(groupInfo.target)
                                        }
                                    } else {
                                        this.checkedTargets = this.checkedTargets.filter((t: string) => t !== groupInfo.target)
                                    }
                                })
                        }
                        .height(60)
                        .width('100%')
                        .padding({ left: 12, right: 12 })
                        .onClick(() => {
                            if (this.checkedTargets.includes(groupInfo.target)) {
                                this.checkedTargets = this.checkedTargets.filter((t: string) => t !== groupInfo.target)
                            } else {
                                this.checkedTargets.push(groupInfo.target)
                            }
                        })
                    }
                }, (groupInfo: GroupInfo) => groupInfo.target + groupInfo.updateDt)
            }
            .width('100%')
            .height('100%')
            .divider({ strokeWidth: 1, startMargin: 60 })
        }
        .title('选取群组')
        .titleMode(NavigationTitleMode.Mini)
        .navBarPosition(NavBarPosition.Start)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .mode(NavigationMode.Stack)
        .menus(this.NavigationMenus())
    }

    @Builder
    NavigationMenus() {
        Row() {
            Button('确定')
                .type(ButtonType.Normal)
                .height(32)
                .margin({ right: 20 })
                .enabled(this.checkedTargets.length > 0)
                .fontSize(FontSize.sm)
                .borderRadius(Radius.sm)
                .onClick(() => {
                    LocalStorage.getShared()
                        .setOrCreate<GroupInfo[]>(PickMultiGroupModal.PICK_RESULT, this.checkedGroups())
                    this.showPickGroupModal = false
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
}
