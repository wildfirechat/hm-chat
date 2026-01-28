import appServer from '../../api/appServer'
import BasicDataSource from '../../common/BasicDataSource'
import MessageContentType from '@wfc/client/src/main/ets/wfc/messages/messageContentType'
import FavItem from '@wfc/client/src/main/ets/wfc/model/favItem'
import { JSONObject } from '@wfc/client/src/main/ets/wfc/type/types'
import { _reverseToJsLongString } from '@wfc/client/src/main/ets/wfc/util/longUtil'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'
import { LengthUnit } from '@kit.ArkUI'
import CompositeMessageContent from '@wfc/client/src/main/ets/wfc/messages/compositeMessageContent'
import { getFiletypeIcon, humanSize, timeFormat } from '../../util/helper'
import VideoMessageContent from '@wfc/client/src/main/ets/wfc/messages/videoMessageContent'
import Config from '@wfc/client/src/main/ets/config'
import FileMessageContent from '@wfc/client/src/main/ets/wfc/messages/fileMessageContent'
import { showToast } from '../../common/utils/Toast'
import { MMMediaEntry } from '../../common/Types'
import { mediaEntry } from '../../helper/messageHelper'
import MMMessagePreviewDialog from '../mm/MMMessagePreviewDialog'
import { downloadMedia } from '../../helper/mediaHelper'
import { filePreview } from '@kit.PreviewKit'
import { fileUri } from '@kit.CoreFileKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import LinkMessageContent from '@wfc/client/src/main/ets/wfc/messages/linkMessageContent'
import CardMessageContent from '@wfc/client/src/main/ets/wfc/messages/cardMessageContent'
import ArticlesMessageContent from '@wfc/client/src/main/ets/wfc/messages/articlesMessageContent'
import ConferenceInviteMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/conferenceInviteMessageContent'
import LocationMessageContent from '@wfc/client/src/main/ets/wfc/messages/locationMessageContent'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import SoundMessageContent from '@wfc/client/src/main/ets/wfc/messages/soundMessageContent'
import AudioPlayManager from '../conversation/audio/AudioPlayManager'

