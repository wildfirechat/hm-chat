import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';
import ConversationInfo from '@wfc/client/src/main/ets/wfc/model/conversationInfo';
import BasicDataSource from '../../common/BasicDataSource';

export default class ConversationInfoDataSource extends BasicDataSource<ConversationInfo> {
  private conversationInfos: ConversationInfo[] = [];

  public setConversationInfos(conversationInfos: ConversationInfo[]): void {
    this.conversationInfos = conversationInfos
    this.notifyDataReload()
  }

  public removeConversationInfo(conversationInfo: ConversationInfo): void {
    let index = this.conversationInfos.findIndex((info: ConversationInfo) => Conversation.equal(info.conversation, conversationInfo.conversation))
    if (index >= 0) {
      this.conversationInfos.splice(index, 1)
      this.notifyDataDelete(index)
    }
  }

  public update(index: number, data: ConversationInfo): void {
    this.notifyDataChange(index)
  }

  public totalCount(): number {
    return this.conversationInfos.length;
  }

  public getData(index: number): ConversationInfo {
    return this.conversationInfos[index];
  }

  public addData(index: number, data: ConversationInfo): void {
    this.conversationInfos.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  public pushData(data: ConversationInfo): void {
    this.conversationInfos.push(data);
    this.notifyDataAdd(this.conversationInfos.length - 1);
  }
}
