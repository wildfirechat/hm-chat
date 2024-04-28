import PickContactComponent from './PickContactComponent'
import { router } from '@kit.ArkUI'
import UserInfo from '../../wfc/model/userInfo'

@Entry
@Component
export default struct PickContactPage {
    @State @Watch('onShowPickContactComponent') showPickContactComponent: boolean = true
    static TAG = 'PickContactPage'

    // @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    build() {
        Column() {
            PickContactComponent({ showPickContactComponent: $showPickContactComponent })
        }
        .width('100%')
        .height('100%')
    }

    onShowPickContactComponent() {
        if (!this.showPickContactComponent) {
            let localStorage = LocalStorage.getShared();
            let pickUsers = localStorage.get<UserInfo[]>(PickContactComponent.PICK_RESULT);
            let options: router.RouterOptions = {
                url: '',
                params: {
                    tag: PickContactPage.TAG,
                    result: pickUsers,
                }
            }
            router.back(options)
        }
    }
}