/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import PollMessageContent from '@wfc/client/src/main/ets/wfc/messages/pollMessageContent';
import { uikitNavigationDestinations } from '../../uikitNavigationConfig';

@Component
export default struct PollMessageContentView {
    @Link message: Message;
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    private pollContent(): PollMessageContent {
        return this.message.messageContent as PollMessageContent;
    }

    private getStatusText(): string {
        let content = this.pollContent();
        let statusText = '';
        if (content.endTime > 0 && content.endTime < this.message.timestamp) {
            statusText = '已结束';
        } else if (content.status === 1) {
            statusText = '已结束';
        } else {
            statusText = '进行中';
        }
        return statusText;
    }

    private getTypeText(): string {
        return this.pollContent().anonymous === 1 ? '匿名投票' : '实名投票';
    }

    private handleClick(): void {
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.PollDetailPage, {
            'pollId': parseInt(this.pollContent().pollId) || 0,
            'groupId': this.pollContent().groupId,
            'message': this.message
        } as Record<string, Object>);
    }

    build() {
        Column() {
            // 标题
            Text('🗳️ ' + this.pollContent().title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.wf_primary_text'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')

            // 描述
            if (this.pollContent().desc) {
                Text(this.pollContent().desc)
                    .fontSize(14)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .margin({ top: 8 })
            }

            // 分隔线
            Divider()
                .strokeWidth(0.5)
                .color($r('app.color.wf_divider'))
                .margin({ top: 12, bottom: 8 })
                .width('100%')

            // 状态信息
            Row() {
                Text(this.getStatusText() + ' · ' + this.getTypeText())
                    .fontSize(12)
                    .fontColor($r('app.color.wf_tertiary_text'))

                Text('点击参与')
                    .fontSize(12)
                    .fontColor($r('app.color.wf_primary'))
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
