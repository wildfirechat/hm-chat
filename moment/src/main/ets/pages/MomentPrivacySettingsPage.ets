import { momentClient } from '../client/MomentClient';
import { Profile, UpdateUserProfileType, VisibleScope } from '../model/MomentModel';
import { MomentConstants } from '../utils/MomentConstants';
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast';
import { uikitNavigationDestinations } from '@wfc/uikit/src/main/ets/pages/uikitNavigationConfig';
import PickMultiContactModal from '@wfc/uikit/src/main/ets/pages/picker/PickMultiContactModal';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import wfc from '@wfc/client';
import { promptAction } from '@kit.ArkUI';
import { FontSize, Radius } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import { trustedMediaSrc } from '@wfc/uikit/src/main/ets/util/trustedMedia'

// 正在选择联系人的目标
enum PickTarget {
    None = 0,
    BlackAdd = 1,       // 不看他名单添加
    BlockAdd = 2,       // 不让他看名单添加
    DefaultPartial = 3, // 发布默认可见范围-部分可见
    DefaultExclude = 4, // 发布默认可见范围-不给谁看
}

/**
 * 朋友圈隐私设置页。
 * 不看他/不让他看名单管理、陌生人可见 10 条、朋友可见范围、发布默认可见范围。
 */
@Component
export struct MomentPrivacySettingsPage {
    @State profile: Profile | undefined = undefined;
    @State isLoading: boolean = true;
    // 陌生人可见 10 条、朋友可见范围（Profile 非 @Observed，用独立 @State 驱动刷新）
    @State strangerEnabled: boolean = false;
    @State visibleScope: VisibleScope = VisibleScope.NoLimit;
    // 名单展开状态
    @State expandBlackList: boolean = false;
    @State expandBlockList: boolean = false;
    @State blackListUsers: string[] = [];
    @State blockListUsers: string[] = [];
    // 发布默认可见范围（本地偏好）
    @State defaultScopeMode: number = 0;
    @State defaultScopeUsers: UserInfo[] = [];

