import AVSessionManager from '@ohos.multimedia.avsession';
import { AVCastPicker } from '@kit.AVSessionKit';
import orgServer from '../api/orgServer'


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
                        orgServer.login()
                            .then(async () => {
                                let orgs = await orgServer.getRootOrganization();
                                console.log('xxxxxxx', orgs.length)
                            })
                    })
            }
        }
        .title('API 测试页')
        .titleMode(NavigationTitleMode.Mini)
        .navBarPosition(NavBarPosition.Start)
    }
}