import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import PickContactModal from './PickContactModal'

@Component
export default struct PickContactPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State @Watch('onShowModalChange') showPickContactModal: boolean = true
    onClickUser?: (user: UserInfo) => void

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            this.onClickUser = params['onClickUser'] as (user: UserInfo) => void
        }
    }

    onShowModalChange() {
        if (!this.showPickContactModal) {
            this.mainNavPathStack.pop(true)
        }
    }

    build() {
        NavDestination() {
            PickContactModal({
                showPickContactModal: $showPickContactModal,
                onClickUser: (user: UserInfo) => {
                    this.showPickContactModal = false
                    this.onClickUser?.(user)
                }
            })
        }
        .hideTitleBar(true)
        .width('100%')
        .height('100%')
    }
}
