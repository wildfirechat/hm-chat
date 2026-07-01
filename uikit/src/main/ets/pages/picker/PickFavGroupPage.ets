import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import PickFavGroupModal from './PickFavGroupModal'

@Component
export default struct PickFavGroupPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State @Watch('onShowModalChange') showPickFavGroupModal: boolean = true
    @State checkedFavGroupInfo: GroupInfo = {} as GroupInfo
    onCheckFavGroup?: (groupInfo: GroupInfo) => void

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            this.onCheckFavGroup = params['onCheckFavGroup'] as (groupInfo: GroupInfo) => void
        }
    }

    onShowModalChange() {
        if (!this.showPickFavGroupModal) {
            if (this.checkedFavGroupInfo && this.checkedFavGroupInfo.target) {
                if (this.onCheckFavGroup) {
                    this.onCheckFavGroup(this.checkedFavGroupInfo)
                }
            }
            this.mainNavPathStack.pop(true)
        }
    }

    build() {
        NavDestination() {
            PickFavGroupModal({
                showPickFavGroupModal: $showPickFavGroupModal,
                checkedFavGroupInfo: $checkedFavGroupInfo
            })
        }
        .hideTitleBar(true)
        .width('100%')
        .height('100%')
    }
}
