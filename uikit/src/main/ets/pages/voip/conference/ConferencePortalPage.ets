import avenginekitImpl from '@wfc/avenginekit'
import wfc from '@wfc/client'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { uikitNavigationDestinations } from '../../uikitNavigationConfig'
import appServer from '../../../api/appServer';
import ConferenceInfo from '@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo'
import JoinConferenceDialog from './JoinConferenceDialog'
import { showToast } from '../../../common/utils/Toast'
import OptionItemView from '../../../view/OptionItemView'

@Component
export default struct ConferencePortalPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
    @State favConferenceInfos: ConferenceInfo[] = []
    private joinConferenceDialogController?: CustomDialogController

    aboutToAppear() {
        this.loadFavConferences()
    }

    loadFavConferences() {
        appServer.getFavConferences()
            .then(infos => {
                this.favConferenceInfos = infos.filter(info => {
                    return info.endTime * 1000 > new Date().getTime()
                });
            })
    }

    build() {
        NavDestination() {
            Column() {
                Row() {
                    Column() {
                        Image($r('app.media.av_join_conference'))
                            .height(60)
                            .width(60)
                            .borderRadius(4)
                        Text('加入会议')
                            .padding({ top: 5 })
                            .fontColor($r('app.color.wf_primary_text'))
                    }
                    .onClick(() => {
                        this.joinConferenceDialogController = new CustomDialogController({
                            builder: JoinConferenceDialog({
                                controller: this.joinConferenceDialogController,
                                onConfirm: (conferenceId: string, password: string) => {
                                    this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConferenceInfoPage, {
                                        'conferenceId': conferenceId,
                                        'password': password
                                    } as Record<string, string>)
                                }
                            }),
                            alignment: DialogAlignment.Center,
                        })
                        this.joinConferenceDialogController.open()
                    })

                    Column() {
                        Image($r('app.media.av_start_conference'))
                            .height(60)
                            .width(60)
                            .borderRadius(4)
                        Text('发起会议')
                            .padding({ top: 5 })
                            .fontColor($r('app.color.wf_primary_text'))
                    }
                    .onClick(async () => {
                        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.StartConferencePage, {} as Record<string, Object>)
                    })

                    Column() {
                        Image($r('app.media.av_book_conference'))
                            .height(60)
                            .width(60)
                            .borderRadius(4)
                        Text('预定会议')
                            .padding({ top: 5 })
                            .fontColor($r('app.color.wf_primary_text'))
                    }
                    .onClick(() => {
                        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.OrderConferencePage, {} as Record<string, Object>)
                    })
                }
                .width('100%')
                .padding({ top: 20, bottom: 20 })
                .backgroundColor($r('app.color.wf_background'))
                .justifyContent(FlexAlign.SpaceAround)

                Stack() {
                    List() {
                        ForEach(this.favConferenceInfos, (info: ConferenceInfo, index: number) => {
                            ListItem() {
                                OptionItemView({
                                    title: info.conferenceTitle,
                                    subTitle: info.startTime * 1000 < new Date().getTime() ? '会议已开始，请尽快加入' : '会议尚未开始',
                                    showRightArrow: false
                                })
                            }
                            .onClick(() => {
                                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConferenceInfoPage, {
                                    'conferenceId': info.conferenceId,
                                    'password': info.password
                                } as Record<string, string>)
                            })
                        }, (info: ConferenceInfo, index: number) => {
                            return index + ''
                        })
                    }
                    .divider({
                        strokeWidth: 0.5,
                        color: $r('app.color.wf_divider'),
                        startMargin: 16,
                        endMargin: 16
                    })
                    .backgroundColor($r('app.color.wf_background'))
                    .width('100%')
                    .height('100%')

                    Row() {
                        Text('会议记录')
                            .padding({ right: 10 })
                            .fontColor($r('app.color.wf_primary'))
                            .onClick(() => {
                                showToast('TODO')
                            })
                    }
                    .visibility(Visibility.Hidden)
                    .width('100%')
                    .justifyContent(FlexAlign.End)
                }
                .width('100%')
                .margin({ top: 10 })
                .layoutWeight(1)
            }
            .height('100%')
            .width('100%')
        }
        .onShown(() => {
            this.loadFavConferences()
        })
        .title('会议')
        .backgroundColor($r('app.color.wf_primary_background_color'))
        .height('100%')
        .width('100%')
    }
}
