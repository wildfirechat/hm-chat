//
// restoreRequestNotificationContent.ets
// hm-chat client
//
// 恢复请求通知消息
// iOS端请求PC端提供恢复备份列表
//

import wfc from '../../client/wfc';
import { JSONObject } from '../../type/types';
import Message from '../message';
import MessagePayload from '../messagePayload';
import NotificationMessageContent from '../notification/notificationMessageContent';
import MessageContentType from '../messageContentType';

/**
 * 恢复请求通知消息内容
 */
export default class RestoreRequestNotificationContent extends NotificationMessageContent {
  /**
   * 请求时间戳
   */
  timestamp: number = 0;

  constructor() {
    super(MessageContentType.Restore_Request);
  }

  /**
   * 创建恢复请求消息
   */
  static create(timestamp: number): RestoreRequestNotificationContent {
    const content = new RestoreRequestNotificationContent();
    content.timestamp = timestamp;
    return content;
  }

  /**
   * 编码消息内容
   */
  encode(): MessagePayload {
    const payload = super.encode();

    const dataDict: JSONObject = {};
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

      this.timestamp = (obj['t'] as number) || 0;
    } catch (error) {
      console.error('[RestoreRequestNotificationContent] Failed to decode:', JSON.stringify(error));
    }
  }

  /**
   * 格式化通知文本
   */
  formatNotification(message?: Message): string {
    return '请求从电脑端恢复备份';
  }
}
