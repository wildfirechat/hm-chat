//
// restoreResponseNotificationContent.ets
// hm-chat client
//
// 恢复响应通知消息
// PC端响应iOS端的恢复请求
//

import wfc from '../../client/wfc';
import { JSONObject } from '../../type/types';
import Message from '../message';
import MessagePayload from '../messagePayload';
import NotificationMessageContent from '../notification/notificationMessageContent';
import MessageContentType from '../messageContentType';

/**
 * 恢复响应通知消息内容
 */
export default class RestoreResponseNotificationContent extends NotificationMessageContent {
  /**
   * 是否同意恢复
   */
  approved: boolean = false;

  /**
   * 服务器IP
   */
  serverIP: string = '';

  /**
   * 服务器端口
   */
  serverPort: number = 0;

  constructor() {
    super(MessageContentType.Restore_Response);
  }

  /**
   * 创建拒绝消息
   */
  static rejectedResponse(): RestoreResponseNotificationContent {
    const content = new RestoreResponseNotificationContent();
    content.approved = false;
    return content;
  }

  /**
   * 创建同意消息
   */
  static approvedResponse(ip: string, port: number): RestoreResponseNotificationContent {
    const content = new RestoreResponseNotificationContent();
    content.approved = true;
    content.serverIP = ip;
    content.serverPort = port;
    return content;
  }

  /**
   * 编码消息内容
   */
  encode(): MessagePayload {
    const payload = super.encode();

    const dataDict: JSONObject = {};
    dataDict['a'] = this.approved;

    if (this.approved) {
      if (this.serverIP) {
        dataDict['ip'] = this.serverIP;
      }
      dataDict['p'] = this.serverPort;
    }

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

      this.approved = (obj['a'] as boolean) || false;

      if (this.approved) {
        this.serverIP = (obj['ip'] as string) || '';
        this.serverPort = (obj['p'] as number) || 0;
      }
    } catch (error) {
      console.error('[RestoreResponseNotificationContent] Failed to decode:', JSON.stringify(error));
    }
  }

  /**
   * 格式化通知文本
   */
  formatNotification(message?: Message): string {
    return this.approved ? '已同意从电脑端恢复' : '已拒绝从电脑端恢复';
  }
}
