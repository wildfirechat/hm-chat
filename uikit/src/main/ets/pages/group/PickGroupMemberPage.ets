import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo'
import PickGroupMemberModal from './PickGroupMemberModal'

@Component
export default struct PickGroupMemberPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State @Watch('onShowModalChange') showPickGroupMemberModal: boolean = true
    groupId: string = ''
    uncheckableUserIds: string[] = []
    title: string = '选择成员'
    singleCheck: boolean = false
    excludeUserIds: string[] = []
    onPickResult?: (users: UserInfo[]) => void

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            this.groupId = params['groupId'] as string
            this.uncheckableUserIds = params['uncheckableUserIds'] as string[] || []
            this.title = params['title'] as string || '选择成员'
            this.onPickResult = params['onPickResult'] as (users: UserInfo[]) => void
            if (params['singleCheck'] !== undefined) {
                this.singleCheck = params['singleCheck'] as boolean
            }
            this.excludeUserIds = params['excludeUserIds'] as string[] || []
        }
    }

    onShowModalChange() {
        if (!this.showPickGroupMemberModal) {
            if (this.onPickResult) {
                let localStorage = LocalStorage.getShared();
                let pickUsers = localStorage.get<UserInfo[]>(PickGroupMemberModal.PICK_RESULT);
                if (pickUsers?.length) {
                    localStorage.delete(PickGroupMemberModal.PICK_RESULT)
                    this.onPickResult(pickUsers)
                }
            }
            this.mainNavPathStack.pop(true)
        }
    }

    build() {
        NavDestination() {
            PickGroupMemberModal({
                groupId: this.groupId,
                showPickGroupMemberModal: $showPickGroupMemberModal,
                uncheckableUserIds: this.uncheckableUserIds,
                excludeUserIds: this.excludeUserIds,
                singleCheck: this.singleCheck,
                title: this.title
            })
        }
        .hideTitleBar(true)
        .width('100%')
        .height('100%')
    }
}