    private pickTarget: PickTarget = PickTarget.None;

    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        this.loadProfile();
        let scope = momentClient.getDefaultVisibleScope();
        this.defaultScopeMode = scope.mode;
        if (scope.users.length > 0) {
            this.defaultScopeUsers = wfc.getUserInfos(scope.users);
        }
    }

    private loadProfile() {
        momentClient.getUserProfile(wfc.getUserId(), (profile: Profile) => {
            this.profile = profile;
            this.blackListUsers = profile.blackList ?? [];
            this.blockListUsers = profile.blockList ?? [];
            this.strangerEnabled = (profile.strangerVisibleCount ?? 0) > 0;
            this.visibleScope = profile.visibleScope ?? VisibleScope.NoLimit;
            this.isLoading = false;
        }, () => {
            this.isLoading = false;
        });
    }

    // ===== 名单管理 =====

    // isBlock: true 不让他看（blockList），false 不看他（blackList）
    private addListMembers(isBlock: boolean) {
        this.pickTarget = isBlock ? PickTarget.BlockAdd : PickTarget.BlackAdd;
        LocalStorage.getShared().setOrCreate<UserInfo[]>(PickMultiContactModal.PICK_RESULT, []);
        let current = isBlock ? this.blockListUsers : this.blackListUsers;
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PickMultiContactPage, {
            'initialCheckedUserIds': current
        } as Record<string, Object>);
    }

    private removeListMember(isBlock: boolean, userId: string) {
        momentClient.updateBlackOrBlockList(isBlock, [], [userId], () => {
            if (isBlock) {
                this.blockListUsers = this.blockListUsers.filter(uid => uid !== userId);
            } else {
                this.blackListUsers = this.blackListUsers.filter(uid => uid !== userId);
            }
        }, (errorCode: number) => {
            showToast(`操作失败 (${errorCode})`);
        });
    }

    // ===== 陌生人可见 10 条 =====

    private onStrangerChanged(enable: boolean) {
        this.strangerEnabled = enable;
        momentClient.updateMyProfile(UpdateUserProfileType.StrangerVisibleCount, null, enable ? 10 : 0, () => {
        }, (errorCode: number) => {
            this.strangerEnabled = !enable;
            showToast(`操作失败 (${errorCode})`);
        });
    }

    // ===== 朋友可见范围 =====

    private scopeText(scope?: VisibleScope): string {
        switch (scope) {
            case VisibleScope.ThreeDays:
                return '最近三天';
            case VisibleScope.OneMonth:
                return '最近一个月';
            case VisibleScope.SixMonths:
                return '最近半年';
            default:
                return '全部';
        }
    }

    private showVisibleScopeMenu() {
        promptAction.showActionMenu({
            title: '允许朋友查看朋友圈的范围',
            buttons: [
                { text: '全部', color: $r('app.color.text_primary') },
                { text: '最近三天', color: $r('app.color.text_primary') },
                { text: '最近一个月', color: $r('app.color.text_primary') },
                { text: '最近半年', color: $r('app.color.text_primary') },
            ]
        }).then(result => {
            if (result.index < 0 || result.index > 3) return;
            let scope = result.index as VisibleScope;
            momentClient.updateMyProfile(UpdateUserProfileType.VisibleScope, null, scope, () => {
                this.visibleScope = scope;
            }, (errorCode: number) => {
                showToast(`操作失败 (${errorCode})`);
            });
        }).catch(() => {});
    }

    // ===== 发布默认可见范围 =====

    private defaultScopeLabel(): string {
        switch (this.defaultScopeMode) {
            case 1:
                return '私密';
            case 2:
                return this.defaultScopeUsers.length > 0 ? `部分可见(${this.defaultScopeUsers.length})` : '部分可见';
            case 3:
                return this.defaultScopeUsers.length > 0 ? `不给谁看(${this.defaultScopeUsers.length})` : '不给谁看';
            default:
                return '公开';
        }
    }

    private showDefaultScopeMenu() {
        promptAction.showActionMenu({
            title: '发布默认可见范围',
            buttons: [
                { text: '公开', color: $r('app.color.text_primary') },
                { text: '私密', color: $r('app.color.text_primary') },
                { text: '部分可见', color: $r('app.color.text_primary') },
                { text: '不给谁看', color: $r('app.color.text_primary') },
            ]
        }).then(result => {
            switch (result.index) {
                case 0:
                    this.saveDefaultScope(0, []);
                    break;
                case 1:
                    this.saveDefaultScope(1, []);
                    break;
                case 2:
                    this.pickTarget = PickTarget.DefaultPartial;
                    this.openDefaultScopePicker();
                    break;
                case 3:
                    this.pickTarget = PickTarget.DefaultExclude;
                    this.openDefaultScopePicker();
                    break;
            }
        }).catch(() => {});
    }

    private openDefaultScopePicker() {
        LocalStorage.getShared().setOrCreate<UserInfo[]>(PickMultiContactModal.PICK_RESULT, []);
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PickMultiContactPage, {
            'initialCheckedUserIds': this.defaultScopeUsers.map(u => u.uid)
        } as Record<string, Object>);
    }

    private saveDefaultScope(mode: number, users: UserInfo[]) {
        this.defaultScopeMode = mode;
        this.defaultScopeUsers = users;
        momentClient.setDefaultVisibleScope(mode, users.map(u => u.uid));
    }

    // 从联系人选择页返回时读取结果
    private consumePickResult(): void {
        if (this.pickTarget === PickTarget.None) return;
        const result = LocalStorage.getShared().get<UserInfo[]>(PickMultiContactModal.PICK_RESULT);
        const target = this.pickTarget;
        this.pickTarget = PickTarget.None;
        if (!result || result.length === 0) {
            return;
        }
        LocalStorage.getShared().setOrCreate<UserInfo[]>(PickMultiContactModal.PICK_RESULT, []);
        if (target === PickTarget.BlackAdd || target === PickTarget.BlockAdd) {
            let isBlock = target === PickTarget.BlockAdd;
            let current = isBlock ? this.blockListUsers : this.blackListUsers;
            let addList = result.map(u => u.uid).filter(uid => current.indexOf(uid) < 0);
            if (addList.length === 0) {
                return;
            }
            momentClient.updateBlackOrBlockList(isBlock, addList, [], () => {
                if (isBlock) {
                    this.blockListUsers = [...this.blockListUsers, ...addList];
                } else {
                    this.blackListUsers = [...this.blackListUsers, ...addList];
                }
            }, (errorCode: number) => {
                showToast(`操作失败 (${errorCode})`);
            });
        } else if (target === PickTarget.DefaultPartial) {
            this.saveDefaultScope(2, result);
        } else if (target === PickTarget.DefaultExclude) {
            this.saveDefaultScope(3, result);
        }
    }

    build() {
        NavDestination() {
            Column() {
                if (this.isLoading) {
                    Column() {
                        LoadingProgress()
                            .width(32)
                            .height(32)
                            .color(MomentConstants.PRIMARY_COLOR)
                    }
                    .width('100%')
                    .layoutWeight(1)
                    .justifyContent(FlexAlign.Center)
                } else {
                    Scroll() {
                        Column({ space: 12 }) {
                            // 名单管理
                            Column() {
                                this.buildListRow('不看他(她)', false)
                                Divider().color(MomentConstants.DIVIDER_COLOR).strokeWidth(0.5)
                                this.buildListRow('不让他(她)看', true)
                            }
                            .width('100%')
                            .borderRadius(MomentConstants.BORDER_RADIUS)
                            .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)

                            Column() {
                                // 陌生人可见 10 条
                                Row() {
                                    Text('允许陌生人查看十条朋友圈')
                                        .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                                        .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                                        .layoutWeight(1)

                                    Toggle({ type: ToggleType.Switch, isOn: $$this.strangerEnabled })
                                        .selectedColor(MomentConstants.PRIMARY_COLOR)
                                        .onChange((isOn: boolean) => this.onStrangerChanged(isOn))
                                }
                                .width('100%')
                                .height(52)
                                .padding({ left: 16, right: 16 })
                                .alignItems(VerticalAlign.Center)

                                Divider().color(MomentConstants.DIVIDER_COLOR).strokeWidth(0.5)

                                // 朋友可见范围
                                this.buildOptionRow('允许朋友查看朋友圈的范围',
                                    this.scopeText(this.visibleScope),
                                    (): void => this.showVisibleScopeMenu())

                                Divider().color(MomentConstants.DIVIDER_COLOR).strokeWidth(0.5)

                                // 发布默认可见范围
                                this.buildOptionRow('发布默认可见范围',
                                    this.defaultScopeLabel(),
                                    (): void => this.showDefaultScopeMenu())
                            }
                            .width('100%')
                            .borderRadius(MomentConstants.BORDER_RADIUS)
                            .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
                        }
                        .width('100%')
                        .padding({ left: 12, right: 12, top: 12 })
                    }
                    .layoutWeight(1)
                    .scrollBar(BarState.Off)
                    .align(Alignment.Top)
                }
            }
            .width('100%')
            .height('100%')
        }
        .title('朋友圈权限')
        .backgroundColor(MomentConstants.BACKGROUND_COLOR)
        .onShown(() => this.consumePickResult())
    }

    // 名单行：点击展开/收起名单列表
    @Builder
    private buildListRow(title: string, isBlock: boolean) {
        Column() {
            Row() {
                Text(title)
                    .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                    .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                    .layoutWeight(1)

                Text(`${(isBlock ? this.blockListUsers : this.blackListUsers).length}人`)
                    .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                    .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                    .margin({ right: 8 })

                SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(FontSize.sm)
                    .fontColor([MomentConstants.TEXT_SECONDARY_COLOR])
                    .rotate({ angle: (isBlock ? this.expandBlockList : this.expandBlackList) ? 90 : 0 })
            }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
                if (isBlock) {
                    this.expandBlockList = !this.expandBlockList;
                } else {
                    this.expandBlackList = !this.expandBlackList;
                }
            })

            if (isBlock ? this.expandBlockList : this.expandBlackList) {
                if ((isBlock ? this.blockListUsers : this.blackListUsers).length === 0) {
                    Text('暂无成员')
                        .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                        .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                        .width('100%')
                        .padding({ left: 16, top: 8, bottom: 8 })
                } else {
                    ForEach(isBlock ? this.blockListUsers : this.blackListUsers, (userId: string) => {
                        Row({ space: 10 }) {
                            Image(trustedMediaSrc(wfc.getUserInfo(userId).portrait) || $r('app.media.icon'))
                                .width(36)
                                .height(36)
                                .borderRadius(MomentConstants.BORDER_RADIUS)
                                .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)

                            Text(wfc.getUserInfo(userId).displayName)
                                .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                                .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                                .layoutWeight(1)
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })

                            Text('移除')
                                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                                .fontColor($r('app.color.like_active'))
                                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                                .onClick(() => this.removeListMember(isBlock, userId))
                        }
                        .width('100%')
                        .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                        .alignItems(VerticalAlign.Center)
                    }, (userId: string) => userId)
                }

                // 添加成员
                Row({ space: 6 }) {
                    SymbolGlyph($r('sys.symbol.plus'))
                        .fontSize(FontSize.md)
                        .fontColor([MomentConstants.LINK_COLOR])
                    Text('添加')
                        .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                        .fontColor(MomentConstants.LINK_COLOR)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 10, bottom: 12 })
                .onClick(() => this.addListMembers(isBlock))
            }
        }
        .width('100%')
    }

    @Builder
    private buildOptionRow(title: string, value: string, action: () => void) {
        Row() {
            Text(title)
                .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                .layoutWeight(1)

            Text(value)
                .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: '50%' })
                .margin({ right: 8 })

            SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(FontSize.sm)
                .fontColor([MomentConstants.TEXT_SECONDARY_COLOR])
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .onClick(action)
    }
}
