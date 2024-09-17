import appServer from '../../api/appServer'
import BasicDataSource from '../../common/BasicDataSource'
import wfc from '../../wfc/client/wfc'
import Message from '../../wfc/messages/message'
import MessageContentType from '../../wfc/messages/messageContentType'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import FavItem from '../../wfc/model/favItem'
import { JSONObject } from '../../wfc/type/types'
import { _reverseToJsLongString } from '../../wfc/util/longUtil'
import { navigationDestinations } from '../navigationConfig'
import { LengthUnit } from '@kit.ArkUI'
import CompositeMessageContent from '../../wfc/messages/compositeMessageContent'
import { getFiletypeIcon, humanSize, timeFormat } from '../../util/helper'
import VideoMessageContent from '../../wfc/messages/videoMessageContent'
import Config from '../../config'
import FileMessageContent from '../../wfc/messages/fileMessageContent'

@Entry
@Component
export default struct FavRecordPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private favListDataSource: FavListDataSource = new FavListDataSource()
    private isLoading: boolean = false

    aboutToAppear() {
        this.loadFavList(0)
    }

    loadFavList(startId: number) {
        appServer.getFavList(startId, 20)
            .then(respData => {
                let respStr = respData as string
                let data = _reverseToJsLongString(respStr, 'messageUid')
                let obj = JSON.parse(data) as JSONObject
                let favItems = ((obj['result'] as JSONObject)['items']) as FavItem[]
                if (favItems.length > 0) {
                    this.favListDataSource.appendFavList(favItems)
                }
            })
    }

    compositeMessageText(favItem: FavItem) {
        let content = FavItem.toMessage(favItem).messageContent as CompositeMessageContent
        let text = ''
        for (let i = 0; i < content.messages.length && i < 2; i++) {
            let msg = content.messages[i]
            text += '\n'
            text += msg.messageContent.digest(msg)
        }
        return text
    }

    videoThumbnail(favItem: FavItem) {
        let msg = FavItem.toMessage(favItem)
        let content = msg.messageContent as VideoMessageContent
        if (content.thumbnail) {
            return 'data:image/jpeg;base64,' + content.thumbnail
        }
        return Config.DEFAULT_THUMBNAIL_URL
    }

    fileSize(favItem: FavItem) {
        let msg = FavItem.toMessage(favItem)
        let content = msg.messageContent as FileMessageContent
        return content.size
    }

    build() {
        NavDestination() {
            List() {
                LazyForEach(this.favListDataSource, (favItem: FavItem) => {
                    ListItem() {
                        Column() {
                            if (favItem.type === MessageContentType.File) {
                                Row() {
                                    Image(getFiletypeIcon(favItem.title))
                                        .width(50)
                                        .height(50)
                                        .margin({ right: 10 })
                                    Column() {
                                        Text(favItem.title)
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                            .fontSize(16)
                                            .maxLines(1)
                                        Text(humanSize(this.fileSize(favItem)))
                                            .fontSize(14)
                                            .maxLines(1)
                                    }
                                    .padding({ right: 10 })
                                    .justifyContent(FlexAlign.SpaceBetween)
                                    .alignItems(HorizontalAlign.Start)
                                }
                            } else if (favItem.type === MessageContentType.Video) {
                                Image(this.videoThumbnail(favItem))
                                    .width(200)
                                    .height(200)
                            } else if (favItem.type === MessageContentType.Image) {
                                Image(favItem.url)
                                    .width(200)
                                    .height(200)
                            } else if (favItem.type === MessageContentType.Composite_Message) {
                                Text(favItem.title)
                                    .fontSize(15)
                                Text(this.compositeMessageText(favItem))
                                    .lineSpacing({ value: 4, unit: LengthUnit.VP })
                                    .fontSize(15)
                                    .fontColor('#252525')
                                    .maxLines(5)
                                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                            } else {
                                Text(favItem.title)
                                    .lineSpacing({ value: 4, unit: LengthUnit.VP })
                                    .fontSize(15)
                                    .fontColor('#252525')
                                    .maxLines(6)
                                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                            }
                            Row() {

                                Text(favItem.origin)
                                    .fontSize(12)
                                    .fontColor('#b2b2b2')

                                Text(timeFormat(favItem.timestamp))
                                    .margin({ left: 10 })
                                    .fontSize(12)
                                    .fontColor('#b2b2b2')
                            }
                            .margin({ top: 10 })
                        }
                        .padding(10)
                        .alignItems(HorizontalAlign.Start)
                    }
                    .key(favItem.id + '')
                }, (favItem: FavItem) => favItem.id + '')
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            .divider({
                strokeWidth: 1,
                startMargin: 10,
                endMargin: 10

            })
            .onScrollIndex((start, end) => {
                if (end === this.favListDataSource.totalCount() - 1 && !this.isLoading) {
                    this.loadFavList(this.favListDataSource.getData(this.favListDataSource.totalCount() - 1).id)
                }
            })

        }
        .title('我的收藏')
        .height('100%')
        .width('100%')
    }
}

class FavListDataSource extends BasicDataSource<FavItem> {
    private favList: FavItem[] = []

    setFavList(favList: FavItem[]): void {
        this.favList = favList
        this.notifyDataReload()
    }

    appendFavList(favList: FavItem[]) {
        this.favList = this.favList.concat(favList)
        this.notifyDataReload()
    }

    getFavList() {
        return this.favList;
    }

    public totalCount(): number {
        return this.favList.length
    }

    public getData(index: number): FavItem {
        return this.favList[index]
    }
}
