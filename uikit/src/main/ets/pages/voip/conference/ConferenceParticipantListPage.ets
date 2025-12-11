import { window } from "@kit.ArkUI";
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import avengineKit from '@wfc/avenginekit'
import CallSession from "@wfc/avenginekit/src/main/ets/wfc/av/engine/callSession";
import wfc from "@wfc/client";
import EventType from '@wfc/client/src/main/ets/wfc/client/wfcEvent'
import { uikitNavigationDestinations } from "../../uikitNavigationConfig";
import ConferenceInviteMessageContent from '@wfc/client/src/main/ets/wfc/av/messages/conferenceInviteMessageContent'
import Message from '@wfc/client/src/main/ets/wfc/messages/message'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConferenceInfo from "@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo";

@Component
export default struct ConferenceParticipantListPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State participantUserInfos: UserInfo[] = []
    private conferenceInfo?: ConferenceInfo

    build() {
        NavDestination() {
            Column() {
                ForEach(this.participantUserInfos, (userInfo: UserInfo, index: number) => {
                    Row() {
                        Image(userInfo.portrait)
                            .width(40)
                            .height(40)
                            .borderRadius(4)
                            .margin({ left: 10 })
                        Text(userInfo.displayName)
                            .margin({ left: 10 })
                            .maxLines(1)
                    }
                    .height(60)
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                }, (userInfo: UserInfo, index: number) => {
                    return userInfo.uid
                })
            }
        }
        .backgroundColor('#EDEDED')
        .height('100%')
        .width('100%')
        .hideTitleBar(false)
        .title('参会人员')
        .menus([
            {
                value: '邀请',
                icon: 'resources/base/media/ic_tab_add.png',
                action: () => {
                    this.inviteNewParticipant()
                }
            }
        ])
    }

    aboutToAppear(): void {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let callId = params['callId'] as string;
        this.conferenceInfo = params['conferenceInfo'] as ConferenceInfo
        let callSession = avengineKit.getCurrentSession()
        if (!callSession || callSession.callId !== callId) {
            this.mainNavPathStack.pop()
            return
        }

        let win = AppStorage.get<window.Window>('window')
        win?.setWindowLayoutFullScreen(false)
        let sysBarProps: window.SystemBarProperties = {
            // statusBarColor: '#00000000',
            // navigationBarColor: '#00000000',
            // 以下两个属性从API Version 8开始支持
            navigationBarContentColor: '#000000',
            statusBarContentColor: '#000000',
        };
        win?.setWindowSystemBarProperties(sysBarProps)

        this.showParticipants(callSession)

        wfc.eventEmitter?.on(EventType.UserInfosUpdate, this.onUserInfosUpdate)
    }

    aboutToDisappear(): void {
        wfc.eventEmitter?.off(EventType.UserInfosUpdate, this.onUserInfosUpdate)

    }

    showParticipants(callSession: CallSession) {
        let participantIds = callSession.getParticipantIds()
        this.participantUserInfos = wfc.getUserInfos([wfc.getUserId(), ...participantIds])
    }

    inviteNewParticipant() {
        let info = this.conferenceInfo!
        let inviteMessageContent = new ConferenceInviteMessageContent(info.conferenceId, info.owner, info.conferenceTitle, '', info.startTime, false, false, info.advance, info.pin, info.password)
        let dummyConversation = new Conversation(0, '', 0)
        let message = new Message(dummyConversation, inviteMessageContent)
        this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ForwardMessagePage,
            {
                'messages': [message]
            } as Record<string, Object>
        )
    }

    onUserInfosUpdate = (usersInfos: UserInfo[]) => {
        for (const info of usersInfos) {
            let index = this.participantUserInfos.findIndex(u => u.uid === info.uid)
            if (index >= 0) {
                this.participantUserInfos[index] = info
            }
        }
    }
}
