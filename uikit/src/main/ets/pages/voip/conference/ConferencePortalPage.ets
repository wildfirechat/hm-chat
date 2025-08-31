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

@Entry
@Component
export default struct ConferencePortalPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack
    private joinConferenceDialogController?: CustomDialogController

    aboutToAppear() {
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
                    this.mainNavPathStack.pushPathByName(navigationDestinations.OrderConferencePage , {} as Record<string, Object>)
                })
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .justifyContent(FlexAlign.SpaceAround)

            Stack() {
                List() {
                    ListItem() {
                        Row() {
                            Text('会议 1')
                        }
                    }

                }
                .width('100%')
                .padding(10)

                Row() {
                    Text('会议记录')
                        .padding({ right: 10 })
                        .fontColor('#3B62E0')
                        .onClick(() => {
                            showToast('TODO')
                        })
                }
                .width('100%')
                .justifyContent(FlexAlign.End)

            }
            .width('100%')

        }
        .title('会议')
        .height('100%')
        .width('100%')
    }
}
