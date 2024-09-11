import wfc from '../../wfc/client/wfc';
import ImageMessageContent from '../../wfc/messages/imageMessageContent';
import Message from '../../wfc/messages/message';
import MessageContentType from '../../wfc/messages/messageContentType';
import VideoMessageContent from '../../wfc/messages/videoMessageContent';
import { exist } from '../../common/utils/FileUtil';
import { curves, display, window } from '@kit.ArkUI';
import { ifaa } from '@kit.OnlineAuthenticationKit';

interface MMMediaEntry {
    message: Message,
    type: string,
    url: string,
    thumbnail: string,
    videoController?: VideoController
}

//@Entry
//@Component
@CustomDialog
export default struct MMMessagePreviewDialog {
    @State mediaEntries: MMMediaEntry[] = []
    private message?: Message
    @State index: number = 0
    @State bgColor: string = '#000000'
    @State marginTop: number = 0
    private isLoadingOldMessage: boolean = false
    private isLoadingNewMessage: boolean = false
    private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Down });
    private displayHeight: number = 0
    private controller: CustomDialogController
    @State showVideoPlayIcon: boolean = false
    private isVideoPlaying = false

    async aboutToAppear() {
        // const params = router.getParams() as Record<string, Object>;
        // this.message = params['message'] as Message
        this.mediaEntries = [this.message!].map(msg => this.mediaEntry(msg))
        let oldMsgs = await this.loadMoreMessages(this.message!, true)
        let newMsgs = await this.loadMoreMessages(this.message!, false)
        this.mediaEntries = oldMsgs.map(msg => this.mediaEntry(msg))
            .concat(this.mediaEntries, newMsgs.map(msg => this.mediaEntry(msg)))
        this.index = oldMsgs.length

        let _display = display.getDefaultDisplaySync()
        this.displayHeight = _display.height;

        let entry = this.mediaEntries[this.index];
        this.showVideoPlayIcon = entry.type === 'video'
        // let windowClass: window.Window = await window.getLastWindow(getContext(this))
        //windowClass.setWindowBackgroundColor('#00000000')
    }

    loadMoreMessages(message: Message, before: boolean): Promise<Message[]> {
        return new Promise((resolve, reject) => {
            wfc.getMessagesByTimestampV2(message.conversation, [MessageContentType.Image, MessageContentType.Video], message.timestamp, before, 5, '', (msgs: Message[]) => {
                resolve(msgs)
            }, (err: number) => {
                resolve([])
            })
        })
    }

    onBackPress(): boolean | void {
        return true
    }

    isImageMessageContent(message: Message) {
        return message.messageContent.type === MessageContentType.Image
    }

    mediaEntry(message: Message): MMMediaEntry {
        if (this.isImageMessageContent(message)) {
            let imageMessageContent = message.messageContent as ImageMessageContent
            return {
                message: message,
                type: 'image',
                url: imageMessageContent.localPath && exist(imageMessageContent.localPath) ? 'file://' + imageMessageContent.localPath : imageMessageContent.remotePath,
                thumbnail: 'data:image/jpeg;base64,' + imageMessageContent.thumbnail
            } as MMMediaEntry

        } else {
            let videoMessageContent = message.messageContent as VideoMessageContent
            return {
                message: message,
                type: 'video',
                url: videoMessageContent.localPath && exist(videoMessageContent.localPath) ? 'file://' + videoMessageContent.localPath : videoMessageContent.remotePath,
                thumbnail: 'data:image/jpeg;base64,' + videoMessageContent.thumbnail,
                videoController: new VideoController()
            } as MMMediaEntry
        }
    }

    onActionUpdate(event: GestureEvent) {
        if (event.offsetY > 0) {
            let alpha = Math.ceil((1 - (vp2px(event.offsetY) / this.displayHeight)) * 255)
            this.bgColor = `#${alpha.toString(16)}000000`
            this.marginTop = event.offsetY;
        }
    }

    onActionEnd() {
        animateTo({ curve: curves.responsiveSpringMotion() }, () => {
            if (vp2px(this.marginTop) > this.displayHeight * 0.5) {
                this.bgColor = '#00000000'
                this.marginTop = this.displayHeight
                this.controller.close()
            } else {
                this.bgColor = '#000000'
                this.marginTop = 0
            }
        })
    }

    build() {
        Stack() {
            Swiper() {
                ForEach(this.mediaEntries, (entry: MMMediaEntry, index: number) => {
                    if (entry.type === 'image') {
                        Image(entry.url)
                            .alt(entry.thumbnail)
                            .objectFit(ImageFit.Contain)
                            .margin({ top: this.marginTop })
                            .width('100%')
                            .height('100%')// .backgroundColor('#EDEDED')
                                // .backgroundColor(this.bgColor)
                            .draggable(true)
                            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                            .gesture(// 绑定PanGesture事件，监听拖拽动作
                                PanGesture(this.panOption)
                                    .onActionStart((event: GestureEvent) => {
                                        console.info('Pan start');
                                    })
                                    .onActionUpdate((event: GestureEvent) => {
                                        this.onActionUpdate(event)
                                    })
                                    .onActionEnd(() => {
                                        this.onActionEnd()
                                    })
                            )
                    } else {
                        Video({
                            previewUri: entry.thumbnail,
                            src: entry.url,
                            controller: entry.videoController
                        })
                            .onDisAppear(() => {
                                // entry.videoController?.stop()
                            })
                            .autoPlay(false)
                            .controls(false)
                            .objectFit(ImageFit.Contain)
                            .width('100%')
                            .height('100%')
                            .margin({ top: this.marginTop })
                            .draggable(false)
                            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                            .gesture(// 绑定PanGesture事件，监听拖拽动作
                                PanGesture(this.panOption)
                                    .onActionStart((event: GestureEvent) => {
                                        console.info('Pan start');
                                    })
                                    .onActionUpdate((event: GestureEvent) => {
                                        this.onActionUpdate(event)
                                    })
                                    .onActionEnd(() => {
                                        this.onActionEnd()
                                    })
                            )
                            .onFinish(() => {
                                this.showVideoPlayIcon = true
                                this.isVideoPlaying = false
                            })
                            .onStart(() => {
                                this.showVideoPlayIcon = false
                            })
                            .onPause(() => {
                                this.showVideoPlayIcon = true
                                this.isVideoPlaying = false
                            })
                            .onClick(() => {
                                if (!this.showVideoPlayIcon) {
                                    entry.videoController?.pause()
                                }
                            })
                    }
                }, (entry: MMMediaEntry) => entry.message.messageId + '')
            }
            .indicator(false)
            .vertical(false)
            .index(this.index)
            .loop(false)
            // 关闭Swiper组件默认的裁切效果以便子节点可以绘制在Swiper外。
            .clip(false)
            .cachedCount(3)
            .onChange((index: number) => {
                let entry = this.mediaEntries[this.index];
                if (entry.type === 'video') {
                    entry.videoController?.stop()
                    entry.videoController?.reset()
                    this.isVideoPlaying = false
                }
                this.index = index
                entry = this.mediaEntries[index];
                if (entry.type === 'video') {
                    this.showVideoPlayIcon = true;
                } else {
                    this.showVideoPlayIcon = false
                }
                if (index < 3) {
                    if (this.isLoadingOldMessage) {
                        return
                    }
                    this.isLoadingOldMessage = true
                    this.loadMoreMessages(this.mediaEntries[0].message, true)
                        .then((msgs: Message[]) => {
                            this.index = msgs.length + this.index
                            this.mediaEntries = msgs.map(msg => this.mediaEntry(msg)).concat(this.mediaEntries)
                            this.isLoadingOldMessage = false
                        })
                } else if (index > this.mediaEntries.length - 3) {
                    if (this.isLoadingNewMessage) {
                        return
                    }
                    this.isLoadingNewMessage = true
                    this.loadMoreMessages(this.mediaEntries[this.mediaEntries.length - 1].message, false)
                        .then((msgs: Message[]) => {
                            this.mediaEntries = this.mediaEntries.concat(msgs.map(msg => this.mediaEntry(msg)))
                            this.isLoadingNewMessage = false
                        })

                }
            })
            .onGestureSwipe(index => {
                this.showVideoPlayIcon = false
            })
            .onAnimationEnd(index => {
                let entry = this.mediaEntries[index];
                if (!this.isVideoPlaying && entry.type === 'video') {
                    this.showVideoPlayIcon = true
                }
            })

            if (this.showVideoPlayIcon) {
                Column() {
                    Image($r('app.media.img_video_play_session'))
                        .width(40)
                        .height(40)
                        .onClick(() => {
                            let entry = this.mediaEntries[this.index];
                            entry.videoController?.start()
                            this.isVideoPlaying = true
                        })
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .margin({ top: this.marginTop })
            }

        }
        // }
        // .title('媒体文件预览')
        // .titleMode(NavigationTitleMode.Mini)
        // .hideTitleBar(true)
        // .hideToolBar(true)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .height('100%')
        .width('100%')

        .backgroundColor(this.bgColor)
    }
}