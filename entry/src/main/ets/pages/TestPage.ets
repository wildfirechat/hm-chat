import AVSessionManager from '@ohos.multimedia.avsession';
import { AVCastPicker } from '@kit.AVSessionKit';
import orgServer from '../api/orgServer'
import TestCustomMessageContent from '../wfc_custom_message/testCustomMessageContent';
import Conversation from '../wfc/model/conversation';
import ConversationType from '../wfc/model/conversationType';
import wfc from '../wfc/client/wfc';


@Entry
@Component
struct TestPage {
    async onPageShow() {
        // 开始创建并激活媒体会话
        // 创建session
        let context: Context = getContext(this)
        let type: AVSessionManager.AVSessionType = 'voice_call';
        let session = await AVSessionManager.createAVSession(context, 'SESSION_NAME', type);
        console.log('AVSession成功：' + JSON.stringify(session))
        // 激活接口要在元数据、控制命令注册完成之后再执行
        await session.activate();
    }

    // 创建组件，并设置大小
    build() {
        Navigation() {
            Row() {
                Column() {
                    Text('本页用于 API 功能测试')
                }

                Button('test')
                    .onClick(() => {
                        let content = new TestCustomMessageContent('hello hm-chat')
                        let conversation = new Conversation(ConversationType.Single, 'uiuJuJcc', 0)
                        wfc.sendConversationMessage(conversation, content)
                    })
            }
        }
        .title('API 测试页')
        .titleMode(NavigationTitleMode.Mini)
        .navBarPosition(NavBarPosition.Start)
    }
}