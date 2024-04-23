import Message from '../wfc/messages/message'
import notificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import { WantAgent } from '@ohos.app.ability.wantAgent';
import Base from '@ohos.base';
import wfc from '../wfc/client/wfc';

class WfcNotificationManager {
    private notificationMessages: Message[] = []

    constructor() {
    }

    async onReceiveMessage(message: Message, hasMore: boolean) {
        if (message.messageId === 0) {
            return;
        }
        let id = this.notificationId(message);
        let title = '新消息'
        let text = message.messageContent.formatNotification(message)

        let wantAgentObj = await this.buildWantAgent(message);
        this.showNotification(id, title, text, wantAgentObj)
    }

    notificationId(message: Message) {
        // TODO
        return message.messageId;
    }

    unreadCount() {
        // todo
        return 1;
    }

    buildWantAgent(message: Message): Promise<WantAgent> {
        return new Promise<WantAgent>((resolve, reject) => {
            // 通过WantAgentInfo的operationType设置动作类型
            let wantAgentInfo: wantAgent.WantAgentInfo = {
                wants: [
                    {
                        deviceId: '',
                        bundleName: 'cn.wildfirechat.messenger',
                        abilityName: 'EntryAbility',
                        action: '',
                        entities: [],
                        uri: '',
                        parameters: {
                            conversation: message.conversation,
                        }
                    }
                ],
                operationType: wantAgent.OperationType.START_ABILITY,
                requestCode: 0,
                wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]

            };

            // 创建WantAgent
            wantAgent.getWantAgent(wantAgentInfo, (err: Base.BusinessError, data: WantAgent) => {
                if (err) {
                    console.error(`Failed to get want agent. Code is ${err.code}, message is ${err.message}`);
                    reject(err)
                    return;
                }
                console.info('Succeeded in getting want agent.');
                resolve(data)
            });
        })
    }

    async showNotification(id: number, title: string, text: string, wantAgent: WantAgent) {
        let notificationRequest: notificationManager.NotificationRequest = {
            id: id,
            wantAgent: wantAgent,
            notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
            badgeNumber: this.unreadCount(),
            content: {
                notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 普通文本类型通知
                normal: {
                    title: title,
                    text: text,
                    // additionalText: 'test_additionalText',
                }
            }
        };
        notificationManager.publish(notificationRequest, (err: Base.BusinessError) => {
            if (err) {
                console.error(`Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
                return;
            }
            console.info('Succeeded in publishing notification.');
        });
    }
}

const self = new WfcNotificationManager()

export default self