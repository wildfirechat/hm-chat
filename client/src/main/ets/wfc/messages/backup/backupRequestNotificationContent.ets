//
// backupRequestNotificationContent.ets
// hm-chat client
//
// 备份请求通知消息
// iOS端请求备份到PC端时发送此通知
//

import wfc from '../../client/wfc';
import { JSONObject } from '../../type/types';
import Message from '../message';
import MessagePayload from '../messagePayload';
import NotificationMessageContent from '../notification/notificationMessageContent';
import MessageContentType from '../messageContentType';

/**
 * 备份请求通知消息内容
 */
export default class BackupRequestNotificationContent extends NotificationMessageContent {
  /**
   * 会话列表（JSON字符串）
   * 格式: [{conversation: {type, target, line}, messageCount: int}, ...]
   */
  conversationsJson: string = '';

  /**
   * 是否包含媒体文件
   */
  includeMedia: boolean = false;

  /**
   * 请求时间戳
   */
  timestamp: number = 0;

  constructor() {
    super(MessageContentType.Backup_Request);
  }

  /**
   * 编码消息内容
   */
  encode(): MessagePayload {
    const payload = super.encode();

    const dataDict: JSONObject = {};

    if (this.conversationsJson) {
      dataDict['c'] = this.conversationsJson;
    }
    dataDict['m'] = this.includeMedia;
    dataDict['t'] = this.timestamp;

    // 将对象转换为JSON字符串，然后转换为Base64
    const jsonStr = JSON.stringify(dataDict);
    payload.binaryContent = wfc.utf8_to_b64(jsonStr);

    return payload;
  }

  /**
   * 解码消息内容
   */
  decode(payload: MessagePayload): void {
    super.decode(payload);

    try {
      // 从Base64解码为UTF-8字符串，然后解析为JSON对象
      const jsonStr = wfc.b64_to_utf8(payload.binaryContent);
      const obj = JSON.parse(jsonStr) as JSONObject;

      this.conversationsJson = (obj['c'] as string) || '';
      this.includeMedia = (obj['m'] as boolean) || false;
      this.timestamp = (obj['t'] as number) || 0;
    } catch (error) {
      console.error('[BackupRequestNotificationContent] Failed to decode:', JSON.stringify(error));
    }
  }

  /**
   * 格式化通知文本
   */
  formatNotification(message?: Message): string {
    return '请求备份到电脑端';
  }
}
