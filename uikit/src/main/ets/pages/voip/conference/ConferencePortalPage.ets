import avenginekitImpl from '@wfc/avenginekit'
import wfc from '@wfc/client'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { navigationDestinations } from '../../navigationConfig'
import appServer from '../../../api/appServer';
import ConferenceInfo from '@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo'
import JoinConferenceDialog from './JoinConferenceDialog'
import { showToast } from '../../../common/utils/Toast'
import OptionItemView from '../../../view/OptionItemView'

@Entry
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
            Row() {
                Column() {
                    Image($r('app.media.av_join_conference'))
                        .height(60)
                        .width(60)
                        .borderRadius(4)
                    Text('加入会议')
                        .padding({ top: 5 })
                }
                .onClick(() => {
                    this.joinConferenceDialogController = new CustomDialogController({
                        builder: JoinConferenceDialog({
                            controller: this.joinConferenceDialogController,
                            onConfirm: (conferenceId: string, password: string) => {
                                this.mainNavPathStack.pushPathByName(navigationDestinations.ConferenceInfoPage, {
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
                }
                .onClick(async () => {
                    // let conferenceInfo = new ConferenceInfo();
                    // conferenceInfo.conferenceTitle = 'Test';
                    // conferenceInfo.pin = '123456'
                    // conferenceInfo.owner = wfc.getUserId()
                    // conferenceInfo.startTime = Math.ceil(new Date().getTime() / 1000)
                    // conferenceInfo.endTime = Math.ceil(new Date().getTime() / 1000 + 3600)
                    // let conferenceId = await appServer.createConference(conferenceInfo)
                    // avenginekitImpl.startConference(conferenceId, false, conferenceInfo.pin, wfc.getUserId(), conferenceInfo.conferenceTitle, 'desc', false, false)
                    this.mainNavPathStack.pushPathByName(navigationDestinations.StartConferencePage, {} as Record<string, Object>)

                })

                Column() {
                    Image($r('app.media.av_book_conference'))
                        .height(60)
                        .width(60)
                        .borderRadius(4)
                    Text('预定会议')
                        .padding({ top: 5 })
                }
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.OrderConferencePage, {} as Record<string, Object>)
                })
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
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
                            this.mainNavPathStack.pushPathByName(navigationDestinations.ConferenceInfoPage, {
                                'conferenceId': info.conferenceId,
                                'password': info.password
                            } as Record<string, string>)

                        })

                    }, (info: ConferenceInfo, index: number) => {
                        return index + ''
                    })
                }
                .width('100%')
                .height('100%')

                Row() {
                    Text('会议记录')
                        .padding({ right: 10 })
                        .fontColor('#3B62E0')
                        .onClick(() => {
                            showToast('TODO')
                        })
                }
                .visibility(Visibility.Hidden)
                .width('100%')
                .justifyContent(FlexAlign.End)

            }
            .width('100%')

        }
        .onShown(() => {
            this.loadFavConferences()
        })
        .title('会议')
        .height('100%')
        .width('100%')
    }
}
