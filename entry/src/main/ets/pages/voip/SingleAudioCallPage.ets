import UserInfo from '../../wfc/model/userInfo'

@Preview
@Entry
@Component
export default struct SingleAudioCallPage {
    @State targetUserInfo?: UserInfo = undefined
    @State selfUserInfo?: UserInfo = undefined
    @State tip: string = '等待对方接听'
    @State isIncoming: boolean = true
    @State state: number = 0

    aboutToAppear(): void {
        this.targetUserInfo = new UserInfo();
        this.targetUserInfo.uid = 'uid'
        this.targetUserInfo.displayName = '测试'
        this.targetUserInfo.portrait = 'https://static.wildfirechat.net/ic_launcher.png';

        this.selfUserInfo = this.targetUserInfo
    }

    // router 路由才生效
    onBackPress(): boolean | void {
        return true
    }

    build() {
        Navigation() {
            Stack() {
                Image(this.targetUserInfo?.portrait)
                    .draggable(false)
                    .width('100%')
                    .height('100%')
                Column() {
                    Stack() {
                        Row() {
                            Image($r('app.media.av_minimize'))
                                .draggable(false)
                                .width(30)
                                .height(30)
                        }
                        .width('100%')

                        Text('10:00')
                            .width('100%')
                            .fontColor(Color.White)
                            .textAlign(TextAlign.Center)
                            .alignSelf(ItemAlign.Center)
                    }
                    .width('100%')
                    .padding(20)

                    if (this.isIncoming) {
                        Column() {
                            Image(this.selfUserInfo?.portrait)
                                .draggable(false)
                                .borderRadius(6)
                                .width(100)
                                .height(100)
                            Text(this.tip)
                                .fontSize(14)
                                .fontColor('#848687')

                            Row() {
                                Column() {
                                    Image($r('app.media.av_hang_up'))
                                        .draggable(false)
                                        .clickEffect({ level: ClickEffectLevel.MIDDLE })
                                        .width(60)
                                        .height(60)
                                    Text('挂断')
                                        .margin({ top: 10 })
                                        .fontSize(13)
                                        .fontColor(Color.White)
                                }

                                Column() {
                                    Image($r('app.media.av_voice_answer'))
                                        .draggable(false)
                                        .width(60)
                                        .height(60)
                                        .clickEffect({ level: ClickEffectLevel.LIGHT })
                                    Text('接听')
                                        .margin({ top: 10 })
                                        .fontSize(13)
                                        .fontColor(Color.White)
                                }
                            }
                            .padding({ top: 20 })
                            .width('100%')
                            .justifyContent(FlexAlign.SpaceAround)

                        }
                        .width('100%')
                        .flexGrow(1)
                        .justifyContent(FlexAlign.SpaceAround)
                    } else {
                        Column() {
                            Image(this.selfUserInfo?.portrait)
                                .draggable(false)
                                .borderRadius(6)
                                .width(100)
                                .height(100)
                            Text(this.tip)
                                .fontSize(14)
                                .fontColor('#848687')

                            Row() {
                                Column() {
                                    Image($r('app.media.av_mute'))
                                        .draggable(false)
                                        .width(60)
                                        .height(60)
                                    Text('麦克风')
                                        .margin({ top: 10 })
                                        .fontSize(13)
                                        .fontColor(Color.White)
                                }

                                Column() {
                                    Image($r('app.media.av_hang_up'))
                                        .draggable(false)
                                        .width(60)
                                        .height(60)
                                    Text('挂断')
                                        .margin({ top: 10 })
                                        .fontSize(13)
                                        .fontColor(Color.White)
                                }

                                Column() {
                                    Image($r('app.media.av_handfree'))
                                        .draggable(false)
                                        .width(60)
                                        .height(60)
                                    Text('扬声器已关')
                                        .margin({ top: 10 })
                                        .fontSize(13)
                                        .fontColor(Color.White)
                                }
                            }
                            .padding({ top: 20 })
                            .width('100%')
                            .justifyContent(FlexAlign.SpaceAround)

                        }
                        .width('100%')
                        .flexGrow(1)
                        .justifyContent(FlexAlign.SpaceAround)
                    }
                }
                .justifyContent(FlexAlign.Start)
                .width('100%')
                .height('100%')
                .backgroundColor('#c0000000')
            }
        }
        .title('Voip Test')
        .hideTitleBar(true)
        .backgroundColor('#c0000000')

        // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
}