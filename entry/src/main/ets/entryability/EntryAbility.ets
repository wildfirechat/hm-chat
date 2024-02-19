import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import data_preferences from '@ohos.data.preferences';
import wfc from '../wfc/client/wfc'
import Config from '../config'
import EventType from '../wfc/client/wfcEvent';
import Message from '../wfc/messages/message';
import ConversationType from '../wfc/model/conversationType';

import NotificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import MessageConfig from '../wfc/client/messageConfig';
import PersistFlag from '../wfc/messages/persistFlag';
import RecallMessageNotification from '../wfc/messages/notification/recallMessageNotification';
import Utils from '../common/Utils';

export default class EntryAbility extends UIAbility {
    private windowStage: window.WindowStage
    private isBackground: boolean

    onCreate(want, launchParam) {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');

        wfc.init(this.context.getApplicationContext(), this.context.eventHub, this.context.filesDir, Config.getWFCPlatform());
        this.context.eventHub.on(EventType.ReceiveMessage, (msg: Message) => {
            if (this.isBackground) {
                // notification
                this.notify(msg)
            }
        })
        // TODO
        // 好友请求通知

        // wfc.setConnectionStatusListener(async (status) => {
        //     console.log('connectionStatus changed', status);
        //     // TODO 有的状态码时，需要清 session
        //     if (status === -6) {
        //         let preference = await data_preferences.getPreferences(this.context, 'wfcstore')
        //         if (preference) {
        //             preference.clear()
        //             preference.flush()
        //         }
        //         let url = 'pages/Login'
        //         this.loadContent(url)
        //     }
        // })
    }

    onDestroy() {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage: window.WindowStage) {
        // Main window is created, set main page for this ability
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
        this.windowStage = windowStage;

        let url = 'pages/LoginPage';
        data_preferences.getPreferences(this.context, 'wfcstore', async (err, val) => {
            if (err) {
                console.error("Failed to get preferences. code =" + err.code + ", message =" + err.message);
            } else {
                let preferences = val;
                try {
                    let userId = await preferences.get('userId', null) as string
                    let token = await preferences.get('token', null) as string
                    if (userId && token) {
                        url = 'pages/MainPage'
                        wfc.connect(userId, token);
                    }
                } catch (e) {

                }
            }
            this.loadContent(url);
        })

        // setConnectionStatusListener((value) => {
        //   hilog.info(0x0000, 'testTag', 'connection status changed: %{public}d', value);
        // });
    }

    onWindowStageDestroy() {
        // Main window is destroyed, release UI related resources
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    }

    onForeground() {
        // Ability has brought to foreground
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
        this.isBackground = false
    }

    onBackground() {
        // Ability has back to background
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
        this.isBackground = true
    }

    private loadContent(url: string) {
        // this.windowStage.getMainWindowSync().setWindowBackgroundColor('#EDEDED')
        this.windowStage.loadContent(url, (err, data) => {
            if (err.code) {
                hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
                return;
            }
            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
    }

    private async notify(msg: Message) {
        if (msg.direction === 0 || (MessageConfig.getMessageContentPersistFlag(msg.messageContent.type) !== PersistFlag.Persist_And_Count) && !(msg.messageContent instanceof RecallMessageNotification)) {
            return
        }

        let conversationInfo = wfc.getConversationInfo(msg.conversation)
        if (conversationInfo && conversationInfo.isSilent) {
            return
        }

        let title: string
        if (msg.conversation.type === ConversationType.Single) {
            let name = wfc.getUserDisplayName(msg.conversation.target)
            title = name ? name : '新消息'
        } else if (msg.conversation.type === ConversationType.Group) {
            let groupInfo = wfc.getGroupInfo(msg.conversation.target, false)
            title = groupInfo ? (groupInfo.remark ? groupInfo.remark : groupInfo.name) : '群聊'
        } else if (msg.conversation.type === ConversationType.Channel) {
            let channelInfo = wfc.getChannelInfo(msg.conversation.target, false)
            title = channelInfo ? channelInfo.name : '频道消息'
        } else {
            title = '新消息'
        }

        let text: string = msg.messageContent.pushContent
        text = text ? text : msg.messageContent.digest(msg)

        let unreadCount = wfc.getConversationUnreadCount(msg.conversation)
        if (unreadCount.unread > 1) {
            text = `[${unreadCount.unread}条] ${text}`
        }

        let wantAgentObj = null; // 用于保存创建成功的wantAgent对象，后续使用其完成触发的动作。

        // 通过WantAgentInfo的operationType设置动作类型。
        let wantAgentInfo = {
            wants: [
                {
                    deviceId: '',
                    bundleName: 'cn.wildfirechat.messenger',
                    abilityName: 'EntryAbility',
                    action: '',
                    entities: [],
                    uri: '',
                    parameters: {}
                }
            ],
            operationType: wantAgent.OperationType.START_ABILITY,
            requestCode: 0,
            wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
        }

        // 创建WantAgent
        wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo);

        let notificationRequest = {
            id: Utils.hashCode(msg.conversation.type + '-' + msg.conversation.target + '-' + msg.conversation.line),
            content: {
                contentType: NotificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 普通文本类型通知
                normal: {
                    title: title,
                    text: text,
                    // additionalText: 'test_additionalText',
                }
            },
            label: '野火IM消息通知',
            wantAgent: wantAgentObj
        }


        NotificationManager.publish(notificationRequest, (err) => {
            if (err) {
                console.error(`[ANS] failed to publish, error[${err}]`);
                return;
            }
            console.info(`[ANS] publish success`);
        });
    }
}
