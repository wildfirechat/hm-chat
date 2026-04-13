import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import { uikitNavigationDestinations } from '../../uikitNavigationConfig';
import CollectionMessageContent from '@wfc/client/src/main/ets/wfc/messages/CollectionMessageContent';
import Collection from '@wfc/client/src/main/ets/wfc/model/collection';
import CollectionEntry from '@wfc/client/src/main/ets/wfc/model/collectionEntry';

@Component
export default struct CollectionMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message;

    collectionMessageContent(): CollectionMessageContent {
        return this.message.messageContent as CollectionMessageContent;
    }

    build() {
        Column() {
            // Title Area: Icon + Title + Count
            Row() {
                Image($r('app.media.ic_func_collection'))
                    .width(18)
                    .height(18)
                    .fillColor($r('app.color.wf_link'))
                    .margin({ right: 6 })

                Text(this.collectionMessageContent().title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.wf_primary_text'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)

                Text(`${this.collectionMessageContent().entries ? this.collectionMessageContent().entries.length : 0}人参与`)
                    .fontSize(12)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .margin({ left: 4 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // Description
            if (this.collectionMessageContent().desc) {
                Text(this.collectionMessageContent().desc)
                    .fontSize(13)
                    .fontColor($r('app.color.wf_tertiary_text'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 })
                    .width('100%')
            }

            // Divider
            Divider()
                .color($r('app.color.wf_divider'))
                .strokeWidth(0.5)
                .margin({ top: 8, bottom: 8 })

            // Entries Preview
            Column() {
                if (this.collectionMessageContent().entries && this.collectionMessageContent().entries.length > 0) {
                    ForEach(this.collectionMessageContent().entries.slice(0, 3), (entry: CollectionEntry, index: number) => {
                         Text(`${index + 1}. ${entry.content}`)
                            .fontSize(14)
                            .fontColor($r('app.color.wf_tertiary_text'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .margin({ top: 2 })
                            .width('100%')
                    })
                    if (this.collectionMessageContent().entries.length > 3) {
                         Text('...')
                            .fontSize(12)
                            .fontColor($r('app.color.wf_tertiary_text'))
                            .margin({ top: 4 })
                    }
                } else {
                    Text('暂无参与，快来抢沙发吧~')
                        .fontSize(13)
                        .fontColor($r('app.color.wf_tertiary_text'))
                }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // Divider
            Divider()
                .color($r('app.color.wf_divider'))
                .strokeWidth(0.5)
                .margin({ top: 8, bottom: 8 })

            // Action Button
            Row() {
                Text(this.collectionMessageContent().status === 0 ? '参与接龙' : '已结束')
                    .fontSize(14)
                    .fontColor(this.collectionMessageContent().status === 0 ? $r('app.color.wf_link') : $r('app.color.wf_tertiary_text'))
            }
            .width('100%')
        }
        .width(240)
        .padding(12)
        .backgroundColor(this.message.direction === 0 ? $r('app.color.wf_sent_bubble_bg') : $r('app.color.wf_received_bubble_bg'))
        .borderRadius(8)
        .onClick(() => {
            let collectionId = parseInt(this.collectionMessageContent().collectionId);
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.CollectionDetailPage, {
                'collectionId': collectionId,
                'groupId': this.collectionMessageContent().groupId
            } as Record<string, Object>)
        })
    }
}
