import PickMultiContactModal from './PickMultiContactModal'
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'

@Component
export default struct PickMultiContactPage {
    @State @Watch('onShowPickContactComponent') showPickContactComponent: boolean = true
    static TAG = 'PickContactPage'
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    // Parameters to pass down to PickMultiContactModal
    @State initialCheckedUserIds: string[] = []
    @State uncheckableUserIds: string[] = []
    @State showFavGroup: boolean = true
    onCheckUser?: (users: UserInfo[]) => void
    onCheckFavGroup?: (groupInfo: GroupInfo) => void

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            this.initialCheckedUserIds = (params['initialCheckedUserIds'] as string[]) || []
            this.uncheckableUserIds = (params['uncheckableUserIds'] as string[]) || []
            if (params['showFavGroup'] !== undefined) {
                this.showFavGroup = params['showFavGroup'] as boolean
            }
            this.onCheckUser = params['onCheckUser'] as (users: UserInfo[]) => void
            this.onCheckFavGroup = params['onCheckFavGroup'] as (groupInfo: GroupInfo) => void
        }
    }

    build() {
        NavDestination() {
            PickMultiContactModal({
                showPickContactModal: $showPickContactComponent,
                initialCheckedUserIds: this.initialCheckedUserIds,
                uncheckableUserIds: this.uncheckableUserIds,
                showFavGroup: this.showFavGroup,
                onCheckUser: (users: UserInfo[]) => {
                    this.showPickContactComponent = false
                    if (this.onCheckUser) {
                        this.onCheckUser(users)
                    } else {
                        LocalStorage.getShared().setOrCreate<UserInfo[]>(PickMultiContactModal.PICK_RESULT, users)
                    }
                },
                onCheckFavGroup: (groupInfo: GroupInfo) => {
                    this.showPickContactComponent = false
                    if (this.onCheckFavGroup) {
                        this.onCheckFavGroup(groupInfo)
                    }
                }
            })
        }
        .hideTitleBar(true)
        .width('100%')
        .height('100%')
    }

    onShowPickContactComponent() {
        if (!this.showPickContactComponent) {
            this.mainNavPathStack.pop(true);
        }
    }
}