@Component
export default struct FavRecordPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State noFavItems: boolean = false
    @State favItemLoaded: boolean = false
    @State playingVoiceId: string = ''
    private favListDataSource: FavListDataSource = new FavListDataSource()
    private isLoading: boolean = false
    private mmPreviewDialogController?: CustomDialogController
    private audioPlayManager: AudioPlayManager = new AudioPlayManager()

    aboutToAppear() {
        this.audioPlayManager.init(getContext(this))
        this.loadFavList(0)
    }

    aboutToDisappear() {
        this.audioPlayManager.release()
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
                if (this.favListDataSource.totalCount() === 0) {
                    this.noFavItems = true
                }
                this.favItemLoaded = true
            })
    }

    compositeMessageText(favItem: FavItem) {
        let msg = FavItem.toMessage(favItem)
        let content = msg.messageContent as CompositeMessageContent
        if (!content || !content.messages) {
            return ''
        }
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
        if (!content) {
            return Config.DEFAULT_THUMBNAIL_URL
        }
        if (content.thumbnail) {
            return 'data:image/jpeg;base64,' + content.thumbnail
        }
        return Config.DEFAULT_THUMBNAIL_URL
    }

    fileSize(favItem: FavItem) {
        let msg = FavItem.toMessage(favItem)
        let content = msg.messageContent as FileMessageContent
        if (!content) {
            return 0
        }
        return content.size
    }

    voiceDuration(favItem: FavItem) {
        let msg = FavItem.toMessage(favItem)
        let content = msg.messageContent as SoundMessageContent
        if (!content) {
            return 0
        }
        return content.duration
    }

    previewMessage(favItem: FavItem) {
        let msg = FavItem.toMessage(favItem)
        let content = msg.messageContent
        if (!content) {
            showToast('消息内容不存在')
            return
        }
        if (content.type === MessageContentType.Text) {
            // 文本消息
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.TextMessagePreviewPage, {
                'message': msg
            } as Record<string, object>)
        } else if ([MessageContentType.Video, MessageContentType.Image].indexOf(content.type) >= 0) {
            // 图片/视频消息：打开预览对话框
            this.mmPreviewDialogController = new CustomDialogController({
                builder: MMMessagePreviewDialog({
                    message: msg,
                    index: 0,
                    mediaEntries: [],
                    controller: this.mmPreviewDialogController,
                }),
                alignment: DialogAlignment.TopStart,
                autoCancel: false,
                customStyle: true,
            })
            this.mmPreviewDialogController.open()
        } else if (content.type === MessageContentType.File) {
            // 文件消息：下载并预览
            let context = getContext(this)
            let fileContent = content as FileMessageContent
            downloadMedia(context, msg.messageUid, fileContent.remotePath)
                .then(async filePath => {
                    let canPreview = await filePreview.canPreview(context, fileUri.getUriFromPath(filePath))
                    if (canPreview) {
                        let title = fileContent.name
                        let uri = fileUri.getUriFromPath(filePath)
                        let typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(filePath.substring(filePath.lastIndexOf('.')));
                        let typeObj = uniformTypeDescriptor.getTypeDescriptor(typeId);
                        let mimeTypes = typeObj.mimeTypes;
                        filePreview.openPreview(context, {
                            title: title,
                            uri: uri,
                            mimeType: mimeTypes[0],
                        })
                    }
                })
                .catch((err: Error) => {
                    showToast('文件预览失败')
                })
        } else if (content.type === MessageContentType.Voice) {
            // 语音消息：播放语音
            let voiceContent = content as SoundMessageContent
            let voiceId = msg.messageUid ? msg.messageUid.toString() : ('fav_' + favItem.id)

            if (this.playingVoiceId === voiceId && this.audioPlayManager.state() === 'playing') {
                // 正在播放，暂停
                this.audioPlayManager.pause()
                this.playingVoiceId = ''
            } else {
                // 开始播放
                this.playingVoiceId = voiceId
                let url: string = voiceContent.remotePath
                if (msg.direction === 1) {
                    url = Config.AMR_TO_MP3_SERVER_ADDRESS + voiceContent.remotePath
                }
                this.audioPlayManager.play(url, true, (err?: Error) => {
                    this.playingVoiceId = ''
                })
            }
        } else if (content.type === MessageContentType.Link) {
            // 链接消息：打开网页
            let linkContent = content as LinkMessageContent
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                'url': linkContent.url,
                'title': linkContent.title
            } as Record<string, Object>)
        } else if (content.type === MessageContentType.UserCard) {
            // 名片消息：跳转到用户信息页面
            let cardContent = content as CardMessageContent
            if (cardContent.cardType === 0) {
                // 个人名片
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                    'userInfo': wfc.getUserInfo(cardContent.target)
                } as Record<string, Object>)
            } else {
                showToast('暂不支持此类型名片')
            }
        } else if (content.type === MessageContentType.Articles) {
            // 图文消息：打开文章
            let articlesContent = content as ArticlesMessageContent
            if (articlesContent.topArticle) {
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                    'url': articlesContent.topArticle.url,
                    'title': articlesContent.topArticle.title
                } as Record<string, Object>)
            }
        } else if (content.type === MessageContentType.CONFERENCE_CONTENT_TYPE_INVITE) {
            // 会议邀请消息：跳转到会议信息页面
            let conferenceContent = content as ConferenceInviteMessageContent
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConferenceInfoPage, {
                'conferenceId': conferenceContent.callId,
                'password': conferenceContent.password
            } as Record<string, string>)
        } else if (content.type === MessageContentType.Location) {
            // 位置消息：暂不支持
            showToast('位置消息请在原会话中查看')
        } else if (content.type === MessageContentType.Sticker) {
            // 表情消息：暂不支持
            showToast('表情消息请在原会话中查看')
        } else if ([MessageContentType.Streaming_Text_Generating, MessageContentType.Streaming_Text_Generated].indexOf(content.type) >= 0) {
            // 流式文本消息：当作文本处理
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.TextMessagePreviewPage, {
                'message': msg
            } as Record<string, object>)
        } else if (content.type === MessageContentType.Composite_Message) {
            // 合并消息：跳转到合并消息预览页面
            this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.CompositeMessagePreviewPage, {
                'message': msg
            } as Record<string, object>)
        } else {
            // 其他类型：暂不支持
            showToast('暂不支持预览此类型消息')
        }
    }

    build() {
        NavDestination() {
            if (!this.favItemLoaded) {
                Text('正在加载...')
            } else if (this.noFavItems) {
                Text('暂无收藏')
            } else {
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
                                } else if (favItem.type === MessageContentType.Voice) {
                                    Row() {
                                        Image($r('app.media.ic_file_type_audio'))
                                            .width(30)
                                            .height(30)
                                            .margin({ right: 10 })
                                        Text(this.voiceDuration(favItem) + '"')
                                            .fontSize(16)
                                        if (favItem.messageUid && this.playingVoiceId === favItem.messageUid.toString()) {
                                            Text('播放中...')
                                                .fontSize(12)
                                                .fontColor('#4CAF50')
                                                .margin({ left: 10 })
                                        }
                                        Image($r('app.media.ic_public_arrow_right'))
                                            .width(16)
                                            .height(16)
                                            .margin({ left: 'auto' })
                                    }
                                    .width('100%')
                                    .padding(10)
                                } else if (favItem.type === MessageContentType.Composite_Message) {
                                    Text(favItem.title)
                                        .fontSize(15)
                                    Text(this.compositeMessageText(favItem))
                                        .lineSpacing({ value: 4, unit: LengthUnit.VP })
                                        .fontSize(15)
                                        .fontColor('#252525')
                                        .maxLines(5)
                                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                                } else if (favItem.type === MessageContentType.Link) {
                                    Row() {
                                        Column() {
                                            Text(favItem.title)
                                                .constraintSize({ maxWidth: 150 })
                                                .maxLines(1)
                                                .fontSize(16)
                                        }
                                        .padding(10)
                                        if (favItem.url) {
                                            Image(favItem.url)
                                                .width(60)
                                                .height(60)
                                                .objectFit(ImageFit.Cover)
                                                .borderRadius(4)
                                        }
                                    }
                                    .backgroundColor(Color.White)
                                    .borderRadius(4)
                                } else if (favItem.type === MessageContentType.UserCard) {
                                    Row() {
                                        Image($r('app.media.ic_user_card'))
                                            .width(40)
                                            .height(40)
                                            .margin({ right: 10 })
                                        Column() {
                                            Text(favItem.title)
                                                .fontSize(16)
                                            Text('个人名片')
                                                .fontSize(12)
                                                .fontColor('#999999')
                                                .margin({ top: 4 })
                                        }
                                        .alignItems(HorizontalAlign.Start)
                                        Image($r('app.media.ic_public_arrow_right'))
                                            .width(16)
                                            .height(16)
                                            .margin({ left: 'auto' })
                                    }
                                    .width('100%')
                                    .padding(10)
                                } else if (favItem.type === MessageContentType.Articles) {
                                    Column() {
                                        if (favItem.url) {
                                            Image(favItem.url)
                                                .width('100%')
                                                .height(120)
                                                .objectFit(ImageFit.Cover)
                                                .borderRadius(4)
                                        }
                                        Text(favItem.title)
                                            .fontSize(16)
                                            .margin({ top: 8 })
                                            .maxLines(2)
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                    }
                                    .width('100%')
                                    .padding(10)
                                    .backgroundColor('#F5F5F5')
                                    .borderRadius(4)
                                } else if (favItem.type === MessageContentType.CONFERENCE_CONTENT_TYPE_INVITE) {
                                    Row() {
                                        Image($r('app.media.ic_func_video'))
                                            .width(40)
                                            .height(40)
                                            .margin({ right: 10 })
                                        Column() {
                                            Text(favItem.title)
                                                .fontSize(16)
                                                .maxLines(1)
                                            Text('会议邀请')
                                                .fontSize(12)
                                                .fontColor('#999999')
                                                .margin({ top: 4 })
                                        }
                                        .alignItems(HorizontalAlign.Start)
                                        Image($r('app.media.ic_public_arrow_right'))
                                            .width(16)
                                            .height(16)
                                            .margin({ left: 'auto' })
                                    }
                                    .width('100%')
                                    .padding(10)
                                } else if (favItem.type === MessageContentType.Location) {
                                    Row() {
                                        Image($r('app.media.ic_func_location'))
                                            .width(30)
                                            .height(30)
                                            .margin({ right: 10 })
                                        Text('位置: ' + favItem.title)
                                            .fontSize(16)
                                        Image($r('app.media.ic_public_arrow_right'))
                                            .width(16)
                                            .height(16)
                                            .margin({ left: 'auto' })
                                    }
                                    .width('100%')
                                    .padding(10)
                                } else if (favItem.type === MessageContentType.Sticker) {
                                    Row() {
                                        Text('[表情] ' + favItem.title)
                                            .fontSize(16)
                                        Image($r('app.media.ic_public_arrow_right'))
                                            .width(16)
                                            .height(16)
                                            .margin({ left: 'auto' })
                                    }
                                    .width('100%')
                                    .padding(10)
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
                            .onClick(() => {
                                this.previewMessage(favItem)
                            })
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
