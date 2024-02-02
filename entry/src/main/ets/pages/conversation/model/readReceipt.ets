import ConversationType from '../../../wfc/model/conversationType'

export default class ReadReceipt {
    conversationType: ConversationType
    readCount: number
    // 群会话时有效
    unreadCount: number
    desc: string
}