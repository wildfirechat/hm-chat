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
        }
        .backgroundColor(Color.Green)
        .width(100)
        .height(100)
    }
}