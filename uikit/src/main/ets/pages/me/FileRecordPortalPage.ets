import { showToast } from '../../common/utils/Toast'
import OptionItemView from '../../view/OptionItemView'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import ConversationType from '@wfc/client/src/main/ets/wfc/model/conversationType'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import { navigationDestinations } from '../navigationConfig'
import PickConversationModal from '../picker/PickConversationModal'
import PickContactModal from '../picker/PickContactModal'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'

@Component
export default struct FileRecordPortalPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State showPickConversationModal: boolean = false
    @State showPickContactModal: boolean = false

    aboutToAppear() {
    }

    @Builder
    pickConversationModal() {
        PickConversationModal({
            onClickConversation: conversation => {
                this.mainNavPathStack.pushPathByName(navigationDestinations.FileRecordPage, {
                    'conversation': conversation.conversation,
                } as Record<string, Object>)
                this.showPickConversationModal = false
            }
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    @Builder
    pickSingleContactModal() {
        PickContactModal({
            showPickContactModal: $showPickContactModal,
            onClickUser: (user: UserInfo) => {
                this.mainNavPathStack.pushPathByName(navigationDestinations.FileRecordPage, {
                    'userId': user.uid,
                } as Record<string, Object>)
                this.showPickContactModal = false
            },
        })
            .height('100%')
            .width('100%')
            .margin({ top: px2vp(AppStorage.get<number>('SafeAreaTopHeight')) })
            .backgroundColor(Color.White)
    }

    build() {
        NavDestination() {
            OptionItemView({
                title: '所有文件',
                showDivider: false
            })
                .margin({ top: 10 })
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.FileRecordPage, {} as Record<string, Object>)
                })
            OptionItemView({
                title: '我的文件',
                showDivider: false
            })
                .margin({ top: 10 })
                .onClick(() => {
                    this.mainNavPathStack.pushPathByName(navigationDestinations.FileRecordPage, {
                        'myFile': true
                    } as Record<string, Object>)
                })
            OptionItemView({
                title: '会话文件',
                showDivider: false
            })
                .margin({ top: 10 })
                .onClick(() => {
                    this.showPickConversationModal = true
                })
                .bindContentCover($$this.showPickConversationModal,
                    this.pickConversationModal(),
                    {
                        modalTransition: ModalTransition.DEFAULT,
                        onDisappear: () => {
                        }
                    })
            OptionItemView({
                title: '用户文件',
                showDivider: false
            })
                .margin({ top: 10 })
                .onClick(() => {
                    this.showPickContactModal = true
                })
                .bindContentCover($$this.showPickContactModal,
                    this.pickSingleContactModal(),
                    {
                        modalTransition: ModalTransition.DEFAULT,
                        onDisappear: () => {
                        }
                    })

        }
        .title('文件记录')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}
