import { showToast } from '../../common/utils/Toast'
import { GlobalContext } from '../../globalContext'
import { window } from '@kit.ArkUI'

@Entry
@Component
export default struct VoipFloatingPage {
    @State now: number = new Date().getTime()

    onPageShow(): void {
        setInterval(() => {
            this.now = new Date().getTime()
        }, 1000)
    }

    build() {
        Column() {
            Text('' + this.now)
                .onClick(() => {
                    showToast('Test')
                })
        }
        .touchable(true)
        // .hitTestBehavior(HitTestMode.Block)
        .onTouch(event => {
            if (event.type === TouchType.Move) {
                let windowClass: window.Window | undefined = GlobalContext.getContext()
                    .getObject<window.Window>('voipWindow')

                windowClass?.moveWindowTo(event.touches[0].displayX, event.touches[0].displayY)

            }
        })
        .backgroundColor(Color.Green)
        .width(100)
        .height(100)
    }
}