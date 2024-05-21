// https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/arkui-ts/ts-universal-attributes-component-id.md
import wfc from '../wfc/client/wfc'
import ChannelInfo from '../wfc/model/channelInfo'
import ChatRoomInfo from '../wfc/model/chatRoomInfo'
import Conversation from '../wfc/model/conversation'
import ConversationInfo from '../wfc/model/conversationInfo'
import ConversationType from '../wfc/model/conversationType'
import GroupInfo from '../wfc/model/groupInfo'
import { PortraitAndName } from './Types'

export default class Utils {
    static rect_left: number
    static rect_top: number
    static rect_right: number
    static rect_bottom: number
    static rect_value: Record<string, number>

    //获取组件所占矩形区域坐标
    static getComponentRect(key: string): Record<string, number> | null {
        let strJson = getInspectorByKey(key)
        if (!strJson) {
            return null
        }
        let obj: Record<string, string> = JSON.parse(strJson)
        console.info("[getInspectorByKey] current component obj is: " + JSON.stringify(obj))
        let rectInfo: string[] = JSON.parse('[' + obj.$rect + ']')
        console.info("[getInspectorByKey] rectInfo is: " + rectInfo)
        Utils.rect_left = JSON.parse('[' + rectInfo[0] + ']')[0]
        Utils.rect_top = JSON.parse('[' + rectInfo[0] + ']')[1]
        Utils.rect_right = JSON.parse('[' + rectInfo[1] + ']')[0]
        Utils.rect_bottom = JSON.parse('[' + rectInfo[1] + ']')[1]
        return Utils.rect_value = {
            "left": Utils.rect_left, "top": Utils.rect_top, "right": Utils.rect_right, "bottom": Utils.rect_bottom
        }
    }

    static computeConversationItemPortraitAndName(conversation: Conversation): Promise<PortraitAndName> {
        return new Promise((resolve, reject) => {

            if (conversation.type === ConversationType.Single) {
                let userInfo = wfc.getUserInfo(conversation.target)
                resolve({
                    portrait: userInfo.portrait,
                    name: userInfo.displayName
                })
                // fixme
                // wfc.getUserInfoEx(conversation.target, false, (info: UserInfo) => {
                //     this.conversationItemPortrait = info.portrait
                // }, null)
            } else if (conversation.type === ConversationType.Group) {
                let groupInfo: GroupInfo = wfc.getGroupInfo(conversation.target)
                resolve({
                    portrait: groupInfo.portrait!,
                    name: groupInfo.remark ? groupInfo.remark : groupInfo.name
                })
            } else if (conversation.type === ConversationType.Channel) {
                let channelInfo: ChannelInfo = wfc.getChannelInfo(conversation.target, false)
                resolve({
                    portrait: channelInfo.portrait,
                    name: channelInfo.name
                })
            } else if (conversation.type === ConversationType.ChatRoom) {
                wfc.getChatroomInfo(conversation.target, 0, (info: ChatRoomInfo) => {
                    resolve({
                        portrait: info.portrait,
                        name: info.title
                    })
                }, err => {
                    reject(err)
                })
            }
        })
    }
}
