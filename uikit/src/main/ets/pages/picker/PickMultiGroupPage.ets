/*
 * Copyright (c) 2024 WildFireChat. All rights reserved.
 */

import GroupInfo from '@wfc/client/src/main/ets/wfc/model/groupInfo'
import PickMultiGroupModal from './PickMultiGroupModal'

@Component
export default struct PickMultiGroupPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State @Watch('onShowModalChange') showPickGroupModal: boolean = true

    onShowModalChange() {
        if (!this.showPickGroupModal) {
            this.mainNavPathStack.pop(true)
        }
    }

    build() {
        NavDestination() {
            PickMultiGroupModal({ showPickGroupModal: $showPickGroupModal })
        }
        .hideTitleBar(true)
        .width('100%')
        .height('100%')
    }
}
