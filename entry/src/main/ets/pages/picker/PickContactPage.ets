import PickContactComponent from './PickContactComponent'

@Entry
@Component
export default struct PickContactPage {
    @State @Watch('onShowPickContactComponent') showPickContactComponent: boolean = true
    static TAG = 'PickContactPage'
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    build() {
        NavDestination() {
            PickContactComponent({ showPickContactComponent: $showPickContactComponent })
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