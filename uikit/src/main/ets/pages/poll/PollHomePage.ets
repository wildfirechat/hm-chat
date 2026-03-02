/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import { uikitNavigationDestinations } from '../uikitNavigationConfig';

@Component
export default struct PollHomePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private groupId: string = '';

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByName(uikitNavigationDestinations.PollHomePage) as Record<string, Object>[];
        if (params && params.length > 0) {
            this.groupId = params[0]['groupId'] as string || '';
        }
    }

    build() {
        NavDestination() {
            List() {
                // 发起投票
                ListItem() {
                    Row({ space: 16 }) {
                        Image($rawfile('ic_poll_create.svg'))
                            .width(40)
                            .height(40)
                            .borderRadius(8)

                        Text('发起投票')
                            .fontSize(16)
                            .fontColor('#333333')
                            .layoutWeight(1)

                        Image($r('app.media.ic_public_arrow_right'))
                            .width(20)
                            .height(20)
                    }
                    .width('100%')
                    .height(64)
                    .padding({ left: 16, right: 16 })
                    .backgroundColor(Color.White)
                }
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.CreatePollPage, {
                        'groupId': this.groupId
                    } as Record<string, Object>);
                })

                // 我的投票
                ListItem() {
                    Row({ space: 16 }) {
                        Image($rawfile('ic_poll_list.svg'))
                            .width(40)
                            .height(40)
                            .borderRadius(8)

                        Text('我的投票')
                            .fontSize(16)
                            .fontColor('#333333')
                            .layoutWeight(1)

                        Image($r('app.media.ic_public_arrow_right'))
                            .width(20)
                            .height(20)
                    }
                    .width('100%')
                    .height(64)
                    .padding({ left: 16, right: 16 })
                    .backgroundColor(Color.White)
                }
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PollListPage, {
                        'groupId': this.groupId
                    } as Record<string, Object>);
                })
            }
            .width('100%')
            .height('100%')
            .divider({ strokeWidth: 0.5, color: '#E5E5E5' })
            .backgroundColor('#F2F2F7')
        }
        .title('投票')
        .backgroundColor('#F2F2F7')
        .hideBackButton(false)
    }
}
