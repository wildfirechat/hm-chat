/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 *
 * 网盘首页：列出可见空间（全局公共 + 自己的），点击进入文件列表。
 */

import { uikitNavigationDestinations } from '../pages/uikitNavigationConfig';
import { pushOrReplaceDetail } from '../util/navUtil';
import { PanEmptyView } from './panWidgets';
import PanService from './panService';
import { PanSpace, PanSpaceType } from './panModels';
import { FontSize, Radius } from '../common/design/Tokens';

@Component
export default struct PanHomePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State spaces: PanSpace[] = [];
    @State loading: boolean = true;
    @State error: string = '';

    aboutToAppear() {
        this.load();
    }

    load() {
        this.loading = true;
        this.error = '';
        PanService.getVisibleSpaces()
            .then((spaces: PanSpace[]) => {
                this.spaces = spaces;
                this.loading = false;
            })
            .catch((e: Error) => {
                this.loading = false;
                this.error = e.message || '加载失败';
            });
    }

    spaceTypeLabel(space: PanSpace): string {
        if (space.spaceType === PanSpaceType.USER_PRIVATE) {
            return '个人空间';
        }
        if (space.spaceType === PanSpaceType.USER_PUBLIC) {
            return '公共空间';
        }
        return '全局公共';
    }

    quotaText(space: PanSpace): string {
        if (space.totalQuota <= 0) {
            return '';
        }
        return `${PanService.formatSize(space.usedQuota)} / ${PanService.formatSize(space.totalQuota)}`;
    }

    openSpace(space: PanSpace) {
        pushOrReplaceDetail(this.mainNavPathStack, uikitNavigationDestinations.PanFileListPage, {
            'space': space
        } as Record<string, Object>);
    }

    build() {
        NavDestination() {
            if (this.loading) {
                Column() {
                    LoadingProgress().width(40).height(40)
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
            } else if (this.error) {
                PanEmptyView({ message: this.error, showRetry: true, onRetry: () => { this.load(); } })
                    .height('100%')
            } else if (this.spaces.length === 0) {
                PanEmptyView({ message: '暂无可用空间' })
                    .height('100%')
            } else {
                List() {
                    ForEach(this.spaces, (space: PanSpace) => {
                        ListItem() {
                            Row({ space: 16 }) {
                                Image($r('app.media.ic_pan_drive'))
                                    .width(40)
                                    .height(40)
                                Column({ space: 4 }) {
                                    Text(space.name)
                                        .fontSize(FontSize.md)
                                        .fontColor($r('app.color.wf_primary_text'))
                                        .maxLines(1)
                                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                                    Text(this.quotaText(space) ? this.quotaText(space) : this.spaceTypeLabel(space))
                                        .fontSize(FontSize.sm)
                                        .fontColor($r('app.color.wf_tertiary_text'))
                                        .maxLines(1)
                                }
                                .layoutWeight(1)
                                .alignItems(HorizontalAlign.Start)

                                Image($r('app.media.ic_public_arrow_right'))
                                    .width(20)
                                    .height(20)
                            }
                            .width('100%')
                            .height(68)
                            .padding({ left: 16, right: 16 })
                            .backgroundColor($r('app.color.wf_background'))
                        }
                        .onClick(() => {
                            this.openSpace(space);
                        })
                    }, (space: PanSpace) => `${space.spaceId}`)
                }
                .width('100%')
                .height('100%')
                .divider({ strokeWidth: 0.5, color: $r('app.color.wf_divider') })
                .backgroundColor($r('app.color.wf_primary_background_color'))
            }
        }
        .title('网盘')
        .hideBackButton(false)
        .backgroundColor($r('app.color.wf_primary_background_color'))
        .menus(this.MenuBuilder())
    }

    @Builder
    MenuBuilder() {
        Row() {
            Image($r('app.media.refreshing'))
                .width(22)
                .height(22)
                .margin({ right: 16 })
                .onClick(() => {
                    this.load();
                })
        }
    }
}
