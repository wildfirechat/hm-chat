/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import PollResultMessageContent from '@wfc/client/src/main/ets/wfc/messages/pollResultMessageContent';
import { uikitNavigationDestinations } from '../../uikitNavigationConfig';

@Component
export default struct PollResultMessageContentView {
    @Link message: Message;
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    private pollResultContent(): PollResultMessageContent {
        return this.message.messageContent as PollResultMessageContent;
    }

    private get winnerText(): string {
        let content = this.pollResultContent();
        if (content.winningOptionTexts && content.winningOptionTexts.length > 0) {
            return content.winningOptionTexts.join('、');
        }
        return '';
    }

    private handleClick(): void {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PollDetailPage, {
            'pollId': parseInt(this.pollResultContent().pollId) || 0,
            'groupId': this.pollResultContent().groupId,
            'message': this.message
        } as Record<string, Object>);
    }

    build() {
        Column() {
            // 标题
            Text('📊 ' + this.pollResultContent().title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')

            // 获胜选项 - 使用条件渲染
            if (this.winnerText) {
                Text('🏆 获胜: ' + this.winnerText)
                    .fontSize(14)
                    .fontColor('#FF9500')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .margin({ top: 8 })
            }

            // 分隔线
            Divider()
                .strokeWidth(0.5)
                .color('#E5E5E5')
                .margin({ top: 12, bottom: 8 })
                .width('100%')

            // 统计信息
            Row() {
                Text(`${this.pollResultContent().voterCount}人参与投票`)
                    .fontSize(12)
                    .fontColor('#999999')

                Text('查看详情')
                    .fontSize(12)
                    .fontColor('#007AFF')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
        }
        .width(240)
        .padding(12)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)
        .onClick(() => this.handleClick())
    }
}
