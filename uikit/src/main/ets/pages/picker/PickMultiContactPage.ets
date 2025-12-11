import PickMultiContactModal from './PickMultiContactModal'

@Component
export default struct PickMultiContactPage {
    @State @Watch('onShowPickContactComponent') showPickContactComponent: boolean = true
    static TAG = 'PickContactPage'
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    build() {
        NavDestination() {
            PickMultiContactModal({ showPickContactModal: $showPickContactComponent })
